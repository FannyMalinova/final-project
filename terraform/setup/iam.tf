###
#Create IAM user and policies for CICD account
###

resource "aws_iam_user" "budget-user" {
  name = "budget-app-user"
}

resource "aws_iam_access_key" "budget-user" {
  user = aws_iam_user.budget-user.name
}

###
# Policy for terraform backend to S3 and Dynamo DB access #
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
      "arn:aws:s3:::${var.tf-state-bucket}/tf-state-prod/*",
      "arn:aws:s3:::${var.tf-state-bucket}/tf-state-prod-env/*"
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
