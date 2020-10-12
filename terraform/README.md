# VM-Series Behind An Appliance Gateway

This package will help you deploy a VM-Series behind an AWS Appliance Gateway using the **security_stack** terraform template to secure your Inbound, Outbound and East-West traffic.

The **app_stack** is an optional deployment of a sample web application behind an Application Load Balancer.

You can deploy the **security_stack** and two sets of **app_stack** to bring up a topology as stated in the diagram below.
<br />
<br />
<br />
<br />
<img src="https://bitbucket.paloaltonetworks.local/users/rtiku/repos/aws/raw/vmseries-agw/topology.png?at=refs%2Fheads%2Fmaster"/>
<br />
<br />
<br />
## Table of Contents
1. Prerequisites
2. Deploy Security Stack
3. Deploy Application Stack
4. Verify Traffic Inspection On VM-Series
5. Support
<br />
<br />

--------

<br />
<br />

## Prerequisites

1. To deploy this template, you would need the following from AWS:
   - Your AWS account whitelisted for AWS Appliance Gateway Beta and
   - AWS Appliance Gateway Beta Package (Containing Model json files).
   
   Note: Reach out to AWS if you don't have the above two.
2. Install Python 3.6.10
	- Confirm the installation 
	
	`python3 --version`
	- This should point to Python 3.6
3. Install Terraform 0.12
    - Confirm the installation
    
    `terraform version`
    - This should point to Terraform v0.12.x
4. Install the python requirements
	- `pip3 install -r requirements.txt`
5. Perform the AWS CLI model addition from AWS Appliance Gateway Beta Package:
    - Configure AWS CLI with access key, secret key and region(AWS Beta whitelisted region)
    
    `aws configure`
    - Add custom model json files provided with AWS Beta package
    
    `aws configure add-model --service-name elbv2-agw --service-model file://elbv2-agw.json` 
    
    `aws configure add-model --service-name ec2-agwe --service-model file://ec2-agw.json`
    - To confirm, the following two files should exist
    
    `~/.aws/models/elbv2-agw/2015-12-01/service-2.json` and 
    
    `~/.aws/models/ec2-agwe/2016-11-15/service-2.json`
5. Create a local ssh keypair to access instances deployed by this terraform deployment.
	- Private Key: `openssl genrsa -out private_key.pem 2048`
	- Change Permissions: `chmod 400 private_key.pem`
	- Public Key: `ssh-keygen -y -f private_key.pem > public_key.pub`
6. To support East West and Outbound Traffic, use an existing or create a new Transit Gateway on your AWS account
    - Transit Gateway should use the following settings:
        - Default route table association: disable
        - Default route table propagation: disable
    - The Transit gateway should exist in the region where AWS has enabled Appliance Gateway Beta. 
    - Note the Transit Gateway ID

**With this, your environment is now ready to deploy VM-Series behind an AWS Appliance Gateway.** 

<br />
<br />

## Deploy Security Stack

1. Setup the variables for Security stack in security_stack/terraform.tfvars. Some of them are explained below:
    1. Parameter(Mandatory) `vpc_cidr`:
        - Use a /25 CIDR. This is an AWS Appliance Gateway Beta limitation.
    2. Parameter(Mandatory) `tgw_id`:
        - Use an Transit Gateway ID you noted in the Prerequisites Step 6.
        
        Ex. `tgw_id = "tgw-0xxxxxxxxx"` 
    3. Parameter(Mandatory) `public_key`:
        - Use the contents of public key created in Prerequisites Step 5 as parameter value.
        
        Ex. `public_key="ssh-rsa xxxxxxxxxx"`
    4. Parameter(Optional) `user_data`:
        - Option 1: Enter a Basic Configuration as User Data.
        
        Ex. `user_data="type=dhcp-client\nhostname=PANW\nauthcodes=<Vm-Series Licensing Authcode>"`.
        - Option 2: Use an S3 Bootstrap bucket. 
        
        Ex. `user_data="vmseries-bootstrap-aws-s3bucket=<s3-bootstrap-bucket-name>"`.
        
        If Option 2 is used, please make sure you have the following line in init-cfg.txt file:
        
        `plugin-op-commands=aws-agw-inspect:enable`
    5. Parameter(Optional) `prefix`:
        - Use this parameter to prefix every resource with this string.
    6. Parameter(Optional) `fw_mgmt_sg_list` and `app_mgmt_sg_list`:
        - Use this parameter to input a list of IP addresses with CIDR from which you want Firewall/App Management to be accessible.
    7. Check out all optional terraform parameters for more functionality. The parameter definitions lie in the file `variables.tf`

2. Deploy Security Stack using Terraform
    - Go to the security stack terraform directory `cd /path/to/security_stack/`
    - Initialize terraform `terraform init`
    - Apply the template `terraform apply`
    - This will start the deployment
    - You will see the output of the deployment once it is complete.
    - The output will look like:
    ```
    agw_arn = <Appliance Gateway ARN>
    agw_listener_arn = <Listener ARN>
    agw_tg_arn = <Target Group ARN>
    agwe_service_id = vpce-svc-xx
    agwe_service_name = com.amazonaws.vpce.<region>.vpce-svc-xx
    deployment_id = <prefix-id>
    firewall_ip = <Firewall Management IP>
    natgw_route_table_id = rtb-xx
    sec_agwe_id = vpce-xx
    sec_agwe_route_table_id = rtb-xx
    tgw_id = tgw-xx
    tgw_sec_attach_id = tgw-attach-xx
    tgw_sec_route_table_id = tgw-rtb-xx
    tgwa_route_table_id = rtb-xx
   ```

3. Wait for VM Series Firewall to boot up. It can take a few minutes based on the `user_data` passed to the terraform.

4. Once ready, login to your firewall:
    - `ssh -i private_key.pem admin@<Firewall IP>`
    - `firewall_ip` can be found in Security Stack deployment output
    - Once you have logged in, you will need to configure your firewall to allow traffic(<Link to this step in David's Doc>):
        - Configure interface 'ethernet1/1' as layer 3 with DHCP 
        - Configure interface 'ethernet1/1' with a virtual router, zone and interface management profile.
        - This template configures a health checks(TCP over port 80) on the Target Group so configure the interface management profile(for ethernet1/1) on the firewall to accept this traffic.
        - With this, 'ethernet1/1' behaves as both ingress and egress interface.
        - This firewall configuration will allow traffic to flow based on intrazone default policy.

**Congratulations! You have successfully deployed the security stack.**

<br />
<br />

## Deploy Application Stack
1. You can now deploy a Sample Application stack to view the traffic flow.

2. Setup the variables for the App Stack in app_stack/terraform.tfvars.
    - Use the Security Stack Terraform output and setup for the variables.
    - Check out all optional terraform parameters for more functionality. The parameter definitions lie in the file `variables.tf`

3. Deploy App Stack using Terraform
    - Go to the app stack terraform directory `cd /path/to/app_stack/`
    - Initialize terraform `terraform init`
    - Apply the template `terraform apply`
    - This will start the deployment
    - You will see the output of the deployment once it is complete.
    - The output will look like:
    ```
    app_agwe_id = vpce-xx
    app_fqdn = <Application Load Balancer FQDN>
    app_mgmt_ip = <Application Management IP>
    deployment_id = <prefix-id>
    ```
    - Once deployed the Application will be ready in a few minutes.

**Congratulations! You have successfully deployed an Application Stack.**

<br />
<br />

## Inspect Traffic On VM-Series

You can now inspect the traffic on VM-Series Firewall:

1. Inbound Traffic Inspection: 
    - Access the Application Web Page from your browser
    - Go to a browser and execute `http://<fqdn>`
    - `app_fqdn` can be found in App Stack deployment output
    - This inbound traffic destined to the application is inspected by the Firewall and can be seen in it.
    
2. Outbound Traffic Inspection:
    - Login to you Application Instance
    `ssh -i private_key.pem ubuntu@<Application IP>`
    - `app_mgmt_ip` can be found in App Stack deployment output
    - Execute the following command:
    `curl https://www.paloaltonetworks.com`
    - This outbound traffic coming from the application(via Transit Gateway) is inspected by the Firewall and can be seen in it.

3. East-West Traffic Inspection:
    - To achieve this we will have to deploy another **app_stack** to send traffic between two applications
    - Create a copy of the directory **app_stack** 
    ```
    mkdir app_stack_2
    cp app_stack/* app_stack_2/
    ```
    - Go to the app stack 2 directory and confirm you are not carrying any terraform state files from the previous application
    ```
    cd app_stack_2
    rm -rf *.tfstate
    ```
    - Setup the variables and deploy another application stack(Follow [Application Stack Steps 7-8](#Deploy Application Stack))
    - Make sure App 1 and App2 deployments have different `vpc_cidr`.
    - Once deployed, wait for the application instance to boot up.
    - Login to your new Application Instance (APP 2)
    `ssh -i private_key.pem ubuntu@<Application IP>`
    - `app_mgmt_ip` can be found in App Stack deployment output
    - Execute the following command:
    `curl http://<APP 1 Private IP>`
    - This East-West traffic coming from the App 2 and destined to App 1 goes via the Transit gateway to be inspected by the Firewall.

**With this you inspected Inbound, Outbound and East-West traffic on the Application with VM-Series Firewall.**

<br />
<br />

--------

## Support

These templates are released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself. Unless explicitly tagged, all projects or work posted in our GitHub repository (at https://github.com/PaloAltoNetworks) or sites other than our official Downloads page on https://support.paloaltonetworks.com are provided under the best effort policy.