onerror {resume}
add wave -divider Control
add wave /tb_audio_dsp/clk /tb_audio_dsp/reset /tb_audio_dsp/sample_req
add wave /tb_audio_dsp/dut/state
add wave -radix unsigned /tb_audio_dsp/dut/filter_sel
add wave -divider "Avalon-MM esclavo"
add wave /tb_audio_dsp/avs_write /tb_audio_dsp/avs_read
add wave -radix hexadecimal /tb_audio_dsp/avs_address /tb_audio_dsp/avs_writedata /tb_audio_dsp/avs_readdata
add wave -divider "Avalon-MM master"
add wave /tb_audio_dsp/avm_read /tb_audio_dsp/avm_waitrequest /tb_audio_dsp/avm_readdatavalid
add wave -radix hexadecimal /tb_audio_dsp/avm_address /tb_audio_dsp/avm_readdata
add wave -radix unsigned /tb_audio_dsp/dut/pcm_rd
add wave -divider Audio
add wave -format analog-step -height 80 -min -32768 -max 32767 -radix decimal /tb_audio_dsp/dut/x_l
add wave -format analog-step -height 80 -min -32768 -max 32767 -radix decimal /tb_audio_dsp/audio_left
add wave -format analog-step -height 80 -min -32768 -max 32767 -radix decimal /tb_audio_dsp/audio_right
run -all
wave zoom full
