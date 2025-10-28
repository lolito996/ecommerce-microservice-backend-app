pipeline {
    agent any
    environment {
        ZIPKIN_URI = 'http://zipkin:9411/api/v2/spans'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t zipkin-dev .'
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
