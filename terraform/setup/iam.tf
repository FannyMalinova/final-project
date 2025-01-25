###
#Create IAM user and policies for CICD account
###

resource "aws_iam_user" "budget-user" {
  name = "budget-app-${local.prefix}-user"
}

resource "aws_iam_access_key" "budget-user" {
  user = aws_iam_user.budget-user.name
}

###
# Add policy for terraform backend to S3 and Dynamo DB access #
###

data "aws_iam_policy_document" "tf-backend" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf-state-bucket}"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf-state-bucket}/tf-state-release/*",
      "arn:aws:s3:::${var.tf-state-bucket}/tf-state-release-env/*",
      "arn:aws:s3:::${var.tf-state-bucket}/env:/*",
      "arn:aws:s3:::${var.tf-state-bucket}final-project-s3/tf-state-config"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.tf-state-lock-table}"]
  }
}

resource "aws_iam_policy" "tf-backend" {
  name        = "${aws_iam_user.budget-user.name}-tf-s3-dynamodb"
  description = "Allow user to use S3 and DynamoDB for Terraform backend resources"
  policy      = data.aws_iam_policy_document.tf-backend.json
}

resource "aws_iam_user_policy_attachment" "tf-backend" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.tf-backend.arn
}

#########################
# Add policy for accessing ECR and allow pushing images
#########################

data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.budget-app-repo.arn]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_user.budget-user.name}-ecr"
  description = "Allow user to manage ECR resources"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.ecr.arn
}


#########################
# Add policy for accessing EC2 resources
#########################

data "aws_iam_policy_document" "ec2" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "rds:CreateDBSubnetGroup",
      "ec2:DescribeSecurityGroups",
      "ec2:DeleteSubnet",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:DeleteInternetGateway",
      "ec2:DetachNetworkInterface",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:DeleteRouteTable",
      "ec2:DeleteVpcEndpoints",
      "ec2:DisassociateRouteTable",
      "ec2:DeleteRoute",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribePrefixLists",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeNetworkAcls",
      "ec2:AssociateRouteTable",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:CreateVpcEndpoint",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateSubnet",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:ModifyVpcAttribute",
      "ec2:RevokeSecurityGroupIngress",
      "rds:ModifyDBSubnetGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2" {
  name        = "${aws_iam_user.budget-user.name}-ec2"
  description = "Allow user to manage EC2 resources."
  policy      = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_user_policy_attachment" "ec2" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.ec2.arn
}

###############################
# Add policy for accessing RDS
###############################

data "aws_iam_policy_document" "rds" {
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBInstances",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:CreateDBInstance",
      "rds:ModifyDBSubnetGroup",
      "rds:DeleteDBInstance",
      "rds:ListTagsForResource",
      "rds:ModifyDBInstance",
      "rds:AddTagsToResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rds" {
  name        = "${aws_iam_user.budget-user.name}-rds"
  description = "Allow user to manage RDS resources."
  policy      = data.aws_iam_policy_document.rds.json
}

resource "aws_iam_user_policy_attachment" "rds" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.rds.arn
}

#########################
# Additional persmissions required for creating a Service Linked Role
#########################

data "aws_iam_policy_document" "rds-service-linked-role" {
  statement {
    actions   = ["iam:CreateServiceLinkedRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "rds-service-linked-role" {
  name        = "${aws_iam_user.budget-user.name}-role"
  description = "Policy to allow creating a service-linked role for RDS"
  policy      = data.aws_iam_policy_document.rds-service-linked-role.json
}

resource "aws_iam_user_policy_attachment" "rds-service-linked-role" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.rds-service-linked-role.arn
}

#########################
# Add policy for accessing ECS
#########################

data "aws_iam_policy_document" "ecs" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DeregisterTaskDefinition",
      "ecs:DeleteCluster",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:DescribeTaskDefinition",
      "ecs:CreateService",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateCluster",
      "ecs:UpdateCluster",
      "ecs:TagResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs" {
  name        = "${aws_iam_user.budget-user.name}-ecs"
  description = "Allow user to manage ECS resources."
  policy      = data.aws_iam_policy_document.ecs.json
}

resource "aws_iam_user_policy_attachment" "ecs" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.ecs.arn
}

#########################
# Policy for IAM access #
#########################

data "aws_iam_policy_document" "iam" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfilesForRole",
      "iam:ListAttachedRolePolicies",
      "iam:DeleteRole",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:AttachRolePolicy",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam" {
  name        = "${aws_iam_user.budget-user.name}-iam"
  description = "Allow user to manage IAM resources."
  policy      = data.aws_iam_policy_document.iam.json
}

resource "aws_iam_user_policy_attachment" "iam" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.iam.arn
}

################################
# Policy for CloudWatch access #
################################

data "aws_iam_policy_document" "logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:CreateLogGroup",
      "logs:TagResource",
      "logs:ListTagsLogGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "logs" {
  name        = "${aws_iam_user.budget-user.name}-logs"
  description = "Allow user to manage CloudWatch resources."
  policy      = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_user_policy_attachment" "logs" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.logs.arn
}

####################################
# Policy for ECS and Fargate access
####################################

data "aws_iam_policy_document" "task-execution-role-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]

  }
}

resource "aws_iam_policy" "task-execution-role-policy" {
  name        = "${local.prefix}-task-execution-role-policy"
  description = "Allow ECS to retrieve images and write to logs."
  policy      = data.aws_iam_policy_document.task-execution-role-policy.json
}

data "aws_iam_policy_document" "task-assume-role-policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task-execution-role" {
  name               = "${local.prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "task-execution-role" {
  role       = aws_iam_role.task-execution-role.name
  policy_arn = aws_iam_policy.task-execution-role-policy.arn
}

################################
# Policy for ECS Task SSM
###############################

data "aws_iam_policy_document" "task-ssm-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "app-task-role" {
  name               = "${local.prefix}-app-task-role"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role-policy.json
}

resource "aws_iam_policy" "task-ssm-policy" {
  name        = "${local.prefix}-task-ssm-role-policy"
  description = "Policy to allow System Manager to execute in container"
  policy      = data.aws_iam_policy_document.task-ssm-policy.json
}

resource "aws_iam_role_policy_attachment" "task-ssm-policy" {
  role       = aws_iam_role.app-task-role.name
  policy_arn = aws_iam_policy.task-ssm-policy.arn
}

#########################
# Policy for accessing LB
#########################

data "aws_iam_policy_document" "elb" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:ModifyListener"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "elb" {
  name        = "${aws_iam_user.budget-user.name}-elb"
  description = "Allow user to manage ELB resources."
  policy      = data.aws_iam_policy_document.elb.json
}

resource "aws_iam_user_policy_attachment" "elb" {
  user       = aws_iam_user.budget-user.name
  policy_arn = aws_iam_policy.elb.arn
}