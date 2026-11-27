
#ifndef HPS_PLAYER_H
#define HPS_PLAYER_H

#include <stddef.h>
#include <stdint.h>

#include "../common/player_proto.h"
#include "wav_reader.h"

#define HPS_PCM_BLOCK_WORDS 1024u

typedef struct {
    volatile player_ctrl_t *ctrl;
    volatile uint32_t *pcm_ram;

    const char *const *tracks;
    size_t track_count;

    wav_reader_t wav;

    uint32_t block[HPS_PCM_BLOCK_WORDS];
    size_t block_count;
    size_t block_offset;

    int track_open;
} hps_player_t;

/*
 * Inicializa el servicio y anuncia el catálogo.
 *
 * Debe llamarse únicamente cuando el Nios V esté
 * detenido y las memorias compartidas estén listas.
 */
int hps_player_init(hps_player_t *player,
                    volatile player_ctrl_t *ctrl,
                    volatile uint32_t *pcm_ram,
                    const char *const *tracks,
                    size_t track_count);

/*
 * Atiende eventos del Nios V y envía PCM.
 * Se invoca repetidamente desde el ciclo HPS.
 */
void hps_player_poll(hps_player_t *player);

/* Cierra recursos locales del HPS. */
void hps_player_close(hps_player_t *player);

#endif
