
# ---------------------------------------------------------------------------------------------------------------------
# CREATE Transit Gateway and Attachment for Security VPC
# Fetch Transit Gateway from Variables
# 1 Transit Gateway Attachment
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ec2_transit_gateway" "panw-tgw"{
  id = var.transit_gw_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "as" {
  subnet_ids = aws_subnet.sec_tgwa_subnet[*].id
  transit_gateway_id = data.aws_ec2_transit_gateway.panw-tgw.id
  vpc_id = aws_vpc.sec_vpc.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  tags = {
    Name = "security-tgwa-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_subnet.sec_tgwa_subnet]
}

resource "aws_ec2_transit_gateway_route_table" "tgw-main-sec-rt" {
  transit_gateway_id = data.aws_ec2_transit_gateway.panw-tgw.id
  tags = {
    Name = "tgw-sec-rt-${random_id.deployment_id.hex}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-sec-rt-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.as.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-main-sec-rt.id
}
