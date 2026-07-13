#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-build}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KAS_CONFIG="${KAS_CONFIG:-kas/tegra.yml}"
KAS_BUILD_DIR="${KAS_BUILD_DIR:-$ROOT_DIR/build}"
DL_DIR="${DL_DIR:-$ROOT_DIR/yocto-cache/downloads}"
SSTATE_DIR="${SSTATE_DIR:-$ROOT_DIR/yocto-cache/sstate-cache}"
BUILDHISTORY_DIR="${BUILDHISTORY_DIR:-$ROOT_DIR/yocto-cache/buildhistory}"
IMAGE_TARGET="${IMAGE_TARGET:-core-image-minimal}"
MACHINE="${MACHINE:-jetson-agx-orin-devkit}"
DEPLOY_DIR="$KAS_BUILD_DIR/tmp/deploy"

export KAS_WORK_DIR="$ROOT_DIR"
export KAS_BUILD_DIR
export DL_DIR
export SSTATE_DIR
export BB_NUMBER_THREADS="${BB_NUMBER_THREADS:-$(nproc)}"
export PARALLEL_MAKE="${PARALLEL_MAKE:--j$(nproc)}"

mkdir -p "$DL_DIR" "$SSTATE_DIR" "$BUILDHISTORY_DIR"
trap 'mkdir -p "$KAS_BUILD_DIR/conf" "$KAS_BUILD_DIR/tmp/log" "$DEPLOY_DIR/images/$MACHINE" "$DEPLOY_DIR/sdk" "$DEPLOY_DIR/licenses" "$DEPLOY_DIR/rpm" "$DEPLOY_DIR/ipk" "$DEPLOY_DIR/deb" "$DEPLOY_DIR/testresults"' EXIT

kas checkout "$KAS_CONFIG"

if [ ! -f "$KAS_BUILD_DIR/conf/local.conf" ]; then
  echo "Expected kas build configuration was not created at $KAS_BUILD_DIR/conf/local.conf" >&2
  exit 1
fi

if ! grep -q '^# CI cache and artifact configuration\.$' "$KAS_BUILD_DIR/conf/local.conf"; then
  cat >> "$KAS_BUILD_DIR/conf/local.conf" <<EOF

# CI cache and artifact configuration.
DL_DIR = "$DL_DIR"
SSTATE_DIR = "$SSTATE_DIR"
INHERIT += "buildhistory"
BUILDHISTORY_DIR = "$BUILDHISTORY_DIR"
BUILDHISTORY_COMMIT = "0"
EOF
fi

if [ -n "${YOCTO_CLEAN_RECIPES:-}" ]; then
  YOCTO_CLEAN_TASK="${YOCTO_CLEAN_TASK:-clean}"

  case "$YOCTO_CLEAN_TASK" in
    clean|cleansstate|cleanall)
      ;;
    *)
      echo "Unsupported YOCTO_CLEAN_TASK: $YOCTO_CLEAN_TASK" >&2
      echo "Supported values: clean, cleansstate, cleanall" >&2
      exit 2
      ;;
  esac

  for recipe in $YOCTO_CLEAN_RECIPES; do
    kas shell --keep-config-unchanged "$KAS_CONFIG" -c "bitbake '$recipe' -c '$YOCTO_CLEAN_TASK'"
  done
fi

case "$MODE" in
  validate)
    kas shell --keep-config-unchanged "$KAS_CONFIG" -c "bitbake -p"
    ;;
  build)
    kas build --keep-config-unchanged --target "$IMAGE_TARGET" "$KAS_CONFIG"
    kas build --keep-config-unchanged --target "$IMAGE_TARGET" -c populate_sdk "$KAS_CONFIG"
    kas shell --keep-config-unchanged "$KAS_CONFIG" -c "bitbake package-index"
    ;;
  testimage)
    kas build --keep-config-unchanged --target "$IMAGE_TARGET" -c testimage "$KAS_CONFIG"
    ;;
  *)
    echo "Usage: $0 [validate|build|testimage]" >&2
    exit 2
    ;;
esac
