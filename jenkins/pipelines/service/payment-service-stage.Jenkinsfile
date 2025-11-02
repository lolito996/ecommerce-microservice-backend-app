pipeline {
  agent any
  environment {
    SERVICE_NAME = 'payment-service'
    DOCKER_IMAGE = 'selimhorri/payment-service-ecommerce-boot'
    DOCKER_TAG = "${env.BUILD_NUMBER}"
    KUBERNETES_NAMESPACE = 'ecommerce-stage'
    MAVEN_OPTS = "-Dhttps.protocols=TLSv1.2,TLSv1.3"
  }

  stages {
    stage('Clean workspace') { steps { script { deleteDir(); echo 'Workspace cleaned.' } } }
    stage('Checkout') { steps { checkout scm } }
    stage('Build') { steps { dir("${SERVICE_NAME}") { sh "mvn -B -e -DskipTests clean package ${MAVEN_OPTS}" } } }
    stage('Unit Tests') { steps { dir("${SERVICE_NAME}") { sh "mvn -B -e -DfailIfNoTests=false test ${MAVEN_OPTS}" } } }
    stage('Docker Build & Push') {
      steps {
        script {
          def svc = SERVICE_NAME
          def imageName = "${DOCKER_IMAGE}:${DOCKER_TAG}"
          echo "Checking for built jar(s) under ${env.WORKSPACE}/${svc}/target/"
          def found = sh(returnStdout: true, script: "bash -lc 'ls ${env.WORKSPACE}/${svc}/target/*.jar 2>/dev/null || true'").trim()
          if (!found) { error "Artifact not found for ${svc}: looked for jars in ${env.WORKSPACE}/${svc}/target/. Ensure 'mvn package' ran successfully." }
          echo "Found artifact(s): ${found}"
          echo "Building image ${imageName} using -f ${svc}/Dockerfile ${env.WORKSPACE}"
          def buildArgs = "-f ${svc}/Dockerfile ${env.WORKSPACE}"
          def image = docker.build(imageName, buildArgs)
          docker.withRegistry('', 'docker-hub-credentials') { image.push(); echo "Pushed ${imageName}" }
        }
      }
    }
    stage('Deploy to Kubernetes Stage') {
      steps {
        script {
          sh "kubectl create namespace ${KUBERNETES_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
          sh "kubectl set image deployment/${SERVICE_NAME} ${SERVICE_NAME}=${DOCKER_IMAGE}:${DOCKER_TAG} -n ${KUBERNETES_NAMESPACE} || true"
          sh "kubectl rollout status deployment/${SERVICE_NAME} -n ${KUBERNETES_NAMESPACE} || true"
        }
      }
    }
  }

  post { always { cleanWs(); echo "Finished ${SERVICE_NAME}" } }
}
