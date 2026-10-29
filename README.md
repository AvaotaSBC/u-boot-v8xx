# Avaota-F1 V821 U-Boot

This repository contains the V821 U-Boot source directly at its top level and
the Avaota-F1 U-Boot board configuration. It is the U-Boot source component of
the Buildroot port; Allwinner Phoenix/Dragon image assembly is maintained in
the separate `avaota-image-tools` repository.

## Contents

- `arch/`, `board/`, `drivers/`, `include/`, `scripts/`, and the other
  top-level source directories: vendor U-Boot 2018 source for the V821
  RISC-V platform.
- `board-config/avaota-f1/uboot/nor/`: SPI-NOR board DTS input for the NOR and
  FEL/USB updater variants.
- `board-config/avaota-f1/uboot/sd/`: SD-card board DTS input.
- `scripts/build-u-boot-v821.sh`: out-of-tree Buildroot-toolchain build
  wrapper.

The `nor` and `sd` variants select different storage boot paths in U-Boot and
are built separately because they use different `storage_type` values in
their board DTS inputs. The `efex` variant is a third, dedicated U-Boot build
using `sun300iw1p1_efex_defconfig`; it uses the NOR board DTS
(`storage_type = 3`) because it is the USB/FEL updater image for the
NOR-capable common
Phoenix image. It is not a renamed copy of either runtime U-Boot.

The SD variant supports both V821 SD layouts at runtime. The direct raw image
uses a DOS/MBR disk at LBA 0. Its host-visible entries are `boot` at LBA
52352, `rootfs` at LBA 67712 (`/dev/mmcblk0p2`), `rootfs_data` at LBA 87808,
and `UDISK` at LBA 98048. The fixed Allwinner Boot0 compatibility GPT map is
stored at LBA 1 with invalid CRCs, so it does not override the DOS MBR. The
partitions used by `sunxi_flash read` and environment loading are resolved by
the V821 map at `boot-resource=41088`, `env=51328`, `env-redund=51840`,
`boot=52352`, `private=62592`, and `riscv0=63616`. For this raw layout,
U-Boot selects the DOS parser and does not append `gpt=1`.

The common PhoenixCard/PhoenixSuit image uses Tina's valid GPT at LBA 0/1.
U-Boot selects the EFI/GPT parser for it, enumerates the NOR-compatible GPT
entries, derives `rootfs` as `/dev/mmcblk0p7`, and appends `gpt=1` like Tina.
The fixed DOS compatibility mapping is only enabled after U-Boot detects the
raw image's non-protective MBR, so the common image cannot accidentally read
the raw SD offsets for `boot`.

Some PhoenixCard versions leave the common image's primary GPT header valid
but its entry array stale after writing a card-specific final partition. The
SD U-Boot checks the backup GPT at the physical end of the card, copies a
valid backup entry array into the primary array, and repairs the primary
header CRC before loading `env`. If no valid backup is available, it retains a
narrow primary-array CRC repair for older cards.

The NOR variant retains the Allwinner logical MTD map. Its `rootfs` entry is
the seventh logical entry (zero-based Linux MTD `mtd6`), while
`rootfs_data` is `mtd7`; the boot environment therefore uses
`/dev/mtdblock6`. U-Boot supplies
`mbr_offset=2016*512` for the kernel's `sunxipart` parser.

## Build

The wrapper requires Buildroot's internal RISC-V32 compiler:

```sh
./scripts/build-u-boot-v821.sh \
  --variant sd \
  --output-dir ./output/u-boot-sd \
  --toolchain-prefix ./output/host/bin/riscv32-buildroot-linux-gnu- \
  --jobs "$(nproc)"
```

The image-tools repository invokes this wrapper for both `nor` and `sd` and
then inserts the resulting `u-boot.bin` files into the Allwinner boot package.
No Tina build environment or vendor toolchain is required.
