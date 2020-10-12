
# ---------------------------------------------------------------------------------------------------------------------
# CREATE HAND-OFF FILE FOR PYTHON SCRIPT(Appliance Gateway Endpoint Deployment)
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "handoff-state-file" {
  template = "${path.module}/handoff_state.json"
}

locals {
  output_json_str = jsonencode({
    "access_key" = var.access_key
    "secret_key" = var.secret_key
    "region" = var.region
    "deployment_id" = random_id.deployment_id.hex
    "app_vpc" = aws_vpc.app_vpc.id
    "app_agwe_subnet" = aws_subnet.app_agwe_subnet.id
    "agwe_service_id" = var.agwe_service_id
    "agwe_service_name" = var.agwe_service_name
    "igw_route_table_id" = aws_route_table.igw-rt.id
//    "app_data_subnet_cidr" = aws_subnet.app_data_subnet.cidr_block
    "app_data_subnet_cidr" = aws_subnet.alb_subnet[*].cidr_block
//    "app_data_route_table_id" = aws_route_table.app-data-rt.id
    "alb_route_table_id" = aws_route_table.app-alb-rt.id
    "sec_natgw_route_table_id" = var.natgw_route_table_id
    "app_vpc_cidr" = aws_vpc.app_vpc.cidr_block
    "sec_agwe_id" = var.sec_agwe_id
    "agwe_id" = ""
  })
}

resource "null_resource" "handoff-state-json" {
  provisioner "local-exec" {
    command = "echo '${local.output_json_str}' > ${data.template_file.handoff-state-file.rendered}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Deploy/Destroy Appliance Gateway Endpoint
# 1 AGWE

# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "appliance-gateway-endpoint" {
  provisioner "local-exec" {
    command = "python3 agwe.py create"
  }
  provisioner "local-exec" {
    when = destroy
    command = "python3 agwe.py destroy"
  }
  depends_on = [null_resource.handoff-state-json]
}

# ---------------------------------------------------------------------------------------------------------------------
# GET DATA FROM HANDOFF FILE
# ---------------------------------------------------------------------------------------------------------------------

data "local_file" "agwe" {
  filename = data.template_file.handoff-state-file.rendered
  depends_on = [null_resource.appliance-gateway-endpoint]
}

# ---------------------------------------------------------------------------------------------------------------------
# ADDING ROUTES ON SECURITY VPC FOR THE APP
# 1 ROUTE ON SEC-AGWE-RT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route" "sec-agwe-to-tgw" {
  route_table_id = var.sec_agwe_route_table_id
  destination_cidr_block    = aws_vpc.app_vpc.cidr_block
  transit_gateway_id = var.tgw_id
  depends_on = [data.local_file.agwe]
}
