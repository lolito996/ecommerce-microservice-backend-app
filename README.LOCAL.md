Documentación local y pipelines
=================================

Este documento centraliza cómo ejecutar y verificar el proyecto en local, los workflows disponibles (GitHub Actions), los tests E2E y recomendaciones para cumplir con los entregables del taller (dev / stage / master pipelines, pruebas unitarias/integración/E2E y performance con Locust).

Contenido rápido
- Requisitos y herramientas
- Ejecución local (Docker / Minikube)
- Workflows importantes en este repo
- Cómo ejecutar las pruebas E2E (local y workflow)
- Pruebas: unidad, integración, E2E y rendimiento (qué existe y qué falta)
- Jenkins y generación de Release Notes
- Troubleshooting y checklist para el runner self-hosted

------------------------------------------------------------------------------

Requisitos y herramientas
-------------------------

Instala en la máquina que actuará como runner (o en tu máquina local para pruebas):

- Docker Desktop (o Docker Engine)
- Minikube (cuando despliegues localmente en Kubernetes)
- kubectl
- Java 11 (JDK Temurin/AdoptOpenJDK)
- Maven (o usa `./mvnw` incluido)
- PowerShell 7 (`pwsh`) si vas a ejecutar workflows que usen `shell: pwsh`.
- (Opcional) Jenkins si deseas correr pipelines externos.

Verifica con:

```powershell
docker --version
minikube version
kubectl version --client
pwsh --version
mvn -v
```

------------------------------------------------------------------------------

Estructura relevante del repositorio
------------------------------------

- `kubernetes/` — manifiestos por servicio (Deployments / Services / Jobs). Contiene los YAML individuales y scripts de inicio.
- `e2e-tests/` — proyecto Maven con pruebas E2E (RestAssured / JUnit 5). Los tests actuales incluyen flujos completos en `E2EFlowsTest.java`.
- `.github/workflows/` — contiene workflows GitHub Actions (deploy-minikube.yml, e2e-minikube.yml, etc.).
- `load-images-minikube.bat` — script para cargar imágenes locales al daemon de Minikube.

------------------------------------------------------------------------------

Workflows GitHub Actions relevantes
----------------------------------

- `.github/workflows/deploy-minikube.yml` — flujo principal que:
  - verifica Minikube en un runner self-hosted
  - construye imágenes (docker compose)
  - carga imágenes en Minikube (`load-images-minikube.bat`)
  - aplica manifiestos desde `./kubernetes`
  - espera el rollout de los deployments

- `.github/workflows/e2e-minikube.yml` — (nuevo) despliega en Minikube y ejecuta las pruebas E2E que están en `e2e-tests/`. Archiva los reports JUnit como artefactos.

Cómo ejecutar el E2E workflow manualmente (desde la UI):

1. Ve a Actions → `E2E Tests on Minikube` → *Run workflow*.
2. Selecciona la rama `pipelines` (o `main`) y lanza.

O ejecutar por push si está configurado para `push` en `pipelines`, `main` o `master`.

------------------------------------------------------------------------------

Ejecutar E2E localmente (sin workflow)
--------------------------------------

Prerequisitos: Minikube corriendo y las imágenes cargadas.

1. Inicia Minikube (si no está iniciado):

```powershell
minikube start
minikube status
```

2. Carga las imágenes (si no lo hiciste):

```powershell
.\load-images-minikube.bat
minikube image ls
```

3. Asegura namespace (si aplicable):

```powershell
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -
```

4. Aplica los manifests:

```powershell
kubectl apply -f kubernetes
kubectl get pods -n ecommerce -o wide
```

5. Ejecuta las pruebas E2E (desde la raíz del repo):

```powershell
mvn -f e2e-tests test
```

Los tests usan la variable de entorno `TEST_BASE_URL` si quieres apuntar a un host distinto a `http://localhost:8080`.

------------------------------------------------------------------------------

Qué pruebas hay hoy en el repo
------------------------------

- E2E: en `e2e-tests/src/test/java/com/selimhorri/app/e2e/E2EFlowsTest.java` y `ApiGatewayE2E.java`.
  - Ejemplos: crear usuario/producto, crear orden, favoritos y consultas cross-service (usa RestAssured y fixtures en `src/test/resources/fixtures`).

- Unit y Integration: revisar cada microservicio bajo `*/src/test/java`. Si no existen suficientes tests unitarios o de integración, ver la sección "Qué falta implementar" abajo.

------------------------------------------------------------------------------

Pruebas de rendimiento (Locust)
------------------------------

No hay scripts de Locust en el repo por defecto. Para añadirlas:

1. Crear carpeta `performance/locust` y fichero `locustfile.py` con escenarios de usuario (por ejemplo: login, búsqueda de productos, agregar al carrito, checkout).

2. Ejecutar en local apuntando al API Gateway:

```powershell
# instalar locust (en un virtualenv o en el runner)
python -m pip install locust
locust -f performance/locust/locustfile.py --host=http://localhost:30080
```

3. En CI (stage), puedes arrancar un job que despliegue en Minikube y ejecute Locust en modo no‑interactivo (headless) para generar métricas:

```bash
locust -f performance/locust/locustfile.py --headless -u 200 -r 10 -t 5m --host=http://api-gateway:8080
```

Analiza tiempos de respuesta, throughput y errores desde los reports/CSV generados por Locust.

------------------------------------------------------------------------------

Generación automática de Release Notes
-------------------------------------

Recomendación simple usando GitHub Actions:

- Usa `release-drafter/release-drafter` o `actions/create-release` con `conventional-commits` para generar notas automáticas cuando merges a `master/main`.
- Ejemplo de idea:
  - Al hacer un merge a `main` crea un Draft Release con el CHANGELOG generado por los commits desde la última release.
  - Publica la release desde la UI cuando quieras hacer el despliegue a `master environment`.

Puedo añadir un workflow `release-drafter.yml` que asista en esto.

------------------------------------------------------------------------------

Jenkins (opcional)
-------------------

Si quieres usar Jenkins en vez de GitHub Actions, en la raíz hay un `Jenkinsfile` de ejemplo que realiza build + test + archive. Intégralo en un Job Pipeline en Jenkins apuntando a la rama `pipelines`.

------------------------------------------------------------------------------

Troubleshooting común para el runner self-hosted
-----------------------------------------------

- Error `pwsh: command not found`: instala PowerShell 7 y reinicia el runner (o adapta `shell: powershell` en el workflow si es temporal).
- `Waiting for a runner to pick up this job...`: asegúrate el Runner Listener está corriendo (`.\run.cmd`) o que el servicio de Windows del runner esté Online y con etiqueta `self-hosted`.
- Errores `ImagePullBackOff`: comprueba `minikube image ls` y que el tag de imagen en el manifest coincide exactamente.
- `kubectl` permisos: ejecuta `kubectl get nodes` y `kubectl get pods -A` desde la cuenta del runner para validar kubeconfig.

------------------------------------------------------------------------------

Qué falta implementar para cumplir el enunciado del taller
---------------------------------------------------------

El enunciado pide (resumen con porcentajes):

- 5 pruebas unitarias nuevas (por lo menos). Actualmente el repositorio contiene principalmente pruebas E2E — hay que añadir tests unitarios en cada microservicio (por ejemplo `user-service/src/test/java`, `product-service/src/test/java`).
- 5 pruebas de integración (usar @SpringBootTest con H2 para validar integración entre capas).
- 5 pruebas E2E (ya existen algunas; revisa que tengas al menos 5 flujos E2E independientes; si no, añadir más en `e2e-tests`).
- Pruebas de rendimiento con Locust (añadir `performance/locust`).

Propuesta práctica para completar los requisitos rápidamente:

1. Añadir 5 pruebas unitarias: por ejemplo en `user-service` y `product-service` usando JUnit5 + Mockito. Casos sugeridos: validación de entrada, servicio que calcula precio, repositorio mockeado.
2. Añadir 5 pruebas de integración: usar `@SpringBootTest` con profile `test` y H2 embebida para validar endpoints y repositorios.
3. Completar al menos 5 pruebas E2E en `e2e-tests` (ej: checkout, búsqueda por categoría, actualización de perfil, cancelación de orden, flujo de favoritos).
4. Implementar Locust scripts y añadir job en CI que los ejecute en stage.

Si quieres, puedo generar automáticamente 5 tests unitarios de ejemplo y 5 integration tests en `user-service` y `product-service` — dime si quieres que lo haga.

------------------------------------------------------------------------------

Cómo ejecutar el workflow E2E desde la línea de comandos (gh cli)
---------------------------------------------------------------

Si tienes `gh` instalado y autenticado:

```powershell
# lanzar manualmente el workflow_dispatch
gh workflow run e2e-minikube.yml --ref pipelines
```

------------------------------------------------------------------------------

Checklist final antes de entregar
---------------------------------

1. Verificar que los pipelines (dev/stage/master) están en la rama `pipelines` y pasan en el runner.
2. Confirmar que existen al menos 5 unit tests, 5 integration tests y 5 E2E tests; si no, añadirlos.
3. Añadir Locust scripts y un job que los ejecute en stage; recoger métricas.
4. Configurar el workflow de Release Notes (release-drafter o actions/create-release).
5. Documentar pantallazos y resultados en el documento final. Puedes usar `actions/upload-artifact` para recoger reportes y `gh` para crear releases.

------------------------------------------------------------------------------

Próximos pasos que puedo implementar por ti (elige una):

- (A) Crear `kubernetes/k8s-all-in-one.yaml` unificado (con `imagePullPolicy: IfNotPresent`) y actualizar workflow para usarlo.
- (B) Añadir un workflow `release-drafter.yml` para generar Release Notes automáticas.
- (C) Añadir ejemplo de 5 tests unitarios en `user-service` (mocked) y 5 integration tests.

Indica la opción o dime qué prefieres que implemente primero y lo hago.

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

