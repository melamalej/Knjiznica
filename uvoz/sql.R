# Neposredno klicanje SQL ukazov v R
library(dplyr)
library(dbplyr)
library(RPostgreSQL)
library(rvest)

source("uvoz/auth.R")

# Povežemo se z gonilnikom za PostgreSQL
drv <- dbDriver("PostgreSQL")

# Uporabimo tryCatch,
# da prisilimo prekinitev povezave v primeru napake
tryCatch({
  # Vzpostavimo povezavo z bazo
  conn <- dbConnect(drv, dbname=db, host=host, user=user, password=password)
  t <- dbGetQuery(conn, build_sql("SELECT * FROM books", con=conn))
                   
  # Poizvedbo zgradimo s funkcijo build_sql
  # in izvedemo s funkcijo dbGetQuery
  #znesek <- 1000
  #t <- dbGetQuery(conn, build_sql("SELECT * FROM transakcija
                                  #WHERE znesek >", znesek, "
                                  #ORDER BY znesek, id", con=conn))
  # Rezultat dobimo kot razpredelnico (data frame)
  
  
  # Vstavimo še eno transakcijo
  #i <- round(runif(1, 1, nrow(t)))
  #print("Storniramo transkacijo:")
  #print(t[i,])
  #znesek <- -t[i, "znesek"]
  #racun <- t[i, "racun"]
  #opis <- paste("Storno:", t[i, "opis"])
  
  # Pošljemo poizvedbo
  #dbSendQuery(conn, build_sql("INSERT INTO transakcija (znesek, racun, opis)
                               #VALUES (", znesek, ", ", racun, ", ", opis, ")", con=conn))
  #}, finally = {
    # Na koncu nujno prekinemo povezavo z bazo,
    # saj preveč odprtih povezav ne smemo imeti
    dbDisconnect(conn)
    # Koda v bloku finally se izvede v vsakem primeru
    # - bodisi ob koncu izvajanja bloka try,
    # ali pa po tem, ko se ta konča z napako
  })

# Če tabela obstaja, jo zbrišemo
delete_table <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
    
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS users CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS books CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS transaction CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS loan CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS make CASCADE", con=conn))
    
  }, finally = {
    dbDisconnect(conn)
  })
}


create_table <- function(){
  # Uporabimo tryCatch (da se povežemo in bazo in odvežemo)
  # da prisilimo prekinitev povezave v primeru napake
  tryCatch({
    
    conn <- dbConnect(drv, dbname=db, host=host, user=user, password=password)
    
    # Glavne tabele
    users <- dbSendQuery(conn, build_sql("CREATE TABLE users (
                                        idnumber text PRIMARY KEY, 
                                        name text NOT NULL,
                                        lastname text NOT NULL,
                                        email text NOT NULL,
                                        adress text NOT NULL,
                                        username text NOT NULL,
                                        password text NOT NULL
                                        )", con=conn))
    
    books <- dbSendQuery(conn, build_sql("CREATE TABLE books (
                                        title text NOT NULL,
                                        author text NOT NULL,
                                        genre text NOT NULL,
                                        kobissid text PRIMARY KEY,
                                        availability text NOT NULL
                                        )", con=conn))
    
    transaction <- dbSendQuery(conn, build_sql("CREATE TABLE transaction (
                                        id text PRIMARY KEY,
                                        date_of_loan text NOT NULL,
                                        date_of_return text NOT NULL,
                                        due_date text NOT NULL,
                                        arrears INTEGER NOT NULL
                                        )", con=conn))
    
    #tabele relacij:
    
    loan <- dbSendQuery(conn, build_sql("CREATE TABLE loan(
                                        kobissid text NOT NULL REFERENCES books(kobissid),
                                        id text NOT NULL REFERENCES transaction(id))", con=conn))
    
    make <- dbSendQuery(conn, build_sql("CREATE TABLE make(
                                        idnumber text NOT NULL REFERENCES users(idnumber),
                                        id text NOT NULL REFERENCES transaction(id))", con=conn))
    
    
  }, finally = {
    dbDisconnect(conn) 
  })
}

insert_data <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
  
    dbWriteTable(conn, name="books", newdata, append=T, row.names=FALSE)
    dbWriteTable(conn, name="users", uporabniki, append=T, row.names=FALSE)

  }, finally = {
    dbDisconnect(conn) 
    
  })
}

pravice <- function(){
  # Uporabimo tryCatch,(da se povežemo in bazo in odvežemo)
  # da prisilimo prekinitev povezave v primeru napake
  tryCatch({
    # Vzpostavimo povezavo
    conn <- dbConnect(drv, dbname = db, host = host,
                      user = user, password = password)
    
    #dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO melam WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO lanaz WITH GRANT OPTION", con=conn))
    
    #dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO melam WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO lanaz WITH GRANT OPTION", con=conn))
    
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO melam WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO lanaz WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO tjasam WITH GRANT OPTION", con=conn))
    
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO melam WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO lanaz WITH GRANT OPTION", con=conn))
    #dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO tjasam WITH GRANT OPTION", con=conn))
    
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO javnost", con=conn))
    dbSendQuery(conn, build_sql("GRANT SELECT ON ALL TABLES IN SCHEMA public TO javnost", con=conn))
    
    
  }, finally = {
    # Na koncu nujno prekinemo povezavo z bazo,
    # saj preveč odprtih povezav ne smemo imeti
    dbDisconnect(conn) #PREKINEMO POVEZAVO
    # Koda v finally bloku se izvede, preden program konča z napako
  })
}

pravice()
delete_table()
create_table()
insert_data() 

