# Agrega CTRL_RAM y PCM_RAM dual-port al sistema.
# Uso (desde la raíz del repo):
#   qsys-script --script=src/scripts/add_ctrl_pcm_ram.tcl
package require qsys

set sys [file join [pwd] src hw firstSystem.qsys]
load_system $sys

proc add_shared_ram {name size base} {
    add_instance $name altera_avalon_onchip_memory2
    set_instance_parameter_value $name dualPort true
    set_instance_parameter_value $name dataWidth 32
    set_instance_parameter_value $name memorySize $size
    set_instance_parameter_value $name initMemContent false
    set_instance_parameter_value $name resetrequest_enabled false

    add_connection CLK.clk       $name.clk1
    add_connection CLK.clk       $name.clk2
    add_connection CLK.clk_reset $name.reset1
    add_connection CLK.clk_reset $name.reset2

    # s1 -> Nios V; s2 queda libre para el lightweight bridge del HPS
    add_connection NIOSV.data_manager $name.s1
    set_connection_parameter_value NIOSV.data_manager/$name.s1 baseAddress $base
    lock_avalon_base_address $name.s1
}

add_shared_ram CTRL_RAM 4096  0x30000
add_shared_ram PCM_RAM  65536 0x40000

save_system $sys
