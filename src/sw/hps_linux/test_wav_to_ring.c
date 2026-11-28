
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "wav_reader.h"
#include "pcm_ring.h"

#define BLOCK_WORDS 1024

static player_ctrl_t ctrl;
static uint32_t ring[PCM_RING_WORDS];

int main(int argc, char **argv) {
    wav_reader_t wav;
    uint32_t buffer[BLOCK_WORDS];
    size_t total_written = 0;
    size_t total_consumed = 0;

    if (argc != 2) {
        fprintf(stderr, "Uso: %s archivo.wav\n", argv[0]);
        return 1;
    }

    memset(&ctrl, 0, sizeof(ctrl));
    memset(ring, 0, sizeof(ring));

    ctrl.pcm_size = PCM_RING_WORDS;

    if (wav_open(&wav, argv[1]) != 0) {
        fprintf(stderr, "Error al abrir WAV\n");
        return 1;
    }

    printf("WAV: %u Hz, %u canales\n",
           wav.sample_rate, wav.channels);

    size_t n;

    while ((n = wav_read_pcm(&wav, buffer, BLOCK_WORDS)) > 0) {
        size_t offset = 0;

        while (offset < n) {
            size_t written = pcm_ring_write(
                &ctrl,
                ring,
                buffer + offset,
                n - offset
            );

            offset += written;
            total_written += written;

            if (written == 0) {
                /*
                 * Simulamos que Nios V consume
                 * las palabras pendientes.
                 */
                uint32_t pending =
                    ctrl.pcm_wr - ctrl.pcm_rd;

                assert(pending <= PCM_RING_WORDS);
                ctrl.pcm_rd += pending;
                total_consumed += pending;
            }
        }
    }

    /* Consumir las últimas palabras pendientes. */
    uint32_t pending = ctrl.pcm_wr - ctrl.pcm_rd;
    assert(pending <= PCM_RING_WORDS);

    ctrl.pcm_rd += pending;
    total_consumed += pending;

    printf("Palabras escritas: %zu\n", total_written);
    printf("Palabras consumidas: %zu\n", total_consumed);
    printf("Ocupacion final: %u\n",
           ctrl.pcm_wr - ctrl.pcm_rd);

    assert(total_written == total_consumed);
    assert(wav.remaining_bytes == 0);

    wav_close(&wav);

    puts("OK: transferencia WAV a PCM_RING simulada");

    return 0;
}
