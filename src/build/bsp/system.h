/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'NIOSV' in SOPC Builder design 'firstSystem'
 * SOPC Builder design path: /home/dell/Escritorio/Proyecto_2_Empotrados/src/hw/firstSystem.sopcinfo
 *
 * Generated: Thu Nov 26 23:11:48 CST 2026
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "intel_niosv_m"
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_DATA_ADDR_WIDTH 0x20
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HAS_CSR_SUPPORT 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x20
#define ALT_CPU_INT_MODE 0
#define ALT_CPU_MTIME_OFFSET 0x00020000
#define ALT_CPU_NAME "NIOSV"
#define ALT_CPU_NIOSV_CORE_VARIANT 1
#define ALT_CPU_NUM_GPR 32
#define ALT_CPU_RESET_ADDR 0x00000000
#define ALT_CPU_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define ALT_CPU_TIMER_DEVICE_TYPE 2


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define ABBOTTSLAKE_CPU_FREQ 50000000u
#define ABBOTTSLAKE_DATA_ADDR_WIDTH 0x20
#define ABBOTTSLAKE_DCACHE_LINE_SIZE 0
#define ABBOTTSLAKE_DCACHE_LINE_SIZE_LOG2 0
#define ABBOTTSLAKE_DCACHE_SIZE 0
#define ABBOTTSLAKE_HAS_CSR_SUPPORT 1
#define ABBOTTSLAKE_HAS_DEBUG_STUB
#define ABBOTTSLAKE_ICACHE_LINE_SIZE 0
#define ABBOTTSLAKE_ICACHE_LINE_SIZE_LOG2 0
#define ABBOTTSLAKE_ICACHE_SIZE 0
#define ABBOTTSLAKE_INST_ADDR_WIDTH 0x20
#define ABBOTTSLAKE_INT_MODE 0
#define ABBOTTSLAKE_MTIME_OFFSET 0x00020000
#define ABBOTTSLAKE_NIOSV_CORE_VARIANT 1
#define ABBOTTSLAKE_NUM_GPR 32
#define ABBOTTSLAKE_RESET_ADDR 0x00000000
#define ABBOTTSLAKE_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define ABBOTTSLAKE_TIMER_DEVICE_TYPE 2


/*
 * CTRL_RAM configuration
 *
 */

#define ALT_MODULE_CLASS_CTRL_RAM altera_avalon_onchip_memory2
#define CTRL_RAM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define CTRL_RAM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define CTRL_RAM_BASE 0x30000
#define CTRL_RAM_CONTENTS_INFO ""
#define CTRL_RAM_DUAL_PORT 1
#define CTRL_RAM_GUI_RAM_BLOCK_TYPE "AUTO"
#define CTRL_RAM_INIT_CONTENTS_FILE "firstSystem_CTRL_RAM"
#define CTRL_RAM_INIT_MEM_CONTENT 0
#define CTRL_RAM_INSTANCE_ID "NONE"
#define CTRL_RAM_IRQ -1
#define CTRL_RAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define CTRL_RAM_NAME "/dev/CTRL_RAM"
#define CTRL_RAM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define CTRL_RAM_RAM_BLOCK_TYPE "AUTO"
#define CTRL_RAM_READ_DURING_WRITE_MODE "DONT_CARE"
#define CTRL_RAM_SINGLE_CLOCK_OP 0
#define CTRL_RAM_SIZE_MULTIPLE 1
#define CTRL_RAM_SIZE_VALUE 4096
#define CTRL_RAM_SPAN 4096
#define CTRL_RAM_TYPE "altera_avalon_onchip_memory2"
#define CTRL_RAM_WRITABLE 1


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __INTEL_NIOSV_M


/*
 * JTAG configuration
 *
 */

#define ALT_MODULE_CLASS_JTAG altera_avalon_jtag_uart
#define JTAG_BASE 0x20080
#define JTAG_IRQ -1
#define JTAG_IRQ_INTERRUPT_CONTROLLER_ID -1
#define JTAG_NAME "/dev/JTAG"
#define JTAG_READ_DEPTH 64
#define JTAG_READ_THRESHOLD 8
#define JTAG_SPAN 8
#define JTAG_TYPE "altera_avalon_jtag_uart"
#define JTAG_WRITE_DEPTH 64
#define JTAG_WRITE_THRESHOLD 8


/*
 * NIOSV_dm_agent configuration
 *
 */

#define ALT_MODULE_CLASS_NIOSV_dm_agent intel_niosv_m
#define NIOSV_DM_AGENT_BASE 0x10000
#define NIOSV_DM_AGENT_CPU_FREQ 50000000u
#define NIOSV_DM_AGENT_DATA_ADDR_WIDTH 0x20
#define NIOSV_DM_AGENT_DCACHE_LINE_SIZE 0
#define NIOSV_DM_AGENT_DCACHE_LINE_SIZE_LOG2 0
#define NIOSV_DM_AGENT_DCACHE_SIZE 0
#define NIOSV_DM_AGENT_HAS_CSR_SUPPORT 1
#define NIOSV_DM_AGENT_HAS_DEBUG_STUB
#define NIOSV_DM_AGENT_ICACHE_LINE_SIZE 0
#define NIOSV_DM_AGENT_ICACHE_LINE_SIZE_LOG2 0
#define NIOSV_DM_AGENT_ICACHE_SIZE 0
#define NIOSV_DM_AGENT_INST_ADDR_WIDTH 0x20
#define NIOSV_DM_AGENT_INTERRUPT_CONTROLLER_ID 0
#define NIOSV_DM_AGENT_INT_MODE 0
#define NIOSV_DM_AGENT_IRQ -1
#define NIOSV_DM_AGENT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define NIOSV_DM_AGENT_MTIME_OFFSET 0x00020000
#define NIOSV_DM_AGENT_NAME "/dev/NIOSV_dm_agent"
#define NIOSV_DM_AGENT_NIOSV_CORE_VARIANT 1
#define NIOSV_DM_AGENT_NUM_GPR 32
#define NIOSV_DM_AGENT_RESET_ADDR 0x00000000
#define NIOSV_DM_AGENT_SPAN 65536
#define NIOSV_DM_AGENT_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define NIOSV_DM_AGENT_TIMER_DEVICE_TYPE 2
#define NIOSV_DM_AGENT_TYPE "intel_niosv_m"


/*
 * NIOSV_timer_sw_agent configuration
 *
 */

#define ALT_MODULE_CLASS_NIOSV_timer_sw_agent intel_niosv_m
#define NIOSV_TIMER_SW_AGENT_BASE 0x20000
#define NIOSV_TIMER_SW_AGENT_CPU_FREQ 50000000u
#define NIOSV_TIMER_SW_AGENT_DATA_ADDR_WIDTH 0x20
#define NIOSV_TIMER_SW_AGENT_DCACHE_LINE_SIZE 0
#define NIOSV_TIMER_SW_AGENT_DCACHE_LINE_SIZE_LOG2 0
#define NIOSV_TIMER_SW_AGENT_DCACHE_SIZE 0
#define NIOSV_TIMER_SW_AGENT_HAS_CSR_SUPPORT 1
#define NIOSV_TIMER_SW_AGENT_HAS_DEBUG_STUB
#define NIOSV_TIMER_SW_AGENT_ICACHE_LINE_SIZE 0
#define NIOSV_TIMER_SW_AGENT_ICACHE_LINE_SIZE_LOG2 0
#define NIOSV_TIMER_SW_AGENT_ICACHE_SIZE 0
#define NIOSV_TIMER_SW_AGENT_INST_ADDR_WIDTH 0x20
#define NIOSV_TIMER_SW_AGENT_INTERRUPT_CONTROLLER_ID 0
#define NIOSV_TIMER_SW_AGENT_INT_MODE 0
#define NIOSV_TIMER_SW_AGENT_IRQ -1
#define NIOSV_TIMER_SW_AGENT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define NIOSV_TIMER_SW_AGENT_MTIME_OFFSET 0x00020000
#define NIOSV_TIMER_SW_AGENT_NAME "/dev/NIOSV_timer_sw_agent"
#define NIOSV_TIMER_SW_AGENT_NIOSV_CORE_VARIANT 1
#define NIOSV_TIMER_SW_AGENT_NUM_GPR 32
#define NIOSV_TIMER_SW_AGENT_RESET_ADDR 0x00000000
#define NIOSV_TIMER_SW_AGENT_SPAN 64
#define NIOSV_TIMER_SW_AGENT_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define NIOSV_TIMER_SW_AGENT_TIMER_DEVICE_TYPE 2
#define NIOSV_TIMER_SW_AGENT_TYPE "intel_niosv_m"


/*
 * PCM_RAM configuration
 *
 */

#define ALT_MODULE_CLASS_PCM_RAM altera_avalon_onchip_memory2
#define PCM_RAM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define PCM_RAM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define PCM_RAM_BASE 0x40000
#define PCM_RAM_CONTENTS_INFO ""
#define PCM_RAM_DUAL_PORT 1
#define PCM_RAM_GUI_RAM_BLOCK_TYPE "AUTO"
#define PCM_RAM_INIT_CONTENTS_FILE "firstSystem_PCM_RAM"
#define PCM_RAM_INIT_MEM_CONTENT 0
#define PCM_RAM_INSTANCE_ID "NONE"
#define PCM_RAM_IRQ -1
#define PCM_RAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PCM_RAM_NAME "/dev/PCM_RAM"
#define PCM_RAM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define PCM_RAM_RAM_BLOCK_TYPE "AUTO"
#define PCM_RAM_READ_DURING_WRITE_MODE "DONT_CARE"
#define PCM_RAM_SINGLE_CLOCK_OP 0
#define PCM_RAM_SIZE_MULTIPLE 1
#define PCM_RAM_SIZE_VALUE 65536
#define PCM_RAM_SPAN 65536
#define PCM_RAM_TYPE "altera_avalon_onchip_memory2"
#define PCM_RAM_WRITABLE 1


/*
 * RAM configuration
 *
 */

#define ALT_MODULE_CLASS_RAM altera_avalon_onchip_memory2
#define RAM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define RAM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define RAM_BASE 0x0
#define RAM_CONTENTS_INFO ""
#define RAM_DUAL_PORT 0
#define RAM_GUI_RAM_BLOCK_TYPE "AUTO"
#define RAM_INIT_CONTENTS_FILE "firstSystem_RAM"
#define RAM_INIT_MEM_CONTENT 1
#define RAM_INSTANCE_ID "NONE"
#define RAM_IRQ -1
#define RAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RAM_NAME "/dev/RAM"
#define RAM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define RAM_RAM_BLOCK_TYPE "AUTO"
#define RAM_READ_DURING_WRITE_MODE "DONT_CARE"
#define RAM_SINGLE_CLOCK_OP 0
#define RAM_SIZE_MULTIPLE 1
#define RAM_SIZE_VALUE 65536
#define RAM_SPAN 65536
#define RAM_TYPE "altera_avalon_onchip_memory2"
#define RAM_WRITABLE 1


/*
 * REG_BTN configuration
 *
 */

#define ALT_MODULE_CLASS_REG_BTN altera_avalon_pio
#define REG_BTN_BASE 0x20070
#define REG_BTN_BIT_CLEARING_EDGE_REGISTER 0
#define REG_BTN_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_BTN_CAPTURE 1
#define REG_BTN_DATA_WIDTH 4
#define REG_BTN_DO_TEST_BENCH_WIRING 0
#define REG_BTN_DRIVEN_SIM_VALUE 0
#define REG_BTN_EDGE_TYPE "FALLING"
#define REG_BTN_FREQ 50000000
#define REG_BTN_HAS_IN 1
#define REG_BTN_HAS_OUT 0
#define REG_BTN_HAS_TRI 0
#define REG_BTN_IRQ 0
#define REG_BTN_IRQ_INTERRUPT_CONTROLLER_ID 0
#define REG_BTN_IRQ_TYPE "LEVEL"
#define REG_BTN_NAME "/dev/REG_BTN"
#define REG_BTN_RESET_VALUE 0
#define REG_BTN_SPAN 16
#define REG_BTN_TYPE "altera_avalon_pio"


/*
 * REG_HEX configuration
 *
 */

#define ALT_MODULE_CLASS_REG_HEX altera_avalon_pio
#define REG_HEX_BASE 0x20050
#define REG_HEX_BIT_CLEARING_EDGE_REGISTER 0
#define REG_HEX_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_HEX_CAPTURE 0
#define REG_HEX_DATA_WIDTH 32
#define REG_HEX_DO_TEST_BENCH_WIRING 0
#define REG_HEX_DRIVEN_SIM_VALUE 0
#define REG_HEX_EDGE_TYPE "NONE"
#define REG_HEX_FREQ 50000000
#define REG_HEX_HAS_IN 0
#define REG_HEX_HAS_OUT 1
#define REG_HEX_HAS_TRI 0
#define REG_HEX_IRQ -1
#define REG_HEX_IRQ_INTERRUPT_CONTROLLER_ID -1
#define REG_HEX_IRQ_TYPE "NONE"
#define REG_HEX_NAME "/dev/REG_HEX"
#define REG_HEX_RESET_VALUE 0
#define REG_HEX_SPAN 16
#define REG_HEX_TYPE "altera_avalon_pio"


/*
 * REG_LEDS configuration
 *
 */

#define ALT_MODULE_CLASS_REG_LEDS altera_avalon_pio
#define REG_LEDS_BASE 0x20040
#define REG_LEDS_BIT_CLEARING_EDGE_REGISTER 0
#define REG_LEDS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_LEDS_CAPTURE 0
#define REG_LEDS_DATA_WIDTH 10
#define REG_LEDS_DO_TEST_BENCH_WIRING 0
#define REG_LEDS_DRIVEN_SIM_VALUE 0
#define REG_LEDS_EDGE_TYPE "NONE"
#define REG_LEDS_FREQ 50000000
#define REG_LEDS_HAS_IN 0
#define REG_LEDS_HAS_OUT 1
#define REG_LEDS_HAS_TRI 0
#define REG_LEDS_IRQ -1
#define REG_LEDS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define REG_LEDS_IRQ_TYPE "NONE"
#define REG_LEDS_NAME "/dev/REG_LEDS"
#define REG_LEDS_RESET_VALUE 0
#define REG_LEDS_SPAN 16
#define REG_LEDS_TYPE "altera_avalon_pio"


/*
 * REG_SW configuration
 *
 */

#define ALT_MODULE_CLASS_REG_SW altera_avalon_pio
#define REG_SW_BASE 0x20060
#define REG_SW_BIT_CLEARING_EDGE_REGISTER 0
#define REG_SW_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_SW_CAPTURE 0
#define REG_SW_DATA_WIDTH 10
#define REG_SW_DO_TEST_BENCH_WIRING 0
#define REG_SW_DRIVEN_SIM_VALUE 0
#define REG_SW_EDGE_TYPE "NONE"
#define REG_SW_FREQ 50000000
#define REG_SW_HAS_IN 1
#define REG_SW_HAS_OUT 0
#define REG_SW_HAS_TRI 0
#define REG_SW_IRQ 1
#define REG_SW_IRQ_INTERRUPT_CONTROLLER_ID 0
#define REG_SW_IRQ_TYPE "LEVEL"
#define REG_SW_NAME "/dev/REG_SW"
#define REG_SW_RESET_VALUE 0
#define REG_SW_SPAN 16
#define REG_SW_TYPE "altera_avalon_pio"


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone V"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/JTAG"
#define ALT_STDERR_BASE 0x20080
#define ALT_STDERR_DEV JTAG
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/JTAG"
#define ALT_STDIN_BASE 0x20080
#define ALT_STDIN_DEV JTAG
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/JTAG"
#define ALT_STDOUT_BASE 0x20080
#define ALT_STDOUT_DEV JTAG
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "firstSystem"
#define ALT_SYS_CLK_TICKS_PER_SEC ALT_CPU_TICKS_PER_SEC
#define ALT_TIMESTAMP_CLK_TIMER_DEVICE_TYPE ALT_CPU_TIMER_DEVICE_TYPE


/*
 * hal2 configuration
 *
 */

#define ALT_MAX_FD 32
#define ALT_SYS_CLK NIOSV
#define ALT_TIMESTAMP_CLK NIOSV
#define INTEL_FPGA_DFL_START_ADDRESS 0xffffffffffffffff
#define INTEL_FPGA_USE_DFL_WALKER 0


/*
 * intel_niosv_m_hal_driver configuration
 *
 */

#define NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND 1000

#endif /* __SYSTEM_H_ */
