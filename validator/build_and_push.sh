#!/bin/sh

PROJECT_VERSION=$1
if [ -z $PROJECT_VERSION ]; then
    echo "Usage: $0 PROJECT_VERSION"
    echo The available project versions are listed at https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases 
    exit 1
fi

echo Using PROJECT_VERSION $PROJECT_VERSION

docker buildx build --platform linux/arm64,linux/amd64 --build-arg "PROJECT_VERSION=${PROJECT_VERSION}" --tag "infernocommunity/inferno-resource-validator:${PROJECT_VERSION}" --tag infernocommunity/inferno-resource-validator:latest --push .