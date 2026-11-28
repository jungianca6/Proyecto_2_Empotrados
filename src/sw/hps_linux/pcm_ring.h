
#ifndef PCM_RING_H
#define PCM_RING_H

#include <stddef.h>
#include <stdint.h>
#include "../common/player_proto.h"

/*
 * Escribe palabras PCM en la memoria compartida.
 *
 * El HPS modifica únicamente pcm_wr.
 * El Nios V es el único responsable de pcm_rd.
 *
 * Retorna la cantidad de palabras escritas.
 * Puede ser menor que requested si el anillo está lleno.
 */
size_t pcm_ring_write(volatile player_ctrl_t *ctrl,
                      volatile uint32_t *ring,
                      const uint32_t *input,
                      size_t requested);

#endif
