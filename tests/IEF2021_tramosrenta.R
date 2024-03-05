# Fichero principal 2020, select columns par150-caseros par36-renta
library(magrittr)
library(survey)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

# Parameters to set (Encuesta de referencia, periodo de estudio, unidad de estudi, columnas seleccionadaso)
ref_survey <- "IEF" # either IEF or EFF
sel_year <- 2021 # 2020 for EFF & 2021 for IEF
ref_unit <- "IDENPER" # Use either IDENPER for personal or IDENHOG for household levels
selected_columns <- c("RENTAB", "RENTAD", "RENTA_ALQ", "PATINMO")

# Import choosen dataframe (cambiar string inicial según ruta de los datos)
dt <- paste0("data/", ref_survey, "-", sel_year, "-new.gz") %>% fread()

# Use lapply with .SDcols to specify columns and replace NA with 0
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation TABLA[ filter_rows , select_columns  , group_by ]
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

dt <- dt[TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL),
  .(
    RENTAB = sum(RENTAB),
    RENTAD = sum(RENTAD),
    TRAMO = mean(TRAMO),
    FACTORCAL = mean(FACTORCAL)
  ),
  by = .(reference = get(ref_unit))
]
setnames(dt, "reference", as.character(ref_unit))
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación


# RESULTS----------------------------------
renta_tramo <- svyby(~RENTAD, ~ as.factor(TRAMO), dt_sv, svymean)
print(renta_tramo) # mean results seem realistic

cortes_renta_disp <- dt[, TRAMO := as.factor(TRAMO)][, .(CORTES = min(RENTAD)), by = .(TRAMO)]
print(cortes_renta_disp) # problematic min values

# obs negativas en todos los tramos incluyendo 24 en el más rico (+1000 en el tramo 2)
nrow(dt[TRAMO == 7 & RENTAD < 0, ]) %>% print()

cortes_renta_bruta <- dt[, .(CORTES = min(RENTAB)), by = .(TRAMO)]
print(cortes_renta_bruta) # problematic min values