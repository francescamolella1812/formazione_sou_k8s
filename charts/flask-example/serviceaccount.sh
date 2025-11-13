#!/usr/bin/env bash

NAMESPACE="formazione-sou"
DEPLOYMENT="flask-app-flask-example"

# Usa il token del ServiceAccount
TOKEN=$(cat token.txt)
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Recupera il Deployment in JSON
DEPLOYMENT_JSON=$(curl -s --cacert ~/.kube/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    "$APISERVER/apis/apps/v1/namespaces/$NAMESPACE/deployments/$DEPLOYMENT")

if [[ -z "$DEPLOYMENT_JSON" ]]; then
  echo "Impossibile recuperare il Deployment."
  exit 1
fi

# Controlli
echo "$DEPLOYMENT_JSON" | jq -e '.spec.template.spec.containers[0].livenessProbe' >/dev/null \
  || { echo "Manca livenessProbe"; exit 1; }

echo "$DEPLOYMENT_JSON" | jq -e '.spec.template.spec.containers[0].readinessProbe' >/dev/null \
  || { echo "Manca readinessProbe"; exit 1; }

echo "$DEPLOYMENT_JSON" | jq -e '.spec.template.spec.containers[0].resources.limits' >/dev/null \
  || { echo "Manca limits"; exit 1; }

echo "$DEPLOYMENT_JSON" | jq -e '.spec.template.spec.containers[0].resources.requests' >/dev/null \
  || { echo "Manca requests"; exit 1; }

echo "Deployment conforme alle Best Practices!"
exit 0

