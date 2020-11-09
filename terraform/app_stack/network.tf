
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC, IGW and Subnets
# 1 VPC
# 1 IGW
# 4 SUBNETS (GWLBE, ALB-1, ALB-2, APP)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "app-vpc-${random_id.deployment_id.hex}"
  }
}
data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "app_vpc_igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "app-vpc-igw-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.app_vpc]
}

resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.app_vpc.cidr_block)[0], "25"]), 3, 0)
  availability_zone = var.availability_zone
  tags = {
    Name = "app-main-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.app_vpc]
}

resource "aws_subnet" "app_agwe_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.app_vpc.cidr_block)[0], "25"]), 3, 1)
  availability_zone = var.availability_zone
  tags = {
    Name = "app-gwlbe-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.app_vpc]
}

resource "aws_subnet" "alb_subnet" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.app_vpc.cidr_block)[0], "25"]), 3, 2+count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "app-alb-${count.index}-subnet-${random_id.deployment_id.hex}"
    UsedBy = "ALB"
  }
  depends_on = [aws_vpc.app_vpc]
}

data "aws_subnet_ids" "alb_subnet_ids" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    UsedBy = "ALB"
  }
  depends_on = [aws_subnet.alb_subnet]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE TGW ATTACHMENT
# 1 TGW ATTACHMENT
# 1 TGW ROUTE TABLE with 1 APP ASSOC AND 1 ROUTE TO SEC ATTACHMENT
# 1 ROUTE ADDITION TO TGW DEFAULT ROUTE TABLE TO APP ATTACHMENT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attachment" {
  subnet_ids         = [aws_subnet.app_subnet.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.app_vpc.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  tags               = {
    Name = "client-server-${random_id.deployment_id.hex}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "app-tgw-rt" {
  transit_gateway_id = var.tgw_id
  tags = {
    Name = "tgw-app-rt-${random_id.deployment_id.hex}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-app-rt-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "tgw-app-route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.tgw_sec_attach_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "tgw-sec-route" {
  destination_cidr_block         = aws_vpc.app_vpc.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attachment.id
  transit_gateway_route_table_id = var.tgw_sec_route_table_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES AND ASSOCIATIONS
# 4 ROUTE TABLES (APP, ALB, GWLBE, IGW)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_route_table" "app-main-rt" {
  default_route_table_id = aws_vpc.app_vpc.main_route_table_id
  tags = {
    Name = "app-main-rt-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tgw-attachment]
}

resource "aws_route_table_association" "main-mgmt-rt-association" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_vpc.app_vpc.main_route_table_id
}

resource "aws_route" "app-mgmt" {
  count = length(var.app_mgmt_sg_list)
  route_table_id = aws_default_route_table.app-main-rt.id
  gateway_id = aws_internet_gateway.app_vpc_igw.id
  destination_cidr_block = var.app_mgmt_sg_list[count.index]
  depends_on = [aws_default_route_table.app-main-rt, aws_route_table_association.main-mgmt-rt-association]
}

resource "aws_route" "app-ob" {
  route_table_id = aws_default_route_table.app-main-rt.id
  transit_gateway_id = var.tgw_id
  destination_cidr_block = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "app-alb-rt" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "app-alb-rt-${random_id.deployment_id.hex}"
  }
}

resource "aws_route_table_association" "app-data-rt-association" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.alb_subnet[count.index].id
  route_table_id = aws_route_table.app-alb-rt.id
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_vpc_igw.id
  }
  tags = {
    Name = "app-gwlbe-rt-${random_id.deployment_id.hex}"
  }
}

resource "aws_route_table_association" "agwe-rt-association" {
  subnet_id      = aws_subnet.app_agwe_subnet.id
  route_table_id = aws_route_table.agwe-rt.id
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "igw-rt" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "igw-rt-${random_id.deployment_id.hex}"
  }
}

resource "aws_route_table_association" "igw-rt-association" {
  gateway_id     = aws_internet_gateway.app_vpc_igw.id
  route_table_id = aws_route_table.igw-rt.id
}
