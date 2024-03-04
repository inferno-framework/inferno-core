# infernocommunity/inferno-resource-validator

This Dockerfile is based on the Dockerfile for org.hl7.fhir.validator-wrapper (see https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/blob/master/Dockerfile ) with 3 key differences relevant to Inferno:
1. It fetches the built JAR from GitHub instead of locally, or building from source
2. It adds MITRE certs, for ease of use by the MITRE development team
3. It uses an Ubuntu-based base image instead of Alpine to support both AMD64 and ARM architectures

It is intended to be a drop-in replacement for the official image; i.e., if you don't need features 2 & 3 above you can use the same version of `markiantorno/validator-wrapper` with all the same settings, environment variables, etc. Version numbers of this image should match the version number of the official image.

In addition to the above differences, published versions of this image have been tested by the Inferno team and are known to be compatible with Inferno test kits.


## Publishing a new version
A script `build_and_push.sh` is provided to assist with publishing a new version. The version of the wrapper service to use must be provided as the first command-line argument (required).
The available versions are listed at https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases .
Replace `1.0.50` in the example below with the appropriate number and run the following command to build & push a multi-arch image to Docker Hub. Images will be tagged as both the provided version number and as `latest`

```sh
./build_and_push.sh 1.0.50
```