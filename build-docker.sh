#!/bin/bash
set -eu
set -o pipefail

# Builds charybdis_left and charybdis_right firmware using the official ZMK Docker image.
# The west workspace is cached in ./zmk-workspace so west update only runs once.
# Output UF2 files are placed in ./build/.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$REPO_DIR/zmk-workspace"
BUILD_OUT_DIR="$REPO_DIR/build"
IMAGE="zmkfirmware/zmk-build-arm:3.5"
BOARD="nice_nano//zmk"

mkdir -p "$BUILD_OUT_DIR"

build_side() {
    local side=$1
    echo "==> Building charybdis_$side ..."
    docker run --rm \
        -v "$REPO_DIR/config:/zmk-config:ro" \
        -v "$WORKSPACE_DIR:/zmk-workspace" \
        -w /zmk-workspace \
        "$IMAGE" \
        bash -c "
            set -euo pipefail

            # Init workspace if not already done
            if [ ! -f /zmk-workspace/.west/config ]; then
                west init -l /zmk-config
                west update
                west zephyr-export
            fi

            # Build
            west build -s zmk/app -d build_${side} \
                -b '${BOARD}' \
                -- \
                -DSHIELD=charybdis_${side} \
                -DZMK_CONFIG=/zmk-config \
                2>&1
        "
    cp "$WORKSPACE_DIR/build_${side}/zephyr/zmk.uf2" "$BUILD_OUT_DIR/charybdis_${side}.uf2"
    echo "==> charybdis_${side}.uf2 -> build/"
}

build_side left
build_side right

echo ""
echo "Done. Firmware in $BUILD_OUT_DIR/"
