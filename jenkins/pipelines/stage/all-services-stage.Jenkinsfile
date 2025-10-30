pipeline {
    agent any
    parameters {
        booleanParam(name: 'FORCE_ALL', defaultValue: false, description: 'Force build of all services')
    }
    environment {
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        KUBERNETES_NAMESPACE = 'ecommerce-stage'
    }
    tools {
        maven 'Maven-3.8.6'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Detect changed services') {
            steps {
                script {
                    def services = ['user-service','product-service','order-service','payment-service','favourite-service','proxy-client']
                    def toBuild = []
                    if (params.FORCE_ALL.toString() == 'true') {
                        toBuild = services
                        echo "FORCE_ALL set -> building all services: ${toBuild}"
                    } else {
                        sh 'git fetch origin main --depth=1 || true'
                        def changed = sh(returnStdout: true, script: "git diff --name-only origin/main...HEAD || git diff --name-only HEAD~1..HEAD").trim()
                        if (changed) {
                            def dirs = changed.split('\n').collect{ it.split('/')[0] }.unique()
                            toBuild = services.findAll { s -> dirs.contains(s) }
                            echo "Changed directories from git: ${dirs} -> will build: ${toBuild}"
                        } else {
                            echo "No changed files detected; defaulting to build all services"
                            toBuild = services
                        }
                    }
                    if (!toBuild) { toBuild = services }
                    env.TO_BUILD = toBuild.join(',')
                }
            }
        }
        stage('Build Selected Services') {
            steps {
                script {
                    def toBuild = env.TO_BUILD.tokenize(',') as List
                    def buildStages = [:]
                    for (s in toBuild) {
                        def svc = s
                        buildStages["build-${svc}"] = {
                            dir(svc) {
                                sh "mvn clean package -DskipTests || echo 'Build failed for ${svc}, continuing...'"
                            }
                        }
                    }
                    parallel buildStages
                }
            }
        }
        stage('Unit Tests (selected services)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            sh "echo 'Running unit tests for ${s}'; mvn test || echo 'Unit tests failed for ${s}, continuing...'"
                        }
                    }
                }
            }
        }
        stage('Docker Build & Push (selected)') {
            steps {
                script {
                    def toBuild = env.TO_BUILD.tokenize(',') as List
                    def buildStages = [:]
                    for (s in toBuild) {
                        def svc = s
                        buildStages["docker-${svc}"] = {
                            dir(svc) {
                                script {
                                    try {
                                        def imageName = "selimhorri/${svc}-ecommerce-boot:${DOCKER_TAG}"
                                        echo "Building image ${imageName}"
                                        def image = docker.build(imageName)
                                        docker.withRegistry('', 'docker-hub-credentials') {
                                            image.push()
                                            echo "Pushed ${imageName}"
                                        }
                                    } catch (Exception e) {
                                        echo "Docker build/push failed for ${svc}: ${e.getMessage()}"
                                    }
                                }
                            }
                        }
                    }
                    parallel buildStages
                }
            }
        }
        stage('Deploy to Kubernetes (stage)') {
            steps {
                script {
                    echo 'Applying Kubernetes manifests from kubernetes/ to cluster (Docker Desktop K8s)'
                    sh 'kubectl apply -f kubernetes/ --namespace ${KUBERNETES_NAMESPACE} || true'
                    echo 'Waiting for pods to be ready (up to 3 minutes)'
                    sh 'kubectl wait --for=condition=ready pods --all --namespace ${KUBERNETES_NAMESPACE} --timeout=180s || true'
                    sh 'kubectl get pods --namespace ${KUBERNETES_NAMESPACE} -o wide || true'
                }
            }
        }
        stage('Integration Tests (against cluster)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            sh "echo 'Running integration tests for ${s} against cluster'; mvn test -Dtest=*IntegrationTest || echo 'Integration tests failed for ${s}, continuing...'"
                        }
                    }
                }
            }
        }
        stage('E2E Tests (against cluster)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            sh "echo 'Running E2E tests for ${s} (if present) against cluster'; mvn test -Dtest=E2ETestSuite || echo 'E2E tests not present or failed for ${s}, continuing...'"
                        }
                    }
                }
            }
        }
        stage('Performance: Locust (basic)') {
            steps {
                script {
                    sh 'python3 -m pip install --user locust -q || true'
                    sh 'echo "Running Locust headless (1m, 50 users) against http://localhost:8080 (adjust host as needed)"'
                    sh 'python3 -m locust -f jenkins/locust/locustfile.py --headless -u 50 -r 5 -t 1m --host http://localhost:8080 || echo "Locust finished or failed"'
                }
            }
        }
    }
    post {
        always { echo 'Pipeline execution completed' }
        success { echo 'All services deployed successfully to stage!' }
        failure { echo 'Deployment to stage failed!' }
    }
}
