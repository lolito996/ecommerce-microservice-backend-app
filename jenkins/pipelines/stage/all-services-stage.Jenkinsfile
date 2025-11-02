pipeline {
    agent any
    parameters {
        booleanParam(name: 'FORCE_ALL', defaultValue: false, description: 'Force build of all services')
    }
    tools {
        maven 'Maven-3.8.6'
    }
    environment {
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        KUBERNETES_NAMESPACE = 'ecommerce-stage'
        MAVEN_OPTS = "-Dhttps.protocols=TLSv1.2,TLSv1.3 -Dmaven.wagon.http.retryHandler.count=5 -Dmaven.wagon.http.connectionTimeout=60000 -Dmaven.wagon.http.readTimeout=600000 -Dmaven.wagon.http.pool=false"
    }
    stages {
        stage('Clean workspace') {
            steps {
                script {
                    // Ensure a clean workspace to avoid stale artifacts causing docker build failures
                    deleteDir()
                    echo 'Workspace cleaned.'
                }
            }
        }
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
                        sh 'git fetch origin --depth=1 || true'
                            // Use a literal Groovy string so ${br} is handled by the shell, not by Groovy
                            def remoteBase = sh(returnStdout: true, script: '''bash -lc 'for br in dev master main; do if git ls-remote --heads origin ${br} | grep ${br} >/dev/null 2>&1; then echo ${br}; break; fi; done' ''').trim()
                        if (remoteBase) {
                            def base = "origin/${remoteBase}"
                            echo "Using base branch ${base} for diff"
                            def changed = sh(returnStdout: true, script: "git diff --name-only ${base}...HEAD || true").trim()
                            if (changed) {
                                def dirs = changed.split('\n').collect{ it.split('/')[0] }.unique()
                                toBuild = services.findAll { s -> dirs.contains(s) }
                                echo "Changed directories from git: ${dirs} -> will build: ${toBuild}"
                            } else {
                                toBuild = services
                            }
                        } else {
                            echo 'No remote dev/master/main found, falling back to last commit diff'
                            def changed = sh(returnStdout: true, script: "git diff --name-only HEAD~1..HEAD || true").trim()
                            if (changed) {
                                def dirs = changed.split('\n').collect{ it.split('/')[0] }.unique()
                                toBuild = services.findAll { s -> dirs.contains(s) }
                                echo "Changed directories from git: ${dirs} -> will build: ${toBuild}"
                            } else {
                                echo "No changed files detected; defaulting to build all services"
                                toBuild = services
                            }
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
                                retry(3) {
                                    sh "mvn -B -e -DskipTests clean package ${MAVEN_OPTS}"
                                }
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
                            retry(3) {
                                sh "echo 'Running unit tests for ${s}'; mvn -B -e -DfailIfNoTests=false test ${MAVEN_OPTS}"
                            }
                        }
                    }
                }
            }
        }
        stage('Docker Build & Push (selected)') {
            steps {
                script {
                    // Build images using the repository root as build context so Dockerfiles that
                    // reference paths like "product-service/target/..." can find the artifacts.
                    def toBuild = env.TO_BUILD.tokenize(',') as List
                    def buildStages = [:]
                    for (s in toBuild) {
                        def svc = s
                        buildStages["docker-${svc}"] = {
                            script {
                                try {
                                    def imageName = "selimhorri/${svc}-ecommerce-boot:${DOCKER_TAG}"
                                    echo "Checking for built jar(s) under ${env.WORKSPACE}/${svc}/target/"
                                    def found = sh(returnStdout: true, script: "bash -lc 'ls ${env.WORKSPACE}/${svc}/target/*.jar 2>/dev/null || true'").trim()
                                    if (!found) {
                                        error "Artifact not found for ${svc}: looked for jars in ${env.WORKSPACE}/${svc}/target/. Ensure 'mvn package' ran successfully."
                                    }
                                    echo "Found artifact(s): ${found}"
                                    echo "Building image ${imageName} using Dockerfile ${svc}/Dockerfile and workspace as context"
                                    // Use the repo root as context and point to the service Dockerfile explicitly.
                                    def buildArgs = "-f ${svc}/Dockerfile ${env.WORKSPACE}"
                                    def image = docker.build(imageName, buildArgs)
                                    docker.withRegistry('', 'docker-hub-credentials') {
                                        image.push()
                                        echo "Pushed ${imageName}"
                                    }
                                } catch (Exception e) {
                                    error "Docker build/push failed for ${svc}: ${e.getMessage()}"
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
                    sh 'kubectl apply -f kubernetes/ --namespace ${KUBERNETES_NAMESPACE}'
                    echo 'Waiting for pods to be ready (up to 3 minutes)'
                    sh 'kubectl wait --for=condition=ready pods --all --namespace ${KUBERNETES_NAMESPACE} --timeout=180s'
                    sh 'kubectl get pods --namespace ${KUBERNETES_NAMESPACE} -o wide'
                }
            }
        }
        stage('Seed test data & Run E2E tests') {
            steps {
                script {
                    echo 'Seeding test data into Kubernetes namespace'
                    // apply seed job and wait
                    sh "${WORKSPACE}/jenkins/scripts/seed-data.sh ${KUBERNETES_NAMESPACE}"
                    // Decide TEST_BASE_URL: prefer cluster DNS if Jenkins agent inside cluster; otherwise port-forward
                    def testBase = "http://api-gateway:${8080}"
                    // Run E2E tests using Maven module e2e-tests
                    withEnv(["TEST_BASE_URL=${testBase}"]) {
                        dir('') {
                            // run only E2E tests (pattern *E2E*)
                            sh "mvn -B -pl e2e-tests -DskipTests=false -Dtest=*E2E* test"
                        }
                    }
                }
            }
        }
        stage('Integration Tests (against cluster)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            retry(3) {
                                sh "echo 'Running integration tests for ${s} against cluster'; mvn -B -e -Dtest=*IT,*IntegrationTest test ${MAVEN_OPTS}"
                            }
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
                            retry(3) {
                                sh "echo 'Running E2E tests for ${s} (if present) against cluster'; mvn -B -e -Dtest=**/*E2E* test ${MAVEN_OPTS}"
                            }
                        }
                    }
                }
            }
        }
        stage('Performance: Locust (basic)') {
            steps {
                script {
                    sh 'python3 -m pip install --user locust -q'
                    sh 'mkdir -p jenkins/locust/locust_report'
                    sh 'echo "Running Locust headless (2m, 100 users) against API-Gateway Ingress/NodePort"'
                    sh 'python3 -m locust -f jenkins/locust/locustfile.py --headless -u 100 -r 10 -t 2m --host http://api-gateway:8080 --html jenkins/locust/locust_report/report.html --csv jenkins/locust/locust_report/results'
                }
            }
        }
        stage('Publish Test Results') {
            steps {
                script {
                    echo 'Publishing test results and artifacts (stage)'
                    junit allowEmptyResults: true, testResults: '**/surefire-reports/*.xml, **/failsafe-reports/*.xml'
                    archiveArtifacts artifacts: 'jenkins/locust/locust_report/**', allowEmptyArchive: true, fingerprint: true
                    echo 'Pipeline execution completed'
                }
            }
        }
    }
    post {
        success { echo 'All services deployed successfully to stage!' }
        failure { echo 'Deployment to stage failed!' }
    }
}
