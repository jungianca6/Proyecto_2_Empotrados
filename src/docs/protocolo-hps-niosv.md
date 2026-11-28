# Protocolo HPS ↔ Nios V

Cumple: REQ-15, REQ-16.

## 1. Memorias compartidas

| Memoria | Tamaño | Nios V (s1) | HPS (s2) |
|---|---|---|---|
| CTRL_RAM | 4 KB | 0x30000 | 0xFF200000 + 0x00000 |
| PCM_RAM | 64 KB | 0x40000 | 0xFF200000 + 0x10000 |

## 2. Reglas generales

1. Cada registro tiene un único escritor (columna "Escribe").
2. Un mensaje se envía así: escribir CMD/EVT y su argumento, y SOLO DESPUÉS
   incrementar SEQ (con barrera de memoria en el HPS).
3. El receptor revisa SEQ en su lazo principal; si es distinto de su último ACK,
   procesa y copia SEQ al ACK correspondiente.
4. Palabras de 32 bits, alineadas, acceso con punteros volatile.
5. Formato PCM: una palabra = una muestra estéreo. Bits 15:0 = L (int16),
   bits 31:16 = R (int16). Si la canción es mono el HPS duplica el canal.

## 3. Bloque de control (CTRL_RAM)

| Offset | Nombre | Escribe | Descripción |
|---|---|---|---|
| 0x00 | MAGIC | HPS | 0x41554449 cuando el HPS terminó de inicializar |
| 0x04 | CMD | HPS | Comando (sección 4) |
| 0x08 | CMD_ARG | HPS | Argumento del comando |
| 0x0C | CMD_SEQ | HPS | Se incrementa con cada comando |
| 0x10 | ACK_SEQ | Nios V | Copia de CMD_SEQ al procesar |
| 0x14 | EVT | Nios V | Evento (sección 5) |
| 0x18 | EVT_SEQ | Nios V | Se incrementa con cada evento |
| 0x1C | EVT_ACK | HPS | Copia de EVT_SEQ al procesar |
| 0x20 | STATE | Nios V | 0 Detenido, 1 Reproduciendo, 2 Pausado, 3 Cargando |
| 0x24 | TRACK_IDX | Nios V | Canción actual (base 0) |
| 0x28 | TRACK_COUNT | HPS | Total de canciones |
| 0x2C | SAMPLE_RATE | HPS | 8000, 16000 o 44100 |
| 0x30 | TOTAL_SEC | HPS | Duración de la canción actual (s) |
| 0x34 | ELAPSED_SEC | Nios V | Tiempo transcurrido (s) |
| 0x38 | PCM_WR | HPS | Índice de escritura del anillo (contador libre) |
| 0x3C | PCM_RD | Nios V | Índice de lectura del anillo (contador libre) |
| 0x40 | PCM_SIZE | HPS | Tamaño del anillo en palabras (16384) |
| 0x44 | HPS_FLAGS | HPS | bit0 EOF: ya se escribió el último bloque |
| 0x48 | NIOS_FLAGS | Nios V | bit0 UNDERRUN: el anillo se vació sin EOF |
| 0x4C | FILTER | Nios V | Filtro activo: 0 bypass, 1 a 3 |

El STATE 3 (Cargando) es interno; para el usuario se muestra como Detenido o
Pausado según corresponda (REQ-12).

## 4. Comandos HPS → Nios V (CMD, CMD_ARG)

| Código | Nombre | CMD_ARG | Significado |
|---|---|---|---|
| 0x01 | LIST_READY | TRACK_COUNT | El catálogo está listo |
| 0x02 | TRACK_READY | índice | Canción cargada: SAMPLE_RATE, TOTAL_SEC y primer bloque listos |
| 0x03 | TRACK_ERROR | índice | Archivo inválido o ilegible: el Nios V salta a la siguiente |

## 5. Eventos Nios V → HPS (EVT)

| Código | Nombre | Significado |
|---|---|---|
| 0x01 | REQ_LOAD | Cargar la canción TRACK_IDX desde el inicio |
| 0x02 | REQ_STOP | Cerrar el archivo actual; el reproductor queda detenido |

## 6. Anillo PCM

- PCM_WR y PCM_RD son contadores libres; la posición en memoria es (contador mod PCM_SIZE).
- Datos disponibles = PCM_WR - PCM_RD. Espacio libre = PCM_SIZE - (PCM_WR - PCM_RD).
- El HPS escribe solo si hay espacio, en bloques de unas 1024 palabras o más.
- A 44.1 kHz el anillo completo equivale a unos 371 ms de audio.
- Al terminar el archivo el HPS escribe HPS_FLAGS.EOF = 1. El Nios V, al vaciar
  el anillo con EOF activo, avanza TRACK_IDX y emite REQ_LOAD.
- Si el anillo se vacía sin EOF, el Nios V levanta NIOS_FLAGS.UNDERRUN.

## 7. Secuencias

**Arranque.** HPS: escribe TRACK_COUNT y MAGIC, luego CMD=LIST_READY y CMD_SEQ++.

**Play desde Detenido.** Nios V: STATE=3, EVT=REQ_LOAD, EVT_SEQ++. HPS: abre el
archivo, parsea, escribe SAMPLE_RATE y TOTAL_SEC, hace PCM_WR = PCM_RD, pone
HPS_FLAGS=0, llena el anillo, CMD=TRACK_READY y CMD_SEQ++. Nios V: STATE=1,
ELAPSED_SEC=0 y empieza a consumir.

**Pausa / Reanudar.** Solo el Nios V (STATE 1 ↔ 2). El HPS no se entera, y deja
de escribir cuando el anillo se llena.

**Siguiente / Anterior.** Nios V: actualiza TRACK_IDX, STATE=3, deja de consumir,
EVT=REQ_LOAD. Resto igual a Play desde Detenido.

**Stop.** Nios V: STATE=0, ELAPSED_SEC=0, EVT=REQ_STOP. HPS cierra el archivo.

**Fin de canción.** Nios V: anillo vacío con EOF activo, TRACK_IDX avanza
(vuelve a 0 al llegar al final), REQ_LOAD.

**Error.** HPS: CMD=TRACK_ERROR. Nios V: avanza TRACK_IDX y emite REQ_LOAD.
