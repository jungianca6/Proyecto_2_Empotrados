#include "buttons.h"
#include "system.h"

#include <stdint.h>

/*
 * PIO register offsets.
 *
 * REG_BTN debe configurarse con edge capture
 * e interrupciones habilitadas en Platform Designer.
 */

#define PIO_DATA_OFFSET          0x00
#define PIO_INTERRUPT_MASK      0x08
#define PIO_EDGE_CAPTURE       0x0C

#define BUTTON_MASK            0x0F

/*
 * Puntero al PIO.
 *
 * Se utiliza volatile porque estamos accediendo
 * directamente a registros de hardware.
 */

#define BUTTON_PIO ((volatile uint32_t *)REG_BTN_BASE)

/*
 * Eventos pendientes generados por la ISR.
 */
static volatile uint32_t pending_events = 0;

static uint32_t buttons_to_events(uint32_t buttons)
{
    uint32_t events = 0;

    if (buttons & BUTTON_PLAY_PAUSE)
        events |= EVENT_PLAY_PAUSE;

    if (buttons & BUTTON_STOP)
        events |= EVENT_STOP;

    if (buttons & BUTTON_NEXT)
        events |= EVENT_NEXT;

    if (buttons & BUTTON_PREVIOUS)
        events |= EVENT_PREVIOUS;

    return events;
}

void buttons_init(void)
{
    volatile uint32_t *interrupt_mask;
    volatile uint32_t *edge_capture;

    interrupt_mask = (volatile uint32_t *)
        (REG_BTN_BASE + PIO_INTERRUPT_MASK);

    edge_capture = (volatile uint32_t *)
        (REG_BTN_BASE + PIO_EDGE_CAPTURE);

    /*
     * Deshabilitar temporalmente las IRQ del PIO.
     */
    *interrupt_mask = 0x0;

    /*
     * Limpiar cualquier evento previo.
     */
    *edge_capture = 0x0;
}

void buttons_enable_interrupts(void)
{
    volatile uint32_t *interrupt_mask;

    interrupt_mask = (volatile uint32_t *)
        (REG_BTN_BASE + PIO_INTERRUPT_MASK);

    /*
     * Habilitar interrupciones para los cuatro botones.
     */
    *interrupt_mask = BUTTON_MASK;
}

void buttons_isr(void)
{
    volatile uint32_t *edge_capture;

    uint32_t captured_buttons;
    uint32_t events;

    edge_capture = (volatile uint32_t *)
        (REG_BTN_BASE + PIO_EDGE_CAPTURE);

    /*
     * Leer qué botones generaron un flanco.
     */
    captured_buttons = *edge_capture;

    /*
     * Reconocer / limpiar los flancos capturados.
     */
    *edge_capture = 0x0;

    /*
     * Traducir botones a eventos de software.
     */
    events = buttons_to_events(captured_buttons);

    /*
     * Registrar eventos para el main loop.
     */
    pending_events |= events;
}

uint32_t buttons_get_events(void)
{
    uint32_t events;

    /*
     * Aquí se debe proteger la operación de lectura
     * y limpieza contra una ISR concurrente.
     *
     * La implementación definitiva requiere una
     * sección crítica compatible con el sistema
     * de interrupciones de Nios V/m.
     */

    events = pending_events;

    pending_events = 0;

    return events;
}