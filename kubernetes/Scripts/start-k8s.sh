#!/bin/bash
# Script para iniciar todos los recursos de Kubernetes en la carpeta ecommerce
kubectl apply -f ecommerce/
echo "Todos los recursos de Kubernetes en el namespace ecommerce han sido desplegados."
