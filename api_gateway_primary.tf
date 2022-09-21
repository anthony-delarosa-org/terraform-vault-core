resource "aws_lb_target_group" "primary_vault_tg" {
  name        = "tf-vault-lb-tg"
  port        = 8200
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.primary_vault_vpc.id
}

resource "aws_lb" "primary_network_lb" {
  name               = "network-vault-lb"
  load_balancer_type = "network"
  internal           = true

  subnet_mapping {
    subnet_id = aws_subnet.primary_subnet_a.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.primary_subnet_b.id
  }
}

resource "aws_lb_listener" "primary_listener" {
  load_balancer_arn = aws_lb.primary_network_lb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary_vault_tg.arn
  }
}

resource "aws_api_gateway_vpc_link" "primary_api_link" {
  name        = "vault-api-link"
  description = "This is the VPC Link for the NLB"
  target_arns = [aws_lb.primary_network_lb.arn]
}

resource "aws_api_gateway_rest_api" "primary_api" {
  name        = "vault-api-gateway"
  description = "Proxy to handle requests to our API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "primary_root_method" {
  rest_api_id      = aws_api_gateway_rest_api.primary_api.id
  resource_id      = aws_api_gateway_rest_api.primary_api.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "primary_root_integration" {
  http_method             = aws_api_gateway_method.primary_root_method.http_method
  resource_id             = aws_api_gateway_rest_api.primary_api.root_resource_id
  rest_api_id             = aws_api_gateway_rest_api.primary_api.id
  type                    = "HTTP"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.primary_api_link.id
  uri                     = trim(hcp_vault_cluster.primary_vault_cluster.vault_private_endpoint_url, ":8200")
}

resource "aws_api_gateway_method_response" "primary_root_response_200" {
  rest_api_id = aws_api_gateway_rest_api.primary_api.id
  resource_id = aws_api_gateway_rest_api.primary_api.root_resource_id
  http_method = aws_api_gateway_method.primary_root_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "primary_root_integration_response" {
  depends_on  = [aws_api_gateway_integration.primary_root_integration]
  rest_api_id = aws_api_gateway_rest_api.primary_api.id
  resource_id = aws_api_gateway_rest_api.primary_api.root_resource_id
  http_method = aws_api_gateway_method.primary_root_method.http_method
  status_code = aws_api_gateway_method_response.primary_root_response_200.status_code
}

resource "aws_api_gateway_resource" "primary_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.primary_api.id
  parent_id   = aws_api_gateway_rest_api.primary_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "primary_proxy_method" {
  rest_api_id      = aws_api_gateway_rest_api.primary_api.id
  resource_id      = aws_api_gateway_resource.primary_proxy_resource.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_method_response" "primary_proxy_response_200" {
  rest_api_id = aws_api_gateway_rest_api.primary_api.id
  resource_id = aws_api_gateway_resource.primary_proxy_resource.id
  http_method = aws_api_gateway_method.primary_proxy_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "primary_proxy_integration" {
  http_method             = aws_api_gateway_method.primary_proxy_method.http_method
  resource_id             = aws_api_gateway_resource.primary_proxy_resource.id
  rest_api_id             = aws_api_gateway_rest_api.primary_api.id
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.primary_api_link.id
  uri                     = replace(hcp_vault_cluster.primary_vault_cluster.vault_private_endpoint_url, ":8200", "/{proxy}")
  integration_http_method = "ANY"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_integration_response" "primary_proxy_integration_response" {
  depends_on  = [aws_api_gateway_integration.primary_proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.primary_api.id
  resource_id = aws_api_gateway_resource.primary_proxy_resource.id
  http_method = aws_api_gateway_method.primary_proxy_method.http_method
  status_code = aws_api_gateway_method_response.primary_proxy_response_200.status_code
}

resource "aws_api_gateway_deployment" "primary_api_gateway_deployment" {
  depends_on  = [aws_api_gateway_integration.primary_proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.primary_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.primary_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "primary_stage" {
  deployment_id = aws_api_gateway_deployment.primary_api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.primary_api.id
  stage_name    = "prod"
}

resource "aws_api_gateway_api_key" "primary_api_key" {
  name = "vault-api-key"
}

resource "aws_api_gateway_usage_plan" "primary_usage_plan" {
  name        = "Vault"
  description = "Vault Usage Plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.primary_api.id
    stage  = aws_api_gateway_stage.primary_stage.stage_name
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

resource "aws_api_gateway_usage_plan_key" "primary_plan_key" {
  key_id        = aws_api_gateway_api_key.primary_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.primary_usage_plan.id
}
