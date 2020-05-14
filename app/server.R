library(shiny)
library(dplyr)
library(RPostgreSQL)

source("auth_public.R")

DB_PORT <- as.integer(Sys.getenv("POSTGRES_PORT"))
if (is.na(DB_PORT)) {
  DB_PORT <- 5432
}

# # Povežemo se z gonilnikom za PostgreSQL
# drv <- dbDriver("PostgreSQL")
# 
# shinyServer(function(input, output, session) {
#   # Vzpostavimo povezavo
#   conn <- dbConnect(drv, dbname=db, host=host, user=user, password=password, port=DB_PORT)
  shinyServer(function(input, output, session) {
    # Vzpostavimo povezavo
    drv <- dbDriver("PostgreSQL")
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
    userID <- reactiveVal()
    dbGetQuery(conn, "SET CLIENT_ENCODING TO 'utf8'; SET NAMES 'utf8'") #poskusim resiti tezave s sumniki
    cancel.onSessionEnded <- session$onSessionEnded(function() {
      dbDisconnect(conn) #ko zapremo shiny naj se povezava do baze zapre
    })
    output$signUpBOOL <- eventReactive(input$signup_btn, 1)
    outputOptions(output, 'signUpBOOL', suspendWhenHidden=FALSE)  # Da omogoca skrivanje/odkrivanje
    observeEvent(input$signup_btn, output$signUpBOOL <- eventReactive(input$signup_btn, 1))
    uporabnik <- reactive({
      user <- userID()
      validate(need(!is.null(user), "Potrebna je prijava!"))
      user
      })
 #------------------------------------------------------------------------------------------------- 
    #protokol pri vpisu
 observeEvent(input$signin_btn,
              {signInReturn <- sign.in.user(input$userName, input$password)
              if(signInReturn[[1]]==1)
                {userID(signInReturn[[2]])
                output$signUpBOOL <- eventReactive(input$signin_btn, 2)
                # loggedIn(TRUE)
                # userID <- input$userName
                # upam da se tu userID nastavi na pravo vrednost
                }
              else if(signInReturn[[1]]==0){
                  showModal(modalDialog(
                  title = "Error during sign in",
                  paste0("An error seems to have occured. Please try again."),
                  easyClose = TRUE,
                  footer = NULL
                ))
              }
              else{
                showModal(modalDialog(
                  title = "Wrong Username/Password",
                  paste0("Username or/and password incorrect"),
                  easyClose = TRUE,
                  footer = NULL
                ))
              }
              })
 
 # sign in funkcija
 sign.in.user <- function(username, pass){
   # Return a list. In the first place is an indicator of success:
   # 1 ... success
   # 0 ... error
   # -10 ... wrong username
   # The second place represents the userid if the login info is correct,
   # otherwise it's NULL
   success <- 0
   uporabnikID <- NULL
    tryCatch({
     drv <- dbDriver("PostgreSQL")
     conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
     userTable <- tbl(conn, "users")
     obstoj <- 0
     # obstoj = 0, ce username in geslo ne obstajata,  1 ce obstaja
     uporabnik <- username
     geslo <- (userTable %>% filter(username == uporabnik) %>% select(password) %>% collect())[[1]]
     #print(pass1)
     #uporabnik vpise svoje originalno geslo, sistem pa ga prevede v hash in preveri,
     #ce se ujema s tabelo
     if(pass == geslo){
       obstoj <- 1
       uporabnikID <- (userTable %>% filter(username == uporabnik) %>% select(idnumber) %>% collect())[[1]]
     }
     if(obstoj == 0){
       success <- -10
     }else{
       uporabnikID <- (userTable %>% filter(username==uporabnik) %>% select(idnumber) %>% collect())[[1]]
       success <- 1
     }
    },warning = function(w){
      print(w)
    },error = function(e){
      print(e)
    }, finally = {
      dbDisconnect(conn)
      return(list(success, uporabnikID))
    }
    )
 }
  })

# # ---------------
#   # Pripravimo tabelo
#   #tbl.transakcija <- tbl(conn, "transakcija")
#   
#   tbl.users <- tbl(conn, "users")
#   tbl.books <- tbl(conn, "books")
#   tbl.transaction <- tbl(conn, "transaction")
#   
#   # Povezava naj se prekine ob izhodu
#   cancel.onSessionEnded <- session$onSessionEnded(function() {
#     dbDisconnect(conn)
#   })
#   
#   output$transakcije <- renderTable({
#     # Naredimo poizvedbo
#     # x %>% f(y, ...) je ekvivalentno f(x, y, ...)
#     t <- tbl.transakcija %>% filter(znesek > !!input$min) %>%
#       arrange(znesek) %>% data.frame()
#     # Čas izpišemo kot niz
#     t$cas <- as.character(t$cas)
#     # Vrnemo dobljeno razpredelnico
#     t
#   })
# 


