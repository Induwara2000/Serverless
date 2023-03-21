# Terraform code
# Define the provider
provider "aws" {
  access_key = "AKIAURGPCGPZZ4ARP44C"
  secret_key = "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"
  region = "us-east-1"
}

# Converting the lambda fuction to a zip
data "archive_file" "zip_the_python_code" {
    type = "zip"
    source_dir = "${path.module}/python/"
    output_path = "${path.module}/python/main.zip"
}

# Define the Lambda function
resource "aws_lambda_function" "movie_serverless" {
  function_name = "movie-serverless1"
  role         = aws_iam_role.lambda_role.arn
  handler      = "main.lambda_handler"
  runtime      = "python3.8"
  timeout      = 10
  memory_size  = 128
  filename     = "${path.module}/python/main.zip"


}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "movie-serverless-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for the Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name = "movie-serverless-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Define API Gateway REST API
resource "aws_api_gateway_rest_api" "serverless_rest_api" {
  name        = "serverless_rest_api"
  description = "REST API for movie serverless application"
}

# Define API Gateway resource
resource "aws_api_gateway_resource" "serverless_post" {
  rest_api_id = aws_api_gateway_rest_api.serverless_rest_api.id
  parent_id   = aws_api_gateway_rest_api.serverless_rest_api.root_resource_id
  path_part   = "movies"
}

# Define API Gateway method
resource "aws_api_gateway_method" "serverless_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_rest_api.id
  resource_id   = aws_api_gateway_resource.serverless_post.id
  http_method   = "POST"
  authorization = "NONE"
}

# Define API Gateway integration
resource "aws_api_gateway_integration" "serverless_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_rest_api.id
  resource_id = aws_api_gateway_resource.serverless_post.id
  http_method = aws_api_gateway_method.serverless_post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.movie_serverless.invoke_arn
}

# Define API Gateway deployment
resource "aws_api_gateway_deployment" "serverless_deployment" {
  depends_on = [aws_api_gateway_integration.serverless_lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.serverless_rest_api.id
  stage_name  = "prod"
}

# Define output for API Gateway URL
output "api_gateway_url" {
  value = aws_api_gateway_deployment.serverless_deployment.invoke_url
}


#Define the API Gateway deployment
resource "aws_api_gateway_deployment" "movie_serverless" {
  depends_on = [
    aws_api_gateway_integration.serverless_lambda_integration,
    aws_api_gateway_method.serverless_post_method
  ]
  rest_api_id = aws_api_gateway_rest_api.serverless_rest_api.id
  stage_name  = "prod"
}


