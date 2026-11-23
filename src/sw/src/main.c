#include <stdint.h>

// Direcciones de los perifericos del SoC firstSystem
#define LEDS_BASE 0x00020040u
#define SW_BASE   0x00020060u

#define REG32(addr) (*(volatile uint32_t *)(addr))

int main(void)
{
    while (1)
    {
        // Leer los 10 switches
        uint32_t switches = REG32(SW_BASE) & 0x3FFu;

        // Mostrar su estado en los LEDs
        REG32(LEDS_BASE) = switches;
    }

    return 0;
}
