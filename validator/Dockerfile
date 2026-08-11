# This Dockerfile is based on the Dockerfile for org.hl7.fhir.validator-wrapper
# https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/blob/master/Dockerfile
# with the following differences:
# 1. It fetches the built JAR from GitHub instead of locally, or building from source
# 2. It uses an Ubuntu-based base image instead of Alpine to support both AMD64 and ARM architectures
# 3. It defaults the following environment variables:
#    - SESSION_CACHE_IMPLEMENTATION=PassiveExpiringSessionCache
#    - SESSION_CACHE_DURATION=-1
#      - These enable the old session cache implementation, and configure the session cache to never expire sessions.
#    - TERMINOLOGY_CLIENT_USE_CACHE_ID=false
#      - This disables terminology caches on tx.fhir.org because they are not long-running like validator sessions in Inferno and were causing errors 
#    - VALIDATION_SERVICE_PRESETS_FILE_PATH=ignore-this-do-not-load-presets
#      - This disables loading presets at service startup by pointing it to a non-existent file. (There is no other explicit value or setting for "do not load presets")
# The validator-wrapper release to use is based on the PROJECT_VERSION build argument (required)

FROM eclipse-temurin:17-jre-jammy

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
RUN wget -O validator-wrapper.jar "https://github.com/hapifhir/org.hl7.fhir.validator-wrapper/releases/download/${PROJECT_VERSION}/validator-wrapper.jar"

# Environment vars here
ENV ENVIRONMENT=prod
ENV SESSION_CACHE_IMPLEMENTATION=PassiveExpiringSessionCache
ENV SESSION_CACHE_DURATION=-1
# disable terminology caches on tx.fhir.org because they are not long-running like validator sessions
ENV TERMINOLOGY_CLIENT_USE_CACHE_ID=false
ENV VALIDATION_SERVICE_PRESETS_FILE_PATH=ignore-this-do-not-load-presets
# By default, java will be run using the G10s GC and assigned 79% of the system's available memory
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:InitialRAMPercentage=79 -XX:MinRAMPercentage=79 -XX:MaxRAMPercentage=79 -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseStringDeduplication -XX:+CrashOnOutOfMemoryError "

EXPOSE 3500

# The last line instructs Docker to run java with the JAVA_OPTS and indicates the packaged application.
CMD ["sh", "-c", "exec java -server ${JAVA_OPTS} -jar validator-wrapper.jar -startServer"]
