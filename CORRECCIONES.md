# Cambios Realizados en Configuración de Entornos

- Se corrigieron los archivos de configuración (`application.yml`) de los microservicios para que usen variables de entorno con valores por defecto, permitiendo que funcionen tanto en local como en Kubernetes.
- En local, los servicios usan `localhost` por defecto. En Kubernetes, las variables de entorno definidas en los manifiestos (`SPRING_ZIPKIN_BASE_URL`, `SPRING_CONFIG_IMPORT`, `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE`, etc.) sobrescriben los valores y apuntan a los endpoints internos del cluster.
- Se verificó que no existan referencias directas a `localhost:8761` en los archivos de configuración, evitando problemas de descubrimiento de servicios.

# Cambios Realizados en Kubernetes

- Se actualizaron los manifiestos de despliegue (`*.yaml`) para definir correctamente las variables de entorno y los endpoints de Eureka y Zipkin.
- Se eliminó el servicio `cloud-config` del despliegue para evitar conflictos de puerto y simplificar la arquitectura.
- Se corrigió el manifiesto de `proxy-client` para registrar el microservicio con la IP del pod y usar los endpoints correctos.
- Se creó el script `Scripts\logs-status-200.cmd` para revisar los logs de todos los pods y filtrar las respuestas HTTP 200.
- Se agregaron los scripts `Scripts\start-k8s.sh` y `Scripts\stop-k8s.sh` para facilitar el despliegue y apagado de los servicios en Kubernetes.

# Guía para Probar la Solución en Kubernetes

## 1. Desplegar los servicios
```powershell
kubectl apply -f kubernetes/zipkin.yaml
kubectl apply -f kubernetes/service.discovery-container.yaml
kubectl apply -f kubernetes/proxy.client-container.yaml
# Repite para otros servicios si es necesario
```

O ejecuta el script:
```bash
bash Scripts/start-k8s.sh
```

## 2. Verificar que los pods estén corriendo
```powershell
kubectl get pods -n ecommerce
```

## 3. Revisar los logs de los pods
```powershell
kubectl logs -n ecommerce <nombre-del-pod>
```

## 4. Validar respuestas HTTP 200 en los logs
```powershell
cd kubernetes/Scripts
logs-status-200.cmd
```

## 5. Apagar los servicios
```bash
bash Scripts/stop-k8s.sh
```

## 6. Probar en entorno local
- Los servicios funcionarán con los valores por defecto (`localhost`) si no se definen variables de entorno.
- Usa `compose-local.yml` para levantar los servicios localmente.

---

