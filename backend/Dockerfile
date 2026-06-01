# syntax=docker/dockerfile:1

# --- Build stage: compile the Spring Boot fat jar with the Gradle wrapper ---
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Copy build scripts + wrapper first so dependency resolution can cache.
COPY gradlew ./
COPY gradle ./gradle
COPY settings.gradle.kts build.gradle.kts ./
RUN chmod +x gradlew

# Build the bootable jar (tests run in CI / locally, skipped here for speed).
COPY src ./src
RUN ./gradlew --no-daemon clean bootJar -x test

# --- Runtime stage: slim JRE running the fat jar ---
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app
COPY --from=build /app/build/libs/*-SNAPSHOT.jar app.jar

# Render injects $PORT; Spring reads it via server.port=${PORT:8080}.
# MaxRAMPercentage keeps the heap inside the 512 MB free instance.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
