#ifndef BUTTONS_H
#define BUTTONS_H

#include <stdint.h>

/* Eventos generados por los botones físicos */
#define EVENT_PLAY_PAUSE (1u << 0)
#define EVENT_STOP       (1u << 1)
#define EVENT_NEXT       (1u << 2)
#define EVENT_PREVIOUS  (1u << 3)

/* Máscara de botones */
#define BUTTON_PLAY_PAUSE  (1u << 0)
#define BUTTON_STOP        (1u << 1)
#define BUTTON_NEXT        (1u << 2)
#define BUTTON_PREVIOUS    (1u << 3)

void buttons_init(void);

/* Función de servicio de interrupción */
void buttons_isr(void);

/* Obtener y limpiar eventos pendientes */
uint32_t buttons_get_events(void);

void buttons_enable_interrupts(void);

#endif