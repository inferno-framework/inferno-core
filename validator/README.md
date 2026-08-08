# infernocommunity/inferno-resource-validator

This Dockerfile is based on the Dockerfile for org.hl7.fhir.validator-wrapper (see https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/blob/master/Dockerfile ) with the following differences relevant to Inferno:
1. It fetches the built JAR from GitHub instead of locally, or building from source
2. It uses an Ubuntu-based base image instead of Alpine to support both AMD64 and ARM architectures
3. It defaults the following environment variables:
   - SESSION_CACHE_IMPLEMENTATION=PassiveExpiringSessionCache
   - SESSION_CACHE_DURATION=-1
     - These enable the old session cache implementation, and configure the session cache to never expire sessions.
   - TERMINOLOGY_CLIENT_USE_CACHE_ID=false
     - This disables terminology caches on tx.fhir.org because they are not long-running like validator sessions in Inferno and were causing errors 
   - VALIDATION_SERVICE_PRESETS_FILE_PATH=ignore-this-do-not-load-presets
     - This disables loading presets at service startup by pointing it to a non-existent file. (There is no other explicit value or setting for "do not load presets")

It is intended to be a drop-in replacement for the official image; i.e., if you don't need features 2 & 3 above you can use the same version of `markiantorno/validator-wrapper`. Version numbers of this image should match the version number of the official image. The only difference is you will need to set the environment variables as mentioned in (4) above, depending on which behavior you want.

In addition to the above differences, published versions of this image have been tested by the Inferno team and are known to be compatible with Inferno test kits.

## Recommended release sequence
Since there are many test kits that depend on this validator service, the following sequence is recommended:

1. Watch https://github.com/hapifhir/org.hl7.fhir.validator-wrapper for new releases.
2. When there is a new release, build this dockerfile locally and test g10 (all versions of US Core) against it by updating the version in `docker-compose.background.yml`
3. If there are changes needed to this dockerfile, submit that PR first.
4. Publish a pre-release version of this image and deploy to QA to verify behavior more broadly on a running system.
5. Publish a new version of this image once it's ready. IMPORTANT: any test kit that doesn't pin a specific version of the validator will now use this latest image.
6. Submit a PR on g10 to update the the version in `docker-compose.background.yml` and `lib/onc_certification_g10_test_kit/configuration_checker.rb`, and update the message filters if necessary.

## Publishing a new version
A script `build_and_push.sh` is provided to assist with publishing a new version. The version of the wrapper service to use must be provided as a command-line argument (required).
The available versions are listed at https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases .

### Standard release
Replace `1.0.50` in the example below with the appropriate version number and run the following command to build & push a multi-arch image to Docker Hub. Images will be tagged as both the provided version number and as `latest`.

```sh
./build_and_push.sh 1.0.50
```

### Pre-release
To publish a pre-release image for testing before a full release, use the `--pre-release` flag. This builds and pushes an image tagged as `<version>-pre` (e.g. `1.0.50-pre`) without updating the `latest` tag.

```sh
./build_and_push.sh --pre-release 1.0.50
```

When you are ready to do a full release, run the standard release command above. The `<version>-pre` tag is not deleted automatically; remove it manually within Docker Hub if you'd like to clean it up.