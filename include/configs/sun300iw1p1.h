/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Configuration settings for the Allwinner A64 (sun50i) CPU
 */

#ifndef __CONFIG_H
#define __CONFIG_H

/* #define FPGA_PLATFORM */

#ifdef CONFIG_USB_EHCI_HCD
#define CONFIG_USB_EHCI_SUNXI
//#ifdef CONFIG_SUNXI_RTOS
//#define CONFIG_USB_MAX_CONTROLLER_COUNT			1
//#else
#define CONFIG_USB_MAX_CONTROLLER_COUNT 		1
//#endif
#endif

#define CONFIG_SUNXI_USB_PHYS	1

/* sram layout*/

// #define SUNXI_SYS_SRAM_BASE (SUNXI_SRAM_C_BASE)
// #define SUNXI_SYS_SRAM_SIZE (0x02021c00 - SUNXI_SRAM_C_BASE)
/* Platform special configuration */
#define SUNXI_SYS_SRAM_BASE (0x82200000 - 0x20000)
#define SUNXI_SYS_SRAM_SIZE (0x20000) /*128k*/

#define CONFIG_SYS_BOOTM_LEN 0x2000000
#define PHOENIX_PRIV_DATA_ADDR (0x02020800)

#define SUNXI_SYS_MALLOC_LEN	CONFIG_SUNXI_MALLOC_LEN

#define AW_SYS_NS16550_CLK		192000000

/*
 * Include common sunxi configuration where most the settings are
 */
#include <configs/sunxi-common.h>

/*
 * Keep the Tina boot path available when the environment partition cannot be
 * read.  PhoenixCard may rebuild the on-card partition metadata and leave
 * U-Boot without an "env" entry; the generic distro default is not suitable
 * here because this platform boots a vendor boot image from sunxi_flash.
 */
#ifndef CONFIG_SPL_BUILD
#undef CONFIG_BOOTCOMMAND
#define CONFIG_BOOTCOMMAND "run setargs_nand boot_normal"

#undef CONFIG_EXTRA_ENV_SETTINGS
#define CONFIG_EXTRA_ENV_SETTINGS \
	"earlyprintk=sunxi-uart,0x42500000\0" \
	"initcall_debug=0\0" \
	"console=ttyS0,115200\0" \
	"loglevel=8\0" \
	"mmc_root=/dev/mmcblk0p7\0" \
	"nor_root=/dev/mtdblock6\0" \
	"nand_root=ubi0_5\0" \
	"mtd_name=sys\0" \
	"init=/init\0" \
	"rdinit=/rdinit\0" \
	"rootfstype=squashfs,ro\0" \
	"cma=1M\0" \
	"riscv_partition=riscv0\0" \
	"root_partition=rootfs\0" \
	"boot_partition=boot\0" \
	"mac=\0" \
	"wifi_mac=\0" \
	"bt_mac=\0" \
	"specialstr=\0" \
	"arm-smmu-v3=0\0" \
	"setargs_mmc=setenv bootargs earlyprintk=${earlyprintk} initcall_debug=${initcall_debug} console=${console} loglevel=${loglevel} root=${mmc_root} rootwait rootfstype=${rootfstype} init=${init} rdinit=${rdinit} partitions=${partitions} cma=${cma} snum=${snum} mac_addr=${mac} wifi_mac=${wifi_mac} bt_mac=${bt_mac} selinux=0 specialstr=${specialstr} arm-smmu-v3.disable_bypass=${arm-smmu-v3}\0" \
	"setargs_nor=setenv bootargs earlyprintk=${earlyprintk} initcall_debug=${initcall_debug} console=${console} loglevel=${loglevel} root=${nor_root} rootwait rootfstype=${rootfstype} init=${init} rdinit=${rdinit} partitions=${partitions} cma=${cma} coherent_pool=${coherent_pool}\0" \
	"setargs_nand=setenv bootargs earlyprintk=${earlyprintk} initcall_debug=${initcall_debug} console=${console} loglevel=${loglevel} root=${nand_root} rootwait rootfstype=${rootfstype} init=${init} rdinit=${rdinit} partitions=${partitions} cma=${cma} snum=${snum} mac_addr=${mac} wifi_mac=${wifi_mac} bt_mac=${bt_mac} selinux=0 specialstr=${specialstr} arm-smmu-v3.disable_bypass=${arm-smmu-v3}\0" \
	"boot_normal=sunxi_flash read 82000000 ${boot_partition};bootm 82000000\0" \
	"boot_recovery=sunxi_flash read 82000000 recovery;bootm 82000000\0" \
	"boot_fastboot=fastboot\0" \
	"bootdelay=0\0"
#endif

#if !IS_ENABLED(CONFIG_RISCV)
#define CONFIG_SYS_NONCACHED_MEMORY (1 << 20)
#endif

#endif /* __CONFIG_H */
