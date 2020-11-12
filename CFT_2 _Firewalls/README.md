# Palo Alto Networks & AWS Gateway Load Balancer Deployment

## Security VPC Deployment

### Overview

This Cloud Formation Template deploys the components needed to deploy Palo Alto Networks VM-Series Firewalls with the AWS Gateway Load Balancer in 2 Availability Zones (A & B).

#### Prerequisites

The following items are required prior to deployment of this template:
- **Non-Overlapping IP CIDR Block (/25)** - This will provide an IP addressing scheme for the VPC and the Subnets (8x /28 Subnets)

- **AMI of Palo Alto Networks VM-Series v10.0.2 or above** - This will allow you to deploy Gateway Load Balancer compatible Palo Alto Networks VM-Series firewalls.

- **EC2 Key Pair** - For authentication to Palo ALto Networks VM-Series firewalls.
  - To connect to the Palo Alto Networks VM-Series after deployment use  ```ssh admin@1.2.3.4 -i ec2keypair.pem``` substituting 1.2.3.4 for the correct Elastic IP or Private IP of the instance you want to connect to.

- **Remote Management IP CIDR** - A IP CIDR to be allowed access to the Palo Alto Networks VM-Series Management interface. To open access to all networks us `0.0.0.0/0`

The following aspects of this template are optional:
- **Configuration** - You can manually configure the Palo Alto Networks VM-Series firewalls, provide a configuration file to allow them to start with this initial configuration and licensing applied. To deploy an existing configuration create an S3 Bucket with the appropriate files and folder stucture, more details can be found here: https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-aws.html

- **Transit Gateway Attachment** - You can choose to attach this VPC to an exitsing Transit Gateway and configure the Routing Needed to connect back to your existing resources. If you chose not to do this you will need an additional configuration later, or you can re-run this template specifying the Transit Gateway ID. This configuration only creates a Transit Gateway Attachment, no other changes to the Transit Gateway are made. To use this attachment for **East/West**, or **Outbound** traffic flow security, you will need to adjust the Transit Gateway Routing.

#### Diagram

![Diagram](diagram.jpeg)

### Deployment Steps

The easiest way to deploy this Cloud Formation Template (CFT) by using the AWS Console.

**Notes:**
- *The Gateway Load Balancer does not currently support Tagging of resources, if you include a Tag when deploying the Cloud Formation Template the deployment will fail.*