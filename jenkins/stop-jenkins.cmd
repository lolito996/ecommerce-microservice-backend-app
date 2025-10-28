@echo off
echo Stopping Jenkins...
docker stop jenkins
docker rm jenkins
