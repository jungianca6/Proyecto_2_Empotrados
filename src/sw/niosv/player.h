#ifndef PLAYER_H
#define PLAYER_H

#include <stdint.h>
#include "buttons.h"

/*
 * Estados del reproductor.
 */
typedef enum
{
    PLAYER_STOPPED,
    PLAYER_LOADING,
    PLAYER_PLAYING,
    PLAYER_PAUSED

} player_state_t;

/*
 * Estructura principal del reproductor.
 */
typedef struct
{
    player_state_t state;

    uint32_t current_track;
    uint32_t total_tracks;

    uint32_t elapsed_seconds;
    uint32_t total_seconds;

} player_t;

/*
 * Inicialización del reproductor.
 */
void player_init(player_t *player);

/*
 * Procesamiento de eventos recibidos de los botones.
 */
void player_handle_event(player_t *player, uint32_t event);

void player_process_events(player_t *player, uint32_t events);

/*
 * Eventos provenientes del protocolo HPS-Nios.
 */
void player_handle_track_ready(player_t *player);

void player_handle_track_error(player_t *player);

/*
 * Fin de canción.
 */
void player_handle_end_of_track(player_t *player);

#endif