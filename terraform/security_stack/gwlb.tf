
# ---------------------------------------------------------------------------------------------------------------------
# CREATE HAND-OFF FILE FOR PYTHON SCRIPT(Gateway Load Balancer Deployment)
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
    "sec_vpc" = aws_vpc.sec_vpc.id
    "sec_data_subnet" = aws_subnet.sec_data_subnet[*].id
    "sec_agwe_subnet" = aws_subnet.sec_agwe_subnet[*].id
    "sec_agwe_ew_subnet" = aws_subnet.sec_agwe_ew_subnet[*].id
    "sec_tgwa_route_table_id" = aws_route_table.tgwa-rt[*].id
    "instance_id" = aws_instance.firewall_instance[*].id
    "account_id" = aws_vpc.sec_vpc.owner_id
    "tgw_sec_attach_id" = aws_ec2_transit_gateway_vpc_attachment.as.id
    "agw_arn" = ""
    "agw_tg_arn" = ""
    "agw_listener_arn" = ""
    "agwe_service_name" = ""
    "agwe_service_id" = ""
    "agwe_id" = []
    "agwe_ew_id" = []
  })
}

resource "null_resource" "handoff-state-json" {
  provisioner "local-exec" {
    command = "echo '${local.output_json_str}' > ${data.template_file.handoff-state-file.rendered}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Deploy/Destroy Appliance Gateway
# 1 APPLIANCE GATEWAY
# 1 TARGET GROUP
# 1 LISTENER
# 1 TARGET REGISTRATION
# 1 VPC ENDPOINT SERVICE
# 1 AGWE

# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "gateway-load-balancer" {
  provisioner "local-exec" {
    command = "python3 gwlb.py create"
  }
  provisioner "local-exec" {
    when = destroy
    command = "python3 gwlb.py destroy"
  }
  depends_on = [null_resource.handoff-state-json, aws_instance.firewall_instance]
}

# ---------------------------------------------------------------------------------------------------------------------
# GET DATA FROM HANDOFF FILE
# ---------------------------------------------------------------------------------------------------------------------

data "local_file" "gwlb" {
  filename = data.template_file.handoff-state-file.rendered
  depends_on = [null_resource.gateway-load-balancer]
}
