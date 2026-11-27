
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "hps_player.h"

static player_ctrl_t ctrl;
static uint32_t pcm_ram[PCM_RING_WORDS];
static hps_player_t hps;

/* Simula que Nios V confirma un comando. */
static void ack_command(uint32_t expected)
{
    assert(ctrl.cmd == expected);
    assert(ctrl.cmd_seq != ctrl.ack_seq);
    ctrl.ack_seq = ctrl.cmd_seq;
}

/* Simula una solicitud de carga del Nios V. */
static void request_load(void)
{
    ctrl.track_idx = 0;
    ctrl.state = ST_LOADING;
    ctrl.evt = EVT_REQ_LOAD;
    ctrl.evt_seq++;
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr,
                "Uso: %s archivo.wav muestras_esperadas\n",
                argv[0]);
        return 1;
    }

    const char *tracks[] = { argv[1] };
    unsigned long expected = 0;

    if (sscanf(argv[2], "%lu", &expected) != 1 ||
        expected == 0) {
        fprintf(stderr, "Cantidad esperada invalida\n");
        return 1;
    }

    memset(&ctrl, 0, sizeof(ctrl));
    memset(pcm_ram, 0, sizeof(pcm_ram));

    /* Inicializar el servicio HPS. */
    assert(hps_player_init(
        &hps, &ctrl, pcm_ram, tracks, 1) == 0);

    assert(ctrl.magic == PLAYER_MAGIC);
    assert(ctrl.track_count == 1);
    assert(ctrl.pcm_size == PCM_RING_WORDS);

    ack_command(CMD_LIST_READY);
    puts("OK: catalogo anunciado");

    /* Nios V solicita la pista 0. */
    request_load();
    hps_player_poll(&hps);

    assert(ctrl.evt_ack == ctrl.evt_seq);
    assert(ctrl.cmd == CMD_TRACK_READY);
    assert(ctrl.cmd_arg == 0);
    assert(ctrl.pcm_wr > 0);

    ack_command(CMD_TRACK_READY);
    ctrl.state = ST_PLAYING;

    puts("OK: solicitud de carga atendida");

    /*
     * Simular consumo de PCM en bloques.
     * No se consume mas de lo publicado por HPS.
     */
    unsigned long consumed = 0;
    unsigned iterations = 0;

    while (iterations++ < 10000) {
        hps_player_poll(&hps);

        uint32_t available =
            ctrl.pcm_wr - ctrl.pcm_rd;

        assert(available <= PCM_RING_WORDS);

        uint32_t take =
            available > 256u ? 256u : available;

        ctrl.pcm_rd += take;
        consumed += take;

        if ((ctrl.hps_flags & HPS_FLAG_EOF) &&
            ctrl.pcm_rd == ctrl.pcm_wr)
            break;
    }

    assert(iterations < 10000);
    assert(consumed == expected);
    assert(ctrl.pcm_rd == ctrl.pcm_wr);
    assert(ctrl.hps_flags & HPS_FLAG_EOF);

    printf("Palabras PCM consumidas: %lu\n", consumed);
    printf("Ocupacion final: %u\n",
           ctrl.pcm_wr - ctrl.pcm_rd);
    puts("OK: transferencia completa y EOF");

    /* Simular la detencion solicitada por Nios V. */
    ctrl.state = ST_STOPPED;
    ctrl.evt = EVT_REQ_STOP;
    ctrl.evt_seq++;

    hps_player_poll(&hps);

    assert(ctrl.evt_ack == ctrl.evt_seq);
    assert(ctrl.hps_flags == 0);
    assert(hps.track_open == 0);

    puts("OK: solicitud STOP atendida");

    hps_player_close(&hps);


    /* Prueba adicional: archivo inexistente. */
    {
        const char *bad_tracks[] = {
            "pruebas_wav/archivo_inexistente.wav"
        };

        hps_player_t bad_hps;

        memset(&ctrl, 0, sizeof(ctrl));

        assert(hps_player_init(
            &bad_hps, &ctrl, pcm_ram,
            bad_tracks, 1) == 0);

        ack_command(CMD_LIST_READY);

        request_load();
        hps_player_poll(&bad_hps);

        assert(ctrl.evt_ack == ctrl.evt_seq);
        assert(ctrl.cmd == CMD_TRACK_ERROR);
        assert(ctrl.cmd_arg == 0);
        assert(bad_hps.track_open == 0);

        puts("OK: archivo inexistente genera TRACK_ERROR");

        hps_player_close(&bad_hps);
    }


    puts("TODAS LAS PRUEBAS HPS PLAYER PASARON");
    return 0;
}
