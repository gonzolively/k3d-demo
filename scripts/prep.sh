#!/bin/bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -d "$CURR_DIR" ] || { echo "FATAL: no current dir (maybe running in zsh?)";  exit 1; }

# shellcheck source=./common.sh
source "$CURR_DIR/common.sh"

# Function to check docker daemon status
check_docker_daemon() {
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker info >/dev/null 2>&1; then
            echo "Docker daemon is running."
            return 0
        fi

        echo "Waiting for Docker daemon to start... (Attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "Error: Docker daemon did not start within the expected time."
    return 1
}

section "Checking Docker daemon status..."
if ! check_docker_daemon; then
    echo "Failed to confirm Docker daemon is running. Please start Docker and try again."
    exit 1
fi

section "Cleaning up docker environment (CAREFUL: STEPS ASK TO DELETE EVERYTHING IN DOCKER!)..."
if proceed_or_not "Section (Docker Cleanup: CAREFUL!)"; then
  info_pause_exec_options "REMOVE docker containers" "docker rm -f $(docker ps -qa | tr '\n' ' ')"
  info_pause_exec_options "REMOVE docker networks" "docker network prune -f"
  info_pause_exec_options "REMOVE docker volumes" "docker volume prune -f"
  info_pause_exec_options "PRUNE docker system" "docker system prune -a -f"
else
  echo "Skipped Section."
fi

section "Pulling images..."
docker pull rancher/k3s:v1.22.2-k3s1
docker pull rancher/k3d-proxy:5.0.0
docker pull rancher/k3d-tools:5.0.0
docker pull python:3.7-slim

section "Preparing Filesystem..."
if [ -d "/tmp/src" ]; then
  rm -rf /tmp/src
fi
mkdir -p /tmp/src

echo "Script completed successfully."
