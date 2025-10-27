#!/bin/bash
# Ejecutar Jenkins en Docker (Linux)
JENKINS_HOME="$(pwd)/jenkins_home"
mkdir -p "$JENKINS_HOME"
echo "Iniciando Jenkins en Docker..."
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
  -v "$JENKINS_HOME":/var/jenkins_home \
  -v "$(pwd)/jenkins-config.xml":/var/jenkins_home/jenkins-config.xml \
  jenkins/jenkins:lts
