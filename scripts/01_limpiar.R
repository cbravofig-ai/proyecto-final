# ==============================================================================
# 01_limpiar.R — Limpieza y construcción de variables (CASEN 2022, Ñuble)
# Autora: Camila Bravo Figueroa
# Fecha: 26-11-2026
# Entrada: data/raw/casen_2022.RData
# Salida:  data/processed/casen_nuble_limpio.dta
# ==============================================================================

library(dplyr)
library(haven)

# -----------------------------------------------------------------------------
# 1. Cargar la base
# -----------------------------------------------------------------------------
load("data/raw/casen_2022.RData") # load() porque es formato binario .RData

# -----------------------------------------------------------------------------
# 2. Seleccionar variables, quitar etiquetas y filtrar muestra objetivo
# -----------------------------------------------------------------------------
vars_clave <- c("region", "pco1", "sexo", "edad",
                "yauth", "esc", "tot_per_h", "expr")

casen_base <- casen_2022 |>
  select(all_of(vars_clave)) |>
  mutate(across(everything(), as.vector)) |>
  filter(
    region == 16,           # Región de Ñuble
    pco1 == 1,              # Jefatura de hogar
    edad >= 20, edad <= 59  # Tramo etario de interés
  )

# -----------------------------------------------------------------------------
# 3. Diagnóstico de faltantes y outliers (antes de limpiar)
# -----------------------------------------------------------------------------
cat("Observaciones iniciales (Ñuble, jefaturas 20-59):", nrow(casen_base), "\n")
cat("\nFaltantes por variable:\n")
print(colSums(is.na(casen_base)))

cat("\nPercentiles de yauth (para revisar cola alta / outliers):\n")
print(quantile(casen_base$yauth, probs = c(0, 0.05, 0.5, 0.95, 0.99, 1), na.rm = TRUE))

cat("\nRangos de variables de control (verificar ausencia de centinelas):\n")
print(summary(casen_base[c("esc", "edad", "tot_per_h", "expr")]))

# -----------------------------------------------------------------------------
# 4. Decisiones de limpieza y creación de variables
# -----------------------------------------------------------------------------
# - Faltantes: se excluyen los 9 hogares con esc = NA (0,5% de la muestra),
#   porque escolaridad es control central del modelo y no se imputa.
# - Ingreso cero (113 hogares iniciales; 111 tras excluir esc = NA): no son
#   errores ni NA, sino hogares sin ingreso autónomo. Son algo más frecuentes
#   con jefatura femenina (6,6% vs 5,0% ponderado; diferencia no significativa,
#   p = 0,15), pero excluirlos igual elimina los hogares de menor ingreso.
#   Como ln(0) no existe, quedan como NA en ln_yauth y se conservan todos en
#   asinh_yauth para el análisis de robustez.
# - Outliers en yauth: se verifican valores altos (p99 = $4.525.000; máximo =
#   $9.643.334). Se mantienen porque corresponden a hogares reales de altos
#   ingresos y la transformación logarítmica (ln / asinh) comprime la cola
#   derecha evitando que dominen la estimación MCO.

casen_limpia <- casen_base |>
  filter(!is.na(esc)) |>
  mutate(
    jefa_fem    = ifelse(sexo == 2, 1, 0),
    ln_yauth    = ifelse(yauth > 0, log(yauth), NA),
    asinh_yauth = asinh(yauth)
  )

# -----------------------------------------------------------------------------
# 5. Verificación final
# -----------------------------------------------------------------------------
cat("\nObservaciones finales en base limpia:", nrow(casen_limpia), "\n")
cat("Con ln_yauth válido (yauth > 0):", sum(!is.na(casen_limpia$ln_yauth)), "\n")
cat("Hogares con yauth = 0 en base limpia:", sum(casen_limpia$yauth == 0), "\n")
cat("Con asinh_yauth válido (incluye ceros):", sum(!is.na(casen_limpia$asinh_yauth)), "\n")

# -----------------------------------------------------------------------------
# 6. Exportar base procesada para Stata
# -----------------------------------------------------------------------------
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
write_dta(casen_limpia, "data/processed/casen_nuble_limpio.dta")
