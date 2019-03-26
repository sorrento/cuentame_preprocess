# https://github.com/jeroen/mongolite

# Librerías ---------------------------------------------------------------
  
  library(mongolite)
  library(readr)

# Conectar ----------------------------------------------------------------
  
  m.conectar <- function(){
    url.cuentame   <- "mongodb://mhalat:xxxx@ds135798.mlab.com:35798/cuentame"
    con.libros     <- mongo(collection = "libros", url = url.cuentame)
    con.libros.sum <- mongo(collection = "librosSum", url = url.cuentame)
    
    print(paste0('*** Número de libros online: ', con.libros.sum$count() - 6))
    
    return(list(texto = con.libros, summary = con.libros.sum))
  } 


  m.ids.libres <- function(){
    #small change
    
  }

# Libros online -----------------------------------------------------------
  libros.sum <- con.libros.sum$find() %>% as.data.table
  libros.sum[!is.na(libroId), .(title, libroId)][order(libroId)] # libroid==NA es letras de canciones
  libros.sum[is.na(libroId)]
  
  n.borrar <- c(5,7,14,17,22,30,53)
  n.borrar <- c(5)

 
  # n.libro <- max(libros.sum$libroId, na.rm = T) + 1
  # ruta.partes <- strsplit(ruta, "(/| - |\\.txt)")[[1]] %>% rev
  # autor <- ruta.partes[1];titulo <- ruta.partes[2]
  # txt.total <- read_file(ruta)

# Borrado de libros -------------------------------------------------------
  
  borra.libros <- function(ids){
  # de summary
    q <- paste0('{"libroId" : {"$in" :[',lista(ids),']}}')
    # cat(q)
    # a <- con.libros.sum$find(q)
    con.libros.sum$remove(q)
    
  # texto
    q <- paste0('{"nLibro" : {"$in" :[',lista(ids),']}}')
    # cat(q)
    # a <- con.libros$find(q, limit = 7)
    con.libros$remove(q)
  }
  # se prepara una cuero u luego se aplica con "remove"
    lista <- function(x, texto =F){
      
      ch <- ifelse(texto==T, "\",\"", ",")
      paste0(x, collapse = ch)
    }
   # lista(n.borrar)
    # borra.libros(lista(115))
  
# Libros que están mal ----------------------------------------------------

  out <- con$find('{"nCapitulo" : "8"}')
  out <- out %>% select(-texto)
  nlibros.bad <- out$nLibro

# reparar ----------------------------------------------------------------

   ids.reparar <- nlibros.bad
  
  for(i in ids.reparar){
    print(paste("reparando", i))
    
    i <- 151
    query <- paste0('{"nLibro" : ', i,'}')
    l.38 <- con.libros$find(query) %>% as.data.table
    
    # lo borramos online
    con$remove(query)
    
    # reparamos
    
    l.38 <- l.38[, nCapitulo := as.numeric(nCapitulo)]
    # l.38 %>% str
    
    # lo subimos
    con$insert(l.38)
  }
  

# tips MONGODB ------------------------------------------------------------
  # https://docs.mongodb.com/manual/reference/method/db.collection.find/
  # https://jeroen.github.io/mongolite/query-data.html#sort-and-limit
  
  # dmd$find('{"cut" : "Premium"}', sort = '{"price": -1}', limit = 7)
  # db.inventory.find( { qty: { $in: [ 5, 15 ] } } )
  # db.inventory.find( { qty: { $in: [ 5, 15 ] } } )

  
