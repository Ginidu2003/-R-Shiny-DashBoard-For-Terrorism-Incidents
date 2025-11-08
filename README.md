### Overview
--------

This project is an interactive Shiny dashboard for analyzing terrorism incident data from 2015 to 2017. The dashboard provides visualizations and metrics on incidents, fatalities, success rates, global density maps, trends, and comparative analysis. It allows users to filter by theme, region, date range, and metrics.

The dashboard is built using R and Shiny, with data preprocessing, UI, server logic, and deployment scripts separated for modularity.

### Code Structure and Organization

The project is organized into separate R scripts for clarity and maintainability:

*   **r preprocessed.R**: Handles data cleaning and preparation. Loads raw CSV, processes it, and saves cleaned versions (.RDS  ) for use in the app.
    
*   **ui.R**: Defines the user interface using Shiny's fluidPage layout. Includes a sidebar for filters and a main panel with tabs for different views. Uses bslib for theming and cards for visual elements.
    
*   **server.R**: Contains the server logic. Loads data, defines reactive expressions for filtering and theming, and renders outputs (KPIs, plots, table) with error handling.
    
*   **shinyapp\_IO.R**: Deployment script using rsconnect to publish the app to Shinyapps.io and retrieve logs.
    

This separation follows Shiny best practices: preprocessing offline to reduce app load time, UI for layout, server for logic, and a dedicated script for deployment.

### Description of Key Functions and Their Purposes

*   **In r preprocessed.R**:
    
    *   read.csv(): Loads the raw dataset.
        
    *   colSums(is.na()) / nrow(): Calculates NA proportions to identify and remove high-missing columns.
        
    *   select\_if(): Selects columns with <60% NAs.
        
    *   make\_date(): Creates a unified incident\_date column from year, month, day.
        
    *   saveRDS() and write.csv(): Saves cleaned data for app use.
        
*   **In ui.R**:
    
    *   fluidPage(): Main layout container with Bootstrap theme via bs\_theme().
        
    *   sidebarPanel(): Contains input controls (selectInput for theme/region/metric, dateRangeInput).
        
    *   mainPanel() with tabsetPanel(): Organizes tabs for Overview, Incident Details, Trends, and Comparative Analysis.
        
    *   card(): Wraps outputs in styled cards for better visual appeal.
        
*   **In server.R**:
    
    *   readRDS(): Loads preprocessed data (wrapped in tryCatch for error handling).
        
    *   filtered\_data() (reactive): Filters data based on user inputs (date range, region); uses validate() and need() for input validation.
        
    *   theme\_settings() (reactive): Returns theme colors based on selected theme.
        
    *   renderUI() for KPIs (total\_incidents, total\_fatalities, success\_rate): Computes and styles metrics.
        
    *   renderPlotly() for charts (choropleth\_map, trend\_chart, bar\_chart): Aggregates data and creates interactive plots using Plotly.
        
    *   renderDT() for incident\_table: Creates an interactive DataTable with styling and export buttons.
        
    *   tryCatch(): Wrapped around key operations to catch errors and show notifications.
        
    *   options(reactlog = TRUE): Enables reactive logging for debugging.
        
*   **In shinyapp\_IO.R**:
    
    *   setAccountInfo(): Authenticates with Shinyapps.io.
        
    *   deployApp(): Deploys the app directory.
        
    *   showLogs(): Retrieves deployment logs for troubleshooting.
        

These functions ensure modularity: reactives handle dynamic data, renders output visuals, and error handling improves robustness.

### Data Preprocessing Steps and Rationale

The preprocessing in r preprocessed.R prepares raw terrorism data for analysis, ensuring cleanliness and efficiency:

1.  **Load Data**: Read CSV with na.strings to handle various missing value representations (e.g., "", "NA", "-99"). Rationale: Standardizes NAs for accurate processing.
    
2.  **Remove High-Missing Columns**: Calculate NA proportion per column; remove those >=60% using select\_if(). Rationale: Columns with excessive missing data (e.g., rare fields) add noise and increase computation without value.
    
3.  **Select Relevant Columns**: Keep key fields like eventid, location, success, attack details, casualties. Rationale: Focuses on analytical essentials, reducing dataset size for faster app loading.
    
4.  **Data Type Conversions**: Convert IDs to character, numerics to integer, success to binary. Rationale: Ensures correct operations (e.g., summing casualties).
    
5.  **Handle Missing Values**: Impute 0 for casualties (assuming no report means none), "Unknown" for categorical fields; remove rows with missing lat/long. Rationale: Prevents errors in aggregations/plots; "Unknown" preserves data without biasing.
    
6.  **Create Date Column**: Use make\_date() from year/month/day. Rationale: Enables date-based filtering and time-series analysis.
    
7.  **Rename Columns**: Use a mapping for descriptive names (e.g., "iyear" to "year"). Rationale: Improves readability in code and outputs.
    
8.  **Save Outputs**: As RDS (for R efficiency) and CSV (for portability). Rationale: RDS loads faster in Shiny; CSV for external use.
    

These steps reduce data issues, improve performance, and ensure the app handles real-world messy data gracefully.

### Library Dependencies and Installation Instructions

The project uses the following R libraries:

*   **shiny**: Core for building interactive web apps.
    
*   **plotly**: Interactive visualizations (maps, charts).
    
*   **dplyr**: Data manipulation (filtering, summarizing).
    
*   **DT**: Interactive tables.
    
*   **colorspace**: Color handling (though minimally used).
    
*   **lubridate**: Date manipulation.
    
*   **bslib**: Bootstrap theming and cards.
    
*   **rsconnect**: Deployment to Shinyapps.io.
    
*   **tidyr**: Pivoting data (implicit in server.R bar chart).
    

**Installation**:Run in R console:

 install.packages(c("shiny", "plotly", "dplyr", "DT", "colorspace", "lubridate", "bslib", "rsconnect", "tidyr"))


### Code Comments and Explanations for Complex Logic

The code includes inline comments for key sections. Below are explanations for complex parts:

*   **Reactive Filtering in server.R (filtered\_data)**:
    
    *   Logic: Validates date range, filters by date and region, then checks for non-empty results.
        
    *   Explanation: Uses reactive() for efficiency (recomputes only on input change). validate(need()) provides user feedback without crashing, e.g., "No incidents found" if filters yield empty data. This prevents downstream errors in plots/KPIs.
        
*   **Theme Settings Reactive**:
    
    *   Logic: switch() based on input, returns a list of colors/styles.
        
    *   Explanation: Allows dynamic theming without reloading; applied via sprintf() in UI elements and Plotly layouts for consistent appearance.
        
*   **Plotly Chart Rendering (e.g., choropleth\_map)**:
    
    *   Logic: Aggregates data with group\_by() %>% summarise(), then uses plot\_geo() with traces and layouts.
        
    *   Explanation: Aggregation reduces data for plotting; colorscale from theme ensures visual consistency. Hover text (text = ~paste()) adds interactivity. Truncated in the provided code, but full layout customizes geo projection and backgrounds.
        
*   **Error Handling with tryCatch**:
    
    *   Logic: Wraps data load and renders; on error, shows notification and fallback (e.g., "N/A" or empty plot).
        
    *   Explanation: Prevents app crashes; showNotification() informs users. For plots, plotly\_empty() returns a blank placeholder to maintain layout.
        
*   **DataTable Callback in incident\_table**:
    
    *   Logic: Uses JavaScript (JS()) to apply theme styles on draw.
        
    *   Explanation: Shiny DT doesn't natively support dynamic CSS, so JS callback overrides table styles post-render, ensuring theme integration.
        
*   **Preprocessing NA Handling**:
    
    *   Logic: Threshold-based column removal, imputation for numerics/categoricals.
        
    *   Explanation: High-NA columns (>60%) are irrelevant; imputing 0 for casualties assumes underreporting means zero, avoiding bias in sums. "Unknown" for categories allows inclusion in filters without loss.
        

For more details, refer to inline comments in the scripts (e.g., "# Aggregate data by year, month, and attack\_type").

Deployment
----------

*   Use shinyapp\_IO.R to deploy: Authenticate and run deployApp().
    
*   Logs: Use showLogs() for troubleshooting.
    
*   Hosted App: Access via Shinyapps.io URL after deployment ( [https://ginidu2003.shinyapps.io/terrorist])