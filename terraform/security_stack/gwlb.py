import sys
import time
import json
from pprint import pprint

import boto3
from botocore import loaders

# import datetime
# from dateutil.tz import tzutc


def main():

    def create():

        # Modify Security VPC TGW Attachment to enable appliance mode
        try:
            ec2_client.modify_transit_gateway_vpc_attachment(TransitGatewayAttachmentId=tgw_sec_attach_id,
                                                             Options={
                                                                 'ApplianceModeSupport': 'enable'}
                                                             )
            pprint(f'Modified Security VPC TGW Attachment to enable appliance mode.')
        except Exception as e:
            pprint(f'Failed to Modify Security VPC TGW Attachment to enable appliance mode: {str(e)}')

        # Create Gateway Load Balancer
        try:
            agw = agw_client.create_load_balancer(Name=f'sec-gwlb-{deployment_id}',
                                                  Subnets=sec_data_subnet,
                                                  Type='gateway')
            pprint('Gateway Load Balancer:')
            pprint(agw)
        except Exception as e:
            pprint(f'Failed to Deploy Gateway Load Balancer: {str(e)}')
            return 1, {}

        # Create Target Group
        try:
            agw_tg = agw_client.create_target_group(Name=f'sec-gwlb-tg-{deployment_id}',
                                                    Protocol='GENEVE',
                                                    Port=6081,
                                                    VpcId=sec_vpc,
                                                    TargetType='instance',
                                                    HealthCheckEnabled=True,
                                                    HealthCheckPort='80',
                                                    HealthCheckProtocol='TCP'
                                                    )
            pprint('Taget Group:')
            pprint(agw_tg)
        except Exception as e:
            pprint(f'Failed to Deploy Target Group: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn']}

        # Wait for GWLB to be available
        while True:
            time.sleep(30)
            lb = agw_client.describe_load_balancers(
                LoadBalancerArns=[agw['LoadBalancers'][0]['LoadBalancerArn']])
            if lb['LoadBalancers'][0]['State']['Code'] == 'active':
                pprint('Gateway Load Balancer is now in Active State.')
                break
            elif lb['LoadBalancers'][0]['State']['Code'] == 'provisioning':
                pprint('Gateway Load Balancer is provisioning...')
                continue
            else:
                pprint('Gateway Load Balancer deployment failed.')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn']}

        # Create Listener
        try:
            agw_listener = agw_client.create_listener(
                LoadBalancerArn=agw['LoadBalancers'][0]['LoadBalancerArn'],
                DefaultActions=[{
                    'Type': 'forward',
                    'TargetGroupArn': agw_tg['TargetGroups'][0]['TargetGroupArn']
                },
                ],
            )
            pprint('Gateway Load Balancer Listener:')
            pprint(agw_listener)
        except Exception as e:
            pprint(f'Failed to Deploy Listener: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn']}

        # Register instance as a target
        try:
            for iid in instance_id:
                register = agw_client.register_targets(
                    TargetGroupArn=agw_tg['TargetGroups'][0]['TargetGroupArn'],
                    Targets=[{'Id': iid}]
                )
                pprint(f'Instance {iid} Registration:')
                pprint(register)
        except Exception as e:
            pprint(f'Failed to Register Instance as target: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                       'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn']}

        # Create VPC Endpoint Service
        try:
            agwe_service = agwe_client.create_vpc_endpoint_service_configuration(
                GatewayLoadBalancerArns=[agw['LoadBalancers'][0]['LoadBalancerArn']],
                AcceptanceRequired=False)
            pprint('VPC Endpoint Service:')
            pprint(agwe_service)
        except Exception as e:
            pprint(f'Failed to Deploy VPC Endpoint Service: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                       'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn']}

        # Wait for VPC Endpoint Service to be available
        while True:
            time.sleep(30)
            service = agwe_client.describe_vpc_endpoint_service_configurations(
                ServiceIds=[agwe_service['ServiceConfiguration']['ServiceId']])
            if service['ServiceConfigurations'][0]['ServiceState'].lower() == 'available':
                pprint('VPC Endpoint Service is now in Available State.')
                break
            elif service['ServiceConfigurations'][0]['ServiceState'].lower() == 'pending':
                pprint('VPC Endpoint Service is in pending state...')
                continue
            else:
                pprint('VPC Endpoint Service deployment failed.')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId']}

        # Modify VPC Endpoint Service Permissions
        agwe_service_permissions = agwe_client.modify_vpc_endpoint_service_permissions(
            ServiceId=agwe_service['ServiceConfiguration']['ServiceId'],
            AddAllowedPrincipals=[
                f'arn:aws:iam::{account_id}:root',
            ])
        pprint('VPC Endpoint Service Permission:')
        pprint(agwe_service_permissions)

        # Wait for VPC Endpoint Service to be available
        while True:
            time.sleep(30)
            service = agwe_client.describe_vpc_endpoint_service_configurations(
                ServiceIds=[agwe_service['ServiceConfiguration']['ServiceId']])
            if service['ServiceConfigurations'][0]['ServiceState'].lower() == 'available':
                pprint('VPC Endpoint Service is now in Available State.')
                break
            elif service['ServiceConfigurations'][0]['ServiceState'].lower() == 'pending':
                pprint('VPC Endpoint Service is in pending state...')
                continue
            else:
                pprint('VPC Endpoint Service deployment failed.')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId']}

        # Create GWLB Endpoint (OB traffic)
        agwe = []

        for idx, subnet in enumerate(sec_agwe_subnet):
            try:
                agwe.append(agwe_client.create_vpc_endpoint(VpcEndpointType='GatewayLoadBalancer',
                                                            VpcId=sec_vpc,
                                                            SubnetIds=[subnet],
                                                            ServiceName=agwe_service['ServiceConfiguration']['ServiceName']))
                pprint(f'Gateway Load Balancer Outbound Endpoint {idx}:')
                pprint(agwe[idx])
            except Exception as e:
                pprint(f'Failed to Deploy VPC Endpoint {idx}(Gateway Load Balancer Endpoint): {str(e)}')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId']}

        # Get all AGWE IDs
        agwe_ids = []
        for endpoint in agwe:
            agwe_ids.append(endpoint['VpcEndpoint']['VpcEndpointId'])

        # Wait for VPC Endpoints to be Available
        time.sleep(30)
        for idx, endpoint in enumerate(agwe):
            while True:
                agwe_state = agwe_client.describe_vpc_endpoints(
                    VpcEndpointIds=[endpoint['VpcEndpoint']['VpcEndpointId']])
                pprint(agwe_state['VpcEndpoints'][0]['State'])
                if agwe_state['VpcEndpoints'][0]['State'].lower() == 'available':
                    pprint(f'VPC Endpoint {idx} is now in Available State.')
                    break
                elif agwe_state['VpcEndpoints'][0]['State'].lower() == 'pending':
                    pprint(f'VPC Endpoint {idx} is in pending state...')
                    time.sleep(30)
                    continue
                else:
                    pprint(f'VPC Endpoint {idx} deployment failed.')
                    return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                               'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                               'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                               'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                               'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                               'agwe_id': agwe_ids}

        # Create AGW Endpoint (EW traffic)
        agwe_ew = []
        for idx, subnet in enumerate(sec_agwe_ew_subnet):
            try:
                agwe_ew.append(agwe_client.create_vpc_endpoint(VpcEndpointType='GatewayLoadBalancer',
                                                               VpcId=sec_vpc,
                                                               SubnetIds=[subnet],
                                                               ServiceName=agwe_service['ServiceConfiguration']['ServiceName']))
                pprint(f'Gateway Load Balancer East-West Endpoint {idx}:')
                pprint(agwe_ew[idx])
            except Exception as e:
                pprint(f'Failed to Deploy VPC Endpoint {idx}(Gateway Load Balancer Endpoint): {str(e)}')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                           'agwe_id': agwe_ids}

        # Get all AGWE-EW IDs
        agwe_ew_ids = []
        for endpoint in agwe_ew:
            agwe_ew_ids.append(endpoint['VpcEndpoint']['VpcEndpointId'])

        # Wait for VPC Endpoint to be Available
        time.sleep(30)
        for idx, endpoint in enumerate(agwe_ew):
            while True:
                agwe_state_ew = agwe_client.describe_vpc_endpoints(
                    VpcEndpointIds=[endpoint['VpcEndpoint']['VpcEndpointId']])
                pprint(agwe_state_ew['VpcEndpoints'][0]['State'])
                if agwe_state_ew['VpcEndpoints'][0]['State'].lower() == 'available':
                    pprint(f'VPC Endpoint {idx} is now in Available State.')
                    break
                elif agwe_state_ew['VpcEndpoints'][0]['State'].lower() == 'pending':
                    pprint(f'VPC Endpoint {idx} is in pending state...')
                    time.sleep(30)
                    continue
                else:
                    pprint(f'VPC Endpoint {idx} deployment failed.')
                    return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                               'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                               'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                               'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                               'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                               'agwe_id': agwe_ids,
                               'agwe_ew_id': agwe_ew_ids}

        # Create Route on TGWA Route Table(0.0.0.0/0->GWLBE_OB)
        for idx, rt_id in enumerate(sec_tgwa_route_table_id):
            try:
                route = agwe_client.create_route(
                    RouteTableId=rt_id,
                    DestinationCidrBlock='0.0.0.0/0',
                    VpcEndpointId=agwe_ids[idx]
                )
                pprint(f'Route from TGWA {idx} to GWLBE_OB {idx}:')
                pprint(route)
            except Exception as e:
                pprint(f'Failed to Deploy Route on TGWA {idx} Route Table {rt_id}: {str(e)}')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                           'agwe_id': agwe_ids,
                           'agwe_ew_id': agwe_ew_ids}

        return 0, {'agw': agw,
                   'agw_tg': agw_tg,
                   'agw_listener': agw_listener,
                   'agwe_service': agwe_service,
                   'agwe': agwe,
                   'agwe_ew': agwe_ew,
                   'agwe_ids': agwe_ids,
                   'agwe_ew_ids': agwe_ew_ids,
                   'route_tgwa_agwe': {'rt_id': sec_tgwa_route_table_id, 'dst_cidr': '0.0.0.0/0'},
                   'State': 'Create Complete'}

    def destroy(**kwargs):
        agwe_ew_id = kwargs.get('agwe_ew_id', None)
        agwe_id = kwargs.get('agwe_id', None)
        agwe_service_id = kwargs.get('agwe_service_id', None)
        agw_listener_arn = kwargs.get('agw_listener_arn', None)
        agw_tg_arn = kwargs.get('agw_tg_arn', None)
        agw_arn = kwargs.get('agw_arn', None)
        route_tgwa_agwe = kwargs.get('route_tgwa_agwe', None)

        # Delete Route from TGWA to GWLBE
        if route_tgwa_agwe:
            for idx, rt_id in enumerate(route_tgwa_agwe['rt_id']):
                route = agwe_client.delete_route(
                    RouteTableId=rt_id,
                    DestinationCidrBlock=route_tgwa_agwe['dst_cidr'],
                )
                pprint(f'Route {idx} from TGWA to GWLBE Destroy:')
                pprint(route)
                time.sleep(10)

        # Delete GWLB Endpoint(East-West)
        if agwe_ew_id:
            agwe_ew = agwe_client.delete_vpc_endpoints(
                VpcEndpointIds=agwe_ew_id)
            pprint('Gateway Load Balancer East-West Endpoint(s) Destroy:')
            pprint(agwe_ew)
            time.sleep(30)

        # Delete GWLB Endpoint(Outbound)
        if agwe_id:
            agwe = agwe_client.delete_vpc_endpoints(
                VpcEndpointIds=agwe_id)
            pprint('Gateway Load Balancer Outbound Endpoint(s) Destroy:')
            pprint(agwe)
            time.sleep(30)

        # Delete VPC Endpoint Service
        if agwe_service_id:
            agwe_service = agwe_client.delete_vpc_endpoint_service_configurations(
                ServiceIds=[agwe_service_id]
            )
            pprint('VPC Endpoint Service Destroy:')
            pprint(agwe_service)
            time.sleep(60)

        # Delete Listener
        if agw_listener_arn:
            agw_listener = agw_client.delete_listener(
                ListenerArn=agw_listener_arn
            )
            pprint('Gateway Load Balancer Listener Destroy:')
            pprint(agw_listener)
            time.sleep(30)

        # Delete Target Group
        if agw_tg_arn:
            agw_tg = agw_client.delete_target_group(
                TargetGroupArn=agw_tg_arn
            )
            pprint('Gateway Load Balancer Target group Destroy:')
            pprint(agw_tg)
            time.sleep(30)

        # Delete Gateway Load Balancer
        if agw_arn:
            agw = agw_client.delete_load_balancer(
                LoadBalancerArn=agw_arn
            )
            pprint('Gateway Load Balancer Destroy:')
            pprint(agw)
            time.sleep(30)

        return 0, {'State': 'Destroy Complete'}

    # Fetch state info
    state_file = 'handoff_state.json'
    with open(state_file, 'r') as inputfile:
        state_info = json.load(inputfile)

    pprint('State File:')
    pprint(state_info)

    # Get Credentials
    secret_key_id = state_info['access_key']
    secret_access_key = state_info['secret_key']
    region = state_info['region']
    deployment_id = state_info['deployment_id']
    sec_vpc = state_info['sec_vpc']
    sec_data_subnet = state_info['sec_data_subnet']
    sec_agwe_subnet = state_info['sec_agwe_subnet']
    sec_agwe_ew_subnet = state_info['sec_agwe_ew_subnet']
    sec_tgwa_route_table_id = state_info['sec_tgwa_route_table_id']
    instance_id = state_info['instance_id']
    account_id = state_info['account_id']
    tgw_sec_attach_id = state_info['tgw_sec_attach_id']

    # Create Gateway Load Balancer Resources for Boto3
    ec2_client = boto3.client('ec2',
                              aws_access_key_id=secret_key_id,
                              aws_secret_access_key=secret_access_key,
                              region_name=region)
    try:
        loader_client = loaders.create_loader()
        loader_client.load_service_model('elbv2-gwlb', 'service-2')
        loader_client.load_service_model('ec2-gwlbe', 'service-2')

        # Create Boto3 resources
        agw_client = boto3.client('elbv2-gwlb',
                                  aws_access_key_id=secret_key_id,
                                  aws_secret_access_key=secret_access_key,
                                  region_name=region)
        agwe_client = boto3.client('ec2-gwlbe',
                                   aws_access_key_id=secret_key_id,
                                   aws_secret_access_key=secret_access_key,
                                   region_name=region)
    except:
        # Create Boto3 resources
        agw_client = boto3.client('elbv2',
                                  aws_access_key_id=secret_key_id,
                                  aws_secret_access_key=secret_access_key,
                                  region_name=region)
        agwe_client = boto3.client('ec2',
                                   aws_access_key_id=secret_key_id,
                                   aws_secret_access_key=secret_access_key,
                                   region_name=region)

    if sys.argv[1] == 'create':
        create_status, create_output = create()
        if create_status != 0:
            pprint('Destroying to maintain state...')
            destroy_status, destroy_output = destroy(**create_output)
            pprint('Destroy Output')
            pprint(destroy_output)
        else:
            pprint('Create Complete.')
            with open(state_file, 'w') as outputfile:
                state_info['agw_arn'] = create_output['agw']['LoadBalancers'][0]['LoadBalancerArn']
                state_info['agw_tg_arn'] = create_output['agw_tg']['TargetGroups'][0]['TargetGroupArn']
                state_info['agw_listener_arn'] = create_output['agw_listener']['Listeners'][0]['ListenerArn']
                state_info['agwe_service_name'] = create_output['agwe_service']['ServiceConfiguration']['ServiceName']
                state_info['agwe_service_id'] = create_output['agwe_service']['ServiceConfiguration']['ServiceId']
                state_info['agwe_id'] = create_output['agwe_ids']
                state_info['agwe_ew_id'] = create_output['agwe_ew_ids']
                state_info['route_tgwa_agwe'] = create_output['route_tgwa_agwe']
                json.dump(state_info, outputfile)
        exit(create_status)
    elif sys.argv[1] == 'destroy':
        destroy_status, destroy_output = destroy(**state_info)
        pprint('Destroy Output')
        pprint(destroy_output)
        exit(destroy_status)


if __name__ == '__main__':
    main()
