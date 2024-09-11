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
| [aws_default_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) |
| [aws_ec2_transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) |
| [aws_ec2_transit_gateway_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) |
| [aws_ec2_transit_gateway_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) |
| [aws_ec2_transit_gateway_vpc_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) |
| [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) |
| [aws_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) |
| [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) |
| [aws_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) |
| [aws_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) |
| [aws_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) |
| [aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) |
| [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) |
| [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) |
| [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) |
| [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) |
| [random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) |
| [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_key | AWS Access Key | `string` | n/a | yes |
| availability\_zones | Availability zones in a region to deploy instances on | `list(any)` | n/a | yes |
| firewall\_ami\_id | VM-Series AMI ID BYOL/Bundle1/Bundle2 for the specified region | `string` | n/a | yes |
| fw\_mgmt\_sg\_list | List of IP CIDRs that are allowed to access firewall management interface | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| instance\_type | Instance type of the web server instances in ASG | `string` | `"m5.xlarge"` | no |
| prefix | Deployment ID Prefix | `string` | `"PANW"` | no |
| public\_key | Public key string for AWS SSH Key Pair | `string` | n/a | yes |
| region | AWS Region | `string` | n/a | yes |
| secret\_key | AWS Secret Key | `string` | n/a | yes |
| transit\_gw\_id | Transit gateway ID | `string` | n/a | yes |
| user\_data | User Data for VM Series Bootstrapping. Ex. 'type=dhcp-client<br>hostname=PANW<br>vm-auth-key=0000000000<br>panorama-server=<Panorama Server IP><br>tplname=<Panorama Template Stack Name><br>dgname=<Panorama Device Group Name>' or 'vmseries-bootstrap-aws-s3bucket=<s3-bootstrap-bucket-name>' | `string` | `""` | no |
| vpc\_cidr | IP CIDR range for the Security VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| deployment\_id | n/a |
| firewall\_ip | n/a |
| gwlb\_arn | n/a |
| gwlb\_listener\_arn | n/a |
| gwlb\_tg\_arn | n/a |
| gwlbe\_service\_id | n/a |
| gwlbe\_service\_name | n/a |
| natgw\_route\_table\_id | n/a |
| sec\_gwlbe\_ew\_id | n/a |
| sec\_gwlbe\_ew\_route\_table\_id | n/a |
| sec\_gwlbe\_ob\_id | n/a |
| sec\_gwlbe\_ob\_route\_table\_id | n/a |
| sec\_tgwa\_route\_table\_id | n/a |
| tgw\_id | n/a |
| tgw\_sec\_attach\_id | n/a |
| tgw\_sec\_route\_table\_id | n/a |
