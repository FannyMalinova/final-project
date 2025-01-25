###############
#Network resources
###############

resource "aws_vpc" "vpc-main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.prefix}-vpc-main"
  }
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
  availability_zone       = "${data.aws_region.current.name}a"

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
  availability_zone       = "${data.aws_region.current.name}b"

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

###################
#Private subnet A
###################

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.vpc-main.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-private-a"
  }
}

###################
#Private subnet B
###################

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.vpc-main.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-private-b"
  }
}

##################
# Endpoints for ECR, CloudWatch, and Systems Manager
##################

resource "aws_security_group" "endpoint-access" {
  description = "Access to endpoints"
  name        = "${local.prefix}-endpoint-access"
  vpc_id      = aws_vpc.vpc-main.id

  ingress {
    cidr_blocks = [aws_vpc.vpc-main.cidr_block]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

}

####################
# ECR-related endpoints
####################

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = aws_vpc.vpc-main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  security_group_ids = [aws_security_group.endpoint-access.id]

  tags = {
    Name = "${local.prefix}-ecr-endpoint"
  }
}


resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.vpc-main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  security_group_ids = [aws_security_group.endpoint-access.id]

  tags = {
    Name = "${local.prefix}-dkr-endpoint"
  }
}

#######################
# CloudWatch-related endpoint
#######################

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.vpc-main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  security_group_ids = [aws_security_group.endpoint-access.id]

  tags = {
    Name = "${local.prefix}-cloudwatch-endpoint"
  }
}

#####################
# SSM-related endpoint
#####################

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc-main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  security_group_ids = [aws_security_group.endpoint-access.id]

  tags = {
    Name = "${local.prefix}-ssmmessages-endpoint"
  }
}

####################
# S3-related endpoint
####################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc-main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.vpc-main.default_route_table_id]

  tags = {
    Name = "${local.prefix}-s3-endpoint"
  }
}
