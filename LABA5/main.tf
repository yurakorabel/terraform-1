provider "aws" {
  region = "eu-west-2"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name = "VPC"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "IGW"
  }
}

#--------Public Subnets, Routing-----------

resource "aws_subnet" "public-subnets" {
  count                   = length(var.public-subnet-cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.public-subnet-cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  count          = length(aws_subnet.public-subnets[*].id)
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = element(aws_subnet.public-subnets[*].id, count.index)
}

#--------Private Subnets, Routing-----------

resource "aws_subnet" "private-subnets" {
  count             = length(var.private-subnet-cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private-subnet-cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_route_table" "private-route-table" {
  count  = length(var.private-subnet-cidrs)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
  count          = length(aws_subnet.private-subnets[*].id)
  route_table_id = aws_route_table.private-route-table[count.index].id
  subnet_id      = element(aws_subnet.private-subnets[*].id, count.index)
}

#--------Database Subnets, Routing-----------

resource "aws_subnet" "database-subnets" {
  count             = length(var.database-subnet-cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.database-subnet-cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "Database Subnet"
  }
}

resource "aws_route_table" "database-route-table" {
  count  = length(var.database-subnet-cidrs)
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Database Route Table"
  }
}

resource "aws_route_table_association" "database-subnet-route-table-association" {
  count          = length(aws_subnet.database-subnets[*].id)
  route_table_id = aws_route_table.database-route-table[count.index].id
  subnet_id      = element(aws_subnet.database-subnets[*].id, count.index)
}

#--------NAT Gateways-----------

resource "aws_eip" "nat-eip" {
  count = length(var.private-subnet-cidrs)
  vpc   = true
  tags = {
    Name = "VPC EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private-subnet-cidrs)
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = element(aws_subnet.public-subnets[*].id, count.index)
  tags = {
    Name = "VPC NAT GW"
  }
}
