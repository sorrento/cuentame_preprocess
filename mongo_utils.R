# https://github.com/jeroen/mongolite

# Librerías ---------------------------------------------------------------
  
  library(mongolite)
  library(readr)

# Conectar ----------------------------------------------------------------
  
  m.conectar <- function(pass){
    url.cuentame   <- paste0("mongodb://mhalat:", pass, "@ds135798.mlab.com:35798/cuentame")
    con.libros     <- mongo(collection = "libros", url = url.cuentame)
    con.libros.sum <- mongo(collection = "librosSum", url = url.cuentame)
    con.dicc       <-  mongo(collection = "diccionario", url = url.cuentame)
    
    print(paste0('*** Número de libros online: ', con.libros.sum$count() - 6))
    
    return(list(texto = con.libros, summary = con.libros.sum, diccionario = con.dicc))
  } 


  get.free.ids <- function(con) {
    libros.sum     <- as.data.table(con$summary$find())
    ids.subidos    <- libros.sum[!is.na(libroId), libroId] %>% sort
    ids.candidatos <- setdiff(seq(min(ids.subidos), max(ids.subidos) + 40), ids.subidos)
    
    return(ids.candidatos)
  }
  
  m.show.books <- function(con) {
    as.data.table(con$summary$find())[!is.na(libroId), .(libroId, fakeTitle, title, author)][order(libroId)] %>% 
      View
  }
  
  m.borra.libros <- function(con, ids){
    # de summary
      q <- paste0('{"libroId" : {"$in" :[', lista(ids),']}}')
      con$summary$remove(q)
    
    # texto
      q <- paste0('{"nLibro" : {"$in" :[', lista(ids),']}}')
      con$texto$remove(q)
  }
  
  # se prepara una cuero u luego se aplica con "remove"
  lista <- function(x, texto = F){
    
    ch <- ifelse(texto == T, "\",\"", ",")
    paste0(x, collapse = ch)
  }
  
# Libros online -----------------------------------------------------------
   # n.libro <- max(libros.sum$libroId, na.rm = T) + 1
  # ruta.partes <- strsplit(ruta, "(/| - |\\.txt)")[[1]] %>% rev
  # autor <- ruta.partes[1];titulo <- ruta.partes[2]
  # txt.total <- read_file(ruta)


# Libros que están mal ----------------------------------------------------

  # out <- con$find('{"nCapitulo" : "8"}')
  # out <- out %>% select(-texto)
  # nlibros.bad <- out$nLibro

# reparar ----------------------------------------------------------------

  #  ids.reparar <- nlibros.bad
  # 
  # for(i in ids.reparar){
  #   print(paste("reparando", i))
  #   
  #   i <- 151
  #   query <- paste0('{"nLibro" : ', i,'}')
  #   l.38 <- con.libros$find(query) %>% as.data.table
  #   
  #   # lo borramos online
  #   con$remove(query)
  #   
  #   # reparamos
  #   
  #   l.38 <- l.38[, nCapitulo := as.numeric(nCapitulo)]
  #   # l.38 %>% str
  #   
  #   # lo subimos
  #   con$insert(l.38)
  # }
  

# tips MONGODB ------------------------------------------------------------
  # https://docs.mongodb.com/manual/reference/method/db.collection.find/
  # https://jeroen.github.io/mongolite/query-data.html#sort-and-limit
  
  # dmd$find('{"cut" : "Premium"}', sort = '{"price": -1}', limit = 7)
  # db.inventory.find( { qty: { $in: [ 5, 15 ] } } )
  # db.inventory.find( { qty: { $in: [ 5, 15 ] } } )

  
