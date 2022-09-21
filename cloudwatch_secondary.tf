resource "aws_cloudwatch_log_group" "secondary_vault_tg_lambda" {
  count             = var.hcp_vault_plus_replication ? 1 : 0
  provider          = aws.secondary
  name              = "/aws/lambda/${aws_lambda_function.secondary_vault_tg_lambda[count.index].function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "secondary_every_five_minutes" {
  count               = var.hcp_vault_plus_replication ? 1 : 0
  provider            = aws.secondary
  name                = "vault-tg-update-every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "secondary_check_nlb_tg_every_five_minutes" {
  count     = var.hcp_vault_plus_replication ? 1 : 0
  provider  = aws.secondary
  rule      = aws_cloudwatch_event_rule.secondary_every_five_minutes[count.index].name
  target_id = "vault_tg_lambda"
  arn       = aws_lambda_function.secondary_vault_tg_lambda[count.index].arn
}

resource "aws_cloudwatch_metric_alarm" "secondary_lambda_alarm" {
  count               = var.hcp_vault_plus_replication ? 1 : 0
  provider            = aws.secondary
  alarm_name          = "vault-tg-lambda-alarm"
  alarm_description   = "This metric monitors lambda invocation errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.secondary_alarm_topic[count.index].arn]

  dimensions = {
    FunctionName = aws_lambda_function.secondary_vault_tg_lambda[count.index].function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "secondary_nlb_tg_alarm" {
  count               = var.hcp_vault_plus_replication ? 1 : 0
  provider            = aws.secondary
  alarm_name          = "vault-tg-nlb-alarm"
  alarm_description   = "This metric monitors for any unhealthy nodes in target group"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.secondary_alarm_topic[count.index].arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.secondary_vault_tg[count.index].arn_suffix
    LoadBalancer = aws_lb.secondary_network_lb[count.index].arn_suffix
  }
}

resource "aws_sns_topic" "secondary_alarm_topic" {
  count        = var.hcp_vault_plus_replication ? 1 : 0
  provider     = aws.secondary
  name         = "hcp-vault-topic"
  display_name = "hcp-vault-topic"
}

resource "aws_sns_topic_subscription" "secondary_alarm_topic_subscription" {
  count     = var.hcp_vault_plus_replication ? 1 : 0
  provider  = aws.secondary
  topic_arn = aws_sns_topic.secondary_alarm_topic[count.index].arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
}