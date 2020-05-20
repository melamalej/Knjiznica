library(tidyr)    #za urejanje tabele v r


source('~/OPB/Knjiznica/Knjiznica/app/auth.R')    #tudi v app dodaj auth.R da lahko urejaš tabele, javnost ne more
#source('~/Knjiznica/app/auth.R')   #lana 
#source('~/OPB/Knjiznica/Knjiznica/app/auth.R')    #tudi v app dodaj auth.R da lahko urejaš tabele, javnost ne more
#source('~/Knjiznica/app/auth.R')   #lana 
#source('~/Documents/FAKS/OPB/Knjiznica/app/auth.R') 
#source('~/Knjiznica/app/auth.R')

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
    sql_vse_knjige <- build_sql("SELECT  title AS \"Book title\", author AS \"Author\",
                                                        genre  AS \"Genre\",
                                                        kobissid  AS \"book ID\",
                                                        availability AS \"availability\"
                                                        FROM books",con = conn)
    vse_knjige <- dbGetQuery(conn, sql_vse_knjige)
    vse_knjige[, ]
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
    knjige_naslov
    
  })
#še vedno ne pomaga, če nič ni napisano piše sorry,...
  output$napis <- renderText({if((count(najdi.naslov()) %>% pull()) <= 0){
    "Sorry, we don't have a book with this title." }
    else{
      "Your search."}
    })
  output$sporocilo1<- renderDataTable(datatable(najdi.naslov()))  
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
    validate(need(nrow(knjige_avtor) > 0, "Sorry, we don't have a book whit this author"))     #ko nič ne vpišeš že to piše, je treba popravit
    knjige_avtor
  })
  output$sporocilo2<-renderDataTable(datatable(najdi.avtor()))
  
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
    validate(need(nrow(knjige_zanr) > 0, "Sorry, we don't have a book whit this genre"))     #ko nič ne vpišeš že to piše, je treba popravit
    knjige_zanr
  })
  output$sporocilo3 <- renderDataTable(datatable(najdi.zanr()) )
  
  #--------------
  #Izposodi knjigo
  
  observeEvent(input$Borrow,{
    idknjige <- renderText({input$bookid})
    danasnji_datum <- Sys.Date()    #v SQL mi now() in CURDATE() ne delata pravilno
    sql_id <- build_sql("SELECT availability FROM books WHERE kobissid =",input$bookid, con = conn)
    id <- dbGetQuery(conn, sql_id)
    
    #generiranje id knjige:
    trans <- floor(runif(1, 10000, 99999))
    dosedanje_transakcije <- build_sql("SELECT id FROM transaction", con = conn)
    dos_trans <- dbGetQuery(conn, dosedanje_transakcije)
    if(trans %in% dos_trans$id) {trans <- round(runif(1, 10000, 99999))}
    
    #proces pri izposoji:
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
      
      #da se izpiše katero knjigo si si sposodil:
      #(naslovi napisani čudno, kjer se začnejo s the je ločeno z vejico, 
      #s tem ločimo v dva stolpca da se pravilno izpiše naslov ko se sposodi)
      sql_naslovi <- build_sql("SELECT * FROM books", con = conn)
      naslovi <- dbGetQuery(conn, sql_naslovi)
      naslovi <- naslovi %>% separate('title', c("prvi","drugi"), ",")
      naslov_knjige <- naslovi %>% filter(kobissid == input$bookid)
      drugi_del <-naslov_knjige %>% pull(drugi)
      if(is.na(drugi_del)){
      n <- naslov_knjige %>% pull(prvi)
      tekst <- sprintf("The book %s was successfully borrowed.", n)}
      else {
        m <- naslov_knjige %>% pull(drugi)
        n <- naslov_knjige %>% pull(prvi)  
        tekst <- sprintf("The book %s %s was successfully borrowed.", m,n)}
      
      output$uspesnost <- renderPrint({tekst})
      # Izpiše naslov knjige ampak kot stolpec  ...
   
    }
    else{
      output$uspesnost <- renderText({"Sorry, the book is not available."})
    }
    shinyjs::reset("bookid")
  })
  
  
  #vrnitev
  observeEvent(input$Return,{
    idknjige <- renderText({input$book})
    danasnji<- Sys.Date()
    
    #racunanje zamudnine
    sql_mora_vrnit <- build_sql("SELECT due_date FROM transaction WHERE kobissid =",input$book, con = conn)
    mora_vrniti <- dbGetQuery(conn, sql_mora_vrnit)
    bi_moral_vrniti <- mora_vrniti %>% pull(due_date)
    zamuda <- as.numeric(danasnji - bi_moral_vrniti)
    if(zamuda <= 0){zamudnina <- 0}
    else {zamudnina <- zamuda * 0.5}
    
    #preveri ce je knjiga sploh izposojena
    sql_razp <- build_sql("SELECT availability FROM books WHERE kobissid =",input$book, con = conn)
    razp <- dbGetQuery(conn, sql_razp)
    #proces pri vrnitvi:
    if((razp %>% pull(availability)) == 'no'){
      sql_zap <- build_sql("UPDATE transaction SET date_of_return = ",danasnji,", arrears = ",zamudnina,"
                             WHERE kobissid =",input$book,"AND date_of_return IS NULL", con = conn)
      
      sql_raz <- build_sql("UPDATE books SET availability = 'yes'
                                      WHERE kobissid =" ,input$book, con = conn)
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
  
  
  #################################################################################
  #ZDAJ DELA AMPAK NI Z JOIN, MOGOČE BI LAHKO RAJŠI Z LEFT JOIN AMPAK MI NI DELALO
  #SPET KO VRNE SE V TABELI MYLOANS VIDI ŠELE KO REFRESHAS STRAN
  
  moje_izposoje <- reactive({ 
    sql_u <- build_sql("SELECT transaction.kobissid AS \"BookID\",books.title AS \"Book title\", books.author AS \"Author\",
transaction.date_of_loan AS \"Date of loan\",transaction. due_date  AS \"Due date\", date_of_return AS \"Date of return\",
    arrears AS \"Arrears\" FROM transaction, books WHERE transaction.kobissid = books.kobissid AND transaction.idnumber = ",uporabnik(), con = conn)
    u <- dbGetQuery(conn, sql_u)
    u[, ]
  })
  
  output$my_loans<- renderDataTable({
    moje_izposoje()
   
  })
    
    
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

#     t$cas <- as.character(t$cas)
#     # Vrnemo dobljeno razpredelnico
#     t
#   })
# 


