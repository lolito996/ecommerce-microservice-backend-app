FROM jenkins/jenkins:lts

USER root

# Instalar Docker CLI y Maven
RUN apt-get update && \
    apt-get install -y docker.io maven && \
    apt-get clean

# Permitir que Jenkins use Docker del host
RUN usermod -aG docker jenkins

USER jenkins
