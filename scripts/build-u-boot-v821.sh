#!/bin/sh

set -eu

usage() {
	cat <<'EOF'
Usage: build-u-boot-v821.sh --variant VARIANT --output-dir DIR [options]

Build the Avaota-F1 V821 U-Boot variant with Buildroot's RISC-V32 compiler.

Options:
  --variant VARIANT        nor, sd, or efex
  --output-dir DIR         U-Boot out-of-tree build directory (required)
  --toolchain-prefix PATH  .../host/bin/riscv32-buildroot-linux-gnu-
  --jobs N                 parallel build jobs
EOF
}

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UBOOT_DIR=$REPO_DIR
BOARD_DIR=$REPO_DIR/board-config/avaota-f1/uboot
VARIANT=
OUTPUT_DIR=
TOOLCHAIN_PREFIX=
JOBS=

while [ "$#" -gt 0 ]; do
	case "$1" in
		--variant) VARIANT=$2; shift 2 ;;
		--output-dir) OUTPUT_DIR=$2; shift 2 ;;
		--toolchain-prefix) TOOLCHAIN_PREFIX=$2; shift 2 ;;
		--jobs) JOBS=$2; shift 2 ;;
		-h|--help) usage; exit 0 ;;
		*) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

case "$VARIANT" in
	nor)
		DEFCONFIG=sun300iw1p1_v821_nor_defconfig
		BOARD_VARIANT_DIR=$BOARD_DIR/nor
		;;
	sd)
		DEFCONFIG=sun300iw1p1_v821_defconfig
		BOARD_VARIANT_DIR=$BOARD_DIR/sd
		;;
	efex)
		# Tina builds the FEL/USB updater from its dedicated efex defconfig,
		# while the board storage overlay still selects the NOR boot medium.
		DEFCONFIG=sun300iw1p1_efex_defconfig
		BOARD_VARIANT_DIR=$BOARD_DIR/nor
		;;
	*) echo "error: --variant must be nor, sd, or efex" >&2; exit 2 ;;
esac

if [ -z "$OUTPUT_DIR" ]; then
	OUTPUT_DIR=$REPO_DIR/build/$VARIANT
fi
if [ -z "$JOBS" ]; then
	JOBS=$(command -v nproc >/dev/null 2>&1 && nproc || echo 1)
fi

if [ -z "$TOOLCHAIN_PREFIX" ]; then
	if command -v riscv32-buildroot-linux-gnu-gcc >/dev/null 2>&1; then
		TOOLCHAIN_PREFIX=$(command -v riscv32-buildroot-linux-gnu-gcc)
		TOOLCHAIN_PREFIX=$(echo "$TOOLCHAIN_PREFIX" | sed 's/gcc$//')
	else
		echo "error: Buildroot RISC-V32 compiler not found; pass --toolchain-prefix" >&2
		exit 1
	fi
fi

CC=$TOOLCHAIN_PREFIX"gcc"
if [ ! -x "$CC" ]; then
	echo "error: compiler not found: $CC" >&2
	exit 1
fi
MACHINE=$($CC -dumpmachine)
case "$MACHINE" in
	riscv32-*) ;;
	*) echo "error: expected a RISC-V32 Buildroot compiler, got $MACHINE" >&2; exit 1 ;;
esac

for path in "$UBOOT_DIR/Makefile" "$BOARD_VARIANT_DIR/uboot-board.dts"; do
	[ -f "$path" ] || { echo "error: missing U-Boot input: $path" >&2; exit 1; }
done

# Prefer the DTC supplied by Buildroot's host directory (or the host system),
# so a clean checkout does not depend on Tina's ignored, prebuilt
# scripts/dtc/dtc.  The repository copy remains a fallback for vendor hosts
# that intentionally do not install DTC system-wide.
DTC=$(command -v dtc 2>/dev/null || true)
if [ -z "$DTC" ]; then
	DTC=$UBOOT_DIR/scripts/dtc/dtc
fi
[ -x "$DTC" ] || {
	echo "error: no usable DTC found; install host dtc or provide $UBOOT_DIR/scripts/dtc/dtc" >&2
	exit 1
}

mkdir -p "$OUTPUT_DIR"

cleanup_source_dts() {
	[ -f "$UBOOT_DIR/arch/riscv/dts/.board-uboot.dts" ] &&
		rm -f "$UBOOT_DIR/arch/riscv/dts/.board-uboot.dts"
}
trap cleanup_source_dts EXIT HUP INT TERM

echo "==> building U-Boot $VARIANT with $MACHINE"
make -C "$UBOOT_DIR" O="$OUTPUT_DIR" ARCH=riscv CROSS_COMPILE="$TOOLCHAIN_PREFIX" \
	buildconfig=/dev/null LICHEE_BOARD_CONFIG_DIR="$BOARD_VARIANT_DIR" "$DEFCONFIG"
make -C "$UBOOT_DIR" O="$OUTPUT_DIR" ARCH=riscv CROSS_COMPILE="$TOOLCHAIN_PREFIX" \
	buildconfig=/dev/null DTC="$DTC" LICHEE_BOARD_CONFIG_DIR="$BOARD_VARIANT_DIR" \
	KCFLAGS="-Wno-error=array-bounds -Wno-error=array-parameter -Wno-error=maybe-uninitialized" \
	-j"$JOBS"

[ -f "$OUTPUT_DIR/u-boot.bin" ] || {
	echo "error: U-Boot $VARIANT build did not produce u-boot.bin" >&2
	exit 1
}

echo "U-Boot $VARIANT: $OUTPUT_DIR/u-boot.bin"
