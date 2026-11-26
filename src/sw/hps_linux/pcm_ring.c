
#include "pcm_ring.h"

size_t pcm_ring_write(volatile player_ctrl_t *ctrl,
                      volatile uint32_t *ring,
                      const uint32_t *input,
                      size_t requested) {

    if (!ctrl || !ring || !input || requested == 0)
        return 0;

    /* Validar el tamaño acordado con Nios V. */
    if (ctrl->pcm_size != PCM_RING_WORDS)
        return 0;

    uint32_t wr = ctrl->pcm_wr;
    uint32_t rd = ctrl->pcm_rd;

    /*
     * Los índices son contadores libres de 32 bits.
     * La resta unsigned permite su desbordamiento natural.
     */
    uint32_t used = wr - rd;

    /* Un valor mayor al tamaño indica estado inválido. */
    if (used > PCM_RING_WORDS)
        return 0;

    uint32_t free_words = PCM_RING_WORDS - used;

    size_t count = requested;
    if (count > free_words)
        count = free_words;

    /* Escribir primero las muestras en la RAM. */
    for (size_t i = 0; i < count; ++i) {
        uint32_t position =
            (wr + (uint32_t)i) % PCM_RING_WORDS;

        ring[position] = input[i];
    }

    if (count > 0) {
        /*
         * Publicar los datos antes de avanzar pcm_wr.
         * Barrera para GCC sobre ARM y x86.
         */
        __sync_synchronize();

        ctrl->pcm_wr = wr + (uint32_t)count;
    }

    return count;
}
