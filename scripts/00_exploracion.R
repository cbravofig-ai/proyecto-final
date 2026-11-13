# ==============================================================================
# EXPLORACIÓN INICIAL DE LOS DATOS
# Autor: Camila Bravo Figueroa
# Fecha: 2026-11-12
# Descripción: Carga la base CASEN 2022 en formato RData, filtra la Región 
#              de Ñuble y el tramo etario (20 a 59 años), y verifica el 
#              número de observaciones y la disponibilidad de las variables clave.
# ==============================================================================

# Cargar librerías del curso
library(tidyverse)

# -----------------------------------------------------------------------------
# 1. Cargar la base (el objeto que crea load() se llama casen_2022) 
# -----------------------------------------------------------------------------
load("data/raw/casen_2022.RData")
datos_casen <- casen_2022

# -----------------------------------------------------------------------------
# 2. Verificar que existan TODAS las variables que usa la propuesta
# -----------------------------------------------------------------------------
variables_requeridas <- c("region", "pco1", "sexo", "edad",
                          "yauth", "esc", "tot_per_h", "expr")
faltantes <- setdiff(variables_requeridas, names(datos_casen))
if (length(faltantes) > 0) {
  stop("Faltan variables en la base: ", paste(faltantes, collapse = ", "))
}

# -----------------------------------------------------------------------------
# 3. Seleccionar, quitar etiquetas (as.vector) y filtrar 
# -----------------------------------------------------------------------------
casen_filtrada <- datos_casen %>%
  select(all_of(variables_requeridas)) %>%
  mutate(across(everything(), as.vector)) %>%
  filter(region == 16, pco1 == 1, edad >= 20, edad <= 59)

# -----------------------------------------------------------------------------
# 4. Evidencia para la propuesta 
# -----------------------------------------------------------------------------
cat("\nN de hogares (jefaturas 20-59, Ñuble):", nrow(casen_filtrada), "\n")

cat("\nHogares por sexo de la jefatura (1 = hombre, 2 = mujer):\n")
print(count(casen_filtrada, sexo))

cat("\nValores perdidos por variable:\n")
print(colSums(is.na(casen_filtrada)))

cat("\nHogares con yauth = 0, por sexo de la jefatura:\n")
print(casen_filtrada %>%
        group_by(sexo) %>%
        summarise(n_ceros = sum(yauth == 0, na.rm = TRUE),
                  pct_ceros = round(100 * mean(yauth == 0, na.rm = TRUE), 1)))

cat("\nResumen de variables numéricas:\n")
print(summary(casen_filtrada[c("yauth", "esc", "edad", "tot_per_h", "expr")]))

cat("\nMediana de yauth por sexo (sin ponderar):\n")
print(casen_filtrada %>%
        group_by(sexo) %>%
        summarise(mediana = median(yauth, na.rm = TRUE)))
