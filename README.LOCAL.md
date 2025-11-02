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

