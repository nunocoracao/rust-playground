# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

################################################################################
# Create a stage for building the application.

# VARS FOR TERMINAL UX
#   Rust version
#   app name - found in cargo.toml
#   Port to expose

ARG RUST_VERSION=1.67 
FROM rust:${RUST_VERSION} AS build

#define working dir
WORKDIR /usr/src/app

#Copy files to container
COPY . .

RUN rustup target add x86_64-unknown-linux-musl

#Build Rust application
RUN cargo build --target x86_64-unknown-linux-musl --release

################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
FROM debian:bullseye-slim AS final

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Install dependencies
RUN apt-get update & apt-get install -y extra-runtime-dependencies & rm -rf /var/lib/apt/lists/*

# Copy the executable from the "build" stage.
COPY --from=build /usr/src/app/target/x86_64-unknown-linux-musl/release/rustwebservice rustwebservice

# Expose the port that the application listens on.
EXPOSE 8080

# What the container should run when it is started.
CMD ["rustwebservice"]

