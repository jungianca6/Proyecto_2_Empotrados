#include "system.h"

#include "buttons.h"
#include "player.h"

#include <stdint.h>

int main(void)
{
    player_t player;

    /*
     * 1. Inicializar player.
     */
    player_init(&player);

    /*
     * 2. Configurar PIO de botones.
     *
     *    - Deshabilitar IRQ del PIO.
     *    - Limpiar Edge Capture.
     */
    buttons_init();

    /*
     * 3. Registrar ISR de botones
     *    en el sistema de interrupciones
     *    del Nios V/m.
     *
     * TODO: Implementar usando el mecanismo
     *       correspondiente al Nios V/m.
     */

    /*
     * 4. Habilitar IRQ del PIO.
     */
    buttons_enable_interrupts();

    /*
     * 5. Habilitar interrupciones globales
     *    del procesador.
     *
     * TODO: Implementar usando el mecanismo
     *       correspondiente al Nios V/m.
     */

    /*
     * 6. Ciclo principal.
     */
    while (1)
    {
        uint32_t events;

        /*
         * Procesar botones.
         */
        events = buttons_get_events();

        player_process_events(&player, events);

        /*
         * Procesar eventos del HPS.
         *
         * TODO:
         * TRACK_READY
         * TRACK_ERROR
         */

        /*
         * Procesar reproducción.
         *
         * TODO:
         * Consumir PCM si PLAYER_PLAYING.
         */

        /*
         * Actualizar tiempo.
         *
         * TODO:
         * elapsed_seconds.
         */

        /*
         * Actualizar displays.
         *
         * TODO:
         * MM:SS
         * Número de canción.
         * Estado.
         */
    }

    return 0;
}