pipeline {
    agent any
    environment {
        EUREKA_URI = 'http://service-discovery:8761/eureka/'
        CONFIG_SERVER_URI = 'http://cloud-config:8888'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            steps {
                sh './mvnw clean package -DskipTests'
            }
        }
        stage('Test') {
            steps {
                sh './mvnw test'
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t service-discovery-dev .'
            }
        }
        stage('Push Image') {
            steps {
                echo 'Push a tu registry aquí'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Despliegue en Kubernetes dev aquí'
            }
        }
    }
}
