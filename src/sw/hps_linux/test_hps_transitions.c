
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "hps_player.h"

static player_ctrl_t ctrl;
static uint32_t pcm_ram[PCM_RING_WORDS];
static hps_player_t hps;

static void acknowledge_command(void)
{
    assert(ctrl.cmd_seq != ctrl.ack_seq);
    ctrl.ack_seq = ctrl.cmd_seq;
}

static void send_event(uint32_t event, uint32_t track)
{
    assert(ctrl.evt_seq == ctrl.evt_ack);

    ctrl.track_idx = track;
    ctrl.evt = event;

    __sync_synchronize();
    ctrl.evt_seq++;
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr,
                "Uso: %s pista1.wav pista2.wav\n",
                argv[0]);
        return 1;
    }

    const char *tracks[] = {argv[1], argv[2]};

    memset(&ctrl, 0, sizeof(ctrl));
    memset(pcm_ram, 0, sizeof(pcm_ram));

    assert(hps_player_init(
        &hps, &ctrl, pcm_ram, tracks, 2) == 0);

    assert(ctrl.cmd == CMD_LIST_READY);
    acknowledge_command();

    puts("OK: catalogo de dos canciones anunciado");

    /* Cargar primera canción. */
    ctrl.state = ST_LOADING;
    send_event(EVT_REQ_LOAD, 0);

    hps_player_poll(&hps);

    assert(ctrl.cmd == CMD_TRACK_READY);
    assert(ctrl.cmd_arg == 0);
    assert(ctrl.evt_seq == ctrl.evt_ack);

    acknowledge_command();
    ctrl.state = ST_PLAYING;

    puts("OK: primera cancion cargada");

    /* Simular NEXT: Nios V deja de consumir PCM. */
    ctrl.state = ST_LOADING;
    send_event(EVT_REQ_LOAD, 1);

    hps_player_poll(&hps);

    assert(ctrl.cmd == CMD_TRACK_READY);
    assert(ctrl.cmd_arg == 1);
    assert(ctrl.evt_seq == ctrl.evt_ack);

    acknowledge_command();
    ctrl.state = ST_PLAYING;

    puts("OK: NEXT cambia a segunda cancion");

    /* Simular STOP. */
    ctrl.state = ST_STOPPED;
    send_event(EVT_REQ_STOP, 1);

    hps_player_poll(&hps);

    assert(ctrl.evt_seq == ctrl.evt_ack);
    assert(hps.track_open == 0);
    assert(ctrl.hps_flags == 0);

    puts("OK: STOP cancela la reproduccion");


    /*
    * Prueba: STOP mientras TRACK_READY sigue
    * pendiente de confirmacion.
    */
    {
        /* Volver a solicitar la primera pista. */
        ctrl.state = ST_LOADING;
        send_event(EVT_REQ_LOAD, 0);
        hps_player_poll(&hps);

        assert(ctrl.cmd == CMD_TRACK_READY);
        assert(ctrl.cmd_seq != ctrl.ack_seq);

        /* Nios V solicita STOP antes de confirmar. */
        ctrl.state = ST_STOPPED;
        send_event(EVT_REQ_STOP, 0);

        hps_player_poll(&hps);

        if (ctrl.evt_ack != ctrl.evt_seq) {
            puts("DETECTADO: STOP espera confirmacion de TRACK_READY");
        }

        /* Simular confirmacion del comando anterior. */
        acknowledge_command();
        hps_player_poll(&hps);

        assert(ctrl.evt_ack == ctrl.evt_seq);
        assert(hps.track_open == 0);

        puts("OK: STOP atendido despues de confirmar comando");
    }


    hps_player_close(&hps);

    puts("TODAS LAS TRANSICIONES BASICAS PASARON");
    return 0;
}
