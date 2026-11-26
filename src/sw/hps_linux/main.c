
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <dirent.h>
#include <limits.h>

#include "../common/player_proto.h"

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static uint16_t le16(const unsigned char *p) {
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t le32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static int revisar_wav(const char *ruta) {
    FILE *f = fopen(ruta, "rb");
    unsigned char cabecera[12];
    unsigned char chunk[8];
    unsigned char fmt[16];
    unsigned canales = 0, bits = 0;
    uint32_t frecuencia = 0, bytes_audio = 0;
    int formato_valido = 0, tiene_audio = 0;

    if (!f) {
        perror(ruta);
        return 0;
    }

    if (fread(cabecera, 1, 12, f) != 12 ||
        memcmp(cabecera, "RIFF", 4) != 0 ||
        memcmp(cabecera + 8, "WAVE", 4) != 0) {
        fclose(f);
        return 0;
    }

    while (fread(chunk, 1, 8, f) == 8) {
        uint32_t tam = le32(chunk + 4);

        if (memcmp(chunk, "fmt ", 4) == 0 && tam >= 16) {
            if (fread(fmt, 1, 16, f) != 16) break;

            formato_valido = (le16(fmt) == 1); /* PCM */
            canales = le16(fmt + 2);
            frecuencia = le32(fmt + 4);
            bits = le16(fmt + 14);

            if (fseek(f, (long)(tam - 16), SEEK_CUR) != 0)
                break;
        } else if (memcmp(chunk, "data", 4) == 0) {
            bytes_audio = tam;
            tiene_audio = 1;
            break;
        } else {
            if (fseek(f, (long)tam, SEEK_CUR) != 0)
                break;
        }

        if (tam & 1u) {
            if (fseek(f, 1, SEEK_CUR) != 0)
                break;
        }
    }

    fclose(f);

    if (!formato_valido || !tiene_audio || bytes_audio == 0 ||
        (canales != 1 && canales != 2) ||
        bits != 16 ||
        (frecuencia != 8000 &&
         frecuencia != 16000 &&
         frecuencia != 44100)) {
        return 0;
    }

    unsigned duracion = bytes_audio /
                        (frecuencia * canales * 2u);

    printf("  Frecuencia: %u Hz\n", frecuencia);
    printf("  Canales: %u\n", canales);
    printf("  Resolucion: %u bits\n", bits);
    printf("  Duracion: %u:%02u\n",
           duracion / 60, duracion % 60);

    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <carpeta_wav>\n", argv[0]);
        return 1;
    }

    DIR *dir = opendir(argv[1]);
    if (!dir) {
        perror("No se pudo abrir la carpeta");
        return 1;
    }

    struct dirent *entrada;
    unsigned validos = 0;

    while ((entrada = readdir(dir)) != NULL) {
        const char *nombre = entrada->d_name;
        size_t largo = strlen(nombre);

        if (largo < 4 ||
            strcasecmp(nombre + largo - 4, ".wav") != 0)
            continue;

        char ruta[PATH_MAX];
        int n = snprintf(ruta, sizeof(ruta), "%s/%s",
                         argv[1], nombre);
        if (n < 0 || (size_t)n >= sizeof(ruta))
            continue;

        printf("\nArchivo: %s\n", nombre);

        if (revisar_wav(ruta)) {
            printf("  Estado: VALIDO\n");
            validos++;
        } else {
            printf("  Estado: NO COMPATIBLE\n");
        }
    }

    closedir(dir);
    printf("\nTotal WAV compatibles: %u\n", validos);
    printf("Capacidad del anillo PCM: %u palabras\n",
           PCM_RING_WORDS);

    return 0;
}
