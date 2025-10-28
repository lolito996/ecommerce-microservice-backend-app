pipeline {
    agent any
    environment {
        SPRING_PROFILES_ACTIVE = 'dev'
        SPRING_ZIPKIN_BASE_URL = 'http://zipkin:9411'
        SPRING_CONFIG_IMPORT = 'optional:configserver:http://cloud-config-container:9296/'
        SPRING_CLOUD_CONFIG_URI = 'http://cloud-config-container:9296'
        EUREKA_CLIENT_SERVICEURL_DEFAULTZONE = 'http://service-discovery-container:8761/eureka/'
        EUREKA_CLIENT_SERVICE_URL_DEFAULT_ZONE = 'http://service-discovery-container:8761/eureka/'
        EUREKA_CLIENT_REGISTER_WITH_EUREKA = 'true'
        EUREKA_CLIENT_FETCH_REGISTRY = 'true'
        SPRING_JPA_HIBERNATE_DDL_AUTO = 'update'
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t order-service-dev .'
            }
        }
    }
}
