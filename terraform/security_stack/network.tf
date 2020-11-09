
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC, IGW, Subnets and NATGW
# 1 VPC
# 1 IGW
# SUBNETS (1 FW MGMT for each AZ, 1 FW DATA for each AZ, 1 GWLBE-OB for each AZ,
#          1 GWLBE-EW for each AZ, 1 TGW Attachment for each AZ,
#          1 NATGW for each AZ)
# 1 NATGW for each AZ
# 1 EIP for each NATGW
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
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 0+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-mgmt-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_data_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 5+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-data-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_agwe_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 10+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-gwlbe-ob-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_agwe_ew_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 15+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-gwlbe-ew-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_tgwa_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 20+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-tgwa-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_natgw_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/",[split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 25+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "sec-natgw-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_eip" "natgw_eip" {
  count = length(var.availability_zones)
  vpc = true
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_nat_gateway" "sec_nat_gw" {
  count = length(var.availability_zones)
  allocation_id = aws_eip.natgw_eip[count.index].id
  subnet_id = aws_subnet.sec_natgw_subnet[count.index].id
  depends_on = [aws_subnet.sec_natgw_subnet, aws_eip.natgw_eip]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES AND ASSOCIATIONS
# ROUTE TABLES (FW MGMT, FW DATA, GWLBE, NATGW, TGWA)
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
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_mgmt_subnet[count.index].id

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
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_data_subnet[count.index].id

  route_table_id = aws_route_table.fw-data-rt.id

  depends_on = [aws_subnet.sec_data_subnet, aws_route_table.fw-data-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-rt" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sec_nat_gw[count.index].id
  }

  tags = {
    Name = "gwlbe-ob-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_nat_gateway.sec_nat_gw]
}

resource "aws_route_table_association" "agwe-rt-association" {
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_agwe_subnet[count.index].id

  route_table_id = aws_route_table.agwe-rt[count.index].id

  depends_on = [aws_subnet.sec_agwe_subnet, aws_route_table.agwe-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-ew-rt" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name = "gwlbe-ew-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
}

resource "aws_route_table_association" "agwe-ew-rt-association" {
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_agwe_ew_subnet[count.index].id

  route_table_id = aws_route_table.agwe-ew-rt[count.index].id

  depends_on = [aws_subnet.sec_agwe_ew_subnet, aws_route_table.agwe-ew-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "natgw-rt" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec_vpc_igw.id
  }

  tags = {
    Name = "natgw-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_subnet.sec_natgw_subnet]
}

resource "aws_route_table_association" "natgw-rt-association" {
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_natgw_subnet[count.index].id

  route_table_id = aws_route_table.natgw-rt[count.index].id

  depends_on = [aws_internet_gateway.sec_vpc_igw, aws_route_table.natgw-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "tgwa-rt" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name = "tgwa-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_subnet.sec_tgwa_subnet]
}

resource "aws_route_table_association" "tgwa-rt-association" {
  count = length(var.availability_zones)
  subnet_id      = aws_subnet.sec_tgwa_subnet[count.index].id

  route_table_id = aws_route_table.tgwa-rt[count.index].id

  depends_on = [aws_route_table.tgwa-rt]
}
