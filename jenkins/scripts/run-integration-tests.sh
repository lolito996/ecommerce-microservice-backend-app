#!/bin/sh
set -e
echo "Running integration tests for selected services..."
SERVICES="user-service product-service order-service payment-service favourite-service proxy-client"
for s in $SERVICES; do
  if [ -d "$s" ]; then
    echo "Running integration tests in $s"
    (cd $s && mvn test -Dtest=*IntegrationTest) || echo "Integration tests failed for $s"
  fi
done
echo "Integration test runner finished"
