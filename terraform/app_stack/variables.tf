
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

variable "gwlbe_service_id" {
  description = "Gateway Load Balancer Endpoint service ID. Ex. vpce-svc-0f65e953ecab61a23"
  type = string
}

variable "gwlbe_service_name" {
  description = "Gateway Load Balancer Endpoint service name. Ex. com.amazonaws.vpce.sa-east-1.vpce-svc-0612d6a7defdde0c8"
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

variable "sec_gwlbe_ob_route_table_id" {
  description = "List of Security VPC GWLBE OB Route Table IDs"
  type = list
}

variable "sec_gwlbe_ew_route_table_id" {
  description = "List of Security VPC GWLBE EW Route Table IDs"
  type = list
}

variable "natgw_route_table_id" {
  description = "List of Security VPC NAT Gateway Route Table IDs"
  type = list
}

variable "sec_gwlbe_ob_id" {
  description = "List of Security VPC GWLB Endpoint IDs"
  type = list
}

variable "sec_gwlbe_ew_id" {
  description = "List of Security VPC GWLB Endpoint IDs"
  type = list
}

variable "sec_tgwa_route_table_id" {
  description = "List of Security VPC TGW Attachment Rout Table IDs"
  type = list
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
