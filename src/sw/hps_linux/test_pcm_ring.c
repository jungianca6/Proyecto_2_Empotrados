
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "pcm_ring.h"

static player_ctrl_t ctrl;
static uint32_t ring[PCM_RING_WORDS];

int main(void) {
    uint32_t samples[] = {
        0xFC1803E8u,
        0xF83007D0u,
        0x0BB8F448u,
        0x00000000u
    };

    memset(&ctrl, 0, sizeof(ctrl));
    memset(ring, 0, sizeof(ring));

    ctrl.pcm_size = PCM_RING_WORDS;

    /* Prueba 1: escritura normal */
    size_t written = pcm_ring_write(
        &ctrl, ring, samples, 4);

    assert(written == 4);
    assert(ctrl.pcm_wr == 4);
    assert(ctrl.pcm_rd == 0);

    for (size_t i = 0; i < 4; ++i)
        assert(ring[i] == samples[i]);

    puts("OK: escritura inicial de 4 palabras");

    /* Prueba 2: simular consumo del Nios V */
    ctrl.pcm_rd = 4;

    assert(ctrl.pcm_wr - ctrl.pcm_rd == 0);
    puts("OK: liberacion de espacio por Nios V");

    /* Prueba 3: escritura que cruza el final */
    ctrl.pcm_wr = PCM_RING_WORDS - 2;
    ctrl.pcm_rd = PCM_RING_WORDS - 2;

    written = pcm_ring_write(
        &ctrl, ring, samples, 4);

    assert(written == 4);
    assert(ring[PCM_RING_WORDS - 2] == samples[0]);
    assert(ring[PCM_RING_WORDS - 1] == samples[1]);
    assert(ring[0] == samples[2]);
    assert(ring[1] == samples[3]);
    assert(ctrl.pcm_wr == PCM_RING_WORDS + 2);

    puts("OK: escritura circular con wrap-around");

    /* Prueba 4: no sobrescribir un anillo lleno */
    ctrl.pcm_rd = 0;
    ctrl.pcm_wr = PCM_RING_WORDS;

    written = pcm_ring_write(
        &ctrl, ring, samples, 4);

    assert(written == 0);
    assert(ctrl.pcm_wr == PCM_RING_WORDS);

    puts("OK: proteccion contra sobrescritura");

    puts("TODAS LAS PRUEBAS PCM RING PASARON");
    return 0;
}
