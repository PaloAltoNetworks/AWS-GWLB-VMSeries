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
        # Wait for VPC Endpoint Service to be available
        while True:
            service = agwe_client.describe_vpc_endpoint_service_configurations(
                ServiceIds=[agwe_service_id])
            if service['ServiceConfigurations'][0]['ServiceState'].lower() == 'available':
                pprint('VPC Endpoint Service is now in Available State.')
                break
            elif service['ServiceConfigurations'][0]['ServiceState'].lower() == 'pending':
                pprint('VPC Endpoint Service is in pending state...')
                time.sleep(30)
                continue
            else:
                pprint('VPC Endpoint Service deployment failed.')
                return 1, {}

        # Create GWLB Endpoint
        try:
            agwe = agwe_client.create_vpc_endpoint(VpcEndpointType='GatewayLoadBalancer',
                                                   VpcId=app_vpc,
                                                   SubnetIds=[app_agwe_subnet],
                                                   ServiceName=agwe_service_name)
            pprint('Gateway Load Balancer Endpoint:')
            pprint(agwe)
        except Exception as e:
            pprint(f'Failed to Deploy VPC Endpoint(Gateway Load Balancer Endpoint): {str(e)}')
            return 1, {}

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
                return 1, {'agwe_id': agwe['VpcEndpoint']['VpcEndpointId']}

        # Create Route on IGW Route Table(APP_LB->GWLBE)
        route1 = []
        for alb_cidr in app_data_subnet_cidr:
            route1.append(agwe_client.create_route(
                RouteTableId=igw_route_table_id,
                DestinationCidrBlock=alb_cidr,
                VpcEndpointId=agwe['VpcEndpoint']['VpcEndpointId']
            ))
        pprint('Route from IGW to GWLBE:')
        pprint(route1)

        # Create Route on ALB Route Table(0.0.0.0/0->GWLBE)
        route2 = agwe_client.create_route(
            RouteTableId=alb_route_table_id,
            DestinationCidrBlock='0.0.0.0/0',
            VpcEndpointId=agwe['VpcEndpoint']['VpcEndpointId']
        )
        pprint('Route from ALB to GWLBE:')
        pprint(route2)

        # Create Route on SEC-NATGW Route Table(APP->SEC-GWLBE-OB)
        for idx, rt_id in enumerate(sec_natgw_route_table_id):
            route3 = agwe_client.create_route(
                RouteTableId=rt_id,
                DestinationCidrBlock=app_vpc_cidr,
                VpcEndpointId=sec_agwe_ob_id[idx]
            )
            pprint(f'Route from SEC-NATGW {idx} to SEC-GWLBE-OB {idx}:')
            pprint(route3)

        # Create Route on SEC-TGWA Route Table(SEC-TGWA->SEC-GWLBE-EW)
        for idx, rt_id in enumerate(sec_tgwa_route_table_id):
            route4 = agwe_client.create_route(
                RouteTableId=rt_id,
                DestinationCidrBlock=app_vpc_cidr,
                VpcEndpointId=sec_agwe_ew_id[idx]
            )
            pprint(f'Route from SEC-TGWA {idx} to SEC-GWLBE-EW {idx}:')
            pprint(route4)

        return 0, {'agwe': agwe,
                   'route_igw_agwe': {'rt_id': igw_route_table_id, 'dst_cidr': app_data_subnet_cidr},
                   'route_alb_agwe': {'rt_id': alb_route_table_id, 'dst_cidr': '0.0.0.0/0'},
                   'route_sec_natgw_sec_agwe': {'rt_id': sec_natgw_route_table_id, 'dst_cidr': app_vpc_cidr},
                   'route_sec_tgwa_sec_agwe_ew': {'rt_id': sec_tgwa_route_table_id, 'dst_cidr': app_vpc_cidr},
                   'State': 'Create Complete'}

    def destroy(**kwargs):
        agwe_id = kwargs.get('agwe_id', None)
        route_igw_agwe = kwargs.get('route_igw_agwe', None)
        route_alb_agwe = kwargs.get('route_alb_agwe', None)
        route_sec_natgw_sec_agwe = kwargs.get('route_sec_natgw_sec_agwe', None)
        route_sec_tgwa_sec_agwe_ew = kwargs.get('route_sec_tgwa_sec_agwe_ew', None)

        # Delete Route from IGW to GWLBE
        if route_igw_agwe:
            for alb_cidr in route_igw_agwe['dst_cidr']:
                route = agwe_client.delete_route(
                    RouteTableId=route_igw_agwe['rt_id'],
                    DestinationCidrBlock=alb_cidr,
                )
                pprint('Route from IGW to GWLBE Destroy:')
                pprint(route)
                time.sleep(10)

        # Delete Route from APP to GWLBE
        if route_alb_agwe:
            route = agwe_client.delete_route(
                RouteTableId=route_alb_agwe['rt_id'],
                DestinationCidrBlock=route_alb_agwe['dst_cidr'],
            )
            pprint('Route from APP to GWLBE Destroy:')
            pprint(route)
            time.sleep(10)

        # Delete Route from SEC-NATGW to SEC-GWLBE
        if route_sec_natgw_sec_agwe:
            for idx, rt_id in enumerate(route_sec_natgw_sec_agwe['rt_id']):
                route = agwe_client.delete_route(
                    RouteTableId=rt_id,
                    DestinationCidrBlock=route_sec_natgw_sec_agwe['dst_cidr'],
                )
                pprint(f'Route from SEC-NATGW {idx} to SEC-GWLBE-OB {idx} Destroy:')
                pprint(route)
                time.sleep(10)

        # Delete Route from SEC-TGWA to SEC-GWLBE-EW
        if route_sec_tgwa_sec_agwe_ew:
            for idx, rt_id in enumerate(route_sec_tgwa_sec_agwe_ew['rt_id']):
                route = agwe_client.delete_route(
                    RouteTableId=rt_id,
                    DestinationCidrBlock=route_sec_tgwa_sec_agwe_ew['dst_cidr'],
                )
                pprint('Route from SEC-TGWA to SEC-GWLBE-EW Destroy:')
                pprint(route)
                time.sleep(10)

        # Delete AGW Endpoint
        if agwe_id:
            agwe = agwe_client.delete_vpc_endpoints(
                VpcEndpointIds=[agwe_id])
            pprint('Gateway Load Balancer Endpoint Destroy:')
            pprint(agwe)
            time.sleep(60)

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
    app_vpc = state_info['app_vpc']
    app_agwe_subnet = state_info['app_agwe_subnet']
    agwe_service_id = state_info['agwe_service_id']
    agwe_service_name = state_info['agwe_service_name']
    app_vpc_cidr = state_info['app_vpc_cidr']
    igw_route_table_id = state_info['igw_route_table_id']
    app_data_subnet_cidr = state_info['app_data_subnet_cidr']
    alb_route_table_id = state_info['alb_route_table_id']

    sec_natgw_route_table_id = state_info['sec_natgw_route_table_id']
    sec_agwe_ob_id = state_info['sec_agwe_ob_id']
    sec_agwe_ew_id = state_info['sec_agwe_ew_id']
    sec_tgwa_route_table_id = state_info['sec_tgwa_route_table_id']

    try:
        # Create Gateway Load Balancer Resources for Boto3
        loader_client = loaders.create_loader()
        loader_client.load_service_model('ec2-gwlbe', 'service-2')

        # Create Boto3 resources
        agwe_client = boto3.client('ec2-gwlbe',
                                   aws_access_key_id=secret_key_id,
                                   aws_secret_access_key=secret_access_key,
                                   region_name=region)
    except:
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
                state_info['agwe_id'] = create_output['agwe']['VpcEndpoint']['VpcEndpointId']
                state_info['route_igw_agwe'] = create_output["route_igw_agwe"]
                state_info['route_alb_agwe'] = create_output["route_alb_agwe"]
                state_info['route_sec_natgw_sec_agwe'] = create_output["route_sec_natgw_sec_agwe"]
                state_info['route_sec_tgwa_sec_agwe_ew'] = create_output["route_sec_tgwa_sec_agwe_ew"]
                json.dump(state_info, outputfile)
        exit(create_status)
    elif sys.argv[1] == 'destroy':
        destroy_status, destroy_output = destroy(**state_info)
        pprint('Destroy Output')
        pprint(destroy_output)
        exit(destroy_status)


if __name__ == '__main__':
    main()
