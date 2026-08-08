# =========================
# VPC
# =========================

module "vpc" {
  source = "./modules/vpc"
}

# =========================
# Cognito
# =========================

module "cognito" {
  source = "./modules/cognito"
}

# =========================
# IAM (rol de ejecución + policy S3 compartidos por las lambdas)
# =========================

module "iam" {
  source = "./modules/iam"
}

# Permiso para que el lambda de auth pueda llamar a Cognito InitiateAuth
resource "aws_iam_role_policy" "auth_cognito_policy" {
  name = "lambda-auth-cognito-policy"
  role = module.iam.role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:InitiateAuth"]
        Resource = module.cognito.user_pool_arn
      }
    ]
  })
}

# =========================
# Lambda layer (dependencias compartidas)
# =========================

module "lambda_layer_deps" {
  source = "./modules/lambda_layer"

  filename             = "dependencies-auth.zip"
  layer_name           = "nodejs-dependencies-auth"
  compatible_runtimes  = [var.runtime]
}

# =========================
# Lambdas
# =========================

module "lambda_api" {
  source = "./modules/lambda_function"

  function_name = var.function_name
  runtime       = var.runtime
  filename      = "lambda.zip"
  role_arn      = module.iam.role_arn
  layers        = [module.lambda_layer_deps.arn]
}

module "lambda_auth" {
  source = "./modules/lambda_function"

  function_name = var.auth_function_name
  runtime       = var.runtime
  filename      = "lambda-auth.zip"
  role_arn      = module.iam.role_arn

  environment_variables = {
    COGNITO_CLIENT_ID = module.cognito.client_id
  }
}

# =========================
# API Gateway
# =========================

module "api_gateway" {
  source = "./modules/api_gateway"

  cognito_user_pool_arn = module.cognito.user_pool_arn

  products_lambda_function_name = module.lambda_api.function_name
  products_lambda_invoke_arn    = module.lambda_api.invoke_arn

  auth_lambda_function_name = module.lambda_auth.function_name
  auth_lambda_invoke_arn    = module.lambda_auth.invoke_arn
}
