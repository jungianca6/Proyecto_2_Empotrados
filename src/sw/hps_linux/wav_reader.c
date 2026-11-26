
#include "wav_reader.h"
#include <string.h>
#include <limits.h>

static uint16_t read_le16(const unsigned char *p) {
    return (uint16_t)((uint16_t)p[0] |
                      ((uint16_t)p[1] << 8));
}

static uint32_t read_le32(const unsigned char *p) {
    return (uint32_t)p[0] |
           ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

void wav_close(wav_reader_t *wav) {
    if (!wav) return;

    if (wav->file)
        fclose(wav->file);

    memset(wav, 0, sizeof(*wav));
}

int wav_open(wav_reader_t *wav, const char *path) {
    unsigned char header[12];
    unsigned char chunk[8];
    unsigned char fmt[16];
    uint32_t remaining;
    int fmt_found = 0;

    if (!wav || !path) return -1;

    memset(wav, 0, sizeof(*wav));

    wav->file = fopen(path, "rb");
    if (!wav->file) return -1;

    if (fread(header, 1, 12, wav->file) != 12 ||
        memcmp(header, "RIFF", 4) != 0 ||
        memcmp(header + 8, "WAVE", 4) != 0) {
        goto error;
    }

    remaining = read_le32(header + 4);
    if (remaining < 4) goto error;
    remaining -= 4;

    while (remaining >= 8) {
        uint32_t size;
        uint32_t padded_size;

        if (fread(chunk, 1, 8, wav->file) != 8)
            goto error;

        remaining -= 8;
        size = read_le32(chunk + 4);

        if (size > remaining) goto error;

        padded_size = size + (size & 1u);
        if (padded_size < size ||
            padded_size > remaining)
            goto error;

        if (memcmp(chunk, "fmt ", 4) == 0 &&
            size >= 16) {

            if (fread(fmt, 1, 16, wav->file) != 16)
                goto error;

            wav->channels = read_le16(fmt + 2);
            wav->sample_rate = read_le32(fmt + 4);
            wav->bits_per_sample = read_le16(fmt + 14);

            if (read_le16(fmt) != 1 ||
                (wav->channels != 1 &&
                 wav->channels != 2) ||
                wav->bits_per_sample != 16 ||
                (wav->sample_rate != 8000 &&
                 wav->sample_rate != 16000 &&
                 wav->sample_rate != 44100)) {
                goto error;
            }

            uint16_t block_align = read_le16(fmt + 12);
            if (block_align != wav->channels * 2u)
                goto error;

            fmt_found = 1;

            if (fseek(wav->file,
                      (long)(padded_size - 16),
                      SEEK_CUR) != 0)
                goto error;

        } else if (memcmp(chunk, "data", 4) == 0 &&
                   fmt_found) {

            uint32_t frame_bytes = wav->channels * 2u;

            if (size == 0 ||
                size % frame_bytes != 0)
                goto error;

            wav->data_bytes = size;
            wav->remaining_bytes = size;

            wav->total_seconds =
                size / (wav->sample_rate * frame_bytes);

            return 0;

        } else {
            uint32_t pendiente = padded_size;

            while (pendiente > 0) {
                long salto = pendiente > 0x7FFFFFFFu
                    ? 0x7FFFFFFFL
                    : (long)pendiente;

                if (fseek(wav->file, salto, SEEK_CUR) != 0)
                    goto error;

                pendiente -= (uint32_t)salto;
            }
        }

        remaining -= padded_size;
    }

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

    const unsigned frame_bytes =
        (unsigned)wav->channels * 2u;

    while (count < max_words &&
           wav->remaining_bytes >= frame_bytes) {

        if (fread(frame, 1, frame_bytes, wav->file)
            != frame_bytes)
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
