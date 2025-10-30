# IAM Roles for ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/ecs/${var.project_name}-api-gateway"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-api-gateway-logs"
  })
}

resource "aws_cloudwatch_log_group" "proxy_client" {
  name              = "/ecs/${var.project_name}-proxy-client"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-proxy-client-logs"
  })
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/${var.project_name}-user-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-user-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/ecs/${var.project_name}-product-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-product-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/${var.project_name}-order-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-order-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "payment_service" {
  name              = "/ecs/${var.project_name}-payment-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-payment-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "shipping_service" {
  name              = "/ecs/${var.project_name}-shipping-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-shipping-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "favourite_service" {
  name              = "/ecs/${var.project_name}-favourite-service"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-favourite-service-logs"
  })
}

resource "aws_cloudwatch_log_group" "service_discovery" {
  name              = "/ecs/${var.project_name}-service-discovery"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-service-discovery-logs"
  })
}

resource "aws_cloudwatch_log_group" "cloud_config" {
  name              = "/ecs/${var.project_name}-cloud-config"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloud-config-logs"
  })
}

