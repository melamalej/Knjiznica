library(shiny)
library(shinydashboard)

source("server.R")
source('~/OPB/Knjiznica/Knjiznica/lib/libraries.R')

vpisniPanel <- tabPanel("SignIn", value="signIn",
                   fluidPage( 
                     titlePanel("Welcome to our library. Please sign in."),
                     img(src = "naslovna.jpg", height = 140, width = 400),
                     fluidRow(
                       column(width = 12,
                              align = "center",
                              textInput("userName","User name", value= "", placeholder = "User name"),
                              passwordInput("password","Password", value = "", placeholder = "Password"),
                              actionButton("signin_btn", "Sign In")
                              ))
                     )
                   )

    
shinyUI(fluidPage(
  conditionalPanel(condition = "output.signUpBOOL!='1' && output.signUpBOOL!='2'",#&& false",
                   vpisniPanel),
  conditionalPanel(condition = "output.signUpBOOL=='2'",
                   navbarPage('Library',
                     tabPanel("Books"
                              )),
                     navbarMenu("Browse",
                                tabPanel("By title",
                                         textInput("text", h3("Enter title"),
                                                   value = "Enter text...")),
                                tabPanel("By author",
                                         textInput("text", h3("Enter author"),
                                                   value = "Enter text...")),
                                tabPanel("By genre",
                                         textInput("text", h3("Enter genre"),
                                                   value = "Enter text..."))
                                                   ),
                     navbarMenu("My profile",
                                tabPanel("My loans"),
                                tabPanel("Borrow"),
                                tabPanel("Return"))

                 )
                 )
  )


