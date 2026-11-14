# Proyecto II: Co-diseño Hardware/Software de SoC con Hardware Personalizado para Reproductor de Audio Avanzado

## 1. Información General
* **Institución:** Instituto Tecnológico de Costa Rica
* **Escuela:** Ingeniería en Computadores
* **Curso:** CE-1113 Sistemas Empotrados
* **Profesor:** Dr.-Ing. Jeferson González Gómez
* **Fecha de entrega:** 2 de diciembre, 2026
* **Equipo:** Giancarlo Vega, Bryan Feng, Alisson Redondo, Sebastian Chaves

## 2. Descripción del Proyecto

El proyecto consiste en el co-diseño hardware/software de un SoC avanzado para un reproductor de audio portátil en una tarjeta Altera DE-SoC1, utilizando una metodología de diseño a nivel de sistema (System Level Design). El equipo aplicará un flujo de trabajo moderno que incluye el modelado de sistemas heterogéneos y el análisis de trade-offs para particionar funciones entre el procesador HPS y la lógica FPGA. Se implementará un sistema Bare Metal con acceso directo al hardware, evitando bibliotecas de abstracción (HAL) para desarrollar filtros digitales en tiempo real y controladores de almacenamiento personalizados. El enfoque técnico integra la gestión de metadatos y la lógica de reproducción con aceleradores de hardware dedicados, justificando cada decisión arquitectural basándose en el rendimiento y la latencia. 

## 3. Estructura Organizativa (Roles)

Por definir

## 4. Matriz de Requerimientos

| Código | Categoría | Requerimiento | Descripción Detallada |
| :--- | :--- | :--- | :--- |
| **REQ-01** | Usuario | Reproducción de audio | El sistema debe soportar al menos 10 canciones almacenadas en una tarjeta SD, en formato WAV PCM de 16 bits y con frecuencias de muestreo de 8 kHz, 16 kHz y 44.1 kHz. |
| **REQ-02** | Usuario | Navegación de pistas | El reproductor debe permitir navegar secuencialmente entre las canciones mediante las funciones Anterior y Siguiente. Al finalizar una canción, debe iniciar automáticamente la siguiente. |
| **REQ-03** | Usuario | Selección de filtros | El sistema debe ofrecer al menos tres filtros digitales diferentes, seleccionables mediante switches físicos. El filtro activo debe poder cambiarse durante la reproducción. |
| **REQ-04** | Funcional | Módulo de hardware personalizado | Se debe diseñar e implementar un componente de hardware personalizado con registros de control, estado y datos, accesibles mediante una interfaz de memoria mapeada (Avalon-MM). |
| **REQ-05** | Funcional | Procesamiento DSP | Se deben implementar al menos tres filtros digitales seleccionables. Al menos uno debe ser un bloque DSP personalizado, diseñado e implementado en HDL dentro de la FPGA. Los filtros restantes pueden implementarse en software o mediante bloques de catálogo de FPGA. |
| **REQ-06** | Funcional | Interfaz de audio | El procesamiento y envío del flujo de audio hacia el códec debe realizarse mediante la FPGA, utilizando la IP de Audio de Platform Designer. El HPS no debe encargarse directamente de controlar el códec. |
| **REQ-07** | Funcional | Gestión de almacenamiento | El HPS (ARM Cortex-A9) debe ejecutar Linux desde la tarjeta SD y gestionar el acceso al sistema de archivos para localizar y leer los archivos de audio almacenados en ella. |
| **REQ-08** | Funcional | Parseo de metadatos | El software ejecutado en el HPS debe interpretar la información de los archivos WAV para obtener la duración y, cuando estén disponibles, el título, artista y álbum de cada canción. |
| **REQ-09** | Funcional | Visualización de información | El sistema debe mostrar los metadatos de la canción actual (título, artista, álbum), mediante una interfaz externa LCD, VGA o TFT. También debe mostrar el filtro activo y el número de canción actual respecto al total disponible. |
| **REQ-10** | Funcional | Control temporal | El sistema debe medir y visualizar el tiempo transcurrido de reproducción en formato MM:SS mediante los displays de siete segmentos de la tarjeta. La implementación del control temporal puede realizarse mediante temporizadores de hardware o contadores en software. |
| **REQ-11** | Funcional | Control de reproducción | El reproductor debe implementar las funciones Play, Pausa, Stop, Anterior y Siguiente mediante los botones físicos de la tarjeta. La detección de las pulsaciones debe utilizar interrupciones. |
| **REQ-12** | Funcional | Estado de reproducción | El sistema debe indicar claramente si el reproductor se encuentra en estado Reproduciendo, Pausado o Detenido. |
| **REQ-13** | Funcional | Control de volumen | El sistema debe permitir ajustar el volumen de reproducción mediante un potenciómetro conectado al conversor ADC AD7928 de la tarjeta, utilizando la IP ADC Controller de Platform Designer. |
| **REQ-14** | Funcional | Bypass de filtros | El sistema debe permitir desactivar el procesamiento de los filtros digitales, de forma que la señal de audio pueda reproducirse sin filtrado ni distorsiones audibles introducidas por el procesamiento DSP. |
| **REQ-15** | Funcional | Comunicación entre procesadores | El sistema debe implementar un mecanismo de comunicación entre el HPS y el Nios V/m que permita coordinar las solicitudes de reproducción, pausa, detención y navegación de pistas, así como comunicar los estados relevantes del reproductor. |
| **REQ-16** | Funcional | Transferencia de datos de audio | El sistema debe implementar un mecanismo de transferencia de bloques de muestras PCM desde el HPS hacia la FPGA. Este mecanismo debe permitir que la lógica de audio consuma las muestras a la frecuencia de reproducción correspondiente, sin depender de la temporización de Linux. |
| **REQ-17** | No Funcional | Tiempo de inicio | El sistema completo, incluyendo el arranque de Linux en el HPS y la inicialización del firmware del Nios V/m, debe estar operativo en un tiempo inferior a 10 segundos después de encender o reiniciar la tarjeta. |
| **REQ-18** | No Funcional | Latencia de control | El tiempo de respuesta del sistema ante las interrupciones generadas por los botones físicos debe ser inferior a 200 ms. |
| **REQ-19** | No Funcional | Latencia de filtros | El cambio dinámico entre filtros digitales durante la reproducción debe completarse en menos de 100 ms. |
| **REQ-20** | No Funcional | Estabilidad de reproducción | El sistema debe mantener una reproducción continua, sin interrupciones audibles ocasionadas por el vaciado de buffers, errores de sincronización o problemas de comunicación entre los componentes. |
| **REQ-21** | Restricción | Desarrollo Bare Metal | El firmware del Nios V/m debe desarrollarse en C Bare Metal y utilizar acceso directo a los periféricos mediante punteros a direcciones de memoria mapeada, evitando las funciones de abstracción del HAL y las macros `IORD`/`IOWR`. |
| **REQ-22** | Restricción | Procesamiento de audio en FPGA | La ruta de reproducción hacia el códec debe utilizar la lógica de la FPGA y la IP de Audio de Platform Designer. El HPS debe encargarse de la lectura y suministro de los datos de audio, no de generar directamente las señales de audio del códec. |
| **REQ-23** | Restricción | Procesadores del sistema | La arquitectura debe integrar tanto el HPS (ARM Cortex-A9 ejecutando Linux) como el procesador Nios V/m (ejecutando firmware Bare Metal), de acuerdo con las indicaciones del profesor. |
| **REQ-24** | Verificación | Verificación del hardware personalizado | El módulo de hardware personalizado y el filtro DSP implementado en HDL deben verificarse de forma aislada antes de su integración al sistema completo, mediante testbenches o rutinas de prueba de software. Se deben documentar los casos de prueba y sus resultados. |

## 5. Flujo de Trabajo en Git

### 5.1. Estrategia de Ramas
* `main`: Rama de producción (código estable).
* `development`: Rama de integración para el trabajo diario.
* `feat/nombre-tarea`: Desarrollo de nuevas funciones.
* `fix/nombre-error`: Corrección de fallos.

### 5.2. Convención de Commits (Conventional Commits)
Formato: `tipo(alcance): descripción`
* `feat`: Nueva funcionalidad.
* `fix`: Corrección de errores.
* `docs`: Cambios en README o documentación de atributos (DI/AC).
* `refactor`: Mejoras en código existente sin cambiar comportamiento.
* `chore`: Mantenimiento general del proyecto.
* `test`: Creación o actualización de pruebas.
* `ci`: Cambios en flujos de CI/CD.
* `build`: Cambios de compilación, toolchain o sistema de build.
* `perf`: Optimización de rendimiento.
* `style`: Cambios de estilo/formato sin impacto funcional.

### 5.3. Pull Requests
* Todo PR debe estar vinculado a un **Issue**.