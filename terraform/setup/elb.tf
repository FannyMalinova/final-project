resource "aws_security_group" "elb" {
  description = "Configure access for the Load Balancer"
  name        = "${local.prefix}-elb-access"
  vpc_id      = aws_vpc.vpc-main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "budget-app-elb" {
  name               = "${local.prefix}-elb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public-a.id, aws_subnet.public-b.id]
  security_groups    = [aws_security_group.elb.id]
}

resource "aws_lb_target_group" "budget-app-target" {
  name        = "${local.prefix}-budget-app"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc-main.id
  target_type = "ip"
  port        = 5000
}

resource "aws_lb_listener" "budget-app-listener" {
  load_balancer_arn = aws_lb.budget-app-elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.budget-app-target.arn
  }
}