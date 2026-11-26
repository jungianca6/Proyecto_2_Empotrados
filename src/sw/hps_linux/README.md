# Software HPS Linux — Reproductor de Audio Avanzado

## 1. Objetivo

Configurar y verificar el arranque de Linux en el procesador HPS ARM Cortex-A9 de la tarjeta DE1-SoC, utilizando una microSD como medio de arranque y almacenamiento de archivos WAV.

Esta implementación corresponde a las actividades del Milestone 3, principalmente:

- **Issue #39:** Configurar y verificar el boot de Linux en HPS desde SD.
- **Issue #13:** Acceso a SD y sistema de archivos.
- **Issue #14:** Lectura y procesamiento de metadatos WAV (en desarrollo).

## 2. Hardware y software utilizado

| Elemento | Descripción |
|---|---|
| Tarjeta | Terasic DE1-SoC, Cyclone V SoC |
| Procesador | HPS ARM Cortex-A9 |
| Almacenamiento | microSD de 16 GB |
| Imagen Linux | `DE1_SoC_FB.img` |
| Sistema operativo | Linux 3.12.0 |
| Arquitectura | ARMv7 (`armv7l`) |
| Comunicación | UART del HPS, puerto J4 |
| Velocidad UART | 115200 baudios, 8N1 |
| Computadora de desarrollo | Ubuntu 24.04 |

La imagen utilizada corresponde a **Linux Console with framebuffer**, distribuida por Terasic.

## 3. Preparación de la microSD

1. Descargar `DE1_SoC_FB.zip` desde la sección Linux BSP de Terasic.
2. Descomprimir el archivo para obtener `DE1_SoC_FB.img`.
3. Grabar la imagen en la microSD utilizando balenaEtcher.
4. Verificar que la grabación finalice correctamente.
5. Expulsar la microSD de forma segura.

**Advertencia:** la grabación de una imagen de disco sobrescribe las particiones y los datos existentes en el dispositivo seleccionado.

### Particiones identificadas

| Partición | Tipo | Tamaño aproximado | Función |
|---|---|---|---|
| `/dev/mmcblk0p1` | FAT32 | 819 MiB | Archivos de arranque y canciones |
| `/dev/mmcblk0p2` | Linux/ext3 | 1 GiB | Sistema operativo |
| `/dev/mmcblk0p3` | Altera A2 | 1 MiB | Datos de arranque del HPS |

La imagen fue grabada en una tarjeta física de aproximadamente 14,6 GiB de capacidad utilizable.

## 4. Arranque de Linux en la DE1-SoC

Para la imagen de referencia utilizada se configuraron los cinco bits MSEL en `00000`, dejando el resto de interruptores conforme a la configuración empleada durante las pruebas.

Procedimiento:

1. Apagar la tarjeta DE1-SoC.
2. Insertar la microSD.
3. Conectar el puerto UART J4 de la tarjeta a la computadora.
4. Conectar la fuente de alimentación.
5. Abrir la consola serie en Ubuntu:

```bash
sudo screen /dev/ttyUSB0 115200
```

El nombre `/dev/ttyUSB0` debe verificarse en cada computadora, ya que puede cambiar.

6. Encender la DE1-SoC y observar los mensajes de arranque.
7. Cuando aparezca `socfpga login:`, iniciar sesión como `root`, utilizando las credenciales de la imagen de referencia.

### Verificación del sistema

En la consola Linux de la DE1-SoC:

```bash
uname -a
cat /proc/partitions
mount
```

Resultado obtenido:

```text
Linux socfpga 3.12.0-00307-g507abb4-dirty
armv7l GNU/Linux
```

Se verificó el inicio de sesión, la detección de la microSD y el montaje del sistema raíz.

## 5. Acceso a la partición FAT32

Crear el punto de montaje:

```bash
mkdir -p /mnt/sdcard
```

Montar la partición en modo de solo lectura:

```bash
mount -t vfat -o ro /dev/mmcblk0p1 /mnt/sdcard
```

Consultar los archivos:

```bash
ls -lah /mnt/sdcard
```

La imagen contiene los siguientes archivos de arranque:

- `soc_system.rbf`: imagen de configuración FPGA de referencia.
- `socfpga.dtb`: descripción de hardware utilizada por Linux.
- `zImage`: imagen del kernel Linux.

Estos archivos deben conservarse para no alterar el arranque de referencia.

## 6. Almacenamiento de canciones WAV

Se creó la carpeta:

```text
/mnt/sdcard/canciones/
```

Para crearla se montó temporalmente la partición FAT32 con permisos de escritura. Las pruebas confirmaron que el HPS puede crear, leer y eliminar archivos dentro de esta carpeta.

Posteriormente se copiaron desde Ubuntu tres archivos WAV de prueba:

| Archivo | Frecuencia | Canales | Resolución |
|---|---|---|---|
| `prueba_8000_mono.wav` | 8000 Hz | Mono | 16 bits |
| `prueba_16000_estereo.wav` | 16000 Hz | Estéreo | 16 bits |
| `prueba_44100_estereo.wav` | 44100 Hz | Estéreo | 16 bits |

Para comprobar su presencia desde Linux:

```bash
ls -lh /mnt/sdcard/canciones/
```

**Resultado:** los tres archivos fueron encontrados correctamente en la microSD por el HPS.

El montaje de la partición FAT32 debe repetirse después de reiniciar, mientras no se configure un montaje automático.

## 7. Catálogo y validación WAV

Se implementó el archivo:

```text
src/sw/hps_linux/main.c
```

Este programa permite:

- Recorrer una carpeta de archivos WAV.
- Identificar archivos RIFF/WAVE.
- Comprobar formato PCM, resolución de 16 bits y canales mono/estéreo.
- Validar las frecuencias de 8000, 16000 y 44100 Hz.
- Mostrar información básica y duración de los archivos.

Compilación en Ubuntu:

```bash
gcc -std=c11 -Wall -Wextra \
  src/sw/hps_linux/main.c \
  -o src/sw/hps_linux/wav_catalog
```

Ejecución de pruebas:

```bash
./src/sw/hps_linux/wav_catalog pruebas_wav
```

**Resultado:** se reconocieron correctamente los tres archivos de prueba.

Estas pruebas se realizaron en Ubuntu sobre la computadora de desarrollo. La ejecución nativa del programa en el HPS ARM todavía está pendiente.

## 8. Integración HPS–Nios V

El equipo dispone del protocolo definido en:

```text
src/docs/protocolo-hps-niosv.md
src/sw/common/player_proto.h
```

Las direcciones previstas son:

| Región | Dirección HPS | Dirección Nios V |
|---|---|---|
| CTRL_RAM | `0xFF200000` | `0x30000` |
| PCM_RAM | `0xFF210000` | `0x40000` |

El protocolo contempla comandos, eventos, estados del reproductor y un anillo de 16384 palabras PCM estéreo.

**Estado actual:** las direcciones y estructuras están definidas en el proyecto, pero todavía debe validarse su funcionamiento con el diseño FPGA personalizado. La imagen Linux de Terasic utilizada para el arranque contiene un diseño FPGA de referencia distinto del diseño del equipo.

## 9. Resultados y estado

| Prueba | Resultado |
|---|---|
| Boot de Linux desde microSD | Exitoso |
| Acceso a consola UART | Exitoso |
| Inicio de sesión en HPS | Exitoso |
| Detección de particiones | Exitoso |
| Montaje FAT32 | Exitoso |
| Escritura, lectura y eliminación de archivo | Exitoso |
| Acceso a los tres WAV desde HPS | Exitoso |
| Validación de formatos WAV en Ubuntu | Exitoso |
| Ejecución del software WAV sobre ARM | Pendiente |
| Transferencia PCM a Nios V | Pendiente |
| Validación de bridges con FPGA personalizada | Pendiente |

## 10. Trabajo pendiente

- Implementar `wav_reader.c` y `wav_reader.h`.
- Leer muestras PCM de 16 bits y convertir audio mono a estéreo.
- Compilar el software HPS para ARM.
- Automatizar el montaje de la partición de canciones.
- Integrar la comunicación usando `player_proto.h`.
- Validar la transferencia de muestras mediante las memorias compartidas del hardware del equipo.
- Ejecutar pruebas completas de reproducción y filtros.

## 11. Observaciones

La imagen Linux de referencia utiliza un kernel de 2014. Su funcionamiento fue validado para el arranque y el acceso básico a archivos, pero todavía no se ha demostrado la compatibilidad completa con el hardware FPGA personalizado.

Este documento registra los procedimientos y resultados de las pruebas realizadas en la tarjeta física DE1-SoC.

## 12. Prueba de rendimiento de lectura desde microSD

Se realizó una medición de lectura sobre el archivo `prueba_44100_estereo.wav` utilizando Linux en el HPS de la tarjeta DE1-SoC.

Para cada ejecución se limpiaron las cachés recuperables del sistema mediante `/proc/sys/vm/drop_caches` y se leyó el archivo con `dd`, utilizando bloques de 4096 bytes.

| Prueba | Tiempo real |
|---|---|
| 1 | 0,08 s |
| 2 | 0,08 s |
| 3 | 0,08 s |
| 4 | 0,08 s |
| 5 | 0,08 s |
| **Promedio observado** | **0,08 s (80 ms)** |

Las cinco pruebas finalizaron correctamente, leyendo el archivo completo de aproximadamente 172,3 KiB.

Los tiempos corresponden a la operación completa de lectura y no representan directamente la latencia de cada bloque individual. Las mediciones incluyen la ejecución del programa `dd` y están limitadas por la resolución de la herramienta utilizada.

Esta prueba verifica el acceso a los datos almacenados en la microSD y proporciona una medición preliminar del rendimiento de lectura desde el HPS.