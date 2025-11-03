Desarrollo local y pipelines (rápido)

He añadido archivos y scripts para poder ejecutar el stack en local construyendo las imágenes desde el código fuente del repo.

- `docker-compose.local.yml` : versión para desarrollo que usa `build:` por servicio y crea una red `microservices_network` local.
- `scripts\create-docker-network.ps1` : crea la red Docker si no existe.
- `scripts\build-and-up.ps1` : compila el proyecto con `mvnw` y levanta `docker-compose.local.yml` con `--build`.

Pasos rápidos (Windows PowerShell):

```powershell
# crear red (opcional)
\.\scripts\create-docker-network.ps1

# compilar y levantar (usa mvnw si está presente)
\.\scripts\build-and-up.ps1
```

Notas y consideraciones:
- El `docker-compose.local.yml` construye las imágenes desde cada submódulo (ej. `./api-gateway`, `./user-service`, etc.). Asegúrate de tener Docker Desktop instalado y en ejecución.
- El `build-and-up` usa `-DskipTests` para acelerar la puesta en marcha; quita esa opción si quieres ejecutar tests.
- El compose original del repo referencia imágenes publicadas (usuario `selimhorri/...`) — la versión `local` evita esa dependencia y permite desarrollo sin acceso a esas imágenes.
- Si quieres, puedo:
  - Ajustar `docker-compose.local.yml` para incluir Zipkin/DB/Redis si lo necesitas.
  - Añadir un `Jenkinsfile` de ejemplo en la raíz que haga `mvn package` y `docker build`/`docker-compose` para integrarlo con tu Jenkins local.

Jenkins (simple) — `Jenkinsfile` añadido
------------------------------------

He añadido un `Jenkinsfile` simple en la raíz (`Jenkinsfile`) que realiza:

- `mvn package` (usa `./mvnw` o `mvn` según el agente).
- Ejecuta la suite de tests y publica resultados JUnit.
- Archiva los artefactos tipo `.jar` encontrados en `**/target/`.

Crear job de Jenkins (ejemplo usando el script provisto)

1. Ajusta los parámetros en `jenkins/scripts/create-job-xml.ps1` o usa el script desde PowerShell:

```powershell
$tempXml = "$PWD\temp-job.xml"
.\jenkins\scripts\create-job-xml.ps1 -TempXml $tempXml -ScriptPath 'Jenkinsfile' -RepoUrl 'https://tu-repo.git' -Branch 'pipelines' -JobDesc 'Build simple'

# luego importa $tempXml en Jenkins (o usa la API)
```

2. En Jenkins, crea un nuevo job de tipo Pipeline desde SCM apuntando al `Jenkinsfile` en la rama `pipelines`.



Local Deploy (GitHub Actions) — Minikube
--------------------------------------

He añadido un workflow de GitHub Actions llamado `Local Deploy to Minikube` en `.github/workflows/local-deploy-minikube.yml` y un script de carga de imágenes `load-images-minikube.bat` en la raíz.

Resumen rápido:
- Workflow: se dispara en push a `main` o `master` (puedes cambiar la rama si prefieres `pipelines`).
- Requisitos del runner: debe ser `self-hosted` y tener Docker, Minikube y kubectl disponibles. El workflow usa PowerShell (shell: pwsh).
- Qué hace:
  - Comprueba si ya hay pods en el namespace `ecommerce-microservices`; si todos están `Running` omite el despliegue.
  - Si hace falta, construye las imágenes usando `docker compose -f compose.yml build`.
  - Ejecuta `load-images-minikube.bat` para cargar las imágenes en Minikube.
  - Aplica el manifiesto Kubernetes definido en `k8s-optimized.yaml` y espera el rollout de los deployments.

Cómo usarlo localmente:
1. Asegúrate de tener un runner self-hosted registrado en GitHub con Docker, kubectl y Minikube.
2. Inicia Minikube y verifica que funciona:

```powershell
minikube start
minikube status
```

3. Empuja (push) a `main` o `master` para que se ejecute el workflow, o ejecútalo manualmente desde la UI de Actions si prefieres.

Notas adicionales:
- La ruta del manifiesto por defecto es `./k8s-optimized.yaml`. Cámbiala en el workflow si usas otro fichero (por ejemplo `kubernetes/k8s-all-in-one.yaml`).
- El script `load-images-minikube.bat` contiene cargas para las imágenes presentes en este proyecto; si cambias tags o nombres de imagen actualiza el script.
- Si quieres, puedo:
  - Añadir `workflow_dispatch` (ejecución manual) y variables de entrada al workflow.
  - Crear un workflow para CI que ejecute tests por servicio (dev) y otro para stage que ejecute las pruebas E2E/Locust dentro de Kubernetes.

