pipeline {
    agent any
    environment {
        DOCKER_REGISTRY = 'alejomunoz'
        KUBERNETES_NAMESPACE = 'ecommerce-microservices'
        MAVEN_OPTS = '-Xmx1024m'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build All Services') {
            parallel {
                stage('Build User Service') {
                    steps {
                        dir('user-service') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Product Service') {
                    steps {
                        dir('product-service') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Order Service') {
                    steps {
                        dir('order-service') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Payment Service') {
                    steps {
                        dir('payment-service') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Favourite Service') {
                    steps {
                        dir('favourite-service') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Proxy Client') {
                    steps {
                        dir('proxy-client') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Cloud Config') {
                    steps {
                        dir('cloud-config') {
                            bat 'mvn clean package'
                        }
                    }
                }
                stage('Build Service Discovery') {
                    steps {
                        dir('service-discovery') {
                            bat 'mvn clean package'
                        }
                    }
                }
            }
        }
        stage('Test All Services') {
            parallel {
                stage('Test User Service') {
                    steps {
                        dir('user-service') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Product Service') {
                    steps {
                        dir('product-service') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Order Service') {
                    steps {
                        dir('order-service') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Payment Service') {
                    steps {
                        dir('payment-service') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Favourite Service') {
                    steps {
                        dir('favourite-service') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Proxy Client') {
                    steps {
                        dir('proxy-client') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Cloud Config') {
                    steps {
                        dir('cloud-config') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Test Service Discovery') {
                    steps {
                        dir('service-discovery') {
                            sh 'mvn test'
                        }
                    }
                    post {
                        always {
                            junit '**/target/surefire-reports/*.xml'
                        }
                    }
                }
            }
        }
        stage('Docker Build All Services') {
            parallel {
                stage('Build User Service Image') {
                    steps {
                        dir('user-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/user-service-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Product Service Image') {
                    steps {
                        dir('product-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/product-service-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Order Service Image') {
                    steps {
                        dir('order-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/order-service-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Payment Service Image') {
                    steps {
                        dir('payment-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/payment-service-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Favourite Service Image') {
                    steps {
                        dir('favourite-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/favourite-service-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Proxy Client Image') {
                    steps {
                        dir('proxy-client') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/proxy-client-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Cloud Config Image') {
                    steps {
                        dir('cloud-config') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/cloud-config-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Build Service Discovery Image') {
                    steps {
                        dir('service-discovery') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/service-discovery-ecommerce-boot:${DOCKER_TAG}")
                                docker.withRegistry('', 'docker-hub-credentials') {
                                    image.push()
                                    image.push('latest')
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Deploy to Dev Environment') {
            steps {
                sh 'echo "Deploying all services to development environment"'
                sh 'docker-compose -f compose.yml up -d'
            }
        }
        stage('Deploy to Kubernetes Stage') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig-stage']) {
                    sh 'kubectl apply -f kubernetes/'
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo 'All services deployed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
