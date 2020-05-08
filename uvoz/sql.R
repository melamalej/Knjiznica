# Neposredno klicanje SQL ukazov v R
library(dplyr)
library(dbplyr)
library(RPostgreSQL)

source("uvoz/auth.R")

pravice <- function(){
  # Uporabimo tryCatch,(da se povežemo in bazo in odvežemo)
  # da prisilimo prekinitev povezave v primeru napake
  tryCatch({
    # Vzpostavimo povezavo
    conn <- dbConnect(drv, dbname = db, host = host,#drv=s čim se povezujemo
                      user = user, password = password)
    
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO melam WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO lanaz WITH GRANT OPTION"))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO melam WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO lanaz WITH GRANT OPTION"))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO melam WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO lanaz WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO tjasam WITH GRANT OPTION"))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO lanaz WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO melam WITH GRANT OPTION"))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO tjasam WITH GRANT OPTION"))
    
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_tjasam TO javnost"))
    dbSendQuery(conn, build_sql("GRANT SELECT ON ALL TABLES IN SCHEMA public TO javnost"))
    
    
    
  }, finally = {
    # Na koncu nujno prekinemo povezavo z bazo,
    # saj preveč odprtih povezav ne smemo imeti
    dbDisconnect(conn) #PREKINEMO POVEZAVO
    # Koda v finally bloku se izvede, preden program konča z napako
  })
}


# Povežemo se z gonilnikom za PostgreSQL
drv <- dbDriver("PostgreSQL")
# Uporabimo tryCatch,
# da prisilimo prekinitev povezave v primeru napake
tryCatch({
  # Vzpostavimo povezavo
  conn <- dbConnect(drv, dbname=db, host=host, user=user, password=password)
  
  # Poizvedbo zgradimo s funkcijo build_sql
  # in izvedemo s funkcijo dbGetQuery
  znesek <- 1000
  t <- dbGetQuery(conn, build_sql("SELECT * FROM transakcija
                                  WHERE znesek >", znesek, "
                                  ORDER BY znesek, id", con=conn))
  # Rezultat dobimo kot razpredelnico (data frame)
  
  # Vstavimo še eno transakcijo
  i <- round(runif(1, 1, nrow(t)))
  print("Storniramo transkacijo:")
  print(t[i,])
  znesek <- -t[i, "znesek"]
  racun <- t[i, "racun"]
  opis <- paste("Storno:", t[i, "opis"])
  
  # Pošljemo poizvedbo
  dbSendQuery(conn, build_sql("INSERT INTO transakcija (znesek, racun, opis)
                               VALUES (", znesek, ", ", racun, ", ", opis, ")", con=conn))
  }, finally = {
    # Na koncu nujno prekinemo povezavo z bazo,
    # saj preveč odprtih povezav ne smemo imeti
    dbDisconnect(conn)
    # Koda v bloku finally se izvede v vsakem primeru
    # - bodisi ob koncu izvajanja bloka try,
    # ali pa po tem, ko se ta konča z napako
  })