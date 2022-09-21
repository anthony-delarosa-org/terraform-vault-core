resource "aws_lb_target_group" "secondary_vault_tg" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  name        = "tf-vault-lb-tg"
  port        = 8200
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.secondary_vault_vpc[count.index].id
}

resource "aws_lb" "secondary_network_lb" {
  count              = var.hcp_vault_plus_replication ? 1 : 0
  provider           = aws.secondary
  name               = "network-vault-lb"
  load_balancer_type = "network"
  internal           = true

  subnet_mapping {
    subnet_id = aws_subnet.secondary_subnet_a[count.index].id
  }

  subnet_mapping {
    subnet_id = aws_subnet.secondary_subnet_b[count.index].id
  }
}

resource "aws_lb_listener" "secondary_listener" {
  count             = var.hcp_vault_plus_replication ? 1 : 0
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary_network_lb[count.index].arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary_vault_tg[count.index].arn
  }
}

resource "aws_api_gateway_vpc_link" "secondary_api_link" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  name        = "vault-api-link"
  description = "This is the VPC Link for the NLB"
  target_arns = [aws_lb.secondary_network_lb[count.index].arn]
}

resource "aws_api_gateway_rest_api" "secondary_api" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  name        = "vault-api-gateway"
  description = "Proxy to handle requests to our API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "secondary_root_method" {
  count            = var.hcp_vault_plus_replication ? 1 : 0
  provider         = aws.secondary
  rest_api_id      = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id      = aws_api_gateway_rest_api.secondary_api[count.index].root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "secondary_root_integration" {
  count                   = var.hcp_vault_plus_replication ? 1 : 0
  provider                = aws.secondary
  http_method             = aws_api_gateway_method.secondary_root_method[count.index].http_method
  resource_id             = aws_api_gateway_rest_api.secondary_api[count.index].root_resource_id
  rest_api_id             = aws_api_gateway_rest_api.secondary_api[count.index].id
  type                    = "HTTP"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.secondary_api_link[count.index].id
  uri                     = trim(hcp_vault_cluster.secondary_vault_cluster[count.index].vault_private_endpoint_url, ":8200")
}

resource "aws_api_gateway_method_response" "secondary_root_response_200" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id = aws_api_gateway_rest_api.secondary_api[count.index].root_resource_id
  http_method = aws_api_gateway_method.secondary_root_method[count.index].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "secondary_root_integration_response" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  depends_on  = [aws_api_gateway_integration.secondary_root_integration]
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id = aws_api_gateway_rest_api.secondary_api[count.index].root_resource_id
  http_method = aws_api_gateway_method.secondary_root_method[count.index].http_method
  status_code = aws_api_gateway_method_response.secondary_root_response_200[count.index].status_code
}

resource "aws_api_gateway_resource" "secondary_proxy_resource" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
  parent_id   = aws_api_gateway_rest_api.secondary_api[count.index].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "secondary_proxy_method" {
  count            = var.hcp_vault_plus_replication ? 1 : 0
  provider         = aws.secondary
  rest_api_id      = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id      = aws_api_gateway_resource.secondary_proxy_resource[count.index].id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}


resource "aws_api_gateway_method_response" "secondary_proxy_response_200" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id = aws_api_gateway_resource.secondary_proxy_resource[count.index].id
  http_method = aws_api_gateway_method.secondary_proxy_method[count.index].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "secondary_proxy_integration" {
  count                   = var.hcp_vault_plus_replication ? 1 : 0
  provider                = aws.secondary
  http_method             = aws_api_gateway_method.secondary_proxy_method[count.index].http_method
  resource_id             = aws_api_gateway_resource.secondary_proxy_resource[count.index].id
  rest_api_id             = aws_api_gateway_rest_api.secondary_api[count.index].id
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.secondary_api_link[count.index].id
  uri                     = replace(hcp_vault_cluster.secondary_vault_cluster[count.index].vault_private_endpoint_url, ":8200", "/{proxy}")
  integration_http_method = "ANY"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_integration_response" "secondary_proxy_integration_response" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  depends_on  = [aws_api_gateway_integration.secondary_proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
  resource_id = aws_api_gateway_resource.secondary_proxy_resource[count.index].id
  http_method = aws_api_gateway_method.secondary_proxy_method[count.index].http_method
  status_code = aws_api_gateway_method_response.secondary_proxy_response_200[count.index].status_code
}

resource "aws_api_gateway_deployment" "secondary_api_gateway_deployment" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  depends_on  = [aws_api_gateway_integration.secondary_proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.secondary_api[count.index].id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.secondary_api[count.index].body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "secondary_stage" {
  count         = var.hcp_vault_plus_replication ? 1 : 0
  provider      = aws.secondary
  deployment_id = aws_api_gateway_deployment.secondary_api_gateway_deployment[count.index].id
  rest_api_id   = aws_api_gateway_rest_api.secondary_api[count.index].id
  stage_name    = "prod"
}

resource "aws_api_gateway_api_key" "secondary_api_key" {
  count    = var.hcp_vault_plus_replication ? 1 : 0
  provider = aws.secondary
  name     = "vault-api-key"
}

resource "aws_api_gateway_usage_plan" "secondary_usage_plan" {
  count       = var.hcp_vault_plus_replication ? 1 : 0
  provider    = aws.secondary
  name        = "Vault"
  description = "Vault Usage Plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.secondary_api[count.index].id
    stage  = aws_api_gateway_stage.secondary_stage[count.index].stage_name
  }

  quota_settings {
    limit  = 1000
    offset = 2
    period = "MONTH"
  }

  throttle_settings {
    rate_limit  = 5
    burst_limit = 10
  }
}

resource "aws_api_gateway_usage_plan_key" "secondary_plan_key" {
  count         = var.hcp_vault_plus_replication ? 1 : 0
  provider      = aws.secondary
  key_id        = aws_api_gateway_api_key.secondary_api_key[count.index].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.secondary_usage_plan[count.index].id
}