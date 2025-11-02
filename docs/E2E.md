# E2E tests for Ecommerce Microservices

This document describes how end-to-end (E2E) tests are organized and executed against a Kubernetes test cluster.

## Overview
- Module: `e2e-tests` (Maven module)
- Fixtures: `e2e-tests/src/test/resources/fixtures/`
- Seed job manifest: `kubernetes/seed-job.yaml`
- Seed script (Jenkins helper): `jenkins/scripts/seed-data.sh`
- Jenkins stage: `Seed test data & Run E2E tests` added to `jenkins/pipelines/stage/all-services-stage.Jenkinsfile`

## Endpoints used by tests (examples)
- GET /api/products
  - Purpose: validate product catalog reachable
- GET /api/products/{id}
- POST /api/products
  - Fixture: `product1.json`
- POST /api/users
  - Fixture: `user1.json`
- POST /api/orders
  - Uses created user and product to validate order flow

## How seeding works
- The Jenkins pipeline (or manually) runs:
  ```bash
  jenkins/scripts/seed-data.sh <namespace>
  ```
- The script applies `kubernetes/seed-job.yaml` which runs a Job that performs HTTP POSTs to the in-cluster `api-gateway` service to create required test entities.

## How to run locally (using Docker Desktop / minikube)
1. Create a test namespace and deploy manifests:

```bash
kubectl create namespace ecommerce-test
kubectl apply -f kubernetes/ --namespace ecommerce-test
kubectl wait --for=condition=ready pods --all --namespace ecommerce-test --timeout=180s
```

2. Seed data:

```bash
jenkins/scripts/seed-data.sh ecommerce-test
```

3. Run E2E tests locally (assumes api-gateway is accessible at localhost:8080, change TEST_BASE_URL if necessary):

```bash
TEST_BASE_URL=http://localhost:8080 mvn -pl e2e-tests -Dtest=*E2E* test
```

## Running in CI (Jenkins)
- The pipeline stage `Seed test data & Run E2E tests` will:
  1. Run the seed job in the test namespace
  2. Execute `mvn -pl e2e-tests -Dtest=*E2E* test` with `TEST_BASE_URL` set to the cluster address
  3. Publish test reports with JUnit

## Fixtures
Fixtures are JSON files in `e2e-tests/src/test/resources/fixtures/` and used by the seed job if you adapt it to mount a ConfigMap. For now the seed job writes inline JSON and posts it.

## Next improvements
- Configure seed job to mount ConfigMap containing fixture files instead of inline payloads.
- Add more E2E tests covering user flows (create user, add favourites, create order, payment), increase assertions and negative tests.
- Use dynamic environment discovery so tests can run from outside cluster via Ingress/NodePort or via port-forward.
