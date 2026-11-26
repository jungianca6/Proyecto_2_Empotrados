
# Software HPS Linux — Reproductor de Audio Avanzado

## 1. Objetivo

Configurar y verificar el arranque de Linux en el procesador HPS ARM Cortex-A9 de la tarjeta DE1-SoC, utilizando una microSD como medio de arranque y almacenamiento de archivos WAV.

También se implementan los componentes de software necesarios para acceder a los archivos, validar su formato, extraer metadatos, convertir muestras PCM y preparar la comunicación con el procesador Nios V.

Este trabajo corresponde al Milestone 3 del proyecto y comprende principalmente:

- **Issue #39:** Configurar y verificar el arranque de Linux en HPS desde SD.
- **Issue #13:** Acceso a SD y sistema de archivos.
- **Issue #14:** Parser WAV y extracción de metadatos.
- **Integración HPS–Nios V:** Preparación del anillo de transferencia PCM.

## 2. Hardware y software utilizado

| Elemento | Descripción |
|---|---|
| Tarjeta | Terasic DE1-SoC, Cyclone V SoC |
| Procesador | HPS ARM Cortex-A9 |
| Almacenamiento | microSD de 16 GB |
| Imagen Linux | `DE1_SoC_FB.img` |
| Sistema operativo HPS | Linux 3.12.0 |
| Arquitectura | ARMv7 (`armv7l`) |
| Comunicación | UART del HPS, puerto J4 |
| Velocidad UART | 115200 baudios, 8N1 |
| Computadora de desarrollo | Ubuntu |
| Compilador local | GCC |
| Compilador cruzado | `arm-linux-gnueabihf-gcc` |
| Compilación ARM verificada | GCC 15.2.0 |

La imagen utilizada corresponde a **Linux Console with framebuffer**, distribuida por Terasic.

El software se desarrolla y prueba inicialmente en Ubuntu. Posteriormente, los componentes compatibles se compilan para ARM y se ejecutan en el HPS.

## 3. Preparación de la microSD

Se utilizó la imagen de referencia de Terasic para preparar el sistema de arranque.

Procedimiento:

1. Descargar `DE1_SoC_FB.zip` desde la sección Linux BSP de Terasic.
2. Descomprimir el archivo para obtener `DE1_SoC_FB.img`.
3. Grabar la imagen en la microSD utilizando balenaEtcher.
4. Verificar que la grabación finalice correctamente.
5. Expulsar la microSD de manera segura.

**Advertencia:** grabar una imagen de disco sobrescribe las particiones y los datos existentes en el dispositivo seleccionado.

### 3.1. Particiones identificadas

| Partición en HPS | Tipo | Tamaño aproximado | Función |
|---|---|---|---|
| `/dev/mmcblk0p1` | FAT32 | 819 MiB | Archivos de arranque y canciones |
| `/dev/mmcblk0p2` | Linux/ext3 | 1 GiB | Sistema operativo |
| `/dev/mmcblk0p3` | Altera A2 | 1 MiB | Datos de arranque del HPS |

La imagen fue grabada en una microSD con aproximadamente 14,6 GiB de capacidad utilizable.

En Ubuntu, durante las pruebas, la tarjeta apareció como `/dev/sda`, con la partición FAT32 en `/dev/sda1`.

La identificación del dispositivo debe comprobarse antes de realizar operaciones de montaje o escritura.

## 4. Arranque de Linux en la DE1-SoC

Para la imagen de referencia utilizada, se configuraron los cinco bits MSEL en `00000`, manteniendo los demás interruptores conforme a la configuración funcional de las pruebas.

### 4.1. Procedimiento

1. Apagar la tarjeta DE1-SoC.
2. Insertar la microSD.
3. Conectar el puerto UART J4 a la computadora.
4. Conectar la fuente de alimentación.
5. Abrir una terminal en Ubuntu.
6. Iniciar la conexión serial:

```bash
sudo screen /dev/ttyUSB0 115200
```

7. Encender la DE1-SoC.
8. Observar los mensajes del sistema.
9. Iniciar sesión cuando aparezca `socfpga login:`.

En la imagen utilizada se pudo acceder mediante el usuario `root`.

El dispositivo `/dev/ttyUSB0` debe verificarse en cada computadora.

### 4.2. Verificación del sistema

Desde la consola del HPS:

```bash
uname -a
cat /proc/partitions
mount
```

Resultado identificado:

```text
Linux socfpga 3.12.0-00307-g507abb4-dirty
armv7l GNU/Linux
```

Se verificó:

- Arranque exitoso del sistema Linux.
- Inicio de sesión mediante UART.
- Acceso al sistema de archivos.
- Detección de la microSD.
- Identificación de las particiones del dispositivo.

### 4.3. Consideraciones de la conexión serial

Durante las pruebas se observaron problemas de visualización de comandos largos.

La consola serial puede mostrar un comportamiento de sobrescritura visual cuando una línea supera el ancho disponible.

Para facilitar la ejecución, se recomienda utilizar rutas relativas y comandos cortos.

También se verificó que las sesiones de GNU Screen pueden consultarse mediante:

```bash
sudo screen -ls
```

Para comprobar qué procesos utilizan el puerto serial:

```bash
sudo fuser -v /dev/ttyUSB0
```

Se debe evitar mantener múltiples programas conectados simultáneamente al mismo puerto UART.

## 5. Acceso a la partición FAT32

La partición FAT32 no se monta automáticamente en la configuración utilizada.

Por ello se crea un punto de montaje:

```bash
mkdir -p /mnt/sdcard
```

Posteriormente se monta en modo de solo lectura:

```bash
mount -t vfat -o ro /dev/mmcblk0p1 /mnt/sdcard
```

Para consultar su contenido:

```bash
ls -lah /mnt/sdcard
```

### 5.1. Archivos de arranque

En la partición FAT32 se identificaron:

- `soc_system.rbf`: configuración FPGA de referencia.
- `socfpga.dtb`: descripción de hardware utilizada por Linux.
- `zImage`: imagen del kernel Linux.

Estos archivos se conservaron sin modificaciones durante las pruebas de acceso a SD y procesamiento WAV.

### 5.2. Pruebas de acceso

Se verificó que el HPS puede:

- Detectar la partición FAT32.
- Montarla correctamente.
- Listar directorios y archivos.
- Leer archivos almacenados en la microSD.
- Crear y eliminar archivos cuando se habilita temporalmente la escritura.

El montaje de la partición debe repetirse después de reiniciar, mientras no se configure un mecanismo automático.

## 6. Almacenamiento y catálogo WAV — Issue #13

Se creó el directorio:

```text
/mnt/sdcard/canciones/
```

Este directorio almacena los archivos WAV utilizados durante las pruebas.

### 6.1. Formatos utilizados

Se prepararon archivos WAV PCM de 16 bits con las siguientes características:

| Formato | Frecuencia | Canales |
|---|---|---|
| WAV mono | 8000 Hz | 1 |
| WAV estéreo | 16000 Hz | 2 |
| WAV estéreo | 44100 Hz | 2 |

Posteriormente se amplió el conjunto de prueba hasta alcanzar **10 archivos WAV**.

### 6.2. Verificación de archivos en el HPS

Se ejecutó:

```bash
ls -lh /mnt/sdcard/canciones/
```

También se verificó la cantidad:

```bash
find /mnt/sdcard/canciones -maxdepth 1 -name '*.wav' | wc -l
```

Resultado:

```text
10
```

Se confirmó que el HPS detectó correctamente los diez archivos WAV almacenados en la microSD.

## 7. Catálogo y validación básica de WAV

Se implementó el programa:

```text
src/sw/hps_linux/main.c
```

Su función es recorrer un directorio e identificar archivos WAV compatibles.

El programa permite:

- Recorrer una carpeta de archivos WAV.
- Identificar encabezados RIFF/WAVE.
- Validar el formato PCM.
- Verificar resolución de 16 bits.
- Reconocer audio mono y estéreo.
- Validar frecuencias de 8000, 16000 y 44100 Hz.
- Mostrar información básica y duración de los archivos.

### 7.1. Compilación en Ubuntu

Desde la raíz del repositorio:

```bash
gcc -std=c11 -Wall -Wextra \
  src/sw/hps_linux/main.c \
  -o src/sw/hps_linux/wav_catalog
```

### 7.2. Ejecución

```bash
./src/sw/hps_linux/wav_catalog pruebas_wav
```

Durante las pruebas locales se validaron diez archivos WAV compatibles.

**Alcance:** el catálogo `main.c` fue probado en Ubuntu. La validación posterior en el HPS ARM corresponde al módulo `wav_reader.c`, descrito en las siguientes secciones.

## 8. Rendimiento de lectura desde microSD — Issue #13

Se realizaron mediciones de lectura desde el HPS utilizando el archivo:

```text
prueba_44100_estereo.wav
```

Su tamaño aproximado era de 172,3 KiB.

Para reducir la influencia de las cachés de archivos, antes de cada prueba se ejecutó:

```bash
echo 3 > /proc/sys/vm/drop_caches
```

Posteriormente se realizó la lectura utilizando `dd` con bloques de 4096 bytes.

### 8.1. Comando utilizado

```bash
sync

for i in 1 2 3 4 5; do
    echo "Prueba $i"

    echo 3 > /proc/sys/vm/drop_caches

    /usr/bin/time -p dd \
        if=/mnt/sdcard/canciones/prueba_44100_estereo.wav \
        of=/dev/null bs=4096
done
```

### 8.2. Resultados

| Prueba | Tiempo real |
|---|---|
| 1 | 0,08 s |
| 2 | 0,08 s |
| 3 | 0,08 s |
| 4 | 0,08 s |
| 5 | 0,08 s |
| **Promedio observado** | **0,08 s (80 ms)** |

Las cinco ejecuciones finalizaron correctamente.

En cada ejecución se procesó el archivo completo utilizando bloques de 4096 bytes.

### 8.3. Interpretación

Las mediciones permiten verificar que Linux puede leer los datos de la microSD de forma consistente.

Sin embargo, los 80 ms corresponden al tiempo total observado para leer el archivo completo, no a la latencia individual de un bloque.

La medición también incluye la ejecución de `dd` y está limitada por la resolución temporal de `/usr/bin/time -p`.

Por ello, estos resultados deben interpretarse como una medición preliminar del rendimiento de lectura.

## 9. Parser WAV y metadatos — Issue #14

Se implementaron los archivos:

```text
src/sw/hps_linux/wav_reader.h
src/sw/hps_linux/wav_reader.c
```

El lector permite abrir archivos WAV PCM compatibles y obtener sus características.

### 9.1. Formatos admitidos

- Formato RIFF/WAVE.
- Audio PCM sin compresión.
- Resolución de 16 bits.
- Uno o dos canales.
- Frecuencias de 8000, 16000 y 44100 Hz.

Se validan los campos principales del encabezado y la estructura de los bloques utilizados por el lector.

### 9.2. Duración

La duración total se calcula a partir de:

- Cantidad de bytes de audio.
- Frecuencia de muestreo.
- Número de canales.
- Tamaño de cada muestra.

La duración se almacena en segundos enteros.

Por esta razón, un archivo con duración menor a un segundo puede mostrar:

```text
Duracion: 0 segundos
```

Esto no representa un error de lectura, sino el truncamiento del resultado a segundos enteros.

### 9.3. Metadatos LIST/INFO

El lector identifica los siguientes campos:

| Código | Metadato |
|---|---|
| `INAM` | Título |
| `IART` | Artista |
| `IPRD` | Álbum |

Se implementó la búsqueda de metadatos en bloques `LIST/INFO` ubicados antes o después del bloque `data`.

El programa conserva la posición del audio para regresar a ella después de analizar los metadatos.

### 9.4. Convención para archivos sin metadatos

Cuando un archivo WAV no contiene los campos correspondientes, se utiliza:

| Campo | Valor predeterminado |
|---|---|
| Título | Nombre del archivo sin `.wav` |
| Artista | `Desconocido` |
| Álbum | `Desconocido` |

Por ejemplo, para:

```text
prueba_8000_mono.wav
```

El resultado es:

```text
Titulo: prueba_8000_mono
Artista: Desconocido
Album: Desconocido
Tiene metadatos: No
```

## 10. Conversión de muestras PCM

El módulo `wav_reader.c` también proporciona la función:

```c
size_t wav_read_pcm(wav_reader_t *wav,
                    uint32_t *output,
                    size_t max_words);
```

Esta función lee muestras PCM de 16 bits y las convierte al formato de 32 bits acordado para la comunicación HPS–Nios V.

### 10.1. Formato de palabra PCM

Cada palabra de 32 bits contiene:

| Bits | Contenido |
|---|---|
| 15:0 | Canal izquierdo, 16 bits |
| 31:16 | Canal derecho, 16 bits |

Cuando el archivo original es mono, la muestra se duplica en ambos canales.

### 10.2. Pruebas locales

Se ejecutaron pruebas utilizando archivos WAV de un segundo.

| Frecuencia | Canales | Palabras PCM generadas |
|---|---|---|
| 8000 Hz | Mono | 8000 |
| 16000 Hz | Estéreo | 16000 |
| 44100 Hz | Estéreo | 44100 |

Todas las pruebas finalizaron con cero bytes pendientes.

También se generó un WAV con valores conocidos para comprobar la correspondencia entre canales.

Resultados:

```text
Muestra 0: L=1000 R=-1000
Muestra 1: L=2000 R=-2000
Muestra 2: L=-3000 R=3000
```

Se confirmó la correcta interpretación de las muestras positivas y negativas.

## 11. Pruebas de metadatos en Ubuntu

Se prepararon tres escenarios:

1. Archivo WAV con `LIST/INFO` antes del audio.
2. Archivo WAV con `LIST/INFO` después del audio.
3. Archivo WAV sin metadatos.

Para los dos primeros casos se utilizaron los siguientes valores:

```text
Titulo: Cancion de prueba
Artista: Artista de prueba
Album: Album de prueba
Tiene metadatos: Si
```

En el tercer escenario se verificaron los valores predeterminados.

Las tres pruebas finalizaron correctamente.

También se comprobó que la lectura de las muestras PCM continuaba funcionando después de incorporar el procesamiento de metadatos.

## 12. Compilación cruzada para ARM

Para ejecutar el lector directamente en el HPS de la DE1-SoC, se instaló el compilador:

```text
arm-linux-gnueabihf-gcc
```

La versión utilizada durante las pruebas fue GCC 15.2.0.

### 12.1. Compilación

Desde la raíz del repositorio:

```bash
arm-linux-gnueabihf-gcc \
  -std=c11 -Wall -Wextra -Werror \
  -O2 -static \
  src/sw/hps_linux/wav_reader.c \
  src/sw/hps_linux/test_wav_reader.c \
  -o /tmp/test_wav_reader_arm
```

Se utilizó enlace estático para reducir las dependencias de bibliotecas dinámicas del sistema Linux antiguo.

### 12.2. Verificación del ejecutable

Se ejecutó:

```bash
file /tmp/test_wav_reader_arm
```

Resultado:

```text
ELF 32-bit LSB executable, ARM, EABI5
statically linked, for GNU/Linux 3.2.0
```

El ejecutable generado tenía un tamaño aproximado de 477 KiB.

### 12.3. Preparación de microSD

Desde Ubuntu se montó la partición FAT32:

```bash
sudo mkdir -p /mnt/de1soc
sudo mount /dev/sda1 /mnt/de1soc
```

Se copiaron el ejecutable y los archivos de prueba:

```bash
sudo cp /tmp/test_wav_reader_arm /mnt/de1soc/

sudo cp pruebas_wav/metadata_antes.wav \
  /mnt/de1soc/canciones/

sudo cp pruebas_wav/metadata_despues.wav \
  /mnt/de1soc/canciones/
```

Finalmente:

```bash
sync
sudo umount /mnt/de1soc
```

**Nota:** `/dev/sda1` fue la ruta identificada durante estas pruebas y debe verificarse nuevamente en otros equipos.

## 13. Validación real en el HPS ARM — Issue #14

Se encendió la DE1-SoC utilizando la imagen Linux de referencia y se accedió al HPS mediante UART.

Después de montar la partición FAT32, se ingresó al directorio:

```bash
cd /mnt/sdcard
```

### 13.1. Prueba con metadatos antes del audio

```bash
./test_wav_reader_arm canciones/metadata_antes.wav
```

Resultado:

```text
Frecuencia: 16000 Hz
Canales: 2
Bits: 16
Duracion: 0 segundos
Titulo: Cancion de prueba
Artista: Artista de prueba
Album: Album de prueba
Tiene metadatos: Si
Muestra 0: L=1000 R=-1000
Muestra 1: L=2000 R=-2000
Palabras PCM generadas: 2
Bytes restantes: 0
```

### 13.2. Prueba con metadatos después del audio

```bash
./test_wav_reader_arm canciones/metadata_despues.wav
```

Resultado:

```text
Frecuencia: 16000 Hz
Canales: 2
Bits: 16
Duracion: 0 segundos
Titulo: Cancion de prueba
Artista: Artista de prueba
Album: Album de prueba
Tiene metadatos: Si
Muestra 0: L=1000 R=-1000
Muestra 1: L=2000 R=-2000
Palabras PCM generadas: 2
Bytes restantes: 0
```

### 13.3. Prueba sin metadatos

```bash
./test_wav_reader_arm canciones/prueba_8000_mono.wav
```

Resultado:

```text
Frecuencia: 8000 Hz
Canales: 1
Bits: 16
Duracion: 1 segundos
Titulo: prueba_8000_mono
Artista: Desconocido
Album: Desconocido
Tiene metadatos: No
Palabras PCM generadas: 8000
Bytes restantes: 0
```

### 13.4. Conclusiones de la validación ARM

Las tres ejecuciones finalizaron correctamente sobre el procesador ARM del HPS.

Se comprobó:

- Compatibilidad del ejecutable con el Linux utilizado.
- Lectura de archivos WAV desde FAT32.
- Identificación de formato, frecuencia, canales y resolución.
- Obtención de título, artista y álbum desde `LIST/INFO`.
- Funcionamiento de la convención para archivos sin metadatos.
- Lectura de muestras PCM.
- Finalización de los archivos sin bytes pendientes.

Por tanto, el parser WAV fue validado tanto en Ubuntu como en el HPS real de la DE1-SoC.

## 14. Integración con el anillo PCM — Simulación

Se implementaron los archivos:

```text
src/sw/hps_linux/pcm_ring.h
src/sw/hps_linux/pcm_ring.c
```

Su función es escribir muestras PCM en el anillo circular definido para la memoria compartida HPS–Nios V.

### 14.1. Protocolo utilizado

Las estructuras y direcciones fueron definidas en:

```text
src/sw/common/player_proto.h
src/docs/protocolo-hps-niosv.md
```

| Región | Dirección HPS | Dirección Nios V |
|---|---|---|
| CTRL_RAM | `0xFF200000` | `0x30000` |
| PCM_RAM | `0xFF210000` | `0x40000` |

El anillo dispone de:

```text
PCM_RING_WORDS = 16384
```

Cada posición contiene una palabra PCM estéreo de 32 bits.

### 14.2. Control de escritura y lectura

Los índices utilizados son:

- `pcm_wr`: actualizado por el HPS.
- `pcm_rd`: actualizado por el Nios V.

La ocupación se calcula mediante:

```text
ocupacion = pcm_wr - pcm_rd
```

El espacio disponible se calcula como:

```text
espacio = PCM_RING_WORDS - ocupacion
```

El HPS solamente escribe cuando existe espacio suficiente.

La implementación utiliza una barrera de memoria antes de publicar el nuevo índice de escritura.

### 14.3. Pruebas del anillo

Se implementó:

```text
src/sw/hps_linux/test_pcm_ring.c
```

Se verificaron los siguientes escenarios:

| Prueba | Resultado |
|---|---|
| Escritura inicial | Exitoso |
| Liberación de espacio por consumidor simulado | Exitoso |
| Escritura circular al llegar al final | Exitoso |
| Protección contra sobrescritura | Exitoso |

Resultado:

```text
TODAS LAS PRUEBAS PCM RING PASARON
```

### 14.4. Pruebas WAV → PCM_RING

Se implementó:

```text
src/sw/hps_linux/test_wav_to_ring.c
```

Este programa conecta el lector WAV con el anillo PCM simulado.

Resultados:

| Archivo | Palabras escritas | Palabras consumidas | Ocupación final |
|---|---|---|---|
| WAV 8 kHz | 8000 | 8000 | 0 |
| WAV 16 kHz | 16000 | 16000 | 0 |
| WAV 44,1 kHz | 44100 | 44100 | 0 |

Las tres pruebas finalizaron con:

```text
OK: transferencia WAV a PCM_RING simulada
```

**Importante:** estas pruebas se realizaron en Ubuntu, utilizando memoria simulada.

El consumidor simulado actualiza `pcm_rd`, pero no reproduce audio ni valida todavía la sincronización entre procesadores reales.

Por tanto, la comunicación física HPS–Nios V continúa pendiente de integración.

## 15. Evidencias

Las capturas de las pruebas se almacenan en:

```text
src/docs/evidencias/
```

Entre las evidencias recopiladas se encuentran:

- Arranque Linux y acceso a la microSD.
- Catálogo de diez archivos WAV.
- Mediciones de rendimiento de lectura.
- Pruebas de formatos y conversión PCM en Ubuntu.
- Pruebas de metadatos `LIST/INFO` en Ubuntu.
- Validación del parser WAV directamente en el HPS ARM.

### 15.1. Evidencias del parser WAV

**Pruebas locales de formatos WAV:**

```text
src/docs/evidencias/hps-wav-parser-formatos.png
```

**Pruebas locales de metadatos:**

```text
src/docs/evidencias/hps-wav-parser-metadatos.png
```

**Validación completa en el HPS ARM:**

```text
src/docs/evidencias/hps-arm-wav-validacion-completa.png
```

La última evidencia corresponde a las pruebas realizadas directamente sobre Linux ARM en la DE1-SoC.

Los nombres de los archivos deben coincidir con las capturas almacenadas en el repositorio.

## 16. Resumen de resultados

| Funcionalidad | Resultado |
|---|---|
| Arranque Linux desde microSD | Verificado |
| Comunicación UART | Verificado |
| Inicio de sesión en HPS | Verificado |
| Detección de particiones | Verificado |
| Montaje FAT32 | Verificado |
| Lectura y escritura básica de archivos | Verificado |
| Listado de diez WAV en microSD | Verificado |
| Medición preliminar de rendimiento SD | Realizada |
| Validación básica de formatos WAV | Verificada en Ubuntu |
| Parser WAV y metadatos | Verificado en Ubuntu y HPS ARM |
| Conversión WAV a PCM estéreo | Verificada en Ubuntu |
| Lectura de muestras PCM en HPS | Verificada |
| Escritura en anillo PCM | Verificada en simulación |
| Transferencia WAV a anillo simulado | Verificada |
| Transferencia real HPS–Nios V | Pendiente |
| Reproducción mediante hardware FPGA | Pendiente |

## 17. Trabajo pendiente

Los principales pasos restantes para la integración completa son:

1. Implementar el servicio HPS que procese los eventos `EVT_REQ_LOAD` y `EVT_REQ_STOP`.
2. Integrar el lector WAV con el anillo PCM dentro del servicio de reproducción.
3. Gestionar el catálogo de canciones y la selección de pistas.
4. Implementar la señalización de fin de archivo mediante `HPS_FLAG_EOF`.
5. Integrar los comandos `CMD_LIST_READY`, `CMD_TRACK_READY` y `CMD_TRACK_ERROR`.
6. Verificar el funcionamiento de los bridges HPS–FPGA con el diseño personalizado del equipo.
7. Comprobar el acceso real a CTRL_RAM y PCM_RAM desde ambos procesadores.
8. Validar la sincronización de índices y eventos durante cambios de canción, pausa y reproducción.
9. Integrar los controles de reproducción y los módulos de audio y filtros.
10. Ejecutar pruebas completas en la tarjeta DE1-SoC.

Como mejoras adicionales se contempla automatizar el montaje de la partición FAT32 y ampliar las pruebas con archivos WAV reales y entradas inválidas.

## 18. Observaciones

La imagen Linux utilizada corresponde a una distribución de referencia de Terasic con kernel 3.12.

Su funcionamiento fue validado para arranque, acceso a archivos y ejecución del parser WAV compilado para ARM.

Sin embargo, el archivo `soc_system.rbf` de la imagen de referencia no corresponde necesariamente al diseño FPGA personalizado del equipo.

Por esta razón, el funcionamiento de Linux y del lector WAV no demuestra todavía la compatibilidad de las memorias compartidas con el hardware personalizado.

Antes de utilizar las direcciones físicas del protocolo, deberá verificarse que el diseño FPGA cargado incluya las regiones CTRL_RAM y PCM_RAM con el direccionamiento acordado.

Este documento registra los procedimientos, resultados y limitaciones de las pruebas realizadas hasta la etapa actual del Milestone 3.
