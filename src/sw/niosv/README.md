# Módulo de Controles y Lógica del Reproductor — Nios V/m

## Descripción

Este módulo contiene la lógica de control del reproductor de audio ejecutado en el Nios V/m. Su objetivo es gestionar las acciones del usuario mediante los botones físicos de la DE1-SoC y mantener el estado del reproductor.

La lógica está separada en dos partes principales:

- **Buttons:** captura las pulsaciones de los botones físicos mediante el PIO y genera eventos de software.
- **Player:** procesa esos eventos y gestiona los estados del reproductor, las acciones de reproducción y las solicitudes de cambio de canción.

La implementación está diseñada para funcionar de manera bare-metal, sin utilizar un sistema operativo, y acceder directamente a los periféricos mediante sus direcciones de memoria.

---

## Estructura de los archivos

| Archivo | Descripción |
|---|---|
| `buttons.h` | Define los eventos de los botones y las funciones disponibles para el módulo. |
| `buttons.c` | Configura el PIO de los botones, captura las pulsaciones mediante Edge Capture y genera eventos. |
| `player.h` | Define los estados del reproductor, su estructura de datos y las funciones de control. |
| `player.c` | Implementa la lógica de reproducción, pausa, detención, cambio de canción y manejo de eventos. |
| `main.c` | Punto de entrada del programa. Inicializa los módulos y contiene el ciclo principal donde se procesan eventos y se integrarán los demás componentes. |

---

## Configuración de los botones

El módulo utiliza el PIO `REG_BTN`, configurado como una entrada de 4 bits para los botones KEY de la FPGA.

La configuración actual utiliza Edge Capture con detección de flanco descendente (*Falling Edge*), de manera que se detecta la pulsación de los botones, considerando su funcionamiento activo en bajo.

| Botón | Acción |
|---|---|
| KEY0 | Play / Pause |
| KEY1 | Stop |
| KEY2 | Next Track |
| KEY3 | Previous Track |

Las pulsaciones detectadas se convierten en eventos de software (`EVENT_PLAY_PAUSE`, `EVENT_STOP`, etc.). De esta manera, el módulo `player` no necesita acceder directamente a los registros del PIO ni conocer los detalles de las interrupciones.

La configuración del PIO, sus offsets y su dirección base se encuentran en `buttons.c` y `system.h`, respectivamente.

---

## Módulo Buttons

`buttons.c` es responsable de la interacción directa con el hardware de los botones.

Sus principales funciones son:

- Inicializar el PIO y configurar su registro de interrupciones.
- Leer el registro Edge Capture para determinar qué botón fue presionado.
- Limpiar los eventos capturados.
- Convertir las pulsaciones en eventos de software.
- Almacenar los eventos pendientes para que sean procesados por el programa principal.

### Interfaz

Las funciones disponibles se encuentran declaradas en `buttons.h`:

- `buttons_init()` — inicializa el módulo.
- `buttons_isr()` — rutina de servicio de interrupción encargada de capturar las pulsaciones.
- `buttons_get_events()` — obtiene los eventos pendientes y los limpia para evitar procesarlos nuevamente.

El módulo está pensado para que la interrupción sea breve: captura el evento y lo almacena, dejando que la lógica del reproductor se ejecute posteriormente en el ciclo principal.

La configuración y habilitación completa del mecanismo de interrupciones del Nios V/m aún debe adaptarse al sistema generado en Platform Designer y al mecanismo de IRQ utilizado en el proyecto.

---

## Módulo Player

`player.c` contiene la lógica de control del reproductor. No accede directamente a los botones físicos, sino que recibe los eventos generados por el módulo `buttons`.

El estado del reproductor se almacena en la estructura `player_t`, definida en `player.h`.

### Estados

| Estado | Descripción |
|---|---|
| `PLAYER_STOPPED` | Reproducción detenida. |
| `PLAYER_LOADING` | Se solicitó cargar una canción y se espera la respuesta del HPS. |
| `PLAYER_PLAYING` | Reproducción activa. |
| `PLAYER_PAUSED` | Reproducción pausada. |

### Acciones implementadas en la lógica

- **Play:** si el reproductor está detenido, solicita cargar la canción actual. Cuando la canción está cargada, pasa a reproducción.
- **Pause / Resume:** alterna entre `PLAYER_PLAYING` y `PLAYER_PAUSED`.
- **Stop:** detiene el reproductor y reinicia el tiempo transcurrido.
- **Next:** selecciona la siguiente canción, regresando a la primera al alcanzar el final de la lista.
- **Previous:** selecciona la canción anterior, regresando a la última si se encuentra en la primera posición.
- **Track Ready:** permite pasar de `PLAYER_LOADING` a `PLAYER_PLAYING` cuando se recibe la confirmación de carga.
- **Track Error:** maneja errores de carga y permite intentar avanzar a otra canción.
- **End of Track:** permite avanzar automáticamente a la siguiente canción.

Las acciones Next y Previous utilizan `total_tracks` y `current_track` para controlar la posición dentro de la lista de canciones.

---

## Procesamiento de eventos

Los eventos obtenidos mediante `buttons_get_events()` son procesados por `player_process_events()`.

Cuando se reciben varios eventos simultáneamente, se utiliza la siguiente prioridad:

1. Stop
2. Next
3. Previous
4. Play / Pause

Esto evita que varias acciones incompatibles sean ejecutadas en una misma iteración del ciclo principal.

---

## Integración con los módulos de HPS y Audio

Este módulo está diseñado para actuar como la capa de control del reproductor, mientras que los demás componentes se encargan de la gestión de archivos y del procesamiento de audio.

### HPS y comunicación

El HPS ejecuta Linux y se encarga de acceder a los archivos de audio, preparar los datos PCM y atender las solicitudes de carga de canciones.

La lógica del reproductor deberá comunicarse con el módulo HPS mediante el protocolo de memoria compartida definido para el proyecto.

Las funciones de control del reproductor deberán conectarse con las operaciones del protocolo para:

- Solicitar la carga de una canción.
- Informar cambios de estado.
- Solicitar la detención de la reproducción.
- Recibir confirmaciones de carga.
- Consultar información de la canción actual y de la lista de reproducción.

Actualmente, `request_track_load()` es el punto de entrada previsto para implementar la solicitud de carga hacia el HPS. Su implementación debe adaptarse al módulo de comunicación correspondiente.

### Módulo de audio FPGA

El módulo de audio se encarga del consumo de muestras PCM, el FIFO, el procesamiento de filtros y la salida de audio.

La lógica del reproductor deberá coordinarse con este módulo para controlar:

- Inicio y pausa del consumo de muestras.
- Detención de la reproducción.
- Reinicio de la lectura del buffer al cambiar de canción.
- Transición entre canciones.
- Estado de reproducción y finalización del audio.

Estas operaciones aún deben conectarse con las interfaces definitivas del módulo de audio.

---

## Main

`main.c` funciona como el punto de integración de los módulos ejecutados en el Nios V/m.

La estructura prevista del programa es:

1. Inicializar el reproductor.
2. Inicializar el módulo de botones.
3. Configurar y registrar las interrupciones correspondientes.
4. Habilitar el mecanismo de interrupciones.
5. Entrar en el ciclo principal.
6. Consultar los eventos pendientes de los botones.
7. Procesar los eventos mediante el módulo `player`.
8. Atender las respuestas del HPS y las solicitudes de comunicación.
9. Coordinar el consumo de PCM y actualizar los periféricos de visualización.

El ciclo principal está planteado para centralizar la coordinación de los módulos, mientras que las interrupciones se utilizan para capturar eventos de hardware.

---

## Consideraciones para la integración

Los módulos `buttons` y `player` constituyen una base para la lógica de control del reproductor, pero todavía requieren integración con los componentes desarrollados por los demás integrantes.

Al integrar el código se debe tener en cuenta:

- Verificar el mecanismo de registro y habilitación de interrupciones del Nios V/m.
- Conectar `request_track_load()` con el protocolo de comunicación HPS-Nios.
- Implementar las operaciones reales de Stop y control de PCM.
- Sincronizar los estados del reproductor con las respuestas del HPS.
- Conectar los estados y la información de la canción con los displays.
- Revisar el acceso concurrente a los eventos generados por la ISR.
- Verificar que las interfaces y direcciones de memoria coincidan con el sistema generado en Platform Designer.

Los archivos están separados por responsabilidad para facilitar su modificación durante la integración. El módulo `buttons` puede mantenerse como la interfaz de entrada de eventos, mientras que `player` puede adaptarse a las interfaces definitivas del protocolo de comunicación y del módulo de audio sin necesidad de modificar la lógica de captura de los botones.

---

## Estado actual

La estructura de los módulos, la definición de eventos, los estados del reproductor y la lógica preliminar de control están desarrollados.

Sin embargo, la integración con las interrupciones del Nios V/m, el protocolo HPS-Nios y el módulo de audio aún está pendiente. Por lo tanto, la lógica descrita representa la implementación base y el comportamiento previsto, no una reproducción completa validada en la FPGA.