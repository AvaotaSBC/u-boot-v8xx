# Avaota-F1 V821 U-Boot

U-Boot source is kept at the repository top level. Board inputs are under
`board-config/avaota-f1/uboot`; image assembly is in `avaota-image-tools`.

Build with the Buildroot RISC-V32 compiler:

```sh
./scripts/build-u-boot-v821.sh \
  --variant sd \
  --output-dir ./output/u-boot-sd \
  --toolchain-prefix ./output/host/bin/riscv32-buildroot-linux-gnu- \
  --jobs "$(nproc)"
```

Variants are `nor`, `sd`, and `efex`. `nor` uses `storage_type = 3`, `sd`
uses `storage_type = 1`, and `efex` is the USB/FEL updater variant. The raw
SD image uses DOS/MBR with rootfs at `/dev/mmcblk0p2`; SPI-NOR uses
`/dev/mtdblock6`. The console is 115200 baud.

The Allwinner IMAGEWTY image is for SPI-NOR/PhoenixSuit. Write the SD raw
image directly to an SD card.

No Tina build tree or vendor toolchain is required.
