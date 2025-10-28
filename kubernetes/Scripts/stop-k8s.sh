#!/bin/bash
# Script para eliminar todos los recursos de Kubernetes en la carpeta ecommerce
kubectl delete -f ecommerce/
echo "Todos los recursos de Kubernetes en el namespace ecommerce han sido eliminados."
