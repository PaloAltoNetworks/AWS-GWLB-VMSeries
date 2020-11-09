
# ---------------------------------------------------------------------------------------------------------------------
# MANDATORY PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "access_key" {
  description = "AWS Access Key"
  type = string
}

variable "secret_key" {
  description = "AWS Secret Key"
  type = string
}

variable "region" {
  description = "AWS Region"
  type = string
}

variable "availability_zones" {
  description = "Availability zones in a region to deploy instances on"
  type = list
}

variable "vpc_cidr" {
  description = "IP CIDR range for the Security VPC"
  type = string
}

variable "firewall_ami_id" {
  description = "VM-Series AMI ID BYOL/Bundle1/Bundle2 for the specified region"
  type = string
}

variable "transit_gw_id" {
  description = "Transit gateway ID"
  type = string
}

variable "public_key" {
  description = "Public key string for AWS SSH Key Pair"
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------


variable "prefix" {
  description = "Deployment ID Prefix"
  type = string
  default = "PANW"
}

variable "user_data" {
  description = "User Data for VM Series Bootstrapping. Ex. 'type=dhcp-client\nhostname=PANW\nvm-auth-key=0000000000\npanorama-server=<Panorama Server IP>\ntplname=<Panorama Template Stack Name>\ndgname=<Panorama Device Group Name>' or 'vmseries-bootstrap-aws-s3bucket=<s3-bootstrap-bucket-name>'"
  type = string
  default = ""
}

variable "fw_mgmt_sg_list" {
  description = "List of IP CIDRs that are allowed to access firewall management interface"
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "Instance type of the web server instances in ASG"
  type = string
  default = "m5.xlarge"
}
