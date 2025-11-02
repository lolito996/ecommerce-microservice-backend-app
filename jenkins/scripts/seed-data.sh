#!/bin/sh
# Seed test data in Kubernetes test namespace
NAMESPACE=${1:-ecommerce-test}
set -e
kubectl apply -f kubernetes/seed-job.yaml --namespace ${NAMESPACE}
# wait for job to complete
kubectl wait --for=condition=complete job/seed-job --namespace ${NAMESPACE} --timeout=120s || (
  echo "Seed job did not complete in time";
  kubectl logs job/seed-job --namespace ${NAMESPACE} || true;
  exit 1
)
# optional: delete job pods
kubectl delete job seed-job --namespace ${NAMESPACE} --ignore-not-found

echo "Seeding complete"
