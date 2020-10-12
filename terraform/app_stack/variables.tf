
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

variable "availability_zone" {
  description = "Availability zones in a region to deploy instances"
  type = string
}

variable "vpc_cidr" {
  description = "IP CIDR range for the App VPC"
  type = string
}

variable "agwe_service_id" {
  description = "Appliance Gateway Endpoint service ID. Ex. vpce-svc-0f65e953ecab61a23"
  type = string
}

variable "agwe_service_name" {
  description = "Appliance Gateway Endpoint service name. Ex. com.amazonaws.vpce.sa-east-1.vpce-svc-0612d6a7defdde0c8"
  type = string
}

variable "tgw_id" {
  description = "Transit Gateway ID from Security VPC Deployment"
  type = string
}

variable "tgw_sec_attach_id" {
  description = "Transit Gateway Security VPC Attachment ID from Security VPC Deployment"
  type = string
}

variable "tgw_sec_route_table_id" {
  description = "Transit Gateway Security VPC Attachment Route Table ID from Security VPC Deployment"
  type = string
}

variable "sec_agwe_route_table_id" {
  description = "Security VPC AGWE Route Table ID"
  type = string
}

variable "natgw_route_table_id" {
  description = "Security VPC NAT Gateway Route Table ID"
  type = string
}

variable "sec_agwe_id" {
  description = "Security VPC AGW Endpoint ID"
  type = string
}

variable "public_key" {
  description = "Public key string for AWS SSH Key Pair"
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_type" {
  description = "Instance type of the web server instances in ASG"
  type = string
  default = "t2.micro"
}

variable "prefix" {
  description = "Deployment ID Prefix"
  type = string
  default = "PANW"
}

variable "app_mgmt_sg_list" {
  description = "List of IP CIDRs that are allowed to access management interface"
  type = list(string)
  default = []
}
