#!/bin/bash

# Configurable variables
DOCKER_USERNAME="your-dockerhub-username"
REPOSITORY_NAME="node"
IMAGE_NAME="${DOCKER_USERNAME}/${REPOSITORY_NAME}"
VERSION_PREFIX="v"
DEPLOYMENT_FILE="./k8s/deployment.yaml"  # Adjust path if needed

# Get the latest version tag from Docker Hub
LATEST_TAG=$(curl -s "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${REPOSITORY_NAME}/tags?page_size=100" | jq -r '.results[].name' | grep -E "^${VERSION_PREFIX}[0-9]+$" | sort -V | tail -n 1)

# Determine new version tag
if [[ -z "$LATEST_TAG" ]]; then
  NEW_VERSION="${VERSION_PREFIX}1"
else
  VERSION_NUMBER=$(echo "$LATEST_TAG" | sed -E "s/^${VERSION_PREFIX}//")
  NEW_VERSION="${VERSION_PREFIX}$((VERSION_NUMBER + 1))"
fi

# Build and tag Docker image
docker build -t ${IMAGE_NAME}:latest .
docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${NEW_VERSION}

# Push the new image to Docker Hub
docker push ${IMAGE_NAME}:${NEW_VERSION}

echo "Pushed image ${IMAGE_NAME}:${NEW_VERSION} to Docker Hub."

# Update image tag in Kubernetes deployment YAML
sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${NEW_VERSION}|" ${DEPLOYMENT_FILE}

echo "✅ Deployment updated with image: ${IMAGE_NAME}:${NEW_VERSION}"
