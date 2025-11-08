library(shiny)
library(plotly)
library(DT)
library(bslib)

fluidPage(
  theme = bs_theme(
    bg = "#f8f9fa",
    fg = "#333333",
    primary = "#007bff",
    secondary = "#6c757d",
    success = "#28a745",
    info = "#17a2b8",
    warning = "#ffc107",
    danger = "#dc3545",
    base_font = font_google("Roboto"),
    heading_font = font_google("Roboto Slab")
  ),
  titlePanel(
    title = div("Terrorism Incident Dashboard", style = "color: #007bff; font-size: 28px; text-align: center; padding: 10px; background-color: #ffffff; border-bottom: 2px solid #007bff;"),
    windowTitle = "Terrorism Incident Dashboard"
  ),
  sidebarLayout(
    sidebarPanel(
      style = "background-color: #ffffff; padding: 15px; border-right: 1px solid #dee2e6;",
      selectInput("theme_selector", "Select Theme:", 
                  choices = c("Default", "Dark", "Light"),
                  selected = "Default",
                  selectize = TRUE,
                  multiple = FALSE,
                  width = "100%"),
      selectInput("region_filter", "Select Region:", 
                  choices = c("All", unique(readRDS("clean_data.rds")$region)),
                  selected = "All",
                  selectize = TRUE,
                  multiple = FALSE,
                  width = "100%"),
      dateRangeInput("date_range", "Select Date Range:",
                     start = as.Date("2015-01-01"),
                     end = as.Date("2017-12-31"),
                     min = min(as.Date(readRDS("clean_data.rds")$incident_date)),
                     max = max(as.Date(readRDS("clean_data.rds")$incident_date)),
                     startview = "year",
                     format = "dd/mm/yyyy",
                     separator = " to ",
                     width = "100%"),
      selectInput("metric_selector", "Select Metric for Trends:", 
                  choices = c("Incidents", "Fatalities"),
                  selected = "Incidents",
                  selectize = TRUE,
                  multiple = FALSE,
                  width = "100%"),
      helpText("Filter by theme, region, date, and metric to update visualizations.", 
               style = "color: #6c757d; font-style: italic;")
    ),
    mainPanel(
      style = "background-color: #f8f9fa; padding: 20px;",
      tabsetPanel(
        tabPanel("Overview",
                 fluidRow(
                   column(4, card(uiOutput("total_incidents"), 
                                  full_screen = TRUE, 
                                  style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);")),
                   column(4, card(uiOutput("total_fatalities"), 
                                  full_screen = TRUE, 
                                  style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);")),
                   column(4, card(uiOutput("success_rate"), 
                                  full_screen = TRUE, 
                                  style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"))
                 ),
                 fluidRow(
                   column(12, card(plotlyOutput("choropleth_map", height = "600px"), 
                                   full_screen = TRUE, 
                                   style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"))
                 )
        ),
        tabPanel("Incident Details",
                 card(DTOutput("incident_table"), 
                      full_screen = TRUE, 
                      style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);")
        ),
        tabPanel("Trends",
                 card(plotlyOutput("trend_chart", height = "600px"), 
                      full_screen = TRUE, 
                      style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);")
        ),
        tabPanel("Comparative Analysis",
                 card(plotlyOutput("bar_chart", height = "600px"), 
                      full_screen = TRUE, 
                      style = "border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);")
        )
      )
    )
  )
)