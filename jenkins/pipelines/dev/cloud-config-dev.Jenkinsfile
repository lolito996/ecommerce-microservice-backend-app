pipeline {
    agent any
    environment {
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
                sh 'docker build -t cloud-config-dev .'
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
