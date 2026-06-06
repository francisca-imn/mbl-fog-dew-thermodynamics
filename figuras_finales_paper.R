# ==============================================================================
# FIGURA 1 RESULTADOS ----
# ==============================================================================
library(ggplot2)
library(dplyr)
library(patchwork)

# 2. PREMIUM AESTHETIC PASTEL PALETTE (Academic Muted Style)
paper_colors <- c(
  "No Event"          = "#F3F4F6", # Light linen gray for background context
  "Atmospheric Water" = "#4B5563", # Deep slate gray for structural anchor
  "Fog"               = "#93C5FD", # Clean pastel blue
  "Fog + Dew"         = "#C4B5FD", # Soft mystic lavender
  "Dew"               = "#FCA5A5"  # Muted pastel salmon/coral
)

# ==============================================================================
# COMPONENT 1: CONTEXT BAR WITH OVERALL TIMEFRAME (Now Panel A)
# ==============================================================================
df_total <- data.frame(
  Category = factor(c("No Event", "Atmospheric Water"), 
                    levels = c("No Event", "Atmospheric Water")),
  Percentage = c(91.41, 8.59),
  Label = c("No Event\n91.41%", "Atm. Water\n8.59%")
)

bar_context <- ggplot(df_total, aes(x = 1, y = Percentage, fill = Category)) +
  geom_bar(stat = "identity", width = 0.35, color = "white", size = 0.8) +
  coord_flip() +
  geom_text(aes(label = Label), 
            position = position_stack(vjust = 0.5), 
            size = 3.3, fontface = "bold", color = c("gray40", "white"),
            lineheight = 0.85) +
  scale_fill_manual(values = paper_colors) +
  theme_void() +
  # Subtitle updated to serve as Panel A heading
  labs(subtitle = "A. Context of Overall Annual Timeframe (Year 2024)") + 
  theme(
    legend.position = "none",
    plot.subtitle = element_text(size = 10, face = "bold", color = "black", 
                                 hjust = 0.5, margin = margin(b = 10, t = 0)),
    plot.margin = margin(t = 10, b = 20, l = 35, r = 35) 
  )

# ==============================================================================
# COMPONENT 2: DONUT CHARTS (Now Panels B and C)
# ==============================================================================
create_paper_donut <- function(data, panel_subtitle, is_panel_B = FALSE) {
  total <- sum(data$Original_Value)
  
  data <- data %>%
    mutate(
      Zoom_Percentage = (Original_Value / total) * 100,
      ymax = cumsum(Zoom_Percentage),
      ymin = c(0, head(ymax, n = -1)),
      mid = (ymin + ymax) / 2
    )
  
  p <- ggplot(data, aes(ymax = ymax, ymin = ymin, xmax = 4, xmin = 1.3, fill = Category)) +
    geom_rect(color = "white", size = 0.9) +
    coord_polar(theta = "y") +
    xlim(c(0.2, 4.5)) +
    scale_fill_manual(values = paper_colors) +
    theme_void() +
    labs(subtitle = panel_subtitle) + 
    theme(
      plot.subtitle = element_text(face = "bold", size = 9.5, hjust = 0.5, 
                                   margin = margin(b = -25, t = 0)), 
      legend.position = "none",
      plot.margin = margin(t = 0, b = 0, l = 10, r = 10)
    )
  
  if(is_panel_B) {
    p <- p + 
      # Fog Section Label
      annotate("text", x = 2.6, y = data$mid[1], 
               label = paste0("Fog\n", round(data$Zoom_Percentage[1], 1), "%\n(", data$Original_Value[1], "% overall)"),
               size = 3.0, fontface = "bold", color = "gray25", lineheight = 0.9) +
      # Fog + Dew Section Label
      annotate("text", x = 2.6, y = data$mid[2], 
               label = paste0("Fog + Dew\n", round(data$Zoom_Percentage[2], 1), "%\n(", data$Original_Value[2], "% overall)"),
               size = 3.0, fontface = "bold", color = "gray25", lineheight = 0.9) +
      # Dew Section Label (Perfect double line formatting entirely inside)
      annotate("text", x = 2.6, y = data$mid[3], 
               label = paste0("Dew\n", round(data$Zoom_Percentage[3], 1), "%\n(", data$Original_Value[3], "% overall)"),
               size = 2.4, fontface = "bold", color = "gray25", lineheight = 0.85)
  } else {
    # Panel C Section Labels
    p <- p + 
      geom_text(aes(x = 2.6, y = mid, 
                    label = paste0(Category, "\n", round(Zoom_Percentage, 1), "%\n", "(", Original_Value, "% overall)")), 
                size = 3.0, fontface = "bold", color = "gray25", lineheight = 0.9)
  }
  
  return(p)
}

# 3. SCIENTIFIC DATA MATRICES
df_inst <- data.frame(
  Category = factor(c("Fog", "Fog + Dew", "Dew"), levels = c("Fog", "Fog + Dew", "Dew")),
  Original_Value = c(4.23, 4.02, 0.34)
)

df_clas <- data.frame(
  Category = factor(c("Fog", "Dew"), levels = c("Fog", "Dew")),
  Original_Value = c(4.58, 4.01)
)

# 4. PANEL EXECUTION (Titles sequentialized to B and C)
donut_B <- create_paper_donut(df_inst, "B. Instrument Detection\n(Internal distribution of 8.59% atmospheric water)", is_panel_B = TRUE)
donut_C <- create_paper_donut(df_clas, "C. GOES Classification + Visibility\n(Internal distribution of 8.59% atmospheric water)", is_panel_B = FALSE)

# ==============================================================================
# FINAL MULTI-PANEL ASSEMBLY
# ==============================================================================
scientific_figure <- (bar_context) / (donut_B + donut_C) + 
  plot_layout(heights = c(0.6, 5))

# Plot verification in RStudio
print(scientific_figure)