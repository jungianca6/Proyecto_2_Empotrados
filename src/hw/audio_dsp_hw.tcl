# Componente de Platform Designer: audio_dsp (REQ-04)
# Mapa de registros en hw/docs/audio_dsp.md
package require qsys

set_module_property NAME audio_dsp
set_module_property VERSION 1.0
set_module_property DISPLAY_NAME "Audio DSP CE-1113"
set_module_property GROUP "CE-1113"
set_module_property DESCRIPTION "Lector del anillo PCM, remuestreo, filtros y volumen"
set_module_property EDITABLE false

proc add_rtl {} {
    add_fileset_file audio_dsp.sv SYSTEM_VERILOG PATH rtl/audio_dsp/audio_dsp.sv TOP_LEVEL_FILE
    add_fileset_file fir_lp31.sv SYSTEM_VERILOG PATH rtl/audio_dsp/fir_lp31.sv
    add_fileset_file fir_defaults.svh SYSTEM_VERILOG_INCLUDE PATH rtl/audio_dsp/fir_defaults.svh
    add_fileset_file HighPassFilter.sv SYSTEM_VERILOG PATH rtl/filters/HighPassFilter.sv
    add_fileset_file BassBoostFilter.sv SYSTEM_VERILOG PATH rtl/filters/BassBoostFilter.sv
}

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL audio_dsp
add_rtl

add_fileset SIM_VERILOG SIM_VERILOG ""
set_fileset_property SIM_VERILOG TOP_LEVEL audio_dsp
add_rtl

# Reloj y reset
add_interface clock clock end
add_interface_port clock clk clk Input 1

add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset reset reset Input 1

# Esclavo de registros
add_interface csr avalon end
set_interface_property csr associatedClock clock
set_interface_property csr associatedReset reset
set_interface_property csr addressUnits WORDS
set_interface_property csr readLatency 1
set_interface_property csr readWaitTime 0
add_interface_port csr avs_address address Input 4
add_interface_port csr avs_read read Input 1
add_interface_port csr avs_write write Input 1
add_interface_port csr avs_writedata writedata Input 32
add_interface_port csr avs_readdata readdata Output 32

# Master hacia PCM_RAM
add_interface pcm avalon start
set_interface_property pcm associatedClock clock
set_interface_property pcm associatedReset reset
set_interface_property pcm addressUnits SYMBOLS
add_interface_port pcm avm_address address Output 16
add_interface_port pcm avm_read read Output 1
add_interface_port pcm avm_readdata readdata Input 32
add_interface_port pcm avm_waitrequest waitrequest Input 1
add_interface_port pcm avm_readdatavalid readdatavalid Input 1

# Senales hacia el serializador de audio
add_interface audio conduit end
add_interface_port audio sample_req sample_req Input 1
add_interface_port audio audio_left left Output 16
add_interface_port audio audio_right right Output 16
