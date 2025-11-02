## Jenkins local (Docker Desktop) — cómo ejecutar y descripción de pipelines

Este documento detalla el orden de ejecución recomendado para levantar el Jenkins local incluido en este repositorio, cómo validar que Jenkins pueda ejecutar Docker dentro del contenedor, y una descripción de los pipelines `all-services-dev` y `all-services-stage`.

IMPORTANTE: estas instrucciones asumen Docker Desktop en Windows y PowerShell como shell.

Requisitos previos
- Docker Desktop (running)
- PowerShell (Windows) o una terminal compatible
- (Opcional) kubectl configurado para usar Docker Desktop Kubernetes si quieres ejecutar la pipeline `stage` que aplica manifiestos k8s

Orden de ejecución (plan recomendado)
1) (Solo si hiciste cambios en la imagen/entrypoint) Reconstruir imagen de Jenkins

   Abre PowerShell en la carpeta raíz del repo y ejecuta:
```powershell
docker-compose -f jenkins\scripts\docker-compose.yml build jenkins
```

   Esto asegura que cualquier cambio en `jenkins/DockerFile` o `jenkins/jenkins-entrypoint.sh` se empaquete.

2) Iniciar Jenkins

   Usa el script que ya existe (usa PowerShell desde `jenkins\`):
```powershell
cd jenkins
.\start-jenkins.cmd
```

   Qué hace: levanta el stack con `docker-compose up -d` y espera ~30s. Si detectas que la imagen no se actualizó, vuelve al paso 1.

3) Instalar plugins y crear jobs (setup)

   Ejecuta el script que descarga `jenkins-cli.jar`, instala plugins y crea los jobs centralizados:
```powershell
.\setup-jenkins.cmd
```

   Notas:
- `setup-jenkins.cmd` usa `http://localhost:8081/jnlpJars/jenkins-cli.jar` y credenciales `admin:admin123` (por defecto en estos scripts). Si cambias credenciales, actualiza los scripts.
- Algunos plugins requieren una versión más reciente de Jenkins; si ves errores en logs (plugins failed), considera actualizar la imagen base de Jenkins.

4) Validar que Jenkins puede usar Docker

   Crea un Pipeline very-simple (o usa la UI) que ejecute:
```groovy
pipeline { agent any; stages { stage('Check Docker') { steps { sh 'docker --version; docker ps -a' } } } }
```

   Alternativa: desde la máquina host puedes inspeccionar en el contenedor:
```powershell
docker exec jenkins sh -c 'docker --version; docker ps -a'
```

   Si `docker ps` falla por permisos, recordá que el entrypoint `jenkins/jenkins-entrypoint.sh` gestiona el ajuste de GID/permiso del socket. En entornos Docker Desktop el socket puede aparecer con GID=0 y el entrypoint hará chmod 666 (solución de desarrollo). Para producción evita chmod 666.

5) Ejecutar pipelines

   Jobs creados por `setup-jenkins.cmd`:
- `all-services-dev` (ruta Jenkinsfile: `jenkins/pipelines/dev/all-services-dev.Jenkinsfile`)
- `all-services-stage` (ruta Jenkinsfile: `jenkins/pipelines/stage/all-services-stage.Jenkinsfile`)

   Ejecuta el job `all-services-dev` para probar todo el flujo dev (build, tests, docker build/push y docker-compose deploy). Si pasa, ejecuta `all-services-stage` para desplegar a Kubernetes y correr las pruebas contra el cluster y realizar la prueba de carga básica con Locust.

Descripción breve de los pipelines

- all-services-dev.Jenkinsfile (pipeline de desarrollo)
  - Checkout
  - Detectar servicios cambiados (compara contra `dev/master/main` o hace fallback a `HEAD~1..HEAD`) o construye todo si `FORCE_ALL=true`.
  - Build (mvn package) en paralelo por servicio seleccionado
  - Unit tests por servicio
  - Docker build & push (usa credencial `docker-hub-credentials`) por servicio
  - Deploy a dev usando `docker-compose -f compose.yml up -d`
  - Integration tests y E2E tests (si existen)

- all-services-stage.Jenkinsfile (pipeline de stage)
  - Igual detección/build/tests que `dev`
  - Docker build & push
  - Deploy a Kubernetes: `kubectl apply -f kubernetes/ --namespace ecommerce-stage` y `kubectl wait` para pods ready
  - Integration/E2E tests apuntando al cluster
  - Performance: ejecuta Locust headless (archivo `jenkins/locust/locustfile.py`) con una prueba básica; ajustar host/usuarios/tiempo según sea necesario

Consideraciones y troubleshooting
- Permisos Docker: el entrypoint gestiona permisos. Si previamente aplicaste `chmod 666` manual en el socket y quieres revertirlo, reinicia Docker Desktop (recomendado) o ejecuta desde PowerShell:
```powershell
docker exec jenkins sh -c "chown root:docker /var/run/docker.sock || true; chmod 660 /var/run/docker.sock || true; ls -l /var/run/docker.sock"
```

- Conflictos de puerto: si `docker-compose up` falla por puerto ocupado, identifica el proceso/servicio que usa ese puerto y deténlo, o modifica el mapeo en `compose.yml` correspondiente.
- Plugins: si ves errores "Failed Loading plugin ... Jenkins (2.xxx) or higher required", actualiza la imagen base de Jenkins o instala versiones de plugin compatibles.
- Git base branch: los Jenkinsfiles intentan detectar `dev/master/main`. Si tu repo usa otro nombre, ajusta la lógica o usa `FORCE_ALL=true` para forzar la build completa.

Buenas prácticas y seguridad
- En entornos compartidos/producción no uses `chmod 666` en el socket. En vez de eso, configura en el host `root:docker` con GID no 0 y deja que el entrypoint alinee el GID dentro del contenedor.
- Mantén actualizado el `jenkins/jenkins-entrypoint.sh` y reconstruye la imagen cuando hagas cambios. Usa `docker-compose -f jenkins/docker-compose.yml build jenkins` seguido de `down && up -d`.

Cambios automáticos propuestos (opcional)
- Puedes modificar `jenkins/start-jenkins.cmd` para que incluya un `docker-compose build jenkins` previo a `docker-compose up -d` si prefieres que siempre se reconstruya la imagen localmente.

Soporte y siguientes pasos
- Si querés, puedo:
  - añadir la opción de rebuild automático en `start-jenkins.cmd` y commitearla,
  - crear un job Pipeline minimal para validar Docker desde la UI, o
  - ayudarte a actualizar Jenkins/plugins si preferís evitar errores de compatibilidad.

-- Fin --

Crear jobs sin GitHub (modo offline / local)
------------------------------------------

Si prefieres crear los jobs en tu Jenkins local sin usar GitHub (por ejemplo para desarrollo con la copia local del repo), hay dos maneras:

- Opción A (rápida): usar `create-jobs-inline.cmd` que está en `jenkins/scripts`. Este script escanea `jenkins/pipelines` en el repo y crea jobs en Jenkins con el contenido de cada `*.Jenkinsfile` embebido directamente en la configuración del job (no necesita que Jenkins clone ningún repositorio).

   Pasos:

   1. Arrancar Jenkins (ver sección arriba). Asegúrate que Jenkins esté accesible en `http://localhost:8081` y que las credenciales en `jenkins/scripts/create-jobs-inline.cmd` (por defecto `admin:admin123`) sean correctas.
   2. Abrir PowerShell en `jenkins\scripts` y ejecutar:

```powershell
cd jenkins\scripts
.\create-jobs-inline.cmd
```

   3. El script descargará `jenkins-cli.jar` si es necesario y creará jobs nombrados según la ruta relativa del Jenkinsfile (por ejemplo `dev-all-services-dev` o `service-favourite-service-dev`).

- Opción B (manual): desde la UI de Jenkins crear un nuevo Pipeline job y pegar manualmente el contenido del `Jenkinsfile` (abrir el archivo en `jenkins/pipelines/...` y copiar/pegar en la sección "Pipeline script").

Notas:
- Los jobs creados inline son independientes del repositorio. Si luego actualizas los Jenkinsfiles locales, deberás volver a ejecutar `create-jobs-inline.cmd` o actualizar los jobs manualmente.
- Los scripts en `jenkins/scripts` incluyen también `create-job-xml.ps1` y `create-jobs.cmd` que crean jobs configurados para clonar el repo desde GitHub; mantienen compatibilidad si quieres volver a crear jobs apuntando a SCM remoto.

