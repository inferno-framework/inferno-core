# This Dockerfile is based on the Dockerfile for org.hl7.fhir.validator-wrapper
# https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/blob/master/Dockerfile
# with the following differences:
# 1. It fetches the built JAR from GitHub instead of locally, or building from source
# 2. It adds MITRE certs, for ease of use by the MITRE development team
# 3. It uses an Ubuntu-based base image instead of Alpine to support both AMD64 and ARM architectures
# 4. It defaults the following environment variables:
#    - SESSION_CACHE_IMPLEMENTATION=PassiveExpiringSessionCache
#    - SESSION_CACHE_DURATION=-1
#      - These enable the old session cache implementation, and configure the session cache to never expire sessions.
#
# The software release to use is based on the PROJECT_VERSION build argument (required)

FROM eclipse-temurin:11-jre-jammy

RUN wget https://gitlab.mitre.org/mitre-scripts/mitre-pki/-/raw/master/os_scripts/install_certs.sh -O - | MODE=ubuntu sh \
 && wget https://gitlab.mitre.org/mitre-scripts/mitre-pki/-/raw/master/tool_scripts/install_certs.sh -O - | MODE=java sh

ARG PROJECT_VERSION
RUN echo "Project version set to -> ${PROJECT_VERSION}"

ENV APPLICATION_USER=ktor
RUN adduser $APPLICATION_USER

RUN mkdir /app
RUN chown -R $APPLICATION_USER /app

RUN mkdir /home/$APPLICATION_USER/.fhir
RUN chown -R $APPLICATION_USER /home/$APPLICATION_USER/.fhir

USER $APPLICATION_USER

# These lines copy the packaged application into the Docker image and sets the working directory to where it was copied.
WORKDIR /app
RUN wget -O validator-wrapper.jar "https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases/download/${PROJECT_VERSION}/validator_cli.jar"

# Environment vars here
ENV ENVIRONMENT=prod
ENV SESSION_CACHE_IMPLEMENTATION=PassiveExpiringSessionCache
ENV SESSION_CACHE_DURATION=-1
ENV VALIDATION_SERVICE_PRESETS_FILE_PATH=ignore-this-do-not-load-presets

EXPOSE 3500

# The last line instructs Docker to run java with G10s GC,  assigns 79% of the system's available memory, and indicates the packaged application.
CMD ["java", "-server", "-XX:+UnlockExperimentalVMOptions", "-XX:InitialRAMPercentage=79", "-XX:MinRAMPercentage=79", "-XX:MaxRAMPercentage=79", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=100", "-XX:+UseStringDeduplication", "-XX:+CrashOnOutOfMemoryError", "-jar", "validator-wrapper.jar", "-startServer"]
