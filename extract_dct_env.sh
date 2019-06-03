#!/bin/bash
# uncomment to debug the script
# set -x

echo "Describing kubernetes secret containing DCT related values"
kubectl describe secret "$REGISTRY_NAMESPACE.$IMAGE_NAME.$DEVOPS_SIGNER" -n$BUILD_CLUSTER_NAMESPACE

export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$(kubectl get secret "$REGISTRY_NAMESPACE.$IMAGE_NAME.$DEVOPS_SIGNER" -n$BUILD_CLUSTER_NAMESPACE -o yaml | grep DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE | awk '{print $2;}' | base64 -w 0 -d -i)
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$(kubectl get secret "$REGISTRY_NAMESPACE.$IMAGE_NAME.$DEVOPS_SIGNER" -n$BUILD_CLUSTER_NAMESPACE -o yaml | grep DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE | awk '{print $2;}' | base64 -w 0 -d -i)
export PEM_FILE_NAME=$(kubectl get secret "$REGISTRY_NAMESPACE.$IMAGE_NAME.$DEVOPS_SIGNER" -n$BUILD_CLUSTER_NAMESPACE -o yaml | grep PEM_FILE_NAME | awk '{print $2;}' | base64 -w 0 -d -i)
export PEM_FILE_CONTENT_BASE64=$(kubectl get secret "$REGISTRY_NAMESPACE.$IMAGE_NAME.$DEVOPS_SIGNER" -n$BUILD_CLUSTER_NAMESPACE -o yaml | grep PEM_FILE_CONTENT_BASE64 | awk '{print $2;}' | base64 -w 0 -d -i)
