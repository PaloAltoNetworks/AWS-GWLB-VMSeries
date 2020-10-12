
output "deployment_id" {
  value = random_id.deployment_id.hex
}

output "firewall_ip" {
  value = aws_eip.fw-mgmt-eip.public_ip
}

output "sec_agwe_route_table_id" {
  value = aws_route_table.agwe-rt.id
}

output "natgw_route_table_id" {
  value = aws_route_table.natgw-rt.id
}

output "tgwa_route_table_id" {
  value = aws_route_table.tgwa-rt.id
}

output "tgw_id" {
  value = data.aws_ec2_transit_gateway.panw-tgw.id
}

output "tgw_sec_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.tgw-main-sec-rt.id
}

output "tgw_sec_attach_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.as.id
}

output "sec_agwe_id" {
  value = jsondecode(data.local_file.agw.content).agwe_id
}

output "agw_arn" {
  value = jsondecode(data.local_file.agw.content).agw_arn
}

output "agw_listener_arn" {
  value = jsondecode(data.local_file.agw.content).agw_listener_arn
}

output "agw_tg_arn" {
  value = jsondecode(data.local_file.agw.content).agw_tg_arn
}

output "agwe_service_name" {
  value = jsondecode(data.local_file.agw.content).agwe_service_name
}

output "agwe_service_id" {
  value = jsondecode(data.local_file.agw.content).agwe_service_id
}
