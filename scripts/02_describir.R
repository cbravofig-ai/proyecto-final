# ==============================================================================
# 02_describir.R — Estadísticas descriptivas ponderadas (CASEN 2022, Ñuble)
# Autora: Camila Bravo Figueroa
# Fecha: 26-11-2026
# Entrada: data/processed/casen_nuble_limpio.dta
# Salida:  output/tablas/tabla1_descriptivos_casen.csv / .tex / .png
# ==============================================================================

library(dplyr)
library(tidyr)
library(haven)
library(broom)
library(tinytable)

# -----------------------------------------------------------------------------
# 1. Cargar la base procesada y crear indicadora de ingreso cero
# -----------------------------------------------------------------------------
casen <- read_dta("data/processed/casen_nuble_limpio.dta") |>
  mutate(ing_cero = ifelse(yauth == 0, 1, 0))

# -----------------------------------------------------------------------------
# 2. Funciones auxiliares para estadísticas ponderadas y formato
# -----------------------------------------------------------------------------
sd_pond <- function(x, w) {
  mu <- weighted.mean(x, w, na.rm = TRUE)
  sqrt(sum(w * (x - mu)^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
}

# Mediana ponderada: ordena los datos, acumula los pesos y toma el primer valor
# donde el peso acumulado alcanza la mitad del total (misma lógica de la T4)
mediana_pond <- function(x, w) {
  ok  <- !is.na(x) & !is.na(w)
  x   <- x[ok]
  w   <- w[ok]
  ord <- order(x)
  x   <- x[ord]
  w   <- w[ord]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

# Formato chileno: coma decimal y punto de miles
# (scientific = FALSE evita que R escriba, por ejemplo, 5e+05)
fmt_num <- function(x, d = 2) {
  format(round(x, d), nsmall = d, decimal.mark = ",", trim = TRUE,
         scientific = FALSE)
}

fmt_signo <- function(x, d = 2) {
  paste0(ifelse(x > 0, "+", ifelse(x < 0, "-", "")), fmt_num(abs(x), d))
}

fmt_pesos <- function(x, signo = FALSE) {
  prefijo <- ifelse(signo & x > 0, "+$", ifelse(x < 0, "-$", "$"))
  paste0(prefijo, format(round(abs(x)), big.mark = ".", decimal.mark = ",",
                         trim = TRUE, scientific = FALSE))
}

orden_vars <- c("yauth", "ing_cero", "esc", "edad", "tot_per_h")

resumir_bloque <- function(datos) {
  datos |>
    select(all_of(orden_vars), expr) |>
    pivot_longer(cols = all_of(orden_vars), names_to = "Var", values_to = "valor") |>
    mutate(Var = factor(Var, levels = orden_vars)) |>
    group_by(Var) |>
    summarise(
      m  = weighted.mean(valor, expr, na.rm = TRUE),
      de = sd_pond(valor, expr),
      .groups = "drop"
    ) |>
    mutate(
      Media = case_when(
        Var == "yauth"    ~ fmt_pesos(m),
        Var == "ing_cero" ~ paste0(fmt_num(100 * m, 1), "%"),
        TRUE              ~ fmt_num(m, 2)
      ),
      DE = case_when(
        Var == "yauth"    ~ fmt_pesos(de),
        Var == "ing_cero" ~ "–",          # en un indicador 0/1 la DE no informa
        TRUE              ~ fmt_num(de, 2)
      )
    ) |>
    select(Var, Media, DE)
}

# -----------------------------------------------------------------------------
# 3. Calcular bloques por grupo y prueba de diferencia de medias ponderada
# -----------------------------------------------------------------------------
bloque_todos <- resumir_bloque(casen) |>
  rename(Todos_Media = Media, Todos_DE = DE)

bloque_fem <- casen |>
  filter(jefa_fem == 1) |>
  resumir_bloque() |>
  select(Fem_Media = Media, Fem_DE = DE)

bloque_masc <- casen |>
  filter(jefa_fem == 0) |>
  resumir_bloque() |>
  select(Masc_Media = Media, Masc_DE = DE)

modelos_diff <- list(
  yauth     = lm(yauth     ~ jefa_fem, data = casen, weights = expr),
  ing_cero  = lm(ing_cero  ~ jefa_fem, data = casen, weights = expr),
  esc       = lm(esc       ~ jefa_fem, data = casen, weights = expr),
  edad      = lm(edad      ~ jefa_fem, data = casen, weights = expr),
  tot_per_h = lm(tot_per_h ~ jefa_fem, data = casen, weights = expr)
)

bloque_diff <- lapply(modelos_diff, tidy) |>
  bind_rows(.id = "Var") |>
  filter(term == "jefa_fem") |>
  mutate(
    Diff = case_when(
      Var == "yauth"    ~ fmt_pesos(estimate, signo = TRUE),
      Var == "ing_cero" ~ paste0(fmt_signo(100 * estimate, 1), " pp"),
      TRUE              ~ fmt_signo(estimate, 2)
    ),
    p_val = ifelse(p.value < 0.001, "<0,001", fmt_num(p.value, 3))
  ) |>
  select(Diff, p_val)

# Mediana ponderada del ingreso (la media está inflada por la cola derecha)
med_todos <- mediana_pond(casen$yauth, casen$expr)
med_fem   <- mediana_pond(casen$yauth[casen$jefa_fem == 1],
                          casen$expr[casen$jefa_fem == 1])
med_masc  <- mediana_pond(casen$yauth[casen$jefa_fem == 0],
                          casen$expr[casen$jefa_fem == 0])

fila_mediana <- tibble(
  Var         = "Ingreso autónomo, mediana ($)",
  Todos_Media = fmt_pesos(med_todos),
  Todos_DE    = "",
  Fem_Media   = fmt_pesos(med_fem),
  Fem_DE      = "",
  Masc_Media  = fmt_pesos(med_masc),
  Masc_DE     = "",
  Diff        = fmt_pesos(med_fem - med_masc, signo = TRUE),
  p_val       = "–"
)

# -----------------------------------------------------------------------------
# 4. Consolidar Tabla 1 con estética de paper
# -----------------------------------------------------------------------------
tabla_variables <- bind_cols(bloque_todos, bloque_fem, bloque_masc, bloque_diff) |>
  mutate(Var = case_when(
    Var == "yauth"     ~ "Ingreso autónomo del hogar, media ($)",
    Var == "ing_cero"  ~ "Hogar sin ingreso autónomo (%)",
    Var == "esc"       ~ "Escolaridad de la jefatura (años)",
    Var == "edad"      ~ "Edad de la jefatura (años)",
    Var == "tot_per_h" ~ "Tamaño del hogar (personas)"
  ))

fila_n <- tibble(
  Var         = "n",
  Todos_Media = format(nrow(casen), big.mark = ".", decimal.mark = ",", trim = TRUE),
  Todos_DE    = "",
  Fem_Media   = format(sum(casen$jefa_fem == 1), big.mark = ".", decimal.mark = ",", trim = TRUE),
  Fem_DE      = "",
  Masc_Media  = format(sum(casen$jefa_fem == 0), big.mark = ".", decimal.mark = ",", trim = TRUE),
  Masc_DE     = "",
  Diff        = "",
  p_val       = ""
)

# La mediana va justo debajo de la media del ingreso (fila 1)
tabla_1_df <- bind_rows(
  tabla_variables[1, ],
  fila_mediana,
  tabla_variables[-1, ],
  fila_n
)
print(tabla_1_df)

tabla_1_mostrar <- tabla_1_df
colnames(tabla_1_mostrar) <- c(
  "Variable",
  "Media", "Desv. Est.",
  "Media", "Desv. Est.",
  "Media", "Desv. Est.",
  "Dif.", "p-valor"
)

nota_tabla1 <- paste(
  "Nota: Elaboración propia a partir de la Encuesta CASEN 2022 (Ministerio de Desarrollo Social y Familia).",
  "Muestra de hogares de la Región de Ñuble con jefaturas de 20 a 59 años tras excluir 9 observaciones sin dato de escolaridad (n = 1.782).",
  "Las medias y desviaciones estándar están ponderadas con el factor de expansión regional (expr).",
  "Dif. corresponde a la diferencia ponderada (Jefatura femenina − Jefatura masculina) estimada mediante MCO ponderado;",
  "los p-valores son aproximados, pues no corrigen por el diseño muestral de la encuesta.",
  "En la fila de mediana, la columna Media muestra la mediana ponderada y la diferencia es entre medianas, sin prueba."
)

tabla_1_paper <- tt(
  tabla_1_mostrar,
  notes = nota_tabla1
) |>
  group_tt(
    j = list(
      "Todos"              = 2:3,
      "Jefatura femenina"  = 4:5,
      "Jefatura masculina" = 6:7,
      "Dif. de medias"     = 8:9
    )
  ) |>
  style_tt(i = 0:7, j = 2:9, align = "c") |>
  style_tt(i = 7, j = 1:9, bold = TRUE) |>
  style_tt(i = 7, line = "bt")

tabla_1_paper

# -----------------------------------------------------------------------------
# 5. Exportar tabla en CSV, LaTeX y PNG
# -----------------------------------------------------------------------------
dir.create("output/tablas", recursive = TRUE, showWarnings = FALSE)

write.csv(tabla_1_df, "output/tablas/tabla1_descriptivos_casen.csv", row.names = FALSE)
save_tt(tabla_1_paper, "output/tablas/tabla1_descriptivos_casen.tex", overwrite = TRUE)
if (requireNamespace("webshot2", quietly = TRUE)) {
  save_tt(tabla_1_paper, "output/tablas/tabla1_descriptivos_casen.png", overwrite = TRUE)
}
