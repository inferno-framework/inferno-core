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

echo Using PROJECT_VERSION $PROJECT_VERSION

if [ "$PRE_RELEASE" = true ]; then
    docker buildx build --platform linux/arm64,linux/amd64 \
        --build-arg "PROJECT_VERSION=${PROJECT_VERSION}" \
        --tag "${IMAGE}:${PROJECT_VERSION}-pre" \
        --push .
else
    docker buildx build --platform linux/arm64,linux/amd64 \
        --build-arg "PROJECT_VERSION=${PROJECT_VERSION}" \
        --tag "${IMAGE}:${PROJECT_VERSION}" \
        --tag "${IMAGE}:latest" \
        --push .
fi
