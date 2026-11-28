# Agrega el componente audio_dsp al sistema.
# Uso (desde la raiz del repo):
#   qsys-script --search-path="$PWD/src/hw,\$" --script=src/scripts/add_audio_dsp.tcl
package require qsys

set sys [file join [pwd] src hw firstSystem.qsys]
load_system $sys

add_instance DSP audio_dsp 1.0
add_connection CLK.clk       DSP.clock
add_connection CLK.clk_reset DSP.reset

# Registros para el Nios V
add_connection NIOSV.data_manager DSP.csr
set_connection_parameter_value NIOSV.data_manager/DSP.csr baseAddress 0x20100
lock_avalon_base_address DSP.csr

# Lectura del anillo PCM (comparte s1 con el Nios V)
add_connection DSP.pcm PCM_RAM.s1
set_connection_parameter_value DSP.pcm/PCM_RAM.s1 baseAddress 0x0000

# Senales de audio hacia el top: dsp_sample_req, dsp_left, dsp_right
add_interface dsp conduit end
set_interface_property dsp EXPORT_OF DSP.audio

save_system $sys
