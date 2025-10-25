################################################################################
# ECV 2024 — Estadística descriptiva y mapa por departamento
# Salida: PNGs en alta resolución (dpi = 300)
################################################################################

# --- Rutas --------------------------------------------------------------------
input_file <- "C:/Users/Jhoan meza/Documents/base_final.csv"
out_dir    <- "C:/Users/Jhoan meza/Documents/Graficos_Descriptivos"

# --- Paquetes -----------------------------------------------------------------
options(menu.graphics = FALSE)
install_if_missing <- function(pkgs){
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if(length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org", quiet = TRUE)
  invisible(lapply(pkgs, require, character.only = TRUE))
}
install_if_missing(c(
  "tidyverse","readr","scales","ggthemes","stringr","stringi",
  "sf","geodata"  # para el mapa departamental
))
dir.create(out_dir, showWarnings = FALSE)

# --- Lectura de base ----------------------------------------------------------
base_final <- readr::read_csv(input_file, show_col_types = FALSE)

# --- Tema visual uniforme -----------------------------------------------------
tema_pub <- theme_minimal(base_size = 13) +
  theme(
    plot.title   = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle= element_text(hjust = 0.5, size = 12),
    axis.title   = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position  = "right"
  )

# Utilidades pequeñas
lab_sexo  <- c(`1` = "Hombre", `2` = "Mujer")
lab_clase <- c(`1` = "Cabecera (Urbano)", `2` = "Centro poblado (Rural)", `3` = "Resto (Rural)")

ggsave_pub <- function(filename, plot, w = 9, h = 6){
  ggsave(file.path(out_dir, filename), plot, width = w, height = h, dpi = 300)
  message("✓ ", filename)
}

# ==============================================================================
# 01 — Distribución de edad (P6040)
# ==============================================================================
p01 <- ggplot(base_final, aes(x = P6040)) +
  geom_histogram(binwidth = 5, fill = "#0072B2", color = "white", alpha = 0.9, boundary = 0) +
  labs(title = "Distribución de la edad", x = "Edad (años)", y = "Frecuencia") +
  tema_pub
ggsave_pub("01_edad.png", p01)

# ==============================================================================
# 02 — Distribución por sexo (P6020)
# ==============================================================================
p02 <- base_final %>%
  mutate(sexo = factor(P6020, levels = c(1,2), labels = c("Hombre","Mujer"))) %>%
  ggplot(aes(x = sexo)) +
  geom_bar(fill = "#009E73", alpha = 0.9) +
  labs(title = "Distribución por sexo", x = "", y = "Número de personas") +
  tema_pub
ggsave_pub("02_sexo.png", p02)

# ==============================================================================
# 03 — Distribución por zona (CLASE)
# ==============================================================================
p03 <- base_final %>%
  mutate(area = factor(CLASE, levels = c(1,2,3), labels = lab_clase)) %>%
  ggplot(aes(x = area, fill = area)) +
  geom_bar(alpha = 0.9, color = "white") +
  scale_fill_manual(values = c("#F8766D","#00BA38","#619CFF")) +
  labs(title = "Distribución por área geográfica", x = "", y = "Número de personas") +
  tema_pub + theme(legend.position = "none")
ggsave_pub("03_zona.png", p03)

# ==============================================================================
# 04 — Tamaño del hogar (CANT_PERSONAS_HOGAR)
# ==============================================================================
p04 <- ggplot(base_final, aes(x = CANT_PERSONAS_HOGAR)) +
  geom_histogram(binwidth = 1, fill = "#D55E00", color = "white", alpha = 0.9, boundary = 0) +
  scale_x_continuous(breaks = 1:10) +
  labs(title = "Distribución del tamaño de los hogares",
       x = "Personas por hogar", y = "Frecuencia") +
  tema_pub
ggsave_pub("04_tamano_hogar.png", p04)

# ==============================================================================
# 05 — Distribución de edad por zona (CLASE)
# ==============================================================================
p05 <- base_final %>%
  mutate(area = factor(CLASE, levels = c(1,2,3), labels = lab_clase)) %>%
  ggplot(aes(x = P6040, fill = area)) +
  geom_histogram(binwidth = 5, position = "identity", alpha = 0.6, color = NA, boundary = 0) +
  labs(title = "Distribución de la edad por área",
       x = "Edad (años)", y = "Número de personas", fill = "Área") +
  tema_pub
ggsave_pub("05_edad_zona.png", p05)

# ==============================================================================
# 06 — Boxplot de edad por zona (CLASE)
# ==============================================================================
p06 <- base_final %>%
  mutate(area = factor(CLASE, levels = c(1,2,3))) %>%
  ggplot(aes(x = area, y = P6040, fill = area)) +
  geom_boxplot(alpha = 0.8, color = "gray40") +
  scale_fill_manual(values = c("#F8766D","#00BA38","#619CFF")) +
  labs(title = "Edad por área geográfica",
       x = "Área (1 = Urbano; 2–3 = Rural)", y = "Edad (años)") +
  tema_pub + theme(legend.position = "none")
ggsave_pub("06_edad_box.png", p06)

# ==============================================================================
# 07 — Relación tamaño del hogar vs edad promedio del hogar
# ==============================================================================
base_hogares <- base_final %>%
  group_by(llavehog) %>%
  summarise(
    promedio_edad = mean(P6040, na.rm = TRUE),
    miembros      = first(CANT_PERSONAS_HOGAR),
    .groups = "drop"
  )

p07 <- ggplot(base_hogares, aes(x = miembros, y = promedio_edad)) +
  geom_point(alpha = 0.35, size = 1.2, color = "#0072B2") +
  geom_smooth(method = "lm", se = FALSE, color = "#E69F00", linewidth = 1) +
  labs(title = "Relación entre tamaño del hogar y edad promedio del hogar",
       x = "Personas en el hogar", y = "Edad promedio (años)") +
  tema_pub
ggsave_pub("07_tamano_vs_edad.png", p07)

# ==============================================================================
# 08 — Pirámide poblacional (Hombres vs Mujeres)
# ==============================================================================
p08_df <- base_final %>%
  mutate(sexo = ifelse(P6020 == 1, "Hombres", "Mujeres"),
         grupo_edad = cut(P6040, breaks = seq(0, 100, by = 5), right = FALSE)) %>%
  count(grupo_edad, sexo) %>%
  mutate(valor = ifelse(sexo == "Hombres", -n, n))

p08 <- ggplot(p08_df, aes(x = grupo_edad, y = valor, fill = sexo)) +
  geom_col(width = 0.95, alpha = 0.9) +
  coord_flip() +
  scale_y_continuous(labels = function(z) abs(z)) +
  scale_fill_manual(values = c("Hombres"="#F8766D","Mujeres"="#00BFC4")) +
  labs(title = "Pirámide poblacional (ECV 2024)",
       x = "Grupo de edad (años)", y = "Personas", fill = "") +
  tema_pub
ggsave_pub("08_piramide.png", p08, w = 10, h = 7)

# ==============================================================================
# 09 — Edad promedio por zona
# ==============================================================================
p09 <- base_final %>%
  group_by(CLASE) %>%
  summarise(edad_prom = mean(P6040, na.rm = TRUE), .groups = "drop") %>%
  mutate(area = factor(CLASE, levels = c(1,2,3), labels = lab_clase)) %>%
  ggplot(aes(x = area, y = edad_prom, fill = area)) +
  geom_col(alpha = 0.9) +
  scale_fill_manual(values = c("#F8766D","#00BA38","#619CFF")) +
  labs(title = "Edad promedio por área", x = "", y = "Edad promedio (años)") +
  tema_pub + theme(legend.position = "none")
ggsave_pub("09_edad_media_zona.png", p09)

# ==============================================================================
# 10 — Mapa: hogares encuestados por departamento
#       (DEPARTAMENTO es código DANE de 2 dígitos)
# ==============================================================================
# Conteo de hogares únicos por dpto (llavehog + DEPARTAMENTO)
hogares_dep <- base_final %>%
  mutate(COD_DANE = str_pad(as.character(DEPARTAMENTO), 2, pad = "0")) %>%
  distinct(llavehog, COD_DANE) %>%
  count(COD_DANE, name = "hogares_encuestados")

# Diccionario COD -> nombre (normalizado)
dicc_dep <- tribble(
  ~COD_DANE, ~DEP_NOMBRE,
  "05","ANTIOQUIA","08","ATLÁNTICO","11","BOGOTÁ D. C.","13","BOLÍVAR",
  "15","BOYACÁ","17","CALDAS","18","CAQUETÁ","19","CAUCA","20","CESAR",
  "23","CÓRDOBA","25","CUNDINAMARCA","27","CHOCÓ","41","HUILA","44","LA GUAJIRA",
  "47","MAGDALENA","50","META","52","NARIÑO","54","NORTE DE SANTANDER","63","QUINDÍO",
  "66","RISARALDA","68","SANTANDER","70","SUCRE","73","TOLIMA","76","VALLE DEL CAUCA",
  "81","ARAUCA","85","CASANARE","86","PUTUMAYO","88","SAN ANDRÉS, PROVIDENCIA Y SANTA CATALINA",
  "91","AMAZONAS","94","GUAINÍA","95","GUAVIARE","97","VAUPÉS","99","VICHADA"
)

# Normalizador para unir con el shapefile
normalize_txt <- function(x){
  x %>%
    stringi::stri_trans_general("Latin-ASCII") %>%
    toupper() %>%
    str_replace_all("[[:punct:]]", " ") %>%
    str_replace_all("\\s+", " ") %>%
    str_trim()
}
fix_alias <- function(x){
  x <- gsub("SANTAFE DE BOGOTA D C|BOGOTA DC", "BOGOTA D C", x)
  x <- gsub("ARCHIPIELAGO DE SAN ANDRES,? PROVIDENCIA Y SANTA CATALINA",
            "SAN ANDRES PROVIDENCIA Y SANTA CATALINA", x)
  x
}

hogares_dep <- hogares_dep %>%
  left_join(dicc_dep, by = "COD_DANE") %>%
  mutate(DEP_NORM = fix_alias(normalize_txt(DEP_NOMBRE)))

# Geometría deptos (GADM nivel 1)
co_deps <- geodata::gadm(country = "COL", level = 1, path = tempdir()) %>%
  sf::st_as_sf() %>%
  dplyr::select(dep_map = NAME_1, geometry) %>%
  sf::st_make_valid() %>%
  mutate(DEP_NORM = fix_alias(normalize_txt(dep_map)))

# Unión y mapa
mapa_df <- co_deps %>% left_join(hogares_dep, by = "DEP_NORM")

p10 <- ggplot(mapa_df) +
  geom_sf(aes(fill = hogares_encuestados), color = "white", linewidth = 0.25) +
  scale_fill_viridis_c(option = "C", direction = 1, na.value = "grey90",
                       labels = label_number(big.mark = ",")) +
  labs(title = "Hogares encuestados por departamento (ECV 2024)",
       subtitle = "Conteo de hogares únicos (llavehog)",
       fill = "Hogares",
       caption = "Fuente: cálculos propios con microdatos ECV 2024 (DANE).") +
  coord_sf() + tema_pub
ggsave_pub("10_mapa_hogares_por_departamento.png", p10, w = 10, h = 7)

message("\nListo. Archivos guardados en: ", out_dir)

