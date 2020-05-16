library(shiny)
library(dplyr)
library(RPostgreSQL)


#source('~/OPB/Knjiznica/Knjiznica/app/auth.R')    #tudi v app dodaj auth.R da lahko urejaš tabele, javnost ne more
#source('~/Knjiznica/app/auth.R')   #lana 
#source('~/Documents/FAKS/OPB/Knjiznica/app/auth.R') 

source('~/Knjiznica/app/auth.R')

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

#KNJIGE
 #zavihek za tabelo vseh knjig
  knjige<- reactive({
    vse_knjige <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"book ID\",
                                                        availability AS \"availability\"
                                                        FROM books",con = conn)
    data <- dbGetQuery(conn, vse_knjige)
    data[, ]
  })
  output$vse.knjige <- renderDataTable({
    knjige()
    
  })

  
  
 #iskanje po avtorju
  observeEvent(input$search,{
    naslov <- renderText({input$text})
    shinyjs::reset("sporocilo1")
  })
  najdi.naslov <- reactive({
    naslov <- input$text
    sql_naslov <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE title =",naslov, con = conn)
    knjige_naslov <- dbGetQuery(conn, sql_naslov)
    validate(need(nrow(knjige_naslov) > 0, "Sorry, we don't have a book whit this title"))
    # validate(need( nrow(komentarji) == 0, "Spodaj so vaša že poslana sporočila" ))
    knjige_naslov
  })
  
  output$sporocilo1<- renderDataTable(datatable(najdi.naslov()) %>% formatStyle(columns = c('Book title', 'Author','Genre','Book ID','Availability'), color = 'grey') )
  
  #Iskanje po avtorju      Ko vpišeš avtorja avtomatično najde že preden klikneš search???
  observeEvent(input$search,{
    avtor <- renderText({input$author})
    shinyjs::reset("sporocilo2")
  })
  najdi.avtor <- reactive({
    avtor <- input$author
    sql_avtor <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE author =",avtor, con = conn)
    knjige_avtor <- dbGetQuery(conn, sql_avtor)
    validate(need(nrow(knjige_avtor) > 0, "Sorry, we don't have a book whit this title"))     #ko nič ne vpišeš že to piše, je treba popravit
    # validate(need( nrow(komentarji) == 0, "Spodaj so vaša že poslana sporočila" ))     
    knjige_avtor
  })
  
  output$sporocilo2<- renderDataTable(datatable(najdi.avtor()) %>% formatStyle(columns = c('Book title', 'Author','Genre','Book ID','Availability'), color = 'grey') )
  
 #iskanje po žanru
  observeEvent(input$search,{
    zanr <- renderText({input$genre})
    shinyjs::reset("sporocilo3")
  })
  najdi.zanr <- reactive({
    zanr <- input$genre
    sql_zanr <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"Book ID\",
                                                        availability AS \"Availability\"
                                                        FROM books WHERE genre =",zanr, con = conn)
    knjige_zanr <- dbGetQuery(conn, sql_zanr)
    validate(need(nrow(knjige_zanr) > 0, "Sorry, we don't have a book whit this title"))     #ko nič ne vpišeš že to piše, je treba popravit
    # validate(need( nrow(komentarji) == 0, "Spodaj so vaša že poslana sporočila" ))     
    knjige_zanr
  })
  
  output$sporocilo3 <- renderDataTable(datatable(najdi.zanr()) %>% formatStyle(columns = c('Book title', 'Author','Genre','Book ID','Availability'), color = 'grey') )
  
  #--------------
  #Izposodi knjigo
  

  observeEvent(input$borrow,{
    idknjige <- renderText({input$bookid})
    danasnji_datum <- Sys.Date()    #v SQL mi now() in CURDATE() ne delata pravilno
    sql_id <- build_sql("SELECT availability FROM books WHERE kobissid =",input$bookid, con = conn)
    id <- dbGetQuery(conn, sql_id)
    
    
    trans <- floor(runif(1, 10000, 99999))
    dosedanje_transakcije <- build_sql("SELECT id FROM transaction", con = conn)
    dos_trans <- dbGetQuery(conn, dosedanje_transakcije)
    if(trans %in% dos_trans$id) {trans <- round(runif(1, 10000, 99999))}
    
    if((id %>% pull(availability)) == 'yes'){
      sql_zapis <- build_sql("INSERT INTO transaction(id,kobissid,idnumber, date_of_loan, due_date)  
                        VALUES( ",trans,",",input$bookid,",", uporabnik(),",",danasnji_datum,",", danasnji_datum + 7,")", con = conn)     
      # transakcije id zdej vsakič nove zgenerira, ampak je v tabeli .0 končnica
      
      sql_razpolozljivost <- build_sql("UPDATE books SET availability = 'no'
                                      WHERE kobissid =" ,input$bookid, con = conn)    #spremeni razpoložljivost v books
      zapis <- dbGetQuery(conn, sql_zapis)
      razpolozljivost <- dbGetQuery(conn, sql_razpolozljivost)
      zapis
      razpolozljivost 
      
      naslov_knjige <- build_sql("SELECT title FROM books WHERE kobissid =",input$bookid, con = conn)
      naslov <- dbGetQuery(conn, naslov_knjige)
      n <- naslov %>% pull(title)
      tekst <- sprintf("The book %s was successfully borrowed.", n)
      
      output$uspesnost <- renderPrint({tekst})
      # Izpiše naslov knjige ampak kot stolpec Age of wrath, The ...
   
    }
    else{
      output$uspesnost <- renderText({"Sorry, the book is not available."})
    }
    shinyjs::reset("bookid")
  })
  
  
  
  #vrnitev
  observeEvent(input$return,{
    idknjige <- renderText({input$book})
    danasnji<- Sys.Date() 
    sql_Id <- build_sql("SELECT availability FROM books WHERE kobissid =",input$book, con = conn)
    Id <- dbGetQuery(conn, sql_Id)
    
    #sql_mora_vrnit <- build_sql("SELECT due_date FROM transaction WHERE kobissid =",input$book, con = conn)
    #mora_vrniti <- dbGetQuery(conn, sql_mora_vrnit)
    #bi_moral_vrniti <- mora_vrniti %>% pull(due_date)
    
    #zamuda <- danasnji - bi_moral_vrniti
    #zamudnina <- zamuda * 0.5 
      
    if((Id %>% pull(availability)) == 'no'){
      sql_zap <- build_sql("UPDATE transaction SET date_of_return = ",danasnji,"
                             WHERE kobissid =",input$book,"AND date_of_return IS NULL", con = conn)
      
      sql_raz <- build_sql("UPDATE books SET availability = 'yes'
                                      WHERE kobissid =" ,input$book, con = conn)    #spremeni razpoložljivost v books
      zap <- dbGetQuery(conn, sql_zap)
      razp <- dbGetQuery(conn, sql_raz)
      zap
      razp

      output$vrniti <- renderPrint({"The book was successfully returned."})
    }
    else{
      output$vrniti <- renderText({"Wrong bookID"})
    }
    shinyjs::reset("uspesnost")
  })
  
  
  
  
  
  #################################################################################3

  #moje_izposoje <- reactive({ 
    #sql_u <- build_sql("SELECT kobissid FROM transaction WHERE idnumber = ",uporabnik(),con = conn)
    #u <- dbGetQuery(conn, sql_u)
    #sql_naslovi_izposojenih <- build_sql("SELECT title.books, author.books FROM books 
                                       #INNER JOIN sql_u ON sql_u.kobissid = books.kobissid", con = conn)
    
    #naslovi_izposojenih <- dbGetQuery(conn, sql_naslovi_izposojenih)
    #naslovi_izposojenih[, ]
    #u[, ]
  #})
  
  #output$my_loans<- renderDataTable({
    #moje_izposoje()
   
  #})
    
    
  #id_trenutnega_uporabnika <- uporabnik()
  
  #sql_U <- build_sql("SELECT kobissid FROM transaction WHERE idnumber = ",id_trenutnega_uporabnika,"", con = conn)
  #U <- dbGetQuery(conn, sql_U)
  
  #sql_naslovi_izposojenih <- build_sql("SELECT title.books, author.books FROM books 
                                       #INNER JOIN sql_U ON kobissid.sql_U = kobissid.books", con = conn)
  
  
  
  

  
  
  
  #  output$uspesnost <- renderText({
  #    idknjige <- renderText({input$bookid})
  #    sql_id <- build_sql("SELECT availability FROM books WHERE kobissid =",input$bookid, con = conn)
  #    id <- dbGetQuery(conn, sql_id)
  #    if ((id %>% pull(availability)) == 'yes') {
  #      "The book successfully borrowed"
  #    } else {
  #      "Sorry, the book is not available"
  #    }
  # })

  
  })
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
#     # Čas izpišemo kot niz
#     t$cas <- as.character(t$cas)
#     # Vrnemo dobljeno razpredelnico
#     t
#   })
# 


