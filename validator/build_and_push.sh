#!/bin/sh

PRE_RELEASE=false
PROJECT_VERSION=""

for arg in "$@"; do
    case "$arg" in
        --pre-release) PRE_RELEASE=true ;;
        *) PROJECT_VERSION="$arg" ;;
    esac
done

if [ -z "$PROJECT_VERSION" ]; then
    echo "Usage: $0 [--pre-release] PROJECT_VERSION"
    echo The available project versions are listed at https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases
    exit 1
fi

IMAGE="infernocommunity/inferno-resource-validator"
PRE_RELEASE_TAG="${PROJECT_VERSION}-pre"

echo Using PROJECT_VERSION $PROJECT_VERSION

if [ "$PRE_RELEASE" = true ]; then
    docker buildx build --platform linux/arm64,linux/amd64 \
        --build-arg "PROJECT_VERSION=${PROJECT_VERSION}" \
        --tag "${IMAGE}:${PRE_RELEASE_TAG}" \
        --push .
else
    if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
        echo "Warning: DOCKER_USERNAME and DOCKER_PASSWORD must be set to delete pre-release tag"
    else
        LOGIN_PAYLOAD=$(printf '{"username":"%s","password":"%s"}' "$DOCKER_USERNAME" "$DOCKER_PASSWORD")
        TOKEN=$(curl -s -X POST -H "Content-Type: application/json" \
            -d "$LOGIN_PAYLOAD" \
            https://hub.docker.com/v2/users/login/ | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

        if [ -z "$TOKEN" ]; then
            echo "Warning: Failed to authenticate with Docker Hub, skipping pre-release tag deletion"
        else
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
                -H "Authorization: JWT ${TOKEN}" \
                "https://hub.docker.com/v2/repositories/${IMAGE}/tags/${PRE_RELEASE_TAG}/")

            case "$STATUS" in
                204) echo "Deleted pre-release tag ${PRE_RELEASE_TAG}" ;;
                404) echo "Pre-release tag ${PRE_RELEASE_TAG} not found, skipping deletion" ;;
                *)   echo "Warning: Failed to delete pre-release tag (HTTP ${STATUS})" ;;
            esac
        fi
    fi

    docker buildx build --platform linux/arm64,linux/amd64 \
        --build-arg "PROJECT_VERSION=${PROJECT_VERSION}" \
        --tag "${IMAGE}:${PROJECT_VERSION}" \
        --tag "${IMAGE}:latest" \
        --push .
fi