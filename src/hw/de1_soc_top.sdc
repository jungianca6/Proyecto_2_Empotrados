# Restricciones de tiempo para DE1-SoC
# Reloj principal: 50 MHz (periodo de 20 ns)

create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

derive_clock_uncertainty
