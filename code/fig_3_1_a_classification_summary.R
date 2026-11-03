# ==============================================================================
# fig_3_1_a_classification_summary.R
#
# Figure 2 of the manuscript (Section 3.1): classification of the atmospheric
# water (AW) occurrences at OYA1211 during 2024.
#   (A) Share of the 10-min records of the year with AW and with no AW.
#   (B) Distribution of the AW records according to the collector-based
#       classification (SFC only, SDC only, both collectors).
#   (C) Distribution after the reclassification based on visibility and
#       GOES-16 FLC detection.
# Percentages are computed from the final classification (step 3), not typed.
#
# Input:  data/derived/oya1211_classification_2024.csv (step 3)
# Output: figures/fig02_classification_summary.png
#
# Run from the project root (open mbl-fog-dew-thermodynamics.Rproj).
# ==============================================================================

library(tidyverse)
library(patchwork)

dir_fig <- "figures"

clasif <- read_csv("data/derived/oya1211_classification_2024.csv",
                   show_col_types = FALSE)

n_total <- nrow(clasif)
pct <- function(x) round(100 * sum(x, na.rm = TRUE) / n_total, 2)

pct_sin  <- pct(clasif$clasif_evento == "SIN_EVENTO")
pct_agua <- round(100 - pct_sin, 2)

# % of the year in each category (collector-based: which collector registered water)
instrumental <- tibble(
  categoria = c("Fog", "Fog + Dew", "Dew"),
  pct_anual = with(clasif, c(pct(fog_cap == 1 & dew_cap == 0),
                             pct(fog_cap == 1 & dew_cap == 1),
                             pct(fog_cap == 0 & dew_cap == 1)))
)
clasificado <- tibble(
  categoria = c("Fog", "Dew"),
  pct_anual = with(clasif, c(pct(clasif_evento == "NIEBLA"), pct(clasif_evento == "ROCIO")))
)


col_cat <- c("Fog" = "#4292c6", "Fog + Dew" = "#8c6bb1", "Dew" = "#c97a4a",
             "No AW" = "#e3e2dc", "Atmospheric water" = "#525252")

tema_titulo <- theme(plot.title = element_text(face = "bold", size = 10, hjust = 0),
                     plot.subtitle = element_text(size = 8.5, color = "grey35", hjust = 0))

# (A) bar of the whole year
barra <- tibble(categoria = factor(c("Atmospheric water", "No AW"),
                                   levels = c("No AW", "Atmospheric water")),
                pct = c(pct_agua, pct_sin))

pA <- ggplot(barra, aes(x = 1, y = pct, fill = categoria)) +
  geom_col(width = 0.6, color = "white", linewidth = 0.6) +
  geom_text(data = barra %>% filter(categoria == "No AW"),
            aes(y = pct_agua + pct_sin / 2,
                label = paste0("No AW, ", sprintf("%.1f", pct), "%")),
            size = 3.2, color = "grey30") +
  # atmospheric water label inside the dark rectangle, in white
  annotate("text", x = 1, y = pct_agua / 2, size = 2.35, color = "white",
           fontface = "bold", lineheight = 0.9,
           label = paste0("Atmospheric\nwater ", sprintf("%.1f", pct_agua), "%")) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = col_cat) +
  scale_y_continuous(expand = expansion(add = 0)) +
  labs(title = "(A) AW occurrences in 2024") +
  theme_void() + tema_titulo +
  theme(legend.position = "none", plot.margin = margin(4, 12, 8, 12))

# (B) and (C) donuts with the distribution within the atmospheric water window
dona <- function(d, titulo) {
  d <- d %>%
    mutate(categoria = factor(categoria, levels = categoria),
           pct_interno = 100 * pct_anual / sum(pct_anual),
           ymax = cumsum(pct_interno), ymin = lag(ymax, default = 0),
           mid = (ymin + ymax) / 2,
           pequeno = pct_interno < 8,
           etiqueta = if_else(pequeno,
                              paste0(categoria, " ", sprintf("%.1f", pct_interno), "%"),
                              paste0(str_replace(categoria, " \\+ ", " +\n"), "\n", sprintf("%.1f", pct_interno), "%")))
  ggplot(d) +
    geom_rect(aes(ymin = ymin, ymax = ymax, xmin = 1.9, xmax = 4, fill = categoria),
              color = "white", linewidth = 0.8) +
    # labels inside the ring (large sectors) or outside (small sectors)
    geom_text(data = d %>% filter(!pequeno),
              aes(x = 2.95, y = mid, label = etiqueta),
              color = "white", fontface = "bold", size = 3, lineheight = 0.9) +
    geom_segment(data = d %>% filter(pequeno),
                 aes(x = 4, xend = 4.45, y = mid, yend = mid),
                 color = "grey45", linewidth = 0.3) +
    geom_text(data = d %>% filter(pequeno),
              aes(x = 4.75, y = mid, label = etiqueta),
              color = "grey20", size = 3, hjust = 0.5) +
    annotate("text", x = 0, y = 0, label = paste0(sprintf("%.1f", pct_agua), "%\nof the year"),
             size = 2.9, color = "grey35", lineheight = 0.9) +
    coord_polar(theta = "y", clip = "off") +
    xlim(c(0, 4.9)) +
    scale_fill_manual(values = col_cat) +
    labs(title = titulo) +
    theme_void() + tema_titulo +
    theme(legend.position = "none", plot.margin = margin(4, 8, 4, 8))
}

pB <- dona(instrumental, "(B) Collectors classification (SFC and SDC)")
pC <- dona(clasificado,  "(C) Visibility and GOES-16 FLC reclassification")

fig_resumen <- pA / (pB | pC) + plot_layout(heights = c(0.22, 1))

fig_resumen

ggsave(file.path(dir_fig, "fig02_classification_summary.png"),
       fig_resumen, width = 9, height = 5, dpi = 300, bg = "white")

instrumental %>% mutate(pct_interno = round(100 * pct_anual / sum(pct_anual), 1))
clasificado  %>% mutate(pct_interno = round(100 * pct_anual / sum(pct_anual), 1))
c(sin_ocurrencia = pct_sin, agua_atmosferica = pct_agua)
