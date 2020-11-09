
# ---------------------------------------------------------------------------------------------------------------------
# CREATE HAND-OFF FILE FOR PYTHON SCRIPT(Gateway Load Balancer Endpoint Deployment)
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
    "igw_route_table_id" = aws_route_table.igw-rt.id
    "app_data_subnet_cidr" = aws_subnet.alb_subnet[*].cidr_block
    "alb_route_table_id" = aws_route_table.app-alb-rt.id
    "app_vpc_cidr" = aws_vpc.app_vpc.cidr_block

    "agwe_service_id" = var.gwlbe_service_id
    "agwe_service_name" = var.gwlbe_service_name
    "sec_natgw_route_table_id" = var.natgw_route_table_id
    "sec_agwe_ob_id" = var.sec_gwlbe_ob_id
    "sec_agwe_ew_id" = var.sec_gwlbe_ew_id
    "sec_tgwa_route_table_id" = var.sec_tgwa_route_table_id
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
# 1 GWLBE

# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "gateway-load-balancer-endpoint" {
  provisioner "local-exec" {
    command = "python3 gwlbe.py create"
  }
  provisioner "local-exec" {
    when = destroy
    command = "python3 gwlbe.py destroy"
  }
  depends_on = [null_resource.handoff-state-json]
}

# ---------------------------------------------------------------------------------------------------------------------
# GET DATA FROM HANDOFF FILE
# ---------------------------------------------------------------------------------------------------------------------

data "local_file" "gwlbe" {
  filename = data.template_file.handoff-state-file.rendered
  depends_on = [null_resource.gateway-load-balancer-endpoint]
}

# ---------------------------------------------------------------------------------------------------------------------
# ADDING ROUTES ON SECURITY VPC FOR THE APP
# 1 ROUTE ON EACH SEC-GWLBE-EW-RT
# 1 ROUTE ON EACH SEC-GWLBE-OB-RT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route" "sec-agwe-ew-to-tgw" {
  count = length(var.sec_gwlbe_ew_route_table_id)
  route_table_id = var.sec_gwlbe_ew_route_table_id[count.index]
  destination_cidr_block    = aws_vpc.app_vpc.cidr_block
  transit_gateway_id = var.tgw_id
  depends_on = [data.local_file.gwlbe]
}

resource "aws_route" "sec-agwe-ob-to-tgw" {
  count = length(var.sec_gwlbe_ob_route_table_id)
  route_table_id = var.sec_gwlbe_ob_route_table_id[count.index]
  destination_cidr_block    = aws_vpc.app_vpc.cidr_block
  transit_gateway_id = var.tgw_id
  depends_on = [data.local_file.gwlbe]
}
