* ==============================================================================
* 03_modelar.do — Estimación de brecha de ingreso autónomo (CASEN 2022, Ñuble)
* Autora: Camila Bravo Figueroa
* Fecha: 26-11-2026
* Entrada: data/processed/casen_nuble_limpio.dta
* Salida:  output/03_modelar.log
*          output/tablas/modelos_hito2.tex / .rtf
* ==============================================================================

version 14
clear all
set more off

capture mkdir "output"
capture mkdir "output/tablas"
capture log close
log using "output/03_modelar.log", replace text

* Verificar que estout esté instalado (para reproducibilidad en otra máquina)
capture which esttab
if _rc != 0 {
    ssc install estout
}

* -----------------------------------------------------------------------------
* 1. Macros de configuración
* -----------------------------------------------------------------------------
local datos     "data/processed/casen_nuble_limpio.dta"
local controles "esc edad tot_per_h"
local depvars   "ln_yauth asinh_yauth"

* -----------------------------------------------------------------------------
* 2. Cargar base procesada y etiquetar variables
* -----------------------------------------------------------------------------
use "`datos'", clear

label variable jefa_fem    "Jefatura femenina"
label variable esc         "Escolaridad (años)"
label variable edad        "Edad (años)"
label variable tot_per_h   "Tamaño del hogar"
label variable ln_yauth    "Log(Ingreso autónomo)"
label variable asinh_yauth "Asinh(Ingreso autónomo)"

* -----------------------------------------------------------------------------
* 3. Estimación de modelos ponderados con factor de expansión regional (expr)
* -----------------------------------------------------------------------------
* Nota: [pw=expr] pondera con el factor regional y aplica errores robustos.

* Modelo 1: Brecha bruta en log(yauth) sin controles
quietly regress ln_yauth jefa_fem [pw=expr]
estimates store m_bruto
estadd local controles "No"        : m_bruto
estadd local muestra   "yauth > 0" : m_bruto

* Modelos 2 y 3: Especificación principal (ln) y robustez con ceros (asinh)
foreach y of local depvars {
    quietly regress `y' jefa_fem `controles' [pw=expr]
    estimates store m_`y'
    estadd local controles "Sí" : m_`y'
}
estadd local muestra "yauth > 0" : m_ln_yauth
estadd local muestra "Completa"  : m_asinh_yauth

* -----------------------------------------------------------------------------
* 4. Salida visible en el log y exportación de tablas
* -----------------------------------------------------------------------------
esttab m_bruto m_ln_yauth m_asinh_yauth, se label b(%9.3f) varwidth(25) ///
    stats(N r2 controles muestra, ///
          labels("Observaciones" "R2" "Controles" "Muestra") ///
          fmt(%9.0f %5.3f))

esttab m_bruto m_ln_yauth m_asinh_yauth using "output/tablas/modelos_hito2.tex", ///
    replace se label b(%9.3f) ///
    stats(N r2 controles muestra, ///
          labels("Observaciones" "R2" "Controles" "Muestra") ///
          fmt(%9.0f %5.3f))

esttab m_bruto m_ln_yauth m_asinh_yauth using "output/tablas/modelos_hito2.rtf", ///
    replace se label b(%9.3f) ///
    stats(N r2 controles muestra, ///
          labels("Observaciones" "R2" "Controles" "Muestra") ///
          fmt(%9.0f %5.3f))

* -----------------------------------------------------------------------------
* 5. Cierre del log
* -----------------------------------------------------------------------------
log close