import sys
import time
import json
from pprint import pprint

import boto3
from botocore import loaders

import datetime
from dateutil.tz import tzutc


def main():

    def create():

        # Create Appliance Gateway
        try:
            agw = agw_client.create_load_balancer(Name=f'sec-agw-{deployment_id}',
                                                  Subnets=[sec_data_subnet],
                                                  Type='appliance')
            pprint('Appliance Gateway:')
            pprint(agw)
        except Exception as e:
            pprint(f'Failed to Deploy Appliance Gateway: {str(e)}')
            return 1, {}

        # Create Target Group
        try:
            agw_tg = agw_client.create_target_group(Name=f'sec-agw-tg-{deployment_id}',
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

        # Wait for AGW to be available
        while True:
            time.sleep(30)
            lb = agw_client.describe_load_balancers(
                LoadBalancerArns=[agw['LoadBalancers'][0]['LoadBalancerArn']])
            if lb['LoadBalancers'][0]['State']['Code'] == 'active':
                pprint('Appliance Gateway is now in Active State.')
                break
            elif lb['LoadBalancers'][0]['State']['Code'] == 'provisioning':
                pprint('Appliance Gateway is provisioning...')
                continue
            else:
                pprint('Appliance Gateway deployment failed.')
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
            pprint('Appliance Gateway Listener:')
            pprint(agw_listener)
        except Exception as e:
            pprint(f'Failed to Deploy Listener: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn']}

        # Register instance as a target
        try:
            register = agw_client.register_targets(
                TargetGroupArn=agw_tg['TargetGroups'][0]['TargetGroupArn'],
                Targets=[{'Id': instance_id}]
            )
            pprint('Instance Registration:')
            pprint(register)
        except Exception as e:
            pprint(f'Failed to Register Instance as target: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                       'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn']}

        # Create VPC Endpoint Service
        try:
            agwe_service = agwe_client.create_vpc_endpoint_service_configuration(
                ApplianceLoadBalancerArns=[agw['LoadBalancers'][0]['LoadBalancerArn']],
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

        # Create AGW Endpoint
        try:
            agwe = agwe_client.create_vpc_endpoint(VpcEndpointType='Appliance',
                                                   VpcId=sec_vpc,
                                                   SubnetIds=[sec_agwe_subnet],
                                                   ServiceName=agwe_service['ServiceConfiguration']['ServiceName'])
            pprint('Appliance Gateway Endpoint:')
            pprint(agwe)
        except Exception as e:
            pprint(f'Failed to Deploy VPC Endpoint(Appliance Gateway Endpoint): {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                       'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                       'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                       'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId']}

        # Wait for VPC Endpoint to be Available
        while True:
            time.sleep(30)
            agwe_state = agwe_client.describe_vpc_endpoints(
                VpcEndpointIds=[agwe['VpcEndpoint']['VpcEndpointId']])
            pprint(agwe_state['VpcEndpoints'][0]['State'])
            if agwe_state['VpcEndpoints'][0]['State'].lower() == 'available':
                pprint('VPC Endpoint is now in Available State.')
                break
            elif agwe_state['VpcEndpoints'][0]['State'].lower() == 'pending':
                pprint('VPC Endpoint is in pending state...')
                continue
            else:
                pprint('VPC Endpoint deployment failed.')
                return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                           'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                           'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                           'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                           'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                           'agwe_id': agwe['VpcEndpoint']['VpcEndpointId']}

        # Create Route on TGWA Route Table(0.0.0.0/0->AGWE)
        try:
            route = agwe_client.create_route(
                RouteTableId=sec_tgwa_route_table_id,
                DestinationCidrBlock='0.0.0.0/0',
                VpcEndpointId=agwe['VpcEndpoint']['VpcEndpointId']
            )
            pprint('Route from TGWA to AGWE:')
            pprint(route)
        except Exception as e:
            pprint(f'Failed to Deploy Route on TGWA Route Table: {str(e)}')
            return 1, {'agw_arn': agw['LoadBalancers'][0]['LoadBalancerArn'],
                       'agw_tg_arn': agw_tg['TargetGroups'][0]['TargetGroupArn'],
                       'agw_listener_arn': agw_listener['Listeners'][0]['ListenerArn'],
                       'agwe_service_name': agwe_service['ServiceConfiguration']['ServiceName'],
                       'agwe_service_id': agwe_service['ServiceConfiguration']['ServiceId'],
                       'agwe_id': agwe['VpcEndpoint']['VpcEndpointId']}

        return 0, {'agw': agw,
                   'agw_tg': agw_tg,
                   'agw_listener': agw_listener,
                   'agwe_service': agwe_service,
                   'agwe': agwe,
                   'route_tgwa_agwe': {'rt_id': sec_tgwa_route_table_id, 'dst_cidr': '0.0.0.0/0'},
                   'State': 'Create Complete'}

    def destroy(**kwargs):
        agwe_id = kwargs.get('agwe_id', None)
        agwe_service_id = kwargs.get('agwe_service_id', None)
        agw_listener_arn = kwargs.get('agw_listener_arn', None)
        agw_tg_arn = kwargs.get('agw_tg_arn', None)
        agw_arn = kwargs.get('agw_arn', None)
        route_tgwa_agwe = kwargs.get('route_tgwa_agwe', None)

        # Delete Route from TGWA to AGWE
        if route_tgwa_agwe:
            route = agwe_client.delete_route(
                RouteTableId=route_tgwa_agwe['rt_id'],
                DestinationCidrBlock=route_tgwa_agwe['dst_cidr'],
            )
            pprint('Route from TGWA to AGWE Destroy:')
            pprint(route)
            time.sleep(10)

        # Delete AGW Endpoint
        if agwe_id:
            agwe = agwe_client.delete_vpc_endpoints(
                VpcEndpointIds=[agwe_id])
            pprint('Appliance Gateway Endpoint Destroy:')
            pprint(agwe)
            time.sleep(60)

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
            pprint('Appliance Gateway Listener Destroy:')
            pprint(agw_listener)
            time.sleep(30)

        # Delete Target Group
        if agw_tg_arn:
            agw_tg = agw_client.delete_target_group(
                TargetGroupArn=agw_tg_arn
            )
            pprint('Appliance Gateway Target group Destroy:')
            pprint(agw_tg)
            time.sleep(30)

        # Delete Appliance Gateway
        if agw_arn:
            agw = agw_client.delete_load_balancer(
                LoadBalancerArn=agw_arn
            )
            pprint('Appliance Gateway Destroy:')
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
    sec_tgwa_route_table_id = state_info['sec_tgwa_route_table_id']
    instance_id = state_info['instance_id']
    account_id = state_info['account_id']

    # Create Appliance Gateway Resources for Boto3
    loader_client = loaders.create_loader()
    loader_client.load_service_model('elbv2-agw', 'service-2')
    loader_client.load_service_model('ec2-agwe', 'service-2')

    # Create Boto3 resources
    agw_client = boto3.client('elbv2-agw',
                              aws_access_key_id=secret_key_id,
                              aws_secret_access_key=secret_access_key,
                              region_name=region)
    agwe_client = boto3.client('ec2-agwe',
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
                state_info['agwe_id'] = create_output['agwe']['VpcEndpoint']['VpcEndpointId']
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
