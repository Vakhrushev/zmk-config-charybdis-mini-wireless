#!/bin/bash
set -eu
set -o pipefail

# Builds charybdis_left and charybdis_right using the ZMK Docker toolchain image.
# The west workspace is cached in ./zmk-workspace (west update only runs on first use).
# Output UF2 files go to ./build/.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$REPO_DIR/zmk-workspace"
BUILD_OUT_DIR="$TMPDIR/zmk-build"
IMAGE="zmkfirmware/zmk-build-arm:4.1-branch"
BOARD="nice_nano//zmk"

mkdir -p "$BUILD_OUT_DIR" "$WORKSPACE_DIR"

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

docker run --rm \
    -v "$REPO_DIR/config:/zmk-workspace/config:ro" \
    -v "$WORKSPACE_DIR:/zmk-workspace" \
    -v "$BUILD_OUT_DIR:/build-out" \
    -e HOST_UID="$HOST_UID" \
    -e HOST_GID="$HOST_GID" \
    -w /zmk-workspace \
    "$IMAGE" \
    bash -c "
        set -eu

        if [ ! -f /zmk-workspace/.west/config ]; then
            echo '--- Initialising west workspace ---'
            west init -l config
            west update
        fi

        west zephyr-export

        for side in left right; do
            echo \"--- Building charybdis_\${side} ---\"
            west build -s zmk/app -d build_\${side} \
                -b '${BOARD}' \
                -- \
                -DSHIELD=charybdis_\${side} \
                -DZMK_CONFIG=/zmk-workspace/config
            cp build_\${side}/zephyr/zmk.uf2 /build-out/charybdis_\${side}.uf2
            chown \"\${HOST_UID}:\${HOST_GID}\" /build-out/charybdis_\${side}.uf2
            chmod 644 /build-out/charybdis_\${side}.uf2
            echo \"==> build/charybdis_\${side}.uf2 ready\"
        done
    "

xattr -cr "$BUILD_OUT_DIR" 2>/dev/null || true

echo ""
echo "Done. Firmware in $BUILD_OUT_DIR/"
