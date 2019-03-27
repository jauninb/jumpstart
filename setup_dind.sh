#!/bin/bash
export BUILD_CLUSTER=${BUILD_CLUSTER:-"bp2i"}
export CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE:-"build"}
export IBMCLOUD_TARGET_REGION=${IBMCLOUD_TARGET_REGION:-"eu-gb"}

echo "Logging in to build cluster account..."
ibmcloud login --apikey "$IBMCLOUD_API_KEY" -r "$IBMCLOUD_TARGET_REGION"

if [ -z "$IBMCLOUD_TARGET_RESOURCE_GROUP" ]; then
  echo "Using default resource group" 
else
  ibmcloud target -g "$IBMCLOUD_TARGET_RESOURCE_GROUP"
fi

echo "Cluster list:"
ibmcloud ks clusters

echo "Running ibmcloud ks cluster-config -cluster "$BUILD_CLUSTER" --export"
CLUSTER_CONFIG_COMMAND=$(ibmcloud ks cluster-config -cluster "$BUILD_CLUSTER" --export)
echo "$CLUSTER_CONFIG_COMMAND"
eval $CLUSTER_CONFIG_COMMAND

echo "Checking cluster namespace $CLUSTER_NAMESPACE"
if ! kubectl get namespace "$CLUSTER_NAMESPACE"; then
  kubectl create namespace "$CLUSTER_NAMESPACE"
fi

# Ensure there is a Docker server on the ${BUILD_CLUSTER}
if ! kubectl --namespace "$CLUSTER_NAMESPACE" rollout status -w deployment/docker; then
  echo "Installing Docker Server into build cluster..."
  kubectl --namespace "$CLUSTER_NAMESPACE" run docker --image=docker:dind --overrides='{ "apiVersion": "apps/v1", "spec": { "template": { "spec": {"containers": [ { "name": "docker", "image": "docker:dind", "securityContext": { "privileged": true } } ] } } } }'
  kubectl --namespace "$CLUSTER_NAMESPACE" rollout status -w deployment/docker
fi

# Use port-forward to make the pod/port locally accessible
# Be sure to use a running POD (not an evicted one)
kubectl --namespace "$CLUSTER_NAMESPACE" get pods 
kubectl --namespace "$CLUSTER_NAMESPACE" port-forward $(kubectl --namespace "$CLUSTER_NAMESPACE" get pods | grep docker | grep -i running | awk '{print $1;}') 2375:2375 > /dev/null 2>&1 &

while ! nc -z localhost 2375; do   
  sleep 0.1
done

export DOCKER_HOST='tcp://localhost:2375'

echo "Logging in to docker registry..."
ibmcloud cr login
