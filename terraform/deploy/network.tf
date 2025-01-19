###############
#Network resources
###############

resource "aws_vpc" "vpc-main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

###################
#Internet GW for inbound access to the Load Balancer
###################

resource "aws_internet_gateway" "gw-main" {
  vpc_id = aws_vpc.vpc-main.id

  tags = {
    Name = "${local.prefix}-gw-main"
  }
}
###################
#Public subnet A
###################

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.vpc-main.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}-a"

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

resource "aws_route_table" "public-a" {
  vpc_id = aws_vpc.vpc-main.id

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-a.id
}

resource "aws_route" "public-internet-access-a" {
  route_table_id         = aws_route_table.public-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw-main.id
}

###################
#Public subnet B
###################

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.vpc-main.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}-b"

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

resource "aws_route_table" "public-b" {
  vpc_id = aws_vpc.vpc-main.id

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public-b.id
}

resource "aws_route" "public-internet-access-b" {
  route_table_id         = aws_route_table.public-b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw-main.id
}
