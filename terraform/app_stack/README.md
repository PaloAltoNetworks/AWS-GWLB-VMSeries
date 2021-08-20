## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| local | n/a |
| null | n/a |
| random | n/a |
| template | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb) |
| [aws_alb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener) |
| [aws_alb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) |
| [aws_alb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group_attachment) |
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) |
| [aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) |
| [aws_default_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) |
| [aws_ec2_transit_gateway_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) |
| [aws_ec2_transit_gateway_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) |
| [aws_ec2_transit_gateway_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) |
| [aws_ec2_transit_gateway_vpc_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) |
| [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) |
| [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) |
| [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) |
| [aws_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) |
| [aws_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) |
| [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) |
| [aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) |
| [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) |
| [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) |
| [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) |
| [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) |
| [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) |
| [random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) |
| [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_key | AWS Access Key | `string` | n/a | yes |
| app\_mgmt\_sg\_list | List of IP CIDRs that are allowed to access management interface | `list(string)` | `[]` | no |
| availability\_zone | Availability zones in a region to deploy instances | `string` | n/a | yes |
| gwlbe\_service\_id | Gateway Load Balancer Endpoint service ID. Ex. vpce-svc-0f65e953ecab61a23 | `string` | n/a | yes |
| gwlbe\_service\_name | Gateway Load Balancer Endpoint service name. Ex. com.amazonaws.vpce.sa-east-1.vpce-svc-0612d6a7defdde0c8 | `string` | n/a | yes |
| instance\_type | Instance type of the web server instances in ASG | `string` | `"t2.micro"` | no |
| natgw\_route\_table\_id | List of Security VPC NAT Gateway Route Table IDs | `list(any)` | n/a | yes |
| prefix | Deployment ID Prefix | `string` | `"PANW"` | no |
| public\_key | Public key string for AWS SSH Key Pair | `string` | n/a | yes |
| region | AWS Region | `string` | n/a | yes |
| sec\_gwlbe\_ew\_id | List of Security VPC GWLB Endpoint IDs | `list(any)` | n/a | yes |
| sec\_gwlbe\_ew\_route\_table\_id | List of Security VPC GWLBE EW Route Table IDs | `list(any)` | n/a | yes |
| sec\_gwlbe\_ob\_id | List of Security VPC GWLB Endpoint IDs | `list(any)` | n/a | yes |
| sec\_gwlbe\_ob\_route\_table\_id | List of Security VPC GWLBE OB Route Table IDs | `list(any)` | n/a | yes |
| sec\_tgwa\_route\_table\_id | List of Security VPC TGW Attachment Rout Table IDs | `list(any)` | n/a | yes |
| secret\_key | AWS Secret Key | `string` | n/a | yes |
| tgw\_id | Transit Gateway ID from Security VPC Deployment | `string` | n/a | yes |
| tgw\_sec\_attach\_id | Transit Gateway Security VPC Attachment ID from Security VPC Deployment | `string` | n/a | yes |
| tgw\_sec\_route\_table\_id | Transit Gateway Security VPC Attachment Route Table ID from Security VPC Deployment | `string` | n/a | yes |
| vpc\_cidr | IP CIDR range for the App VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app\_fqdn | n/a |
| app\_gwlbe\_id | n/a |
| app\_mgmt\_ip | n/a |
| deployment\_id | n/a |
