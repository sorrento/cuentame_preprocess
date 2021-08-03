library(data.table)
library(dplyr)

source("mongo_utils.R")

dicc <- readRDS('datos/diccionario.RDS')


# INIT --------------------------------------------------------------------

  config       <- config::get() 
  con          <- m.conectar(config$pass)

# lo subimos a parse
  con$diccionario$insert(dicc)
  
  con$diccionario$insert(dicc %>% head(19))
  