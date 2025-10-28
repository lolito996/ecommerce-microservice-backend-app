pipeline {
    agent any
    environment {
        DOCKER_REGISTRY = 'alejomunoz'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Favourite Service') {
            steps {
                dir('favourite-service') {
                    bat 'mvn clean package -DskipTests'
                }
            }
        }
        stage('Docker Build Favourite Service') {
            steps {
                dir('favourite-service') {
                    bat "docker build -t %DOCKER_REGISTRY%/favourite-service-ecommerce-boot:%DOCKER_TAG% ."
                    bat "docker push %DOCKER_REGISTRY%/favourite-service-ecommerce-boot:%DOCKER_TAG%"
                    bat "docker tag %DOCKER_REGISTRY%/favourite-service-ecommerce-boot:%DOCKER_TAG% %DOCKER_REGISTRY%/favourite-service-ecommerce-boot:latest"
                    bat "docker push %DOCKER_REGISTRY%/favourite-service-ecommerce-boot:latest"
                }
            }
        }
        stage('Deploy to Dev Environment') {
            steps {
                bat 'echo "Deploying favourite-service to development environment"'
                bat 'docker-compose -f compose.yml up -d favourite-service'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Favourite Service deployed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
