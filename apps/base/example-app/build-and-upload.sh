#!/bin/bash

docker build -t harbor.internal/example-app-registry/example-app:latest . && \
  docker push harbor.internal/example-app-registry/example-app:latest
