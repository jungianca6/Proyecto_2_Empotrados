# Componente audio_dsp

Cumple: REQ-04, REQ-05, REQ-14, REQ-16, REQ-19.
Estado: especificación (sin implementar).

## 1. Función
Lee el anillo PCM, convierte a 48 kHz, aplica el filtro y el volumen, y
entrega muestras estéreo al serializador de audio.

## 2. Diagrama de bloques

```
 Nios V --Avalon-MM esclavo--> [registros]
                                    |
 PCM_RAM.s1 <--Avalon-MM master-- [lector del anillo]
                                    |
                      [remuestreo lineal a 48 kHz]
                                    | L, R
          +-------------+-----------+------------+
       bypass     FIR pasa-bajos  pasa-altos   realce
          +-------------+-----------+------------+
                                    |
                [mux FILTER_SEL] -> [volumen] -> [salida L, R]
                                                      |
 serializador (12.288 MHz) <--------------------------+
 serializador -- sample_req --> [sincronizador] (marca cada muestra)
```

## 3. Registros (base Nios V propuesta: 0x20100, 32 bits)

| Offset | Nombre | Acceso | Reset | Descripción |
|---|---|---|---|---|
| 0x00 | CONTROL | R/W | 0 | bit0 ENABLE; bit1 CLEAR (se autolimpia) |
| 0x04 | STATUS | R/W1C | - | bit0 RUNNING; bit1 EMPTY; bit2 UNDERRUN (se limpia con 1) |
| 0x08 | FILTER_SEL | R/W | 0 | [1:0] 0 bypass, 1 FIR pasa-bajos, 2 pasa-altos, 3 realce |
| 0x0C | COEF_ADDR | R/W | 0 | [3:0] coeficiente 0 a 15 |
| 0x10 | COEF_DATA | R/W | - | [15:0] Q1.15; al escribir incrementa COEF_ADDR |
| 0x14 | SAMPLE_RATE | R/W | 48000 | [15:0] Hz de la canción (máximo 48000) |
| 0x18 | PCM_WR | R/W | 0 | Copia de PCM_WR de CTRL_RAM |
| 0x1C | PCM_RD | R | 0 | Contador libre de palabras consumidas |
| 0x20 | SAMPLE_CNT | R | 0 | Palabras consumidas desde CLEAR |
| 0x24 | UNDERRUN_CNT | R | 0 | Veces que faltó una muestra desde CLEAR |
| 0x28 | VOLUME | R/W | 256 | [8:0] ganancia = VOLUME/256 (máximo 256) |
| 0x2C | ID | R | 0x44535031 | Identificador "DSP1" |

CLEAR pone en cero el estado de filtros y remuestreo, SAMPLE_CNT,
UNDERRUN y UNDERRUN_CNT. No modifica PCM_RD ni PCM_WR.

## 4. Comportamiento
- Anillo de 16384 palabras; posición = PCM_RD mod 16384.
  Palabra: L en [15:0], R en [31:16].
- ENABLE=0: salida en silencio y no se consumen muestras.
- Anillo vacío: entra un cero, PCM_RD no avanza y se marca UNDERRUN.
- Remuestreo: acc += SAMPLE_RATE en cada muestra de salida; si
  acc >= 48000, se resta 48000 y se toma la siguiente muestra.
  Se interpola linealmente entre las dos últimas.
- FIR: 31 coeficientes simétricos (16 únicos) Q1.15, acumulador de
  36 bits, salida saturada a 16 bits.
- Bypass: no pasa por ningún filtro. Con VOLUME=256 no se escala.

## 5. Temporización con el serializador
En cada sample_req (sincronizado a 50 MHz) se publica la muestra ya
calculada y luego se calcula la siguiente (unos 1041 ciclos disponibles).
El top genera sample_valid retrasando sample_req 8 ciclos de audio_clk,
cuando los datos ya están estables.

## 6. Contrato con el firmware del Nios V
El protocolo HPS-Nios V no cambia.

| Momento | Acciones en orden |
|---|---|
| Arranque | CONTROL=CLEAR; copiar PCM_RD a CTRL_RAM |
| TRACK_READY | escribir SAMPLE_RATE y PCM_WR; CONTROL=ENABLE y CLEAR |
| Reproduciendo | leer HPS_FLAGS y luego PCM_WR de CTRL_RAM; escribir PCM_WR; copiar PCM_RD a CTRL_RAM |
| Pausa / reanudar | ENABLE=0 / ENABLE=1 |
| Cambio de pista o stop | ENABLE=0; copiar PCM_RD a CTRL_RAM; enviar el evento |
| Fin de canción | EOF y EMPTY: avanzar de pista |
| Underrun sin EOF | NIOS_FLAGS.UNDERRUN |
| Switches | leer REG_SW; escribir FILTER_SEL y FILTER en CTRL_RAM |

Tiempo transcurrido = SAMPLE_CNT / SAMPLE_RATE.

## 7. Decisiones
| Decisión | Alternativa | Motivo |
|---|---|---|
| Lector en hardware | Nios V copia muestras | El flujo no depende del lazo del firmware |
| Nios V copia punteros | Master sobre CTRL_RAM | Mantiene un único escritor por registro |
| Remuestreo lineal | Repetir muestra | Menos distorsión, sobre todo a 44.1 kHz |

## 8. Pendiente
- Confirmar salida: serializador propio o IP de Audio.
- Confirmar reutilización de pasa-altos y realce, y dueño de VOLUME.
