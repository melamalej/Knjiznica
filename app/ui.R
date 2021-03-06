library(shiny)
library(shinythemes)
library(knitr)
library(dplyr)
library(dbplyr)
library(hash)
library(rvest)
library(gsubfn)
library(tibble)
library(DT)
library(shiny)
library(dplyr)
library(RPostgreSQL)
library(shinyjs)
library(shinyBS)
library(DBI)
library(bcrypt)
library(digest)

#source("server.R")

vpisniPanel <- tabPanel("SignIn", value="signIn",
                   fluidPage( 
                     titlePanel("Welcome to our library. Please sign in."),
                     img(src = "naslovna.jpg", height = 180, width = 800),
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
  shinyjs::useShinyjs(),
  theme = shinytheme("cerulean"),
  conditionalPanel(condition = "output.signUpBOOL!='1' && output.signUpBOOL!='2'",#&& false",
                   vpisniPanel),
  conditionalPanel(condition = "output.signUpBOOL=='2'",
                   navbarPage('Library', 
                     tabPanel('Home',
                              titlePanel('My online library.'),
                              img(src = "izposoja.jpg", height = 240, width = 260),
                              actionButton(
                                inputId = "logout",
                                label = "Logout",
                                tooltip = "Logout",
                                icon = icon("sign-out"),
                                style="color:black; border-color: black"
                                )),
                     tabPanel("Books",
                              mainPanel(DT::dataTableOutput(outputId ="vse.knjige"))
                              ),
                     navbarMenu("Browse",
                                tabPanel("By title",
                                         textInput("title", "Enter title",placeholder = 'Search by title'),
                                         actionButton(inputId ="gumb1", label = "Search"),
                                         textOutput("napis"),
                                         dataTableOutput("sporocilo1")),
                                tabPanel("By author",
                                         textInput("author", "Enter author",placeholder = 'Search by author'),
                                         actionButton(inputId ="gumb2", label = "Search"),
                                         textOutput("napis2"),
                                         dataTableOutput("rezultat2")),
                                tabPanel("By genre",
                                         textInput("genre", "Enter genre",placeholder = 'Search by genre'),
                                         actionButton(inputId ="gumb3", label = "Search"),
                                         textOutput("napis3"),
                                         dataTableOutput("rezultat3"))
                                ),
                     navbarMenu("My profile",
                                tabPanel("Active loans",
                                         titlePanel('Active loans'),
                                         DT::dataTableOutput(outputId ="active_loans")
                                         ),
                                tabPanel("Returned books",
                                         titlePanel('Returned books'),
                                         DT::dataTableOutput(outputId ="returned_books")
                                )
                                )

                 )
                )
  ))

