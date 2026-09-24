#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-e2e-api-suite:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-e2e-api-suite}"
ENVIRONMENT="${ENVIRONMENT:-qa}"
REMOTE_DIR="${REMOTE_DIR:-/opt/e2e-api-suite}"
EC2_USER="${EC2_USER:-ubuntu}"
EC2_HOST="${EC2_HOST:?Set EC2_HOST to the EC2 public DNS name or IP}"
KEY_PATH="${KEY_PATH:?Set KEY_PATH to the EC2 private key path}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_ARCHIVE="${TMPDIR:-/tmp}/e2e-api-suite.tar.gz"

cleanup() {
    rm -f "$IMAGE_ARCHIVE"
}
trap cleanup EXIT

command -v docker >/dev/null 2>&1 || { echo "Docker is required locally" >&2; exit 1; }
command -v ssh >/dev/null 2>&1 || { echo "SSH is required locally" >&2; exit 1; }
command -v scp >/dev/null 2>&1 || { echo "SCP is required locally" >&2; exit 1; }

chmod 400 "$KEY_PATH"

echo "Building API test image: $IMAGE_NAME"
docker build --file "$SCRIPT_DIR/Dockerfile.api" --tag "$IMAGE_NAME" "$SCRIPT_DIR"

echo "Exporting image"
docker save "$IMAGE_NAME" | gzip > "$IMAGE_ARCHIVE"

echo "Preparing Docker on $EC2_HOST"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "$EC2_USER@$EC2_HOST" \
    "REMOTE_DIR='$REMOTE_DIR' bash -s" <<'REMOTE_SETUP'
set -euo pipefail
if ! command -v docker >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
fi
sudo mkdir -p "$REMOTE_DIR/results"
sudo chown -R "$USER":"$USER" "$REMOTE_DIR"
REMOTE_SETUP

echo "Copying image to EC2"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "$IMAGE_ARCHIVE" \
    "$EC2_USER@$EC2_HOST:$REMOTE_DIR/e2e-api-suite.tar.gz"

echo "Running API suite on EC2"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "$EC2_USER@$EC2_HOST" \
    "IMAGE_NAME='$IMAGE_NAME' CONTAINER_NAME='$CONTAINER_NAME' ENVIRONMENT='$ENVIRONMENT' REMOTE_DIR='$REMOTE_DIR' bash -s" <<'REMOTE_RUN'
set -euo pipefail

docker load --input "$REMOTE_DIR/e2e-api-suite.tar.gz"
rm -f "$REMOTE_DIR/e2e-api-suite.tar.gz"
docker rm --force "$CONTAINER_NAME" >/dev/null 2>&1 || true
mkdir -p "$REMOTE_DIR/results"

set +e
docker run --name "$CONTAINER_NAME" \
    --env "env=$ENVIRONMENT" \
    --volume "$REMOTE_DIR/results:/workspace/target" \
    "$IMAGE_NAME" "-Denv=$ENVIRONMENT"
EXIT_CODE=$?
set -e

echo "Reports and logs are available at $REMOTE_DIR/results"
docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
exit "$EXIT_CODE"
REMOTE_RUN

echo "API suite deployment completed"
