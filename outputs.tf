output "api_gateway_invoke_url" {
  value = module.api_gateway.invoke_url
}

output "user_pool" {
  value = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  value = module.cognito.client_id
}

output "login_url" {
  value = module.api_gateway.login_url
}

output "products_url" {
  value = module.api_gateway.products_url
}
