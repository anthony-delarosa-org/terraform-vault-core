resource "local_file" "secondary_nlb_update" {
  count    = var.hcp_vault_plus_replication ? 1 : 0
  content  = templatefile("${path.module}/secondary_lambda/nlb_update.tpl", { vault_url = trimprefix(aws_api_gateway_integration.secondary_root_integration[0].uri, "https://"), tg_arn = aws_lb_target_group.secondary_vault_tg[0].arn })
  filename = "${path.module}/secondary_lambda/nlb_update.py"
}

data "archive_file" "secondary_zip_the_python_code" {
  depends_on  = [local_file.secondary_nlb_update]
  type        = "zip"
  source_dir  = "${path.module}/secondary_lambda"
  output_path = "${path.module}/secondary_vault-tg.zip"
  excludes    = ["${path.module}/secondary_lambda/nlb_update.tpl"]
}

resource "aws_lambda_function" "secondary_vault_tg_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  count         = var.hcp_vault_plus_replication ? 1 : 0
  provider      = aws.secondary
  depends_on    = [aws_api_gateway_rest_api.secondary_api, data.archive_file.secondary_zip_the_python_code]
  filename      = "${path.module}/secondary_vault-tg.zip"
  function_name = "vault-tg-ip-update"
  role          = aws_iam_role.vault_tg_role.arn
  handler       = "nlb_update.main"
  runtime       = "python3.9"
}

resource "aws_lambda_permission" "secondary_allow_cloudwatch_to_call_lambda" {
  count         = var.hcp_vault_plus_replication ? 1 : 0
  provider      = aws.secondary
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secondary_vault_tg_lambda[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secondary_every_five_minutes[count.index].arn
}