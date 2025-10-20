# ECR Repositories
resource "aws_ecr_repository" "api_gateway" {
  name                 = "${var.project_name}-api-gateway"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-api-gateway-repo"
  })
}

resource "aws_ecr_repository" "proxy_client" {
  name                 = "${var.project_name}-proxy-client"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-proxy-client-repo"
  })
}

resource "aws_ecr_repository" "user_service" {
  name                 = "${var.project_name}-user-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-user-service-repo"
  })
}

resource "aws_ecr_repository" "product_service" {
  name                 = "${var.project_name}-product-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-product-service-repo"
  })
}

resource "aws_ecr_repository" "order_service" {
  name                 = "${var.project_name}-order-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-order-service-repo"
  })
}

resource "aws_ecr_repository" "payment_service" {
  name                 = "${var.project_name}-payment-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-payment-service-repo"
  })
}

resource "aws_ecr_repository" "shipping_service" {
  name                 = "${var.project_name}-shipping-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-shipping-service-repo"
  })
}

resource "aws_ecr_repository" "favourite_service" {
  name                 = "${var.project_name}-favourite-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-favourite-service-repo"
  })
}

resource "aws_ecr_repository" "service_discovery" {
  name                 = "${var.project_name}-service-discovery"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-service-discovery-repo"
  })
}

resource "aws_ecr_repository" "cloud_config" {
  name                 = "${var.project_name}-cloud-config"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloud-config-repo"
  })
}
