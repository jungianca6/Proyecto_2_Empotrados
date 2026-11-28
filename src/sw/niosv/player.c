#include "player.h"

#include <stdint.h>

/*
 * Estas funciones son interfaces conceptuales
 * hacia el protocolo HPS-Nios.
 *
 * Se implementarán utilizando los registros
 * compartidos definidos en shared_memory.h
 * y protocol.h.
 */

static void request_track_load(uint32_t track)
{
    /*
     * TODO:
     *
     * 1. Actualizar TRACK_IDX.
     * 2. Actualizar STATE = LOADING.
     * 3. Generar EVT = REQ_LOAD.
     * 4. Incrementar EVT_SEQ.
     */
}

void player_init(player_t *player)
{
    player->state = PLAYER_STOPPED;

    player->current_track = 0;
    player->total_tracks = 0;

    player->elapsed_seconds = 0;
    player->total_seconds = 0;
}

static void player_play_pause(player_t *player)
{
    switch (player->state)
    {
        case PLAYER_STOPPED:

            /*
             * Iniciar reproducción de la canción actual.
             */
            player->state = PLAYER_LOADING;

            request_track_load(player->current_track);

            break;


        case PLAYER_PLAYING:

            /*
             * Pausar.
             *
             * El Nios dejará de consumir muestras PCM,
             * pero el HPS y la canción actual no
             * necesariamente deben reiniciarse.
             */
            player->state = PLAYER_PAUSED;

            break;


        case PLAYER_PAUSED:

            /*
             * Reanudar desde donde se pausó.
             */
            player->state = PLAYER_PLAYING;

            break;


        case PLAYER_LOADING:

            /*
             * Ignorar PLAY durante la carga.
             *
             * Posteriormente podemos definir si
             * cancelar, pausar o ignorar.
             */
            break;
    }
}

static void player_stop(player_t *player)
{
    player->state = PLAYER_STOPPED;

    player->elapsed_seconds = 0;

    /*
     * TODO:
     *
     * 1. Detener consumo de PCM.
     * 2. Resetear PCM_RD.
     * 3. Enviar REQ_STOP al HPS.
     * 4. Actualizar displays.
     */
}

static void player_next(player_t *player)
{
    if (player->total_tracks == 0)
        return;

    player->current_track++;

    /*
     * Reproducción circular.
     */
    if (player->current_track >= player->total_tracks)
    {
        player->current_track = 0;
    }

    player->elapsed_seconds = 0;

    player->state = PLAYER_LOADING;

    request_track_load(player->current_track);
}

static void player_previous(player_t *player)
{
    if (player->total_tracks == 0)
        return;

    if (player->current_track == 0)
    {
        player->current_track = player->total_tracks - 1;
    }
    else
    {
        player->current_track--;
    }

    player->elapsed_seconds = 0;

    player->state = PLAYER_LOADING;

    request_track_load(player->current_track);
}

void player_handle_event(
    player_t *player,
    uint32_t event
)
{
    switch (event)
    {
        case EVENT_PLAY_PAUSE:

            player_play_pause(player);

            break;


        case EVENT_STOP:

            player_stop(player);

            break;


        case EVENT_NEXT:

            player_next(player);

            break;


        case EVENT_PREVIOUS:

            player_previous(player);

            break;


        default:

            break;
    }
}

void player_handle_track_ready(player_t *player)
{
    if (player->state != PLAYER_LOADING)
        return;

    player->state = PLAYER_PLAYING;

    player->elapsed_seconds = 0;
}

void player_process_events(
    player_t *player,
    uint32_t events
)
{
    if (events & EVENT_STOP)
    {
        player_stop(player);
        return;
    }

    if (events & EVENT_NEXT)
    {
        player_next(player);
        return;
    }

    if (events & EVENT_PREVIOUS)
    {
        player_previous(player);
        return;
    }

    if (events & EVENT_PLAY_PAUSE)
    {
        player_play_pause(player);
        return;
    }
}

void player_handle_track_error(player_t *player)
{
    if (player->total_tracks == 0)
    {
        player->state = PLAYER_STOPPED;
        return;
    }

    /*
     * Si una canción no pudo cargarse,
     * intentar la siguiente.
     */

    player->current_track++;

    if (player->current_track >= player->total_tracks)
    {
        player->current_track = 0;
    }

    player->state = PLAYER_LOADING;

    request_track_load(player->current_track);
}

void player_handle_end_of_track(player_t *player)
{
    /*
     * Reproducción continua.
     *
     * Al finalizar una canción:
     *     siguiente canción
     *     carga
     *     reproduce
     */

    player_next(player);
}