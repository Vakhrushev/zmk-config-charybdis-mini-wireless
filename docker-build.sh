#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DOCKER_IMAGE="zmkfirmware/zmk-build-arm:stable"
CACHE_VOLUME="zmk-charybdis-west-cache"

mkdir -p "$BUILD_DIR"

echo "==> Pulling ZMK build image..."
docker pull "$DOCKER_IMAGE"

echo "==> Building in Docker container..."
docker run --rm \
  -v "$SCRIPT_DIR/config:/workspace/config:ro" \
  -v "$BUILD_DIR:/output" \
  -v "$CACHE_VOLUME:/workspace" \
  -w /workspace \
  "$DOCKER_IMAGE" \
  bash -c '
set -euo pipefail

if [ ! -d ".west" ]; then
  echo "==> Initializing west workspace (first run, will be cached)..."
  west init -l config
  west update
else
  echo "==> Using cached west workspace, updating..."
  west update
fi

export ZEPHYR_BASE=/workspace/zephyr

cd zmk/app

build_side() {
  local side=$1
  echo "==> Building charybdis_${side}..."
  west build -p -b nice_nano_v2 -d /tmp/build_${side} -- \
    -DSHIELD=charybdis_${side} \
    -DZMK_CONFIG=/workspace/config
  cp /tmp/build_${side}/zephyr/zmk.uf2 /output/charybdis_${side}.uf2
  echo "==> charybdis_${side}.uf2 built successfully"
}

build_side left
build_side right

echo "==> All builds complete!"
'

echo ""
echo "Firmware files:"
ls -la "$BUILD_DIR"/*.uf2
