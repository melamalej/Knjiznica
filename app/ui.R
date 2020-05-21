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
library(readxl)
library(shinydashboard)
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
  theme = shinytheme("spacelab"),
  conditionalPanel(condition = "output.signUpBOOL!='1' && output.signUpBOOL!='2'",#&& false",
                   vpisniPanel),
  conditionalPanel(condition = "output.signUpBOOL=='2'",
                   navbarPage('Library',
                     tabPanel('Home',
                              titlePanel('My online library.'),
                              img(src = "izposoja.jpg", height = 240, width = 260)),
                     tabPanel("Books",
                              mainPanel(dataTableOutput("vse.knjige"))
                              ),
                     navbarMenu("Browse",
                                tabPanel("By title",
                                         textInput("text", "Enter title",placeholder = 'Search by title'),
                                         actionButton(inputId ="search", label = "Search"),
                                         textOutput("napis"),
                                         dataTableOutput("sporocilo1")),
                                tabPanel("By author",
                                         textInput("author", "Enter author",placeholder = 'Search by author'),
                                         actionButton(inputId ="search", label = "Search"),
                                         dataTableOutput("sporocilo2")),
                                tabPanel("By genre",
                                         textInput("genre", "Enter genre",placeholder = 'Search by genre'),
                                         actionButton(inputId ="search", label = "Search"),
                                         dataTableOutput("sporocilo3"))
                                                    ),
                     navbarMenu("My profile",
                                tabPanel("My loans",
                                         titlePanel('My loans.'),
                                         dataTableOutput("my_loans")
                                         ),
                                tabPanel("Borrow",
                                         titlePanel('Borrow books.'),
                                         "Here you can borrow any available books by using their id. If
                                                    you don't know it you can find it in section books.",
                                         textInput("bookid", "Enter bookID"),
                                         actionButton(inputId ="Borrow", label = "Borrow"),
                                         textOutput("uspesnost")
                                ),
                                tabPanel("Return",
                                         titlePanel("Return books."),
                                         textInput("book", "Enter bookID"),
                                         actionButton(inputId ="Return", label = "Return"),
                                         textOutput("vrniti")
                                         
                                         )
                                )

                 )
                 )
  ))

