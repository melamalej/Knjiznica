# Uvozimo potrebne knjižnice
library(rvest)
library(dplyr)
library(gsubfn)
library(readr)

# Naslov, od koder pobiramo podatke
#link <- "https://sl.wikipedia.org/wiki/Seznam_ob%C4%8Din_v_Sloveniji"
#stran <- html_session(link) %>% read_html()

# Preberemo prvo ustrezno tabelo
#tabela <- stran %>% html_nodes(xpath="//table[@class='wikitable sortable']") %>%
  #.[[1]] %>% html_table()

knjige <- read_csv("knjige.csv")
knjige$Height <- NULL
knjige$SubGenre <- NULL
knjige$Publisher <- NULL
newdata <- na.omit(knjige)  

v <- round(runif(187, min = 10000, max = 99999))    

newdata$kobissid <- v
newdata$availability <- rep(c("yes"), times = 187)
names(newdata)[names(newdata)=="Title"] <- "title"
names(newdata)[names(newdata)=="Author"] <- "author"
names(newdata)[names(newdata)=="Genre"] <- "genre"

# Zapišemo v datoteko CSV
write_csv(newdata, "books.csv", na="")

uporabniki <- read_csv("uporabniki.csv")
names(uporabniki)[names(uporabniki)=="emso"] <- "idnumber"
names(uporabniki)[names(uporabniki)=="ime"] <- "name"
names(uporabniki)[names(uporabniki)=="priimek"] <- "lastname"
names(uporabniki)[names(uporabniki)=="naslov"] <- "adress"
names(uporabniki)[names(uporabniki)=="uporabnisko_ime"] <- "username"
names(uporabniki)[names(uporabniki)=="geslo"] <- "password"


# Nadomestimo decimalne vejice in ločila tisočic ter pretvorimo v števila
#sl <- locale(decimal_mark=",", grouping_mark=".")
#for (i in c(2, 3, 5, 6)) {
  #tabela[[i]] <- tabela[[i]] %>% parse_number(na="-", locale=sl)
#}
#tabela[[9]] <- tabela[[9]] %>% parse_character(na="-")

# Zapišemo v datoteko CSV
#write_csv(tabela, "obcine.csv", na="")
