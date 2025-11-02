Usage: service-pipeline.Jenkinsfile

This is a parameterized Jenkinsfile template for running a single-service pipeline.
Place it in a job's Pipeline script from SCM (and set job parameters / environment variables), or copy/rename for a specific service.

Variables to configure (either in the job config or by copying and editing the file):
- SERVICE_NAME: directory name of the service (e.g. 'favourite-service')
- DOCKER_IMAGE: docker repository name (e.g. 'selimhorri/favourite-service-ecommerce-boot')

Behavior
- Checkout SCM
- Build (mvn package) inside the service directory
- Run unit tests
- Verify that a JAR exists under ${WORKSPACE}/${SERVICE_NAME}/target/*.jar
- Build Docker image using the repo root as context and the service Dockerfile: `docker build -f ${SERVICE_NAME}/Dockerfile ${WORKSPACE}`
- Push image to Docker Hub using credentials id 'docker-hub-credentials'
- Clean workspace at the end (cleanWs())

Notes
- The template intentionally uses the repository root as Docker build context so it works with existing Dockerfiles that reference paths like `product-service/target/...`.
- If you prefer to always start from a clean workspace, uncomment the deleteDir() call in the 'Clean workspace (optional)' stage.
- For multi-environment pipelines (dev/stage/prod) create separate jobs that set different KUBERNETES_NAMESPACE or DOCKER_IMAGE values.
