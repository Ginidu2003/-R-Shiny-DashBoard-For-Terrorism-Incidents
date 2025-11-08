library(shiny)
library(plotly)
library(dplyr)
library(DT)
library(colorspace)
library(lubridate)

# Enable reactlog for visualizing reactive dependency graphs (for local debugging)
options(reactlog = TRUE)

server <- function(input, output, session) {
  # Load data with error handling
  data <- tryCatch(
    readRDS("clean_data.rds"),
    error = function(e) {
      showNotification(paste("Error loading data:", e$message), type = "error", duration = NULL)
      NULL
    }
  )
  
  # Reactive data filtering
  filtered_data <- reactive({
    validate(
      need(input$date_range[1] <= input$date_range[2], "End date must be after start date.")
    )
    df <- data %>%
      filter(incident_date >= input$date_range[1] & incident_date <= input$date_range[2])
    if (input$region_filter != "All") {
      df <- df %>% filter(region == input$region_filter)
    }
    validate(
      need(nrow(df) > 0, "No incidents found for the selected region and date range.")
    )
    df
  })
  
  # Theme settings
  theme_settings <- reactive({
    switch(input$theme_selector,
           "Default" = list(
             plot_bg = "white",
             paper_bg = "white",
             font_color = "black",
             colorscale = "Viridis",
             table_bg = "white",
             table_text = "black",
             kpi_bg = "#f0f0f0",
             kpi_text = "black"
           ),
           "Dark" = list(
             plot_bg = "#1e1e1e",
             paper_bg = "#1e1e1e",
             font_color = "white",
             colorscale = "Blues",
             table_bg = "#2e2e2e",
             table_text = "white",
             kpi_bg = "#333333",
             kpi_text = "white"
           ),
           "Light" = list(
             plot_bg = "#f5f5f5",
             paper_bg = "#f5f5f5",
             font_color = "black",
             colorscale = "Greys",
             table_bg = "#ffffff",
             table_text = "black",
             kpi_bg = "#e0e0e0",
             kpi_text = "black"
           )
    )
  })
  
  # KPI: Total Incidents
  output$total_incidents <- renderUI({
    tryCatch(
      {
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Total Incidents"),
            h3(nrow(filtered_data())))
      },
      error = function(e) {
        showNotification(paste("Error rendering Total Incidents:", e$message), type = "error", duration = NULL)
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Total Incidents"),
            h3("N/A"))
      }
    )
  })
  
  # KPI: Total Fatalities
  output$total_fatalities <- renderUI({
    tryCatch(
      {
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Total Fatalities"),
            h3(sum(filtered_data()$num_killed, na.rm = TRUE)))
      },
      error = function(e) {
        showNotification(paste("Error rendering Total Fatalities:", e$message), type = "error", duration = NULL)
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Total Fatalities"),
            h3("N/A"))
      }
    )
  })
  
  # KPI: Success Rate
  output$success_rate <- renderUI({
    tryCatch(
      {
        success_rate <- mean(filtered_data()$attack_success, na.rm = TRUE) * 100
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Success Rate"),
            h3(paste(round(success_rate, 2), "%")))
      },
      error = function(e) {
        showNotification(paste("Error rendering Success Rate:", e$message), type = "error", duration = NULL)
        div(style = sprintf("background-color: %s; color: %s; padding: 10px; border-radius: 5px; text-align: center;",
                            theme_settings()$kpi_bg, theme_settings()$kpi_text),
            h4("Success Rate"),
            h3("N/A"))
      }
    )
  })
  
  # Choropleth Map
  output$choropleth_map <- renderPlotly({
    tryCatch(
      {
        # Aggregate incidents by country
        country_data <- filtered_data() %>%
          group_by(country) %>%
          summarise(incidents = n()) %>%
          ungroup()
        
        # Create choropleth map
        plot_geo(country_data) %>%
          add_trace(
            type = "choropleth",
            locations = ~country,
            locationmode = "country names",
            z = ~incidents,
            colorscale = theme_settings()$colorscale,
            text = ~paste(country, "<br>Incidents:", incidents),
            hoverinfo = "text"
          ) %>%
          layout(
            title = list(text = "Global Incident Density by Country", font = list(color = theme_settings()$font_color)),
            geo = list(
              showframe = FALSE,
              projection = list(type = "mercator"),
              bgcolor = theme_settings()$plot_bg
            ),
            plot_bgcolor = theme_settings()$plot_bg,
            paper_bgcolor = theme_settings()$paper_bg,
            font = list(color = theme_settings()$font_color)
          )
      },
      error = function(e) {
        showNotification(paste("Error rendering Choropleth Map:", e$message), type = "error", duration = NULL)
        plotly_empty()
      }
    )
  })
  
  # Interactive Data Table
  output$incident_table <- renderDT({
    tryCatch(
      {
        datatable(
          filtered_data() %>%
            select(incident_date, city_name, country, region, attack_type, target_type, num_killed, num_wounded) %>%
            rename(Date = incident_date, City = city_name, `Attack Type` = attack_type),
          options = list(
            pageLength = 10,
            searching = TRUE,
            autoWidth = TRUE,
            scrollX = TRUE,
            dom = 'Bfrtip',
            buttons = c('copy', 'csv', 'excel')
          ),
          rownames = FALSE,
          style = "bootstrap",
          class = "table-bordered table-striped",
          callback = JS(sprintf(
            "table.on('draw.dt', function() {
               $('table').css({'background-color': '%s', 'color': '%s'});
               $('table thead').css({'background-color': '%s', 'color': '%s'});
             })",
            theme_settings()$table_bg, theme_settings()$table_text,
            theme_settings()$kpi_bg, theme_settings()$table_text
          ))
        )
      },
      error = function(e) {
        showNotification(paste("Error rendering Incident Table:", e$message), type = "error", duration = NULL)
        datatable(data.frame(Message = "Table data unavailable"))
      }
    )
  })
  
  # Trend/Time-Series Line Chart
  output$trend_chart <- renderPlotly({
    tryCatch(
      {
        # Aggregate data by year, month, and attack_type
        trend_data <- filtered_data() %>%
          mutate(year_month = floor_date(incident_date, "month")) %>%
          group_by(year_month, attack_type) %>%
          summarise(
            incidents = n(),
            fatalities = sum(num_killed, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          ungroup()
        
        # Select metric based on user input
        metric_col <- if (input$metric_selector == "Incidents") "incidents" else "fatalities"
        y_label <- if (input$metric_selector == "Incidents") "Number of Incidents" else "Number of Fatalities"
        
        # Create line chart
        plot_ly(data = trend_data, x = ~year_month, y = ~get(metric_col), color = ~attack_type, 
                type = "scatter", mode = "lines") %>%
          layout(
            title = list(text = paste("Monthly", input$metric_selector, "by Attack Type"), 
                         font = list(color = theme_settings()$font_color)),
            xaxis = list(title = "Date", titlefont = list(color = theme_settings()$font_color), 
                         tickfont = list(color = theme_settings()$font_color)),
            yaxis = list(title = y_label, titlefont = list(color = theme_settings()$font_color), 
                         tickfont = list(color = theme_settings()$font_color)),
            plot_bgcolor = theme_settings()$plot_bg,
            paper_bgcolor = theme_settings()$paper_bg,
            font = list(color = theme_settings()$font_color),
            showlegend = TRUE
          )
      },
      error = function(e) {
        showNotification(paste("Error rendering Trend Chart:", e$message), type = "error", duration = NULL)
        plotly_empty()
      }
    )
  })
  
  # Comparative Analysis Grouped Bar Chart
  output$bar_chart <- renderPlotly({
    tryCatch(
      {
        # Aggregate data by attack_type
        bar_data <- filtered_data() %>%
          group_by(attack_type) %>%
          summarise(
            killed = sum(num_killed, na.rm = TRUE),
            wounded = sum(num_wounded, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          tidyr::pivot_longer(cols = c(killed, wounded), names_to = "casualty_type", values_to = "count")
        
        # Create grouped bar chart
        plot_ly(
          data = bar_data,
          x = ~attack_type,
          y = ~count,
          color = ~casualty_type,
          type = "bar",
          text = ~count,
          textposition = "auto",
          hovertemplate = paste("Attack Type: %{x}<br>Casualty Type: %{fullData.name}<br>Count: %{y}<extra></extra>")
        ) %>%
          layout(
            title = list(text = "Casualties (Killed vs. Wounded) by Attack Type", 
                         font = list(color = theme_settings()$font_color)),
            xaxis = list(title = "Attack Type", titlefont = list(color = theme_settings()$font_color), 
                         tickfont = list(color = theme_settings()$font_color)),
            yaxis = list(title = "Number of Casualties", titlefont = list(color = theme_settings()$font_color), 
                         tickfont = list(color = theme_settings()$font_color)),
            barmode = "group",
            plot_bgcolor = theme_settings()$plot_bg,
            paper_bgcolor = theme_settings()$paper_bg,
            font = list(color = theme_settings()$font_color),
            showlegend = TRUE
          )
      },
      error = function(e) {
        showNotification(paste("Error rendering Bar Chart:", e$message), type = "error", duration = NULL)
        plotly_empty()
      }
    )
  })
}