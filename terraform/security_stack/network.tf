
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC, IGW, Subnets and NATGW
# 1 VPC
# 1 IGW
# 5 SUBNETS (FW MGMT, FW DATA, AGWE, TGW Attachment, NATGW)
# 1 EIP for NATGW
# 1 NATGW
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "sec_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "sec-vpc-${random_id.deployment_id.hex}"
  }
}

resource "aws_internet_gateway" "sec_vpc_igw" {
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name = "sec-vpc-igw-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_mgmt_subnet" {
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sec_vpc.cidr_block, 3, 0)
  availability_zone = var.availability_zone  #data.aws_availability_zones.all.names[tostring(each.key - 1)]
  tags = {
    Name = "sec-mgmt-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_data_subnet" {
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sec_vpc.cidr_block, 3, 1)
  availability_zone = var.availability_zone  #data.aws_availability_zones.all.names[tostring(each.key - 1)]
  tags = {
    Name = "sec-data-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_agwe_subnet" {
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sec_vpc.cidr_block, 3, 2)
  availability_zone = var.availability_zone  #data.aws_availability_zones.all.names[tostring(each.key - 1)]
  tags = {
    Name = "sec-agwe-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_tgwa_subnet" {
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sec_vpc.cidr_block, 3, 3)
  availability_zone = var.availability_zone  #data.aws_availability_zones.all.names[tostring(each.key - 1)]
  tags = {
    Name = "sec-tgwa-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_natgw_subnet" {
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sec_vpc.cidr_block, 3, 4)
  availability_zone = var.availability_zone  #data.aws_availability_zones.all.names[tostring(each.key - 1)]
  tags = {
    Name = "sec-natgw-subnet-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_eip" "natgw_eip" {
  vpc = true
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_nat_gateway" "sec_nat_gw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id = aws_subnet.sec_natgw_subnet.id
  depends_on = [aws_subnet.sec_natgw_subnet, aws_eip.natgw_eip]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES AND ASSOCIATIONS
# 5 ROUTE TABLES (FW MGMT, FW DATA, AGWE, NATGW, TGWA)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_route_table" "main-mgmt-rt" {
  default_route_table_id = aws_vpc.sec_vpc.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec_vpc_igw.id
  }

  tags = {
    Name = "main-fw-mgmt-rt-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_route_table_association" "main-mgmt-rt-association" {
  subnet_id      = aws_subnet.sec_mgmt_subnet.id

  route_table_id = aws_vpc.sec_vpc.main_route_table_id

  depends_on = [aws_subnet.sec_mgmt_subnet]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "fw-data-rt" {
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name = "fw-data-rt-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_route_table_association" "app-data-rt-association" {
  subnet_id      = aws_subnet.sec_data_subnet.id

  route_table_id = aws_route_table.fw-data-rt.id

  depends_on = [aws_subnet.sec_data_subnet, aws_route_table.fw-data-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-rt" {
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sec_nat_gw.id
  }

  tags = {
    Name = "agwe-rt-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_nat_gateway.sec_nat_gw]
}

resource "aws_route_table_association" "agwe-rt-association" {
  subnet_id      = aws_subnet.sec_agwe_subnet.id

  route_table_id = aws_route_table.agwe-rt.id

  depends_on = [aws_subnet.sec_agwe_subnet, aws_route_table.agwe-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "natgw-rt" {
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec_vpc_igw.id
  }

  tags = {
    Name = "natgw-rt-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_subnet.sec_natgw_subnet]
}

resource "aws_route_table_association" "natgw-rt-association" {
  subnet_id      = aws_subnet.sec_natgw_subnet.id

  route_table_id = aws_route_table.natgw-rt.id

  depends_on = [aws_internet_gateway.sec_vpc_igw, aws_route_table.natgw-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "tgwa-rt" {
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name = "tgwa-rt-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_subnet.sec_tgwa_subnet]
}

resource "aws_route_table_association" "tgwa-rt-association" {
  subnet_id      = aws_subnet.sec_tgwa_subnet.id

  route_table_id = aws_route_table.tgwa-rt.id

  depends_on = [aws_route_table.tgwa-rt]
}
