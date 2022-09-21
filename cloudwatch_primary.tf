resource "aws_cloudwatch_log_group" "primary_vault_tg_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.primary_vault_tg_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "primary_every_five_minutes" {
  name                = "vault-tg-update-every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "primary_check_nlb_tg_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.primary_every_five_minutes.name
  target_id = "vault_tg_lambda"
  arn       = aws_lambda_function.primary_vault_tg_lambda.arn
}

resource "aws_cloudwatch_metric_alarm" "primary_lambda_alarm" {
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
  alarm_actions       = [aws_sns_topic.primary_alarm_topic.arn]

  dimensions = {
    FunctionName = aws_lambda_function.primary_vault_tg_lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "primary_nlb_tg_alarm" {
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
  alarm_actions       = [aws_sns_topic.primary_alarm_topic.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.primary_vault_tg.arn_suffix
    LoadBalancer = aws_lb.primary_network_lb.arn_suffix
  }
}

resource "aws_sns_topic" "primary_alarm_topic" {
  name         = "hcp-vault-topic"
  display_name = "hcp-vault-topic"
}

resource "aws_sns_topic_subscription" "primary_alarm_topic_subscription" {
  topic_arn = aws_sns_topic.primary_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
}