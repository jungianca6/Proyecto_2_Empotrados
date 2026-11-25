# Revisión del reporte Quartus de audio

## 1. Alcance

Esta revisión usa el resultado guardado en `hw/quartus_build/` para el proyecto `de1_soc_audio`. No representa ejecución en placa ni validación física del códec.

Herramienta observada: Quartus Prime Lite 25.1std.0. Dispositivo: 5CSEMA5F31C6.

## 2. Resultado de compilación

| Métrica | Valor observado |
|---------|-----------------|
| ALMs | 2,563 / 32,070 (8%) |
| Registros dedicados | 3,569 |
| M10K | 68 / 397 (17%) |
| Bloques DSP | 0 / 87 (0%) |
| PLL | 0 / 6 (0%) en el diseño compilado |
| Setup slack mínimo | 8.390 ns |
| Hold slack mínimo | 0.112 ns |
| Archivo de programación | `de1_soc_audio.sof` |

La compilación finalizó correctamente. El Timing Analyzer no debe interpretarse como validación de las rutas I2S/audiófilas porque no existen todas las restricciones de reloj y pines del subsistema final.

## 3. Clasificación de warnings

### 3.1 Debe corregirse antes de entrega

| Warning | Causa | Acción requerida |
|---------|-------|------------------|
| 332060: `aud_xck_reg` sin asignación de clock | el divisor manual se usa como reloj | reemplazar por PLL y crear `create_clock` o `derive_pll_clocks` cuando corresponda |
| 15714: pines con asignaciones I/O incompletas | faltan o están incompletas asignaciones de top | completar QSF final con pines, I/O estándar y pull-ups I2C requeridas |
| 16406/16407: reloj `KEY[0]` por ruta global no dedicada | reset usado como fuente global en un ejemplo | separar reset async de clock y verificar que reset no sea reloj |
| 10259: constant value overflow en filtros | literales saturación pueden interpretarse de forma no deseada | usar literales signed explícitos o casts, por ejemplo `32'sd32767` con cuidado de anchura |
| 20013: reset controller ignorado | asignaciones de jerarquía no existen en este build | limpiar SDC/QSF y regenerar Platform Designer si cambió la jerarquía |
| 24850: licencia IP/NiosV | el Environment tuvo 401 al obtener licencia | archivar validación/licencia o cerrar el entorno antes de build reproducible |
| 12241: jerarquía con connectivity warning | existen conexiones o puertos por revisar | abrir Connectivity Checks y cerrarlo antes de integrar el subsistema |

### 3.2 Benignos o internos si se mantienen sin cambios

| Warning | Diagnóstico |
|---------|-------------|
| 18236 processors not specified | afecta paralelismo de build, no funcionalidad | agregar `NUM_PARALLEL_PROCESSORS` al QSF o invocación |
| 292013 LogicLock sin licencia | la función no está usada por el diseño actual | no requiere cambio funcional |
| 12090 entity obtenida de submodule en vez de megafunction | selección de fuente Platform Designer o biblioteca generada | acceptable si las fuentes generadas son las aprobadas |
| 14285/14320 RVFI nodes synthesized away | señales de debug/Nios no usadas | benigno si no se necesita RVFI/JTAG diagnóstico |
| 21700 `assert` ignored for synthesis | assertions de IP no se sintetizan | no afectan la ruta funcional; conservar para simulación si aplica |
| 287013 data_b/rden_a never used | señales internas de IP/ram no usadas | benigno si el megafunction usa puertos opcionales |
| 10230 truncado 3 a 1 bits en AXI/Nios | comportamiento observado en IP generado | revisar jerarquía: si es parte del sistema Nios generado, no editar internamente sin regeneración |
| 12189 evaluación IP | advertencia de licencia/código de evaluación | confirma limitaciones de distribución de IP; documentar licencia o eliminar IP si no corresponde |

## 4. Warnings HDL específicos

Los warnings 10259 mencionan `LowPassFilter.sv`, `HighPassFilter.sv` y `BassBoostFilter.sv`. Conviene corregir la forma de las constantes antes de la siguiente compilación, porque los testbenches Icarus no sustituyen el análisis de literales por Quartus.

Ejemplos conceptuales:

```text
32'sd32767
automatic logic signed [15:0] sat16(...)
```

No se sustituyó el RTL en esta etapa para no cambiar el diseño ya compilado sin ejecutar una compilación posterior.

## 5. Relojes y restricciones pendientes

No hay PLL declarada en el build analizado. El diseño usa `CLOCK_50 -> aud_xck_reg`, con 25 MHz teóricos. El objetivo de audio requiere una PLL que genere 12.288 MHz a 48 kHz o 11.2896 MHz a 44.1 kHz, más restricciones de False Path/Max Delay coherentes.

Debe agregarse al menos:

- entrada de reloj 50 MHz;
- PLL/clocks derivados y sus multiplicadores;
- restricciones de reset;
- constraints de pines externos del WM8731;
- exclusión o synchronizer de CDC de FIFOs;
- dominio `audio_clk` no derivado de una expresión RTL tipo toggling.

## 6. Recursos

El uso de 2563 ALMs / 32070 y 68 M10K muestra margen de recurso. El sistema de filtros no usa bloques DSP en el reporte. No debe concluirse de esto que el resultado final sea más liviano: integrar Nios/HPS/FIFOs/PLL puede aumentar registros y memoria.

## 7. Potencia

No se encontró un reporte de potencia en el directorio inspeccionado. Por ello no debe informar todavía consumo total, estático o dinámico. El procedimiento final debe ejecutar Power Analyzer con archivo de actividad, modo de operación y tensiones de placa, o declarar explícitamente que el dato no está disponible.

## 8. Lista de cierre antes de recompilar

- [ ] Definir PLL y familia de tasa de salida.
- [ ] Completar pines I/O.
- [ ] Asignar reloj correcto a `aud_xck_reg` o reemplazarlo.
- [ ] Revisar literales signed de saturación.
- [ ] Regenerar Platform Designer y borrar asignaciones obsoletas.
- [ ] Resolver Connectivity Checks.
- [ ] Ejecutar TimeQuest/Timing Analyzer con constraints finales.
- [ ] Guardar map/fit/sta/flow/sof y una revisión de potencia si aplica.
