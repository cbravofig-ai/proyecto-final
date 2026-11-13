# Ingreso autónomo de los hogares según el sexo de la jefatura de hogar en Ñuble (CASEN 2022)

Proyecto final - Hito 1
Autora: Camila Bravo Figueroa 
Fecha: 12-11-2026
Profesor: Ariel Soto Caro

> **Estado:** Hito 1 (propuesta). Los scripts, resultados e informe se agregan 
en los hitos siguientes; lo que aún no existe aparece marcado como *(pendiente)*.

## Pregunta

¿Cuánto menor es el ingreso autónomo mensual de los hogares con jefatura femenina 
respecto de los hogares con jefatura masculina en la Región de Ñuble, entre jefaturas 
de 20 a 59 años, a igual escolaridad, edad de la jefatura y tamaño del hogar?

**Por qué importa:** 
Permite observar si los hogares con jefatura femenina tienen menos ingresos aun 
con igual escolaridad y tamaño que los hogares con jefatura masculina. Además, 
aporta evidencia para el diseño de políticas públicas en materia de brechas de 
género y permite conocer cuánto es esta diferencia en pesos.

## Datos

| | |
|---|---|
| **Fuente** | Encuesta CASEN 2022, Ministerio de Desarrollo Social y Familia |
| **Enlace** | https://observatorio.ministeriodesarrollosocial.gob.cl/encuesta-casen-2022 |
| **Fecha de descarga** | 12-11-2026 |
| **Archivos en `data/raw/`** | `casen_2022.RData` (base), `Libro_de_codigos_Casen_2022.xlsx`, `Nota_uso_base_de_datos_Casen_2022.pdf`. No se editan. |
| **Unidad de observación** | Personas en la base original; al filtrar la jefatura de hogar (`pco1 == 1`) queda un hogar por registro |
| **Cobertura** | Región de Ñuble (`region == 16`), jefaturas de 20 a 59 años. |
| **Variables** | `yauth` (ingreso autónomo del hogar), `sexo`, `edad`, `pco1`, `esc` (escolaridad), `tot_per_h` (personas en el hogar), `expr` (factor de expansión regional) |
| **Casos** | 1.791 hogares (834 con jefatura masculina, 957 con femenina); 113 con `yauth = 0`; 9 sin dato de `esc` |

Los números anteriores salen de `scripts/00_exploracion.R`.

## Modelo (tentativo)

```
ln(yauth) =β_0+β_1 (jefa_fem)+β_2 (esc)+β_3 (tot_per_h)+u
```

Estimado por MCO con ponderador `expr`. Como `ln(0)` no existe, se estimarán dos 
versiones: `ln(yauth)` sin los hogares con ingreso cero, y `asinh(yauth)` con todos 
los hogares. Los resultados se interpretarán como asociaciones y la magnitud se 
expresará en pesos.

## Estructura del repositorio

```
proyecto-final/
├── data/
│   ├── raw/                  
│   └── processed/           
├── scripts/
│   ├── 00_exploracion.R      carga, filtra y verifica la base
│   ├── 01_limpiar.R          (pendiente)
│   ├── 02_describir.R        (pendiente)
│   ├── 03_modelar.do         (pendiente)
│   └── 04_figuras.R          (pendiente)
├── output/
│   ├── figuras/              (pendiente)
│   └── tablas/               (pendiente)
├── readings/                 literatura de apoyo
├── informe.tex               (pendiente)
├── presentacion.qmd          (pendiente)
└── README.md
```

## Uso de R y Stata

- **R** para limpiar y preparar la base: viene en formato `.RData`, que Stata no 
lee, así que limpiarla en R evita una conversión previa. Los datos pasan a Stata 
como archivo `.dta` (`haven::write_dta()`).
- **Stata** para estimar: `regress` con ponderadores y `esttab`, que deja la tabla 
lista para incluirla en el informe LaTeX. Las especificaciones alternativas se 
recorren con un loop.
- **R** para comunicar: figuras con `ggplot2`, y presentación con Quarto.

## Cómo reproducir

1. Abrir `proyecto-final.Rproj`.
2. Instalar el paquete `tidyverse`.
3. Correr `scripts/00_exploracion.R`.
4. El resto de los scripts se ejecutará en orden numérico *(pendiente)*. 

## Declaración de autoría humana y uso de tecnologías digitales emergentes

- **Integrantes y responsabilidades:** Camila Bravo Figueroa (trabajo individual: pregunta, datos, código y redacción).
- **Herramienta(s) de IA utilizada(s):** Gemini; Claude (Anthropic).
- **Para qué se usaron:** En primer lugar, se utilizó para conseguir fuentes 
chilenas sobre informes asociados a la pregunta planteada. También se utilizó 
para trabajar algunos errores de carga de la base de datos en el script 00_exploración, 
por ser un tipo de archivo desconocido. Finalmente, se le solicitó ayuda para un 
código asociado a la verificación de la existencia de las variables clave en la 
base de datos, luego de verificar el libro de códigos.
- **Qué hizo el equipo:** Planteé la pregunta, desarrollé la justificación, 
revisé el material sugerido por Gemini superficialmente y descargué los archivos 
para una revisión más profunda. Creé, trabajé y redacté el script de exploración 
preliminar, y presenté el plan de trabajo y el modelo esperado.
- **Verificación:** confirmamos que entendemos y podemos explicar todo lo que entregamos, incluido cada línea de código.

*Esta declaración se actualizará en cada hito.*
