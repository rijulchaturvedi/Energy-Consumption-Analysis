library(shiny)
library(ggplot2)
library(dplyr)
library(patchwork)

# Define UI
ui <- fluidPage(
  
  titlePanel("Energy Consumption Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset", "Select Dataset:", choices = c("July Subset", "Rest of the Year Subset")),
      sliderInput("temperature_increase", "Temperature Increase (°C):", min = 0, max = 10, value = 5)
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Energy Consumption", plotOutput("energy_plot")),
        tabPanel("Heating and VAC", plotOutput("heating_vac_plot")),
        tabPanel("Quarterly Energy", plotOutput("quarterly_energy_plot"))
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Sample data
  set.seed(123)
  increased_temp_july_subset <- data.frame(
    time = seq(as.POSIXct("2018-07-01 00:00:00"), by = "hour", length.out = 100),
    `Dry Bulb Temperature [°C]` = runif(100, 20, 35),
    sum_heating = runif(100, 100, 200),
    sum_vac = runif(100, 50, 150),
    total_energy_sum = runif(100, 500, 1000),
    out.electricity.pv.energy_consumption = runif(100, 200, 400)
  )
  
  # Function to filter dataset based on user selection and temperature increase
  filtered_data <- reactive({
    # Replace this with your dataset filtering logic
    return(increased_temp_july_subset)
  })
  
  # Function to calculate quarterly energy consumption
  calculate_quarterly_energy <- reactive({
    data <- filtered_data()
    quarterly_energy <- data %>%
      mutate(quarter = quarters(time)) %>%
      group_by(quarter) %>%
      summarize(total_energy_sum = sum(total_energy_sum),
                pv_energy_consumption = sum(out.electricity.pv.energy_consumption))
    return(quarterly_energy)
  })
  
  # Function to calculate monthly sum_heating and sum_vac
  calculate_monthly_heating_vac <- reactive({
    data <- filtered_data()
    monthly_heating_vac <- data %>%
      mutate(month = format(time, "%m")) %>%
      group_by(month) %>%
      summarize(avg_sum_heating = mean(sum_heating),
                avg_sum_vac = mean(sum_vac))
    return(monthly_heating_vac)
  })
  
  # Render plot for energy consumption
  output$energy_plot <- renderPlot({
    total_energy_sum <- sum(filtered_data()$total_energy_sum)
    pv_energy_consumption <- sum(filtered_data()$out.electricity.pv.energy_consumption)
    
    # Create dataframe for plotting
    energy_df <- data.frame(Category = c("Total Energy Consumption", "PV Energy Consumption"),
                            Energy = c(total_energy_sum, pv_energy_consumption))
    
    # Plot quarterly energy consumption
    quarterly_energy <- calculate_quarterly_energy()
    
    # Plot
    p1 <- ggplot(energy_df, aes(x = Category, y = Energy, fill = Category)) +
      geom_bar(stat = "identity") +
      labs(title = "Energy Consumption Analysis",
           y = "Energy (kWh)",
           fill = "Category") +
      theme_minimal()
    
    p2 <- ggplot(quarterly_energy, aes(x = factor(quarter), y = total_energy_sum, fill = "Total Energy Consumption")) +
      geom_bar(stat = "identity") +
      labs(title = "Quarterly Energy Consumption",
           x = "Quarter",
           y = "Total Energy Consumption (kWh)",
           fill = NULL) +
      theme_minimal()
    
    p3 <- ggplot(quarterly_energy, aes(x = factor(quarter), y = pv_energy_consumption, fill = "PV Energy Consumption")) +
      geom_bar(stat = "identity") +
      labs(title = "Quarterly PV Energy Consumption",
           x = "Quarter",
           y = "PV Energy Consumption (kWh)",
           fill = NULL) +
      theme_minimal()
    
    # Combine the plots using patchwork
    combined_plots <- p2 / p3
    final_plot <- p1 + combined_plots
    
    # Render the combined plot
    final_plot
  })
  
  # Render plot for heating and VAC
  output$heating_vac_plot <- renderPlot({
    monthly_heating_vac <- calculate_monthly_heating_vac()
    
    # Plot
    p <- ggplot(monthly_heating_vac, aes(x = month, y = avg_sum_heating, fill = "Heating")) +
      geom_bar(stat = "identity", position = "dodge") +
      geom_bar(aes(y = avg_sum_vac, fill = "VAC"), stat = "identity", position = "dodge") +
      labs(title = "Monthly Heating and VAC Consumption",
           x = "Month",
           y = "Average Consumption",
           fill = NULL) +
      scale_fill_manual(values = c("Heating" = "blue", "VAC" = "green")) +
      theme_minimal()
    
    # Render the plot
    p
  })
  
  # Render plot for quarterly energy consumption
  output$quarterly_energy_plot <- renderPlot({
    quarterly_energy <- calculate_quarterly_energy()
    
    # Plot
    p <- ggplot(quarterly_energy, aes(x = factor(quarter), y = total_energy_sum, fill = "Total Energy Consumption")) +
      geom_bar(stat = "identity") +
      labs(title = "Quarterly Energy Consumption",
           x = "Quarter",
           y = "Total Energy Consumption (kWh)",
           fill = NULL) +
      theme_minimal()
    
    # Render the plot
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)
