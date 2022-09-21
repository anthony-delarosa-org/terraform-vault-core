resource "local_file" "primary_nlb_update" {
  content  = templatefile("${path.module}/primary_lambda/nlb_update.tpl", { vault_url = trimprefix(aws_api_gateway_integration.primary_root_integration.uri, "https://"), tg_arn = aws_lb_target_group.primary_vault_tg.arn })
  filename = "${path.module}/primary_lambda/nlb_update.py"
}

data "archive_file" "primary_zip_the_python_code" {
  depends_on  = [local_file.primary_nlb_update]
  type        = "zip"
  source_dir  = "${path.module}/primary_lambda"
  output_path = "${path.module}/primary_vault-tg.zip"
  excludes    = ["${path.module}/primary_lambda/nlb_update.tpl"]
}

resource "aws_lambda_function" "primary_vault_tg_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  depends_on    = [aws_api_gateway_rest_api.primary_api, data.archive_file.primary_zip_the_python_code]
  filename      = "${path.module}/primary_vault-tg.zip"
  function_name = "vault-tg-ip-update"
  role          = aws_iam_role.vault_tg_role.arn
  handler       = "nlb_update.main"
  runtime       = "python3.9"
}

resource "aws_iam_role" "vault_tg_role" {
  name = "vault-tg-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "vault_tg_policy" {
  name        = "vault-tg-policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
           "elasticloadbalancing:RegisterTargets",
           "elasticloadbalancing:DeregisterTargets",
           "elasticloadbalancing:DescribeTargetHealth",
           "ec2:DescribeInstances",
           "ec2:DescribeInternetGateways",
           "ec2:DescribeSubnets",
           "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "primary_role_attachment_default" {
  role       = aws_iam_role.vault_tg_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "primary_role_attachment" {
  role       = aws_iam_role.vault_tg_role.name
  policy_arn = aws_iam_policy.vault_tg_policy.arn
}

resource "aws_lambda_permission" "primary_allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.primary_vault_tg_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.primary_every_five_minutes.arn
}