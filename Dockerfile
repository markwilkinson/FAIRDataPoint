# https://docs.docker.com/reference/dockerfile/#syntax
# syntax=docker/dockerfile:1

################################################################################
# BUILD JAR

FROM maven:3-eclipse-temurin-21-alpine AS builder

WORKDIR /builder

ADD . /builder

# https://maven.apache.org/ref/current/maven-embedder/cli.html
ARG PROJECT_VERSION
RUN mvn --quiet --batch-mode --update-snapshots --fail-fast -DskipTests -Drevision=${PROJECT_VERSION} package

################################################################################
# BUILD IMAGE

FROM eclipse-temurin:21-jdk-alpine

# Pick up whatever OS package security fixes Alpine has published since this base
# image was last rebuilt -- eclipse-temurin's own image lags its own upstream Alpine
# repo by days/weeks, so patched packages are often already available even when the
# base image tag itself hasn't been refreshed.
RUN apk update && apk upgrade --no-cache

# add non-root user to run the app
# https://spring.io/guides/gs/spring-boot-docker
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

WORKDIR /fdp

COPY --from=builder /builder/target/fdp-spring-boot.jar /fdp/app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
