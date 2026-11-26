
#ifndef WAV_READER_H
#define WAV_READER_H

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

typedef struct {
    FILE *file;

    /* Formato del audio */
    uint32_t sample_rate;
    uint32_t data_bytes;
    uint32_t remaining_bytes;
    uint16_t channels;
    uint16_t bits_per_sample;
    uint32_t total_seconds;

    /* Metadatos LIST/INFO */
    char title[128];
    char artist[128];
    char album[128];

    /* Indica si se encontraron metadatos */
    int has_metadata;
} wav_reader_t;

/* Abre y valida un WAV PCM de 16 bits. */
int wav_open(wav_reader_t *wav, const char *path);

/* Lee frames y los convierte a palabras PCM estéreo.
 * Bits 15:0 = izquierda; bits 31:16 = derecha.
 * En mono se duplica la muestra.
 * Devuelve la cantidad de palabras producidas.
 */
size_t wav_read_pcm(wav_reader_t *wav,
                    uint32_t *output,
                    size_t max_words);

/* Cierra el archivo. */
void wav_close(wav_reader_t *wav);

#endif

