library(shiny)
library(shinydashboard)


vpisniPanel <- tabPanel("SignIn", value="signIn",
                        fluidPage( titlePanel("Welcome to or library. Please sign in."),
                          #HTML('<body background = "https://raw.githubusercontent.com/ZavbiA/Iskalnik-postnih-posiljk/master/slike/digital-mail-2-1.jpg"></body>'),
                          fluidRow(
                            column(width = 12,
                                   align = "center",
                                   textInput("userName","User name", value= "", placeholder = "User name"),
                                   passwordInput("password","Password", value = "", placeholder = "Password"),
                                   actionButton("signin_btn", "Sign In")
                            )
                            
                            
                          )))





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
