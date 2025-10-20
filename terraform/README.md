# E-commerce Microservices - Despliegue en AWS con Terraform

Este proyecto contiene la infraestructura Terraform para desplegar el sistema de microservicios de ecommerce en AWS.

## Arquitectura

La infraestructura incluye:

- **VPC** con subnets públicas y privadas
- **Application Load Balancer** para distribuir tráfico
- **ECS Fargate** para ejecutar los microservicios
- **RDS MySQL** para persistencia de datos
- **ElastiCache Redis** para caché
- **ECR** para almacenar imágenes Docker
- **CloudWatch** para logging y monitoreo

## Servicios Incluidos

1. **service-discovery** - Eureka Server (puerto 8761)
2. **cloud-config** - Configuración centralizada (puerto 9296)
3. **api-gateway** - Gateway principal (puerto 8080)
4. **proxy-client** - Autenticación y autorización (puerto 8900)
5. **user-service** - Gestión de usuarios (puerto 8700)
6. **product-service** - Gestión de productos (puerto 8500)
7. **favourite-service** - Lista de favoritos (puerto 8800)
8. **order-service** - Gestión de órdenes (puerto 8300)
9. **shipping-service** - Gestión de envíos (puerto 8600)
10. **payment-service** - Gestión de pagos (puerto 8400)

## Prerrequisitos

1. **AWS CLI** configurado con credenciales
2. **Terraform** >= 1.0 instalado
3. **Docker** instalado y funcionando
4. **Maven** instalado
5. **Java 11** instalado

## Instrucciones de Despliegue

### 1. Configurar Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
aws_region   = "us-east-1"
environment  = "prod"
project_name = "ecommerce-microservices"
db_password  = "tu-password-seguro"
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Planificar el Despliegue

```bash
terraform plan
```

### 4. Desplegar la Infraestructura

```bash
terraform apply
```

### 5. Construir y Subir Imágenes Docker

**En Linux/Mac:**
```bash
chmod +x deploy-images.sh
./deploy-images.sh
```

**En Windows:**
```powershell
.\deploy-images.ps1
```

### 6. Actualizar Configuraciones de Producción

Los servicios necesitan ser actualizados para usar las bases de datos de AWS. Copia el archivo `application-aws-prod.yml` a cada servicio:

```bash
# Para cada servicio
cp terraform/application-aws-prod.yml user-service/src/main/resources/application-aws-prod.yml
cp terraform/application-aws-prod.yml product-service/src/main/resources/application-aws-prod.yml
# ... etc para todos los servicios
```

### 7. Reconstruir y Redesplegar

Después de actualizar las configuraciones, reconstruye y redespliega:

```bash
# Reconstruir el proyecto
./mvnw clean package -DskipTests

# Redesplegar imágenes
./deploy-images.sh  # o .\deploy-images.ps1 en Windows
```

## Acceso a la Aplicación

Una vez desplegado, puedes acceder a:

- **API Gateway**: `http://<ALB_DNS_NAME>`
- **Proxy Client**: `http://<ALB_DNS_NAME>/auth/*`
- **Eureka Dashboard**: `http://<ALB_DNS_NAME>:8761`
- **Cloud Config**: `http://<ALB_DNS_NAME>:9296`

## Monitoreo

- **CloudWatch Logs**: `/ecs/ecommerce-microservices-*`
- **ECS Console**: Para ver el estado de los servicios
- **RDS Console**: Para monitorear la base de datos
- **ElastiCache Console**: Para monitorear Redis

## Costos Estimados

Los recursos desplegados tienen los siguientes costos aproximados mensuales:

- **ECS Fargate**: ~$50-100 (dependiendo del uso)
- **RDS MySQL**: ~$15-30
- **ElastiCache Redis**: ~$15-25
- **ALB**: ~$20
- **ECR**: ~$5-10
- **CloudWatch**: ~$10-20

**Total estimado**: $115-205/mes

## Limpieza

Para eliminar todos los recursos:

```bash
terraform destroy
```

## Problemas Conocidos y Soluciones

### 1. Docker Desktop no funciona
- **Problema**: Errores 500 en Docker Desktop
- **Solución**: Reinicia Docker Desktop o reinstálalo

### 2. Imágenes no se encuentran
- **Problema**: Las imágenes `selimhorri/*` no están en Docker Hub
- **Solución**: Usa `compose-local.yml` para construir localmente

### 3. Configuración de Base de Datos
- **Problema**: Los servicios usan H2 en desarrollo
- **Solución**: Actualiza las configuraciones para usar MySQL en producción

### 4. Variables de Entorno
- **Problema**: Los servicios necesitan variables de entorno para AWS
- **Solución**: Configura las variables en las tareas de ECS

## Próximos Pasos

1. **Configurar HTTPS** con certificados SSL
2. **Implementar CI/CD** con GitHub Actions
3. **Agregar monitoreo** con Prometheus/Grafana
4. **Configurar backup** automático de RDS
5. **Implementar auto-scaling** para ECS

## Soporte

Si encuentras problemas:

1. Revisa los logs en CloudWatch
2. Verifica el estado de los servicios en ECS
3. Confirma que las imágenes están en ECR
4. Valida las configuraciones de red y seguridad
