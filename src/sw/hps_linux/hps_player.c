
#include "hps_player.h"
#include "pcm_ring.h"

#include <limits.h>
#include <string.h>

static void publish_command(hps_player_t *p,
                            uint32_t cmd,
                            uint32_t arg)
{
    p->ctrl->cmd = cmd;
    p->ctrl->cmd_arg = arg;

    /* Publicar el contenido antes de la secuencia. */
    __sync_synchronize();

    p->ctrl->cmd_seq++;
}

static void close_track(hps_player_t *p)
{
    if (p->track_open) {
        wav_close(&p->wav);
        p->track_open = 0;
    }

    p->block_count = 0;
    p->block_offset = 0;
}

static void stop_track(hps_player_t *p)
{
    close_track(p);

    /* Solo se modifican campos propiedad del HPS. */
    p->ctrl->hps_flags = 0;
}

/*
 * El Nios V debe estar en LOADING, sin consumir PCM,
 * antes de que el HPS reinicie el contenido del anillo.
 */
static void load_track(hps_player_t *p, uint32_t index)
{
    close_track(p);
    p->ctrl->hps_flags = 0;

    if (p->ctrl->state != ST_LOADING ||
        index >= p->track_count ||
        wav_open(&p->wav, p->tracks[index]) != 0) {
        publish_command(p, CMD_TRACK_ERROR, index);
        return;
    }

    p->track_open = 1;

    /* Mantener el contador del Nios V intacto. */
    p->ctrl->pcm_wr = p->ctrl->pcm_rd;

    p->ctrl->sample_rate = p->wav.sample_rate;
    p->ctrl->total_sec = p->wav.total_seconds;

    /*
     * Preparar el primer bloque antes de anunciar
     * que la pista está lista.
     */
    p->block_count = wav_read_pcm(
        &p->wav, p->block, HPS_PCM_BLOCK_WORDS);

    p->block_offset = 0;

    if (p->block_count == 0) {
        close_track(p);
        publish_command(p, CMD_TRACK_ERROR, index);
        return;
    }

    size_t written = pcm_ring_write(
        p->ctrl, p->pcm_ram,
        p->block, p->block_count);

    if (written != p->block_count) {
        close_track(p);
        publish_command(p, CMD_TRACK_ERROR, index);
        return;
    }

    p->block_offset = written;

    __sync_synchronize();
    publish_command(p, CMD_TRACK_READY, index);
}

static void pump_audio(hps_player_t *p)
{
    if (!p->track_open)
        return;

    /* Un bloque por iteración para atender STOP pronto. */
    if (p->block_offset == p->block_count) {
        p->block_count = wav_read_pcm(
            &p->wav, p->block, HPS_PCM_BLOCK_WORDS);

        p->block_offset = 0;

        if (p->block_count == 0) {
            if (p->wav.remaining_bytes == 0) {
                /* Final normal del archivo. */
                __sync_synchronize();
                p->ctrl->hps_flags |= HPS_FLAG_EOF;
            } else {
                /*
                * Error de lectura inesperado.
                * Informar al Nios V.
                */
                publish_command(
                    p,
                    CMD_TRACK_ERROR,
                    p->ctrl->track_idx
                );
            }

            close_track(p);
            return;
        }
    }

    size_t written = pcm_ring_write(
        p->ctrl, p->pcm_ram,
        p->block + p->block_offset,
        p->block_count - p->block_offset);

    p->block_offset += written;
}

int hps_player_init(hps_player_t *p,
                    volatile player_ctrl_t *ctrl,
                    volatile uint32_t *pcm_ram,
                    const char *const *tracks,
                    size_t track_count)
{
    if (!p || !ctrl || !pcm_ram ||
        !tracks || track_count == 0 ||
        track_count > UINT32_MAX)
        return -1;

    memset(p, 0, sizeof(*p));

    p->ctrl = ctrl;
    p->pcm_ram = pcm_ram;
    p->tracks = tracks;
    p->track_count = track_count;

    ctrl->pcm_size = PCM_RING_WORDS;
    ctrl->track_count = (uint32_t)track_count;
    ctrl->hps_flags = 0;

    __sync_synchronize();
    ctrl->magic = PLAYER_MAGIC;

    publish_command(p, CMD_LIST_READY,
                    (uint32_t)track_count);

    return 0;
}

void hps_player_poll(hps_player_t *p)
{
    if (!p || !p->ctrl)
        return;

    volatile player_ctrl_t *ctrl = p->ctrl;

    /*
     * No sobrescribir un comando que Nios V
     * todavía no ha confirmado.
     */
    if (ctrl->cmd_seq != ctrl->ack_seq)
        return;

    __sync_synchronize();

    if (ctrl->evt_seq != ctrl->evt_ack) {
        uint32_t seq = ctrl->evt_seq;
        uint32_t event = ctrl->evt;

        if (event == EVT_REQ_LOAD) {
            uint32_t index = ctrl->track_idx;
            load_track(p, index);
        } else if (event == EVT_REQ_STOP) {
            stop_track(p);
        }

        /* Confirmar después de procesar el evento. */
        __sync_synchronize();
        ctrl->evt_ack = seq;
        return;
    }

    pump_audio(p);
}

void hps_player_close(hps_player_t *p)
{
    if (!p)
        return;

    close_track(p);
}
