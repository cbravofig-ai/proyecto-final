# Ingreso autónomo de los hogares según el sexo de la jefatura de hogar en Ñuble (CASEN 2022)

Proyecto final - Hito 2  
Autora: Camila Bravo Figueroa  
Fecha: 26-11-2026  
Profesor: Ariel Soto Caro

> **Estado:** Hito 2 (avance). La limpieza, las estadísticas descriptivas ponderadas 
y los primeros modelos ya están implementados y corren de cero. Las figuras, el 
informe y la presentación se agregan en los hitos siguientes; lo que aún no existe 
aparece marcado como *(pendiente)*.

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
| **Casos** | 1.791 hogares iniciales (834 con jefatura masculina, 957 con femenina); 9 sin dato de `esc`. Tras la limpieza quedan 1.782 hogares: 1.671 con `yauth > 0` y 111 con `yauth = 0` |

Los números iniciales salen de `scripts/00_exploracion.R` y la muestra final documentada de `scripts/01_limpiar.R`.

## Modelo estimado

```math
\ln(\text{yauth}) = \beta_0 + \beta_1(\text{jefa\_fem}) + \beta_2(\text{esc}) + \beta_3(\text{edad}) + \beta_4(\text{tot\_per\_h}) + u
```

Estimado por MCO con ponderador `expr` (`[pw=expr]`, con errores estándar robustos) 
en `scripts/03_modelar.do`. Como $\ln(0)$ no existe, se estiman dos versiones: 
`ln(yauth)` sin los hogares con ingreso cero (modelo bruto y modelo con controles),
y `asinh(yauth)` con todos los hogares como chequeo de robustez. Los resultados se 
interpretan como asociaciones y la magnitud se expresará en pesos en el informe final.

## Estructura del repositorio

```text
proyecto-final/
├── data/
│   ├── raw/                  datos originales sin editar (CASEN 2022)
│   └── processed/
│       └── casen_nuble_limpio.dta
├── scripts/
│   ├── 00_exploracion.R      carga, filtra y verifica la base (Hito 1)
│   ├── 01_limpiar.R          limpia, documenta NA/outliers y exporta a .dta
│   ├── 02_describir.R        estadísticas descriptivas ponderadas y Tabla 1
│   ├── 03_modelar.do         modelos MCO ponderados (macros, loop y esttab)
│   └── 04_figuras.R          (pendiente)
├── output/
│   ├── 03_modelar.log        bitácora de ejecución de Stata
│   ├── figuras/              (pendiente)
│   └── tablas/
│       ├── tabla1_descriptivos_casen.csv / .tex / .png
│       └── modelos_hito2.tex / .rtf
├── readings/                 literatura de apoyo
├── informe.tex               (pendiente)
├── presentacion.qmd          (pendiente)
└── README.md
```

## Uso de R y Stata

- **R** para limpiar y describir: la base viene en formato `.RData`, que Stata no 
lee, así que limpiarla en R evita una conversión previa. Los datos pasan a Stata 
como archivo `.dta` (`haven::write_dta()`), y las estadísticas descriptivas 
ponderadas se generan con `dplyr` y `tinytable`.
- **Stata** para estimar: `regress` con ponderadores `[pw=expr]` y `esttab`, que 
deja la tabla lista para incluirla en el informe LaTeX. Las especificaciones con 
controles se recorren con un loop `foreach`.
- **R** para comunicar *(próximo hito)*: figuras con `ggplot2`, y presentación con Quarto.

## Cómo reproducir

1. Abrir `proyecto-final.Rproj` en RStudio.
2. Tener instalados los paquetes de R: `dplyr`, `tidyr`, `haven`, `broom` y `tinytable`.
3. Ejecutar en orden `scripts/01_limpiar.R` y `scripts/02_describir.R`.
4. Abrir Stata, ubicarse en la raíz del proyecto con `cd "ruta/a/proyecto-final"` y ejecutar `do scripts/03_modelar.do` (el script instala `estout` automáticamente si no está disponible).

## Declaración de autoría humana y uso de tecnologías digitales emergentes

- **Integrantes y responsabilidades:** Camila Bravo Figueroa (trabajo individual: 
pregunta, datos, código y redacción).
- **Herramienta(s) de IA utilizada(s):** Gemini.
- **Para qué se usó:** En el Hito 1, como apoyo para ubicar informes chilenos 
relacionados con la pregunta y resolver errores de carga del archivo `.RData` en 
`00_exploracion.R`. En el Hito 2, como consulta puntual para resolver dudas de 
sintaxis en R y Stata (`tinytable`, `estadd` y `esttab`), verificar que el flujo 
cumpliera con la pauta de reproducibilidad y ajustar el formato de las tablas y 
mensajes de commit.
- **Qué hice yo:** Planteé la pregunta, la justificación y el diseño empírico; 
revisé el libro de códigos y la literatura; definí y justifiqué todas las decisiones 
de limpieza (faltantes, ceros y outliers); construí, adapté y ejecuté personalmente 
en RStudio y Stata todos los scripts (`00` a `03`), verifiqué cada salida numérica 
y tabla generada, y gestioné el control de versiones en GitHub.
- **Verificación:** confirmo que entiendo y puedo explicar todo lo que entrego, 
incluida cada línea de código.

*Esta declaración se actualizará en cada hito.*