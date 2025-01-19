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
