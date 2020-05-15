library(shiny)
library(shinydashboard)


shinyUI(dashboardPage(
 
  dashboardHeader(title = "Library"),
  
  dashboardSidebar(sidebarMenu(
    menuItem("Home page", tabName = "naslovnica", icon = icon("home")),
    menuItem("Books", tabName = "knjige", icon = icon("book")),
    menuItem("Borrow a book", tabName = "izposoja", icon = icon("book-reader")),
    menuItem("My loans", tabName = "profil", icon = icon("user")))),
  
  dashboardBody(
    # Boxes need to be put in a row (or column)
    tabItems(
      # First tab content
      tabItem(tabName = "naslovnica",
              h2("Welcome to our library!")),
      # Second tab content
      tabItem(tabName = "knjige",
              h2("Search by title or by author"), box('', textInput('text', 'Title'), textInput('text', 'Author'),
                                             actionButton('isci', 'Search'))
            ),
      # Third tab content2
      tabItem(tabName = "izposoja",
              h2("Widgets tab content"), box('Vpis_zaposleni', textInput('text', 'User name'), textInput('text', 'Password'),
                                             actionButton('vpis', 'Login'))), 
      #tuki bi lahko mele možnost, da se vpiše samo knjižničarka, ker sam sebi itak ne morš izposodit knjige
      
      # Fourth tab content
      tabItem(tabName = "profil",
              h2("Widgets tab content"), box('Vpis_clan', textInput('text', 'User name'), textInput('text', 'Password'),
                                             actionButton('vpis', 'Login')))
      
      # tuki bi mele pa možnost da se vpiše študent in pol vidi naprej svoj profil..Ko pritisneš login bi se ti desno izpisali podatki
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

