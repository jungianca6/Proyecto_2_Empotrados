#!/usr/bin/env python3
"""Genera add_hps.tcl copiando los parametros del HPS de un .qsys de Terasic.

Uso: python3 gen_hps_tcl.py SOC_SYSTEM.qsys SALIDA.tcl
"""
import sys
import xml.etree.ElementTree as ET

SKIP = {
    "deviceFamily", "deviceFeatures", "device", "deviceSpeedGrade",
    "FPGA_PERIPHERAL_INPUT_CLOCK_FREQ_SDIO_CLK_IN",
}

# Cambios respecto al GHRD: solo el lightweight bridge, sin interfaces extra
OVERRIDES = [
    ("F2S_Width", "0"),
    ("S2F_Width", "0"),
    ("LWH2F_Enable", "true"),
    ("F2SINTERRUPT_Enable", "false"),
    ("F2SCLK_COLDRST_Enable", "false"),
    ("F2SCLK_WARMRST_Enable", "false"),
    ("F2SCLK_DBGRST_Enable", "false"),
    ("STM_Enable", "false"),
]


def q(s):
    for ch in ("\\", '"', "$", "[", "]"):
        s = s.replace(ch, "\\" + ch)
    return '"' + s + '"'


def tcl_value(v):
    # Los parametros de tipo lista vienen separados por comas
    if "," in v:
        return "[list " + " ".join(q(e) for e in v.split(",")) + "]"
    return q(v)


def main(src, out):
    root = ET.parse(src).getroot()
    hps = next((m for m in root.iter("module") if m.get("kind") == "altera_hps"), None)
    if hps is None:
        sys.exit("No encontre un modulo altera_hps en " + src)

    override_names = {n for n, _ in OVERRIDES}
    params = []
    for p in hps.findall("parameter"):
        name = p.get("name")
        val = p.get("value")
        if val is None:
            val = p.text or ""
        if name.startswith("AUTO_") or name in SKIP or name in override_names:
            continue
        params.append((name, val))

    print("HPS origen:", hps.get("name"), "| version", hps.get("version"))
    print("Parametros copiados:", len(params))
    print("Parametros con lista (convertidos a lista Tcl):",
          sum(1 for _, v in params if "," in v))

    with open(out, "w") as f:
        f.write("# Generado por gen_hps_tcl.py a partir de %s\n" % src)
        f.write("# Uso (desde la raiz del repo): qsys-script --script=src/scripts/add_hps.tcl\n")
        f.write("package require qsys\n\n")
        f.write("set sys [file join [pwd] src hw firstSystem.qsys]\n")
        f.write("load_system $sys\n\n")
        f.write("if {[lsearch -exact [get_instances] hps_0] >= 0} {\n")
        f.write('    puts "INFO: hps_0 ya existe, no se hace nada"\n')
        f.write("    return\n}\n\n")
        f.write("add_instance hps_0 altera_hps\n\n")
        f.write("proc setp {n v} {\n    set_instance_parameter_value hps_0 $n $v\n}\n\n")
        for n, v in params:
            f.write("setp %s %s\n" % (n, tcl_value(v)))
        f.write("\n# Solo el lightweight bridge hacia la FPGA, sin interfaces extra\n")
        for n, v in OVERRIDES:
            f.write("setp %s %s\n" % (n, q(v)))
        f.write("""
# Reloj y puente (el lightweight bridge no tiene entrada de reset en esta version)
add_connection CLK.clk hps_0.h2f_lw_axi_clock
add_connection hps_0.h2f_lw_axi_master CTRL_RAM.s2
set_connection_parameter_value hps_0.h2f_lw_axi_master/CTRL_RAM.s2 baseAddress 0x00000
lock_avalon_base_address CTRL_RAM.s2
add_connection hps_0.h2f_lw_axi_master PCM_RAM.s2
set_connection_parameter_value hps_0.h2f_lw_axi_master/PCM_RAM.s2 baseAddress 0x10000
lock_avalon_base_address PCM_RAM.s2

# Interfaces exportadas
add_interface memory conduit end
set_interface_property memory EXPORT_OF hps_0.memory
add_interface hps_io conduit end
set_interface_property hps_io EXPORT_OF hps_0.hps_io

save_system $sys
""")
    print("Escrito", out)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
