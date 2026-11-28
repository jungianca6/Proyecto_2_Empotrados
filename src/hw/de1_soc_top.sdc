# Restricciones de tiempo para DE1-SoC
# Reloj principal: 50 MHz (periodo de 20 ns)

create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

derive_pll_clocks

derive_clock_uncertainty

# Cruces de reloj entre audio_dsp (CLOCK_50) y el serializador (audio_clk)
set_false_path -to [get_registers {soc|dsp|req_sync[0]}]
set_false_path -from [get_registers {soc|dsp|audio_left[*]}] -to [get_registers {audio_out|pending_left[*]}]
set_false_path -from [get_registers {soc|dsp|audio_right[*]}] -to [get_registers {audio_out|pending_right[*]}]
