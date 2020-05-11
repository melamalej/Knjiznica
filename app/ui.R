library(shiny)
library(shinydashboard)

shinyUI(dashboardPage(
  dashboardHeader(title = "Library"),
  dashboardSidebar(sidebarMenu(
    menuItem("Home page", tabName = "naslovnica", icon = icon("home")),
    menuItem("Books", tabName = "knjige", icon = icon("book")),
    menuItem("Borrow a book", tabName = "izposoja", icon = icon("book-reader")),
    menuItem("My loans", tabName = "profil", icon = icon("user")))
  ),
  dashboardBody(
    # Boxes need to be put in a row (or column)
    tabItems(
      # First tab content
      tabItem(tabName = "naslovnica",
              h2("Welcome to our library!")),
      # Second tab content
      tabItem(tabName = "knjige",
              h2("Widgets tab content")),
      # Third tab content
      tabItem(tabName = "izposoja",
              h2("Widgets tab content")),
      # Fourth tab content
      tabItem(tabName = "profil",
              h2("Widgets tab content"))
    )
  )
)
)

#shinyUI(fluidPage(

  #titlePanel("Knjiznica"),

  #sidebarLayout(
    #sidebarPanel(
      #sliderInput("min",
                  #"Minimalni znesek transakcije:",
                  #min = -10000,
                  #max = 10000,
                  #value = 1000)
    #),

    #mainPanel(
      #tableOutput("transakcije")
    #)
  #)
#))
