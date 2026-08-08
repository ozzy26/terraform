# Cómo integrar esto en tu proyecto

## 1. Archivos que se movieron a módulos
Reemplaza tu `main.tf`, `iam.tf` por los nuevos `main.tf` / `variables.tf` / `outputs.tf` /
`provider.tf` de este paquete, y copia la carpeta `modules/` completa a la raíz
de tu proyecto (junto a `lambda/` y `lambda-auth/`, que ya vienen incluidas aquí
sin cambios).

## 2. Tienes un terraform.tfstate existente — esto es lo importante
Como ya aplicaste el `main.tf` plano anteriormente, tu `terraform.tfstate` tiene
los recursos con direcciones "planas" (ej: `aws_vpc.name`, `aws_lambda_function.api`,
`aws_iam_role.lambda_role`). Al mover esos mismos recursos dentro de módulos,
Terraform los ve como recursos *nuevos* (ej: `module.vpc.aws_vpc.this`) y, si
corres `terraform apply` directo, va a intentar **destruir los que existen y
crear otros nuevos**.

Para evitar downtime / recreación, migra el state con `terraform state mv`
antes de aplicar, por ejemplo:

```bash
terraform state mv aws_vpc.name                         module.vpc.aws_vpc.this
terraform state mv aws_subnet.public                    module.vpc.aws_subnet.public
terraform state mv aws_subnet.private                   module.vpc.aws_subnet.private
terraform state mv aws_internet_gateway.main             module.vpc.aws_internet_gateway.main
terraform state mv aws_route_table.public                module.vpc.aws_route_table.public
terraform state mv aws_route_table_association.public    module.vpc.aws_route_table_association.public

terraform state mv aws_cognito_user_pool.main             module.cognito.aws_cognito_user_pool.main
terraform state mv aws_cognito_user_pool_client.client    module.cognito.aws_cognito_user_pool_client.client

terraform state mv aws_iam_role.lambda_role               module.iam.aws_iam_role.lambda_role
terraform state mv aws_iam_policy.lambda_s3_policy         module.iam.aws_iam_policy.lambda_s3_policy
terraform state mv aws_iam_role_policy_attachment.attach_s3          module.iam.aws_iam_role_policy_attachment.attach_s3
terraform state mv aws_iam_role_policy_attachment.attach_lambda_logs module.iam.aws_iam_role_policy_attachment.attach_lambda_logs

terraform state mv aws_lambda_layer_version.auth           module.lambda_layer_deps.aws_lambda_layer_version.this
terraform state mv aws_lambda_function.api                 module.lambda_api.aws_lambda_function.this
terraform state mv aws_lambda_function.auth                module.lambda_auth.aws_lambda_function.this

terraform state mv aws_api_gateway_rest_api.api             module.api_gateway.aws_api_gateway_rest_api.api
terraform state mv aws_api_gateway_authorizer.cognito        module.api_gateway.aws_api_gateway_authorizer.cognito
terraform state mv aws_api_gateway_resource.source            module.api_gateway.aws_api_gateway_resource.products
terraform state mv aws_api_gateway_method.name                module.api_gateway.aws_api_gateway_method.products
terraform state mv aws_api_gateway_integration.products        module.api_gateway.aws_api_gateway_integration.products
terraform state mv aws_lambda_permission.apigw_products         module.api_gateway.aws_lambda_permission.apigw_products
terraform state mv aws_api_gateway_resource.auth               module.api_gateway.aws_api_gateway_resource.auth
terraform state mv aws_api_gateway_method.auth                  module.api_gateway.aws_api_gateway_method.auth
terraform state mv aws_api_gateway_integration.auth             module.api_gateway.aws_api_gateway_integration.auth
terraform state mv aws_lambda_permission.auth                     module.api_gateway.aws_lambda_permission.apigw_auth
terraform state mv aws_api_gateway_deployment.deployment          module.api_gateway.aws_api_gateway_deployment.deployment
terraform state mv aws_api_gateway_stage.dev                       module.api_gateway.aws_api_gateway_stage.dev
```

`aws_iam_role_policy.auth_cognito_policy` se queda igual (sigue estando en el
root `main.tf`, no lo moví a un módulo), así que no necesita `state mv`.

Después de mover todo, corre:

```bash
terraform init
terraform plan
```

El plan debería salir "sin cambios" (o solo cambios cosméticos). Si ves que
quiere destruir/crear algo, detente y revisa la dirección del `state mv`
correspondiente antes de aplicar.

## 3. Si prefieres partir de cero (sin state previo)
Simplemente borra `terraform.tfstate` / `terraform.tfstate.backup` / `.terraform/`
de tu copia y corre `terraform init && terraform apply` normal — Terraform creará
todo desde cero con la nueva estructura.

## 4. Qué cambié respecto a tu código original
- Corregí lo que ya habías anotado en tu `NOTA.txt`: el `source_arn` de los
  `aws_lambda_permission` ya llevaba el sufijo `/*/*` (estaba bien) y las
  integraciones ya usan `invoke_arn` (no `.arn`) — quedó igual en los módulos.
- `iam.tf` se movió completo a `modules/iam` (rol + policy S3 + los dos
  attachments), sin cambiar lógica, solo parametrizando nombres.
- El resto de la lógica (Cognito, VPC, API Gateway, deployment/stage) es
  exactamente la misma, solo repartida en módulos.
