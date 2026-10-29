# Avaota-F1 V821 U-Boot

This repository contains the V821 U-Boot source at the top level. The
Avaota-F1 board inputs are under `board-config/avaota-f1/uboot`; Allwinner
image assembly is maintained by the separate `avaota-image-tools` repository.

Build with the Buildroot RISC-V32 compiler:

```sh
./scripts/build-u-boot-v821.sh \
  --variant sd \
  --output-dir ./output/u-boot-sd \
  --toolchain-prefix ./output/host/bin/riscv32-buildroot-linux-gnu- \
  --jobs "$(nproc)"
```

Variants are `nor`, `sd`, and `efex`. `nor` uses `storage_type = 3`, `sd`
uses `storage_type = 1`, and `efex` is the USB/FEL updater variant using the
NOR storage overlay. The SD U-Boot recognizes the Tina GPT common image and
the DOS/MBR raw SD image; their roots are p7 and p2 respectively. NOR uses
`/dev/mtdblock6`. The console is 115200 baud.

For PhoenixCard, the SD variant recalculates stale GPT entry-array CRCs
in-place and preserves the card-specific partition entries.

No Tina build tree or vendor toolchain is required.
