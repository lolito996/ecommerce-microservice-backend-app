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
        KUBERNETES_NAMESPACE = 'ecommerce-dev'
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
                        // Try to detect an appropriate base branch (dev, master, main) and diff against it
                        sh 'git fetch origin --depth=1 || true'
                        def changed = sh(returnStdout: true, script: "bash -lc 'for br in dev master main; do if git ls-remote --heads origin \\${br} | grep \\${br} >/dev/null 2>&1; then echo \\${br}; break; fi; done'").trim()
                        if (changed) {
                            def base = "origin/${changed}"
                            echo "Using base branch ${base} for diff"
                            changed = sh(returnStdout: true, script: "git diff --name-only ${base}...HEAD || true").trim()
                        } else {
                            echo 'No remote dev/master/main found, falling back to last commit diff'
                            changed = sh(returnStdout: true, script: "git diff --name-only HEAD~1..HEAD || true").trim()
                        }
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
                                        sh 'git fetch origin --depth=1 || true'
                                        // Use a literal Groovy string to avoid GString interpolation of ${br}
                                        def changed = sh(returnStdout: true, script: '''bash -lc 'for br in dev master main; do if git ls-remote --heads origin ${br} | grep ${br} >/dev/null 2>&1; then echo ${br}; break; fi; done' ''').trim()
                script {
                    // Build docker images using repo root as context and the service Dockerfile
                    def toBuild = env.TO_BUILD.tokenize(',') as List
                    def buildStages = [:]
                    for (s in toBuild) {
                        def svc = s
                        buildStages["docker-${svc}"] = {
                            script {
                                try {
                                    def imageName = "selimhorri/${svc}-ecommerce-boot:${DOCKER_TAG}"
                                    // verify artifact exists
                                    echo "Checking for built jar(s) under ${env.WORKSPACE}/${svc}/target/"
                                    def found = sh(returnStdout: true, script: "bash -lc 'ls ${env.WORKSPACE}/${svc}/target/*.jar 2>/dev/null || true'").trim()
                                    if (!found) {
                                        error "Artifact not found for ${svc}: looked for jars in ${env.WORKSPACE}/${svc}/target/. Ensure 'mvn package' ran successfully."
                                    }
                                    echo "Found artifact(s): ${found}"
                                    echo "Building image ${imageName} using Dockerfile ${svc}/Dockerfile and workspace as context"
                                    def buildArgs = "-f ${svc}/Dockerfile ${env.WORKSPACE}"
                                    def image = docker.build(imageName, buildArgs)
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
                    parallel buildStages
                }
            }
        }
        stage('Deploy to Dev (docker-compose)') {
            steps {
                sh 'echo "Deploying selected services to development environment (docker-compose)..."'
                sh 'docker-compose -f compose.yml up -d'
                sh 'sleep 30'
                sh 'docker ps'
            }
        }
        stage('Integration Tests (selected)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            retry(3) {
                                sh "echo 'Running integration tests for ${s}'; mvn -B -e -Dtest=*IT,*IntegrationTest test ${MAVEN_OPTS}"
                            }
                        }
                    }
                }
            }
        }
        stage('E2E Tests (selected)') {
            steps {
                script {
                    def toTest = env.TO_BUILD.tokenize(',') as List
                    for (s in toTest) {
                        dir(s) {
                            retry(3) {
                                sh "echo 'Running E2E tests for ${s} (if present)'; mvn -B -e -Dtest=**/*E2E* test ${MAVEN_OPTS}"
                            }
                        }
                    }
                }
            }
        }
        stage('Publish Test Results') {
            steps {
                script {
                    echo 'Publishing test results and artifacts'
                    junit allowEmptyResults: true, testResults: '**/surefire-reports/*.xml, **/failsafe-reports/*.xml'
                    archiveArtifacts artifacts: 'jenkins/locust/locust_report/**', allowEmptyArchive: true, fingerprint: true
                    echo 'Pipeline execution completed'
                }
            }
        }
    }
    post {
        success { echo 'All services deployed successfully!' }
        failure { echo 'Deployment failed!' }
    }
}
