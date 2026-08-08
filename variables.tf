variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Function Productos"
  type        = string
  default     = "product-lambda"
}

variable "auth_function_name" {
  description = "Funcion Lambda Auth"
  type        = string
  default     = "lambda-auth"
}

variable "runtime" {
  description = "Runtime de la Lambda"
  type        = string
  default     = "nodejs22.x"
}
