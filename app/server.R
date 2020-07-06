library(tidyr)    #za urejanje tabele v r
library(shiny)
library(dplyr)
library(dbplyr)
library(hash)
library(RPostgreSQL)
library(bcrypt)
library(digest)
library(DT)
library(shinyjs)
library(shinymanager)

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
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password,port=DB_PORT)
    userID <- reactiveVal()   #placeholder za user ID
    loggedIn <- reactiveVal(FALSE)     #za logout button
    dbGetQuery(conn, "SET CLIENT_ENCODING TO 'utf8'; SET NAMES 'utf8'") #poskusim resiti tezave s sumniki
    cancel.onSessionEnded <- session$onSessionEnded(function() {
      dbDisconnect(conn) #ko zapremo shiny naj se povezava do baze zapre
    })
    
    output$signUpBOOL <- eventReactive(input$signup_btn, 1)
    outputOptions(output, 'signUpBOOL', suspendWhenHidden=FALSE)  # Da omogoca skrivanje/odkrivanje
    observeEvent(input$signup_btn, output$signUpBOOL <- eventReactive(input$signup_btn, 1))
    
    observeEvent(c(input$userName,input$password), {
      shinyjs::toggleState("signin_btn", 
                           all(c(input$userName, input$password)!=""))
    })
    
    #funkcija uporabnik
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
     conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password, port = DB_PORT)
     userTable <- tbl(conn, "users")
     obstoj <- 0
     # obstoj = 0, ce username in geslo ne obstajata,  1 ce obstaja
     uporabnik <- username
     geslo <- (userTable %>% filter(username == uporabnik) %>% select(password) %>% collect())[[1]]
     #print(pass1)
     #uporabnik vpise svoje originalno geslo, preveri,
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
 
 observeEvent(session$input$logout,{
   session$reload()
 })
 #------------------------------------------------------------------------------------------------- 

 # TABELA KNJIG
 #zavihek za tabelo vseh knjig
 myValue <- reactiveValues()
 
 shinyInput <- function(FUN, len, id, ...) {
   inputs <- character(len)
   for (i in seq_len(len)) {
     inputs[i] <- as.character(FUN(paste0(id, i), ...))
   }
   inputs
 }
 
 stevec <- reactiveVal(0)
 
  knjige <- reactive({
    stevec()
    sql_vse_knjige <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\", 
                                                        genre  AS \"Genre\",
                                                        availability AS \"availability\",
                                                        kobissid AS \"ID\"
                                                        FROM books",con = conn)
    vse_knjige <- dbGetQuery(conn, sql_vse_knjige)
    vse_knjige <- tibble(vse_knjige)
    vse_knjige %>% add_column(Actions = shinyInput(actionButton, nrow(vse_knjige),
                                         'button_',
                                         label = "Borrow",
                                         onclick = paste0('Shiny.onInputChange( \"select_button\" , this.id)') 
    ))
  })
  
  output$vse.knjige <- renderDataTable({
    knjige() %>% select(-ID)
  }, escape=F)
  
  #Izposodi knjigo
  
  observeEvent(input$select_button,{
    selectedRow <- as.numeric(strsplit(input$select_button, "_")[[1]][2])
    #title <<- knjige()[selectedRow,0]
    #author <<- knjige()[selectedRow,1]
    #genre <<- knjige()[selectedRow,2]
    idbook <- knjige()[selectedRow,5]
    idbook <- as.character(idbook)
    
    stevec(stevec()+1)
    
    danasnji_datum <- Sys.Date()    #v SQL mi now() in CURDATE() ne delata pravilno
    sql_id <- build_sql("SELECT availability FROM books WHERE kobissid =",idbook, con = conn)
    id <- dbGetQuery(conn, sql_id)
    
    #generiranje id izposoje:
    # trans <- floor(runif(1, 10000, 99999))
    # dosedanje_transakcije <- build_sql("SELECT id FROM transaction", con = conn)
    # dos_trans <- dbGetQuery(conn, dosedanje_transakcije)
    # if(trans %in% dos_trans$id) {trans <- round(runif(1, 10000, 99999))}
    
    #proces pri izposoji:
    if((id %>% pull(availability)) == 'yes'){
      # transakcije id zdej vsakič nove zgenerira, ampak je v tabeli .0 končnica
      sql_zapis <- build_sql("INSERT INTO transaction(id,kobissid,idnumber, date_of_loan, due_date)  
                        VALUES( ,",idbook,",", uporabnik(),",",danasnji_datum,",", danasnji_datum + 1,")", con = conn)     
      #spremeni razpoložljivost v books
      sql_razpolozljivost <- build_sql("UPDATE books SET availability = 'no'
                                      WHERE kobissid =" ,idbook, con = conn)
      zapis <- dbGetQuery(conn, sql_zapis)
      razpolozljivost <- dbGetQuery(conn, sql_razpolozljivost)
      
      zapis
      razpolozljivost
    
      #da se izpiše katero knjigo si si sposodil:
      #(naslovi napisani čudno, kjer se začnejo s the je ločeno z vejico, 
      #s tem ločimo v dva stolpca da se pravilno izpiše naslov ko se sposodi)
      sql_naslovi <- build_sql("SELECT * FROM books", con = conn)
      naslovi <- dbGetQuery(conn, sql_naslovi)
      naslovi <- naslovi %>% separate('title', c("prvi","drugi"), ",")
      naslov_knjige <- naslovi %>% filter(kobissid == idbook)
      drugi_del <-naslov_knjige %>% pull(drugi)
      if(is.na(drugi_del)){
        n <- naslov_knjige %>% pull(prvi)
        tekst <- sprintf("The book %s was successfully borrowed.", n)}
      else {
        m <- naslov_knjige %>% pull(drugi)
        n <- naslov_knjige %>% pull(prvi)  
        tekst <- sprintf("The book %s %s was successfully borrowed.", m,n)}
      #output$uspesnost <- renderPrint({tekst})
      #Izpiše naslov knjige ampak kot stolpec  ...
   
      showModal(modalDialog(
        title = "Notice",
        paste0(tekst),
        easyClose = TRUE,
        footer = actionButton("Ok1", "Ok")))
      
    }
    else{
      showModal(modalDialog(
        title = "Notice",
        paste0("Sorry, the book is not available."),
        easyClose = TRUE,
        footer = actionButton("Ok2", "Ok")))
    }
    
  })
  
  observeEvent(input$Ok1, {
    removeModal()
  })
  
  observeEvent(input$Ok2, {
    removeModal()
  })

 #-------------------------------------------------------------------------------------------------   
 #ISKANJE
  
  #iskanje po naslovu
  observeEvent(input$gumb1,{
    naslov <- renderText({input$title})
  })
  
  najdi.naslov <- reactive({
    naslov <- input$title
    sql_naslov <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE title =",naslov, con = conn)
    knjige_naslov <- dbGetQuery(conn, sql_naslov)
    knjige_naslov
    
  })
  
  isci.naslov <- eventReactive(input$gumb1, {
    najdi.naslov()
  })
  
  output$rezultat1 <- renderDataTable({
    isci.naslov()
  })
  
  isci.naslov.tekst <- eventReactive(input$gumb1, {
    tabela <- data.frame(najdi.naslov())
    if (nrow(tabela)!=0) paste("Books with title", input$title, ":")
    else paste("Sorry, we do not have book with this title.")
  })
  
  output$text1 <- renderText({
    isci.naslov.tekst()
  })  
  
  #Iskanje po avtorju      
  observeEvent(input$gumb2,{
    avtor <- renderText({input$author})
  })
  
  najdi.avtor <- reactive({
    avtor <- input$author
    sql_avtor <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE author =",avtor, con = conn)
    knjige_avtor <- dbGetQuery(conn, sql_avtor)
    knjige_avtor
  })
  
  isci.avtor <- eventReactive(input$gumb2, {
    najdi.avtor()
  })
  
  output$rezultat2<-renderDataTable({
    isci.avtor()
  })
  
  isci.avtor.tekst <- eventReactive(input$gumb2, {
    tabela <- data.frame(najdi.avtor())
    if (nrow(tabela)!=0) paste("Books from author", input$author, ":")
    else paste("Sorry, we do not have books from this author.")
  })
  
  output$text2 <- renderText({
    isci.avtor.tekst()
  })  
  
 #iskanje po žanru
  observeEvent(input$gumb3,{
    zanr <- renderText({input$genre})
  })
  najdi.zanr <- reactive({
    zanr <- input$genre
    sql_zanr <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE genre =",zanr, con = conn)
    knjige_zanr <- dbGetQuery(conn, sql_zanr)
    knjige_zanr
  })
  
  isci.zanr <- eventReactive(input$gumb3, {
    najdi.zanr()
  })
  
  output$rezultat3 <- renderDataTable({
    isci.zanr()
  })  
  
  isci.zanr.tekst <- eventReactive(input$gumb3, {
    tabela <- data.frame(najdi.zanr())
    if (nrow(tabela)!=0) paste("Books in genre", input$genre, ":")
    else paste("This genre does not exists.")
  })
  
  output$text3 <- renderText({
    isci.zanr.tekst()
  })  
  
  #------------------------------------------------------------------------------------------------- 
  
  #TABELA IZPOSOJENIH KNJIG
  
  moje_izposoje <- reactive({
    stevec()
    sql_u <- build_sql("SELECT books.title AS \"Book title\", books.author AS \"Author\",
    transaction.date_of_loan AS \"Date of loan\",transaction. due_date  AS \"Due date\", transaction.kobissid AS \"BookID\"
    FROM transaction, books WHERE transaction.kobissid = books.kobissid AND
                       date_of_return IS NULL AND transaction.idnumber = ",uporabnik(), con = conn)
    izposojene_knjige <- dbGetQuery(conn, sql_u)
    izposojene_knjige <- tibble(izposojene_knjige)
    izposojene_knjige %>% add_column(Actions = shinyInput(actionButton, nrow(izposojene_knjige),
                                                   'button_',
                                                   label = "Return",
                                                   onclick = paste0('Shiny.onInputChange( \"select_button1\" , this.id)'))
    )
    })
  
  output$active_loans<- renderDataTable({
    moje_izposoje()
  }, escape = FALSE)
  
  
  #vrni knjigo
  observeEvent(input$select_button1,{
    danasnji<- Sys.Date()
    selectedRow <- as.numeric(strsplit(input$select_button1, "_")[[1]][2])
    idbook <- moje_izposoje()[selectedRow,5]
    idbook <- as.character(idbook)
    
    #racunanje zamudnine
    sql_mora_vrnit <- build_sql("SELECT due_date FROM transaction WHERE kobissid =",idbook, con = conn)
    mora_vrniti <- dbGetQuery(conn, sql_mora_vrnit)
    bi_moral_vrniti <- mora_vrniti %>% pull(due_date)
    zamuda <- as.numeric(danasnji - bi_moral_vrniti)
    if(zamuda <= 0){zamudnina <- 0}
    else {zamudnina <- zamuda * 0.5}
    
    #preveri ce je knjiga sploh izposojena
    sql_razp <- build_sql("SELECT availability FROM books WHERE kobissid =",idbook, con = conn)
    razp <- dbGetQuery(conn, sql_razp)
    #proces pri vrnitvi:
    if((razp %>% pull(availability)) == 'no'){
      sql_zap <- build_sql("UPDATE transaction SET date_of_return = ",danasnji,", arrears = ",zamudnina,"
                             WHERE kobissid =",idbook,"AND date_of_return IS NULL", con = conn)
      
      sql_raz <- build_sql("UPDATE books SET availability = 'yes'
                                      WHERE kobissid =" , idbook, con = conn)
      zap <- dbGetQuery(conn, sql_zap)
      razp <- dbGetQuery(conn, sql_raz)
      zap
      razp
      output$vrniti <- renderPrint({"The book was successfully returned."})
      stevec(stevec()+1)
      shinyjs::reset("my_loans")
      shinyjs::reset("vse.knige")
    }
    else{
      showModal(modalDialog(
        title = "Notice.",
        paste0("This book was already returned."),
        easyClose = TRUE,
        footer = actionButton("Ok10", "Ok")))
      shinyjs::reset("my_loans")
    }
    
    if(zamuda > 0){
      showModal(modalDialog(
      title = "You need to pay arreas",
      paste0("You have exceeded your due date."),
      easyClose = TRUE,
      footer = actionButton("Pay", "Pay")))
      shinyjs::reset("my_loans")
    }
    else{
      showModal(modalDialog(
        title = "Notice.",
        paste0("You succesfully returnd your book."),
        easyClose = TRUE,
        footer = actionButton("Finish1", "Finish")))
      shinyjs::reset("my_loans")
    }
    
    shinyjs::reset("my_loans") #ne dela
    shinyjs::reset("vse.knjige")  #ne dela

  })
  
  observeEvent(input$Pay, {
    showModal(modalDialog(
      title = "You succesfully returnd your book.",
      paste0("Printing receipt. Please pay at the cash register."),
      easyClose = TRUE,
      footer = actionButton("Finish", "Finish")))
  })
  
  observeEvent(input$Finish, {
  removeModal()
  })
  observeEvent(input$Finish1, {
    removeModal()
  })
  observeEvent(input$Ok10, {
    removeModal()
  })
  
  #------------------------------------------------------------------------------------------------- 
  
  #TABELA VRNJENIH KNJIG
  vrnjene_knjige <- reactive({
    sql_u <- build_sql("SELECT books.title AS \"Book title\", books.author AS \"Author\",
transaction.date_of_loan AS \"Date of loan\",transaction. due_date  AS \"Due date\", date_of_return AS \"Date of return\",
    arrears AS \"Arrears\" FROM transaction, books WHERE transaction.kobissid = books.kobissid AND date_of_return  IS NOT NULL AND transaction.idnumber = ",uporabnik(), con = conn)
    vrnjene_knjige <- dbGetQuery(conn, sql_u)
  })
  
  output$returned_books<- renderDataTable({
    vrnjene_knjige()
  }, escape = FALSE)
  
  })


    
    
  #id_trenutnega_uporabnika <- uporabnik()

  
# # -------------------------------------------------
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

#     t$cas <- as.character(t$cas)
#     # Vrnemo dobljeno razpredelnico
#     t
#   })
# 


