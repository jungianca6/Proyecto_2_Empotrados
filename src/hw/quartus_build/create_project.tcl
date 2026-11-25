project_new de1_soc_audio -overwrite
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEMA5F31C6
set_global_assignment -name TOP_LEVEL_ENTITY de1_soc_top
set_global_assignment -name VERILOG_FILE "../de1_soc_top.v"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/filters/ByPassFilter.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/filters/LowPassFilter.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/filters/HighPassFilter.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/filters/BassBoostFilter.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/filters/AudioFilter.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/audio/AudioFilterControlAvalon.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/audio/AudioSampleInputAvalon.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/audio/AudioOutputSerializer.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/audio/ToneGenerator.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "../rtl/audio/WM8731Config.sv"
set_global_assignment -name QIP_FILE "../gen/synthesis/firstSystem.qip"
set_global_assignment -name SDC_FILE "../de1_soc_top.sdc"
source "../de1_soc_top-pines.qsf"
project_close
