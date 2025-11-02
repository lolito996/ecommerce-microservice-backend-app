pipeline {
    agent any

    // Configure these when creating the job: SERVICE_NAME and DOCKER_IMAGE
    environment {
        SERVICE_NAME = env.SERVICE_NAME ?: 'favourite-service'
        DOCKER_IMAGE = env.DOCKER_IMAGE ?: "selimhorri/${env.SERVICE_NAME ?: 'favourite-service'}-ecommerce-boot"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        MAVEN_OPTS = "-Dhttps.protocols=TLSv1.2,TLSv1.3 -Dmaven.wagon.http.retryHandler.count=5"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Clean workspace (optional)') {
            steps {
                script {
                    // Optional: if you want to guarantee a clean workspace, you can uncomment this line
                    // deleteDir()
                    echo "Workspace preserved. To force clean, enable deleteDir() here."
                }
            }
        }

        stage('Build') {
            steps {
                dir("${SERVICE_NAME}") {
                    retry(3) {
                        sh "mvn -B -e -DskipTests clean package ${MAVEN_OPTS}"
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir("${SERVICE_NAME}") {
                    sh "mvn -B -e -DfailIfNoTests=false test ${MAVEN_OPTS}"
                }
            }
            post { always { echo "Unit tests stage finished for ${SERVICE_NAME}" } }
        }

        stage('Docker Build') {
            steps {
                script {
                    def svc = SERVICE_NAME
                    def imageName = "${DOCKER_IMAGE}:${DOCKER_TAG}"

                    // Verify artifact(s) exist under repo-root/service/target/*.jar
                    echo "Checking for built jar(s) under ${env.WORKSPACE}/${svc}/target/"
                    def found = sh(returnStdout: true, script: "bash -lc 'ls ${env.WORKSPACE}/${svc}/target/*.jar 2>/dev/null || true'").trim()
                    if (!found) {
                        error "Artifact not found for ${svc}: looked for jars in ${env.WORKSPACE}/${svc}/target/. Ensure 'mvn package' ran successfully."
                    }
                    echo "Found artifact(s): ${found}"

                    // Build using the service folder as context so Dockerfile COPY target/... resolves
                    echo "Building image ${imageName} using -f ${svc}/Dockerfile ${env.WORKSPACE}/${svc}"
                    def buildArgs = "-f ${svc}/Dockerfile ${env.WORKSPACE}/${svc}"
                    def image = docker.build(imageName, buildArgs)
                    docker.withRegistry('', 'docker-hub-credentials') {
                        image.push()
                        echo "Pushed ${imageName}"
                    }
                }
            }
        }

        stage('Deploy (optional)') {
            steps {
                echo "Deployment steps are environment-specific. Configure this stage as needed."
            }
        }
    }

    post {
        always {
            // clean workspace to save disk on agent
            cleanWs()
            echo "Job finished for ${SERVICE_NAME}"
        }
        success { echo "Pipeline success: ${SERVICE_NAME}" }
        failure { echo "Pipeline failed: ${SERVICE_NAME}" }
    }
}
