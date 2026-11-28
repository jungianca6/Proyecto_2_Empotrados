
#include "wav_reader.h"

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint16_t read_le16(const unsigned char *p) {
    return (uint16_t)p[0] |
           ((uint16_t)p[1] << 8);
}

static uint32_t read_le32(const unsigned char *p) {
    return (uint32_t)p[0] |
           ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

/* Desplazamientos compatibles con long de 32 bits. */
static int skip_bytes(FILE *file, uint32_t bytes) {
    while (bytes > 0) {
        long step = bytes > 0x7FFFFFFFu
                  ? 0x7FFFFFFFL
                  : (long)bytes;

        if (fseek(file, step, SEEK_CUR) != 0)
            return -1;

        bytes -= (uint32_t)step;
    }

    return 0;
}

static void set_default_metadata(wav_reader_t *wav,
                                 const char *path) {
    const char *base = strrchr(path, '/');
    base = base ? base + 1 : path;

    size_t length = strlen(base);

    if (length >= 4) {
        const char *ext = base + length - 4;

        if (ext[0] == '.' &&
            tolower((unsigned char)ext[1]) == 'w' &&
            tolower((unsigned char)ext[2]) == 'a' &&
            tolower((unsigned char)ext[3]) == 'v') {
            length -= 4;
        }
    }

    if (length >= sizeof(wav->title))
        length = sizeof(wav->title) - 1;

    memcpy(wav->title, base, length);
    wav->title[length] = '\0';

    snprintf(wav->artist, sizeof(wav->artist),
             "Desconocido");
    snprintf(wav->album, sizeof(wav->album),
             "Desconocido");
}

static int parse_info(wav_reader_t *wav,
                      uint32_t list_size) {
    unsigned char type[4];

    if (list_size < 4)
        return skip_bytes(wav->file, list_size);

    if (fread(type, 1, 4, wav->file) != 4)
        return -1;

    uint32_t remaining = list_size - 4;

    if (memcmp(type, "INFO", 4) != 0)
        return skip_bytes(wav->file, remaining);

    while (remaining >= 8) {
        unsigned char header[8];

        if (fread(header, 1, 8, wav->file) != 8)
            return -1;

        remaining -= 8;

        uint32_t size = read_le32(header + 4);
        uint64_t padded = (uint64_t)size + (size & 1u);

        if (padded > remaining)
            return -1;

        char *destination = NULL;
        size_t capacity = 0;

        if (memcmp(header, "INAM", 4) == 0) {
            destination = wav->title;
            capacity = sizeof(wav->title);
        } else if (memcmp(header, "IART", 4) == 0) {
            destination = wav->artist;
            capacity = sizeof(wav->artist);
        } else if (memcmp(header, "IPRD", 4) == 0) {
            destination = wav->album;
            capacity = sizeof(wav->album);
        }

        if (destination && size > 0) {
            size_t count = size;

            if (count >= capacity)
                count = capacity - 1;

            if (fread(destination, 1, count,
                      wav->file) != count)
                return -1;

            destination[count] = '\0';

            if (skip_bytes(wav->file,
                           size - (uint32_t)count) != 0)
                return -1;

            if (destination[0] != '\0')
                wav->has_metadata = 1;

        } else {
            if (skip_bytes(wav->file, size) != 0)
                return -1;
        }

        if ((size & 1u) &&
            skip_bytes(wav->file, 1) != 0)
            return -1;

        remaining -= (uint32_t)padded;
    }

    return skip_bytes(wav->file, remaining);
}

void wav_close(wav_reader_t *wav) {
    if (!wav)
        return;

    if (wav->file)
        fclose(wav->file);

    memset(wav, 0, sizeof(*wav));
}

int wav_open(wav_reader_t *wav, const char *path) {
    unsigned char header[12];

    if (!wav || !path)
        return -1;

    memset(wav, 0, sizeof(*wav));

    wav->file = fopen(path, "rb");
    if (!wav->file)
        return -1;

    set_default_metadata(wav, path);

    if (fread(header, 1, 12, wav->file) != 12 ||
        memcmp(header, "RIFF", 4) != 0 ||
        memcmp(header + 8, "WAVE", 4) != 0)
        goto error;

    uint32_t remaining = read_le32(header + 4);

    if (remaining < 4)
        goto error;

    remaining -= 4;

    int fmt_found = 0;
    int data_found = 0;
    long data_position = -1;

    while (remaining >= 8) {
        unsigned char chunk[8];

        if (fread(chunk, 1, 8, wav->file) != 8)
            goto error;

        remaining -= 8;

        uint32_t size = read_le32(chunk + 4);
        uint64_t padded = (uint64_t)size + (size & 1u);

        if (padded > remaining)
            goto error;

        if (memcmp(chunk, "fmt ", 4) == 0) {
            unsigned char fmt[16];

            if (size < 16 ||
                fread(fmt, 1, 16, wav->file) != 16)
                goto error;

            wav->channels = read_le16(fmt + 2);
            wav->sample_rate = read_le32(fmt + 4);
            wav->bits_per_sample = read_le16(fmt + 14);

            uint16_t block_align = read_le16(fmt + 12);
            uint32_t byte_rate = read_le32(fmt + 8);

            if (read_le16(fmt) != 1 ||
                (wav->channels != 1 &&
                 wav->channels != 2) ||
                wav->bits_per_sample != 16 ||
                (wav->sample_rate != 8000 &&
                 wav->sample_rate != 16000 &&
                 wav->sample_rate != 44100) ||
                block_align != wav->channels * 2u ||
                byte_rate != wav->sample_rate * block_align)
                goto error;

            fmt_found = 1;

            if (skip_bytes(wav->file,
                           (uint32_t)(padded - 16)) != 0)
                goto error;

        } else if (memcmp(chunk, "data", 4) == 0) {
            if (!data_found) {
                data_position = ftell(wav->file);

                if (data_position < 0)
                    goto error;

                wav->data_bytes = size;
                data_found = 1;
            }

            if (skip_bytes(wav->file,
                           (uint32_t)padded) != 0)
                goto error;

        } else if (memcmp(chunk, "LIST", 4) == 0) {
            if (parse_info(wav, size) != 0)
                goto error;

            if ((size & 1u) &&
                skip_bytes(wav->file, 1) != 0)
                goto error;

        } else {
            if (skip_bytes(wav->file,
                           (uint32_t)padded) != 0)
                goto error;
        }

        remaining -= (uint32_t)padded;
    }

    if (!fmt_found || !data_found ||
        wav->data_bytes == 0 ||
        wav->data_bytes % (wav->channels * 2u) != 0)
        goto error;

    wav->remaining_bytes = wav->data_bytes;

    wav->total_seconds =
        wav->data_bytes /
        (wav->sample_rate * wav->channels * 2u);

    /* Volver al inicio del audio tras analizar los metadatos. */
    if (fseek(wav->file, data_position, SEEK_SET) != 0)
        goto error;

    return 0;

error:
    wav_close(wav);
    return -1;
}

size_t wav_read_pcm(wav_reader_t *wav,
                    uint32_t *output,
                    size_t max_words) {
    size_t count = 0;
    unsigned char frame[4];

    if (!wav || !wav->file || !output)
        return 0;

    unsigned frame_bytes = wav->channels * 2u;

    while (count < max_words &&
           wav->remaining_bytes >= frame_bytes) {

        if (fread(frame, 1, frame_bytes,
                  wav->file) != frame_bytes)
            break;

        uint16_t left = read_le16(frame);
        uint16_t right = wav->channels == 2
                       ? read_le16(frame + 2)
                       : left;

        output[count++] =
            ((uint32_t)right << 16) | left;

        wav->remaining_bytes -= frame_bytes;
    }

    return count;
}
