cmake_minimum_required(VERSION 3.14)

add_subdirectory(../bsp bsp)

include(../bsp/toolchain.cmake)

project(firstSystem)

enable_language(ASM)
enable_language(C)
enable_language(CXX)

add_executable(firstSystem.elf)

target_sources(firstSystem.elf
    PRIVATE
        ../../sw/src/main.c
)

target_include_directories(firstSystem.elf
    PRIVATE
    PUBLIC
)

target_link_libraries(firstSystem.elf
    PRIVATE
        -T "${BspLinkerScript}" -nostdlib
        "${ExtraArchiveLibraries}"
        -Wl,--start-group "${BspLibraryName}" -lc -lstdc++ -lgcc -lm -Wl,--end-group
)

# Create objdump from ELF.
set(objdump firstSystem.elf.objdump)
add_custom_command(
    OUTPUT "${objdump}"
    DEPENDS firstSystem.elf
    COMMAND "${ToolchainObjdump}" "${ToolchainObjdumpFlags}" firstSystem.elf >
            "${objdump}"
    COMMENT "Creating ${objdump}."
    VERBATIM
)
add_custom_target(create-objdump ALL DEPENDS "${objdump}")

# Report space free for stack + heap. Note that the file below is never created
# so the report is always output on build.
set(stack_report_file firstSystem.elf.stack_report)
add_custom_command(
    OUTPUT "${stack_report_file}"
    DEPENDS firstSystem.elf
    COMMAND niosv-stack-report -p "${ToolchainPrefix}" firstSystem.elf
    COMMENT "Reporting memory available for stack + heap in firstSystem.elf."
    VERBATIM
)
add_custom_target(niosv-stack-report ALL DEPENDS "${stack_report_file}")

# Generate HEX file(s) from firstSystem.elf using elf2hex tool.
# Note : If ECC Full is enabled, width of 39 is set for NiosV TCM. Otherwise, 32.
add_custom_command(
    OUTPUT "PCM_RAM.hex"
    DEPENDS firstSystem.elf
    COMMAND elf2hex firstSystem.elf -o PCM_RAM.hex -b 0x00040000 -w 32 -e 0x0004FFFF -r 4
    COMMENT "Creating PCM_RAM.hex."
    VERBATIM
)
add_custom_command(
    OUTPUT "CTRL_RAM.hex"
    DEPENDS firstSystem.elf
    COMMAND elf2hex firstSystem.elf -o CTRL_RAM.hex -b 0x00030000 -w 32 -e 0x00030FFF -r 4
    COMMENT "Creating CTRL_RAM.hex."
    VERBATIM
)
add_custom_command(
    OUTPUT "RAM.hex"
    DEPENDS firstSystem.elf
    COMMAND elf2hex firstSystem.elf -o RAM.hex -b 0x00000000 -w 32 -e 0x0000FFFF -r 4
    COMMENT "Creating RAM.hex."
    VERBATIM
)
add_custom_target(create-hex ALL DEPENDS "RAM.hex" "CTRL_RAM.hex" "PCM_RAM.hex")
