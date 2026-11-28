
#include <stdio.h>
#include <stdint.h>
#include "wav_reader.h"

int main(int argc, char **argv) {
    wav_reader_t wav;
    uint32_t buffer[1024];
    size_t n;
    size_t total = 0;

    if (argc != 2) {
        fprintf(stderr, "Uso: %s archivo.wav\n", argv[0]);
        return 1;
    }

    if (wav_open(&wav, argv[1]) != 0) {
        fprintf(stderr, "WAV no compatible o ilegible\n");
        return 1;
    }

    printf("Frecuencia: %u Hz\n", wav.sample_rate);
    printf("Canales: %u\n", wav.channels);
    printf("Bits: %u\n", wav.bits_per_sample);
    printf("Duracion: %u segundos\n", wav.total_seconds);
    printf("Titulo: %s\n", wav.title);
    printf("Artista: %s\n", wav.artist);
    printf("Album: %s\n", wav.album);
    printf("Tiene metadatos: %s\n",
        wav.has_metadata ? "Si" : "No");

    while ((n = wav_read_pcm(&wav, buffer, 1024)) > 0) {
        for (size_t i = 0; i < n; i++) {
            if (total + i < 5) {
                int16_t izquierda = (int16_t)(buffer[i] & 0xFFFFu);
                int16_t derecha = (int16_t)(buffer[i] >> 16);

                printf("Muestra %zu: L=%d R=%d\n",
                    total + i,
                    (int)izquierda,
                    (int)derecha);
            }
        }
        total += n;
    }

    printf("Palabras PCM generadas: %zu\n", total);
    printf("Bytes restantes: %u\n", wav.remaining_bytes);

    wav_close(&wav);
    return 0;
}
