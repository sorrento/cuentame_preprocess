# Librerías ---------------------------------------------------------------

  library(data.table)
  library(mongolite)
  library(dplyr)
  library(readr)

# Conectar ----------------------------------------------------------------

  url.cuentame   <- "mongodb://mhalat:xxxxxx@ds135798.mlab.com:35798/cuentame" #pass corta
  con.libros     <- mongo(collection = "libros", url = url.cuentame)
  con.libros.sum <- mongo(collection = "librosSum",url = url.cuentame)
  
  con.libros.sum$count()
  # con.libros$count()

# Selección de libros -----------------------------------------------------
  # setwd("c:/Users/Milenko/Documents/Biblioteca de calibre/") # red
  setwd("c:/Users/halatm/Documents/Biblioteca de calibre/")

  txts <- list.files(".", pattern = "txt$", recursive = T, full.names = T)
  
  dt.files <- lapply(txts, file.info) %>% bind_rows %>% as.data.table
  dt.files[, ':='(path  = txts,
                  fecha = as.Date(mtime))]
  (fechas <- dt.files$fecha %>% unique %>% sort(T))
  
  rutas <- dt.files[fecha == fechas[1]]$path # fecha y quitamos el que está en inglés

# Configuración -----------------------------------------------------------
  
  # tres libros para hacer el titulo
  # rutas <- c("c:/Users/Milenko/Documents/Biblioteca de calibre/Clara Sanchez/Lo que esconde tu nombre (75)/Lo que esconde tu nombre - Clara Sanchez.txt",
  #            "c:/Users/Milenko/Documents/Biblioteca de calibre/Camilo Jose Cela/Nuevo viaje a la Alcarria (74)/Nuevo viaje a la Alcarria - Camilo Jose Cela.txt",
  #            "c:/Users/Milenko/Documents/Biblioteca de calibre/Eduardo Gallego y Guillem Sanchez/La Cosecha del Centauro (76)/La Cosecha del Centauro - Eduardo Gallego y Guillem Sanch.txt"
  # )  
  # ruta1 <- "c:/Users/Milenko/Documents/Biblioteca de calibre/Clara Sanchez/Lo que esconde tu nombre (75)/Lo que esconde tu nombre - Clara Sanchez.txt"
  # ruta2 <- "c:/Users/Milenko/Documents/Biblioteca de calibre/Camilo Jose Cela/Nuevo viaje a la Alcarria (74)/Nuevo viaje a la Alcarria - Camilo Jose Cela.txt"
  # ruta3 <- "c:/Users/Milenko/Documents/Biblioteca de calibre/Eduardo Gallego y Guillem Sanchez/La Cosecha del Centauro (76)/La Cosecha del Centauro - Eduardo Gallego y Guillem Sanch.txt"
  # 
  th     <- 1200 # letras maximas por seccion
  th.min <- 500

# División ----------------------------------------------------------------
  
  libros.sum     <- con.libros.sum$find() %>% as.data.table
  ids.subidos    <- libros.sum[!is.na(libroId), libroId] %>% sort
  ids.candidatos <- setdiff(seq(min(ids.subidos), max(ids.subidos) + 1), ids.subidos)
  # n.libro      <- max(libros.sum$libroId, na.rm = T) + 1
  n.libro        <- ids.candidatos[1]
  ruta <- rutas[1]
  ruta.partes    <- strsplit(ruta, "(/| - |\\.txt)")[[1]] %>% rev
  autor          <- ruta.partes[1];titulo <- ruta.partes[2]
  txt.total      <- read_file(ruta)
  
  dt.partes <- data.table(txt = strsplit(txt.total, "\r\n")[[1]])
  dt.partes[, ':='(
    letras  = stringi::stri_length(txt),
    preview = strtrim(txt, 100),
    id      = 1:.N)]
  dt.partes <- dt.partes[letras > 0]

# Cabeza y cola -----------------------------------------------------------

  dt.partes[1:25,.(id, preview)]
  dt.partes[,. (id, preview)] %>% tail(155) %>% as.data.frame
  mini <- 49; maxi <- 5360
  dt.partes <- dt.partes[id >= mini & id <= maxi]
  
# Capsulas --------------------------------------------------------------
  
  dt.partes$grupo <- 0
  i <- 1
  while (nrow(dt.partes[grupo == 0]) > 0){
    print(i)
    if (dt.partes[grupo == 0][1, letras] >= th) {
      idm <- dt.partes[grupo == 0][1, id]
      print(paste("uno Largo", dt.partes[grupo == 0][1, letras], "id=", idm))
      dt.partes[id == idm, grupo := i]
    } else{
      dt.partes[grupo == 0, cu := cumsum(letras)]
      dt.partes[grupo == 0 & cu < th, grupo := i]
      # si es menor que el largo minimo, incluimos tambien el siguietne
      if (dt.partes[grupo == i, .SD[.N, cu]] < th.min) {
        print(paste("esmu corto"))
        idm <- dt.partes[grupo == 0][1, id]
        dt.partes[id == idm, grupo := i]
      }
    }
    i <- i + 1
  }
  
  aver <- dt.partes[, .(
    # id = .SD[1,id],
    texto = paste0(txt, collapse = "\r\n"),
    letras = sum(letras),
    preview = .SD[1,preview],
    nLibro = n.libro, 
    autor = autor,
    titulo = titulo
  ), grupo][, nCapitulo := 1:.N]
  
  aver[,.(nCapitulo, letras, preview)]
  
  dt <- aver %>% select(-preview,-letras,-grupo)
  # names(dt)
  # str(dt)

  con.libros$insert(dt)

# Insert en summary -------------------------------------------------------

  dt.summary <- data.table(fakeAuthor = "pipo", 
                           fakeTitle = "El Coso",
                           nCapitulos = nrow(aver), 
                           author = autor,
                           title = titulo,
                           libroId = n.libro,
                           idioma = "ES" #<<<<<<<- cambiar
                           )
  con.libros.sum$insert(dt.summary)
    
# EXTRA : cambio de nombres -----------------------------------------------
  libros.sum
  
  dt.titulos <- readRDS("c:/Users/Milenko/Documents/Biblioteca de calibre/dt.titulos.RDS")
  libros.sum %>% names
  merged <- merge(libros.sum,
                  dt.titulos,
                  all.x = T,
                  by.x  = "title",
                  by.y  = "titulo") %>% as.data.table
  
  merged %>% names
  merged %>% class
  # merged[] %>% select(-image,-_created)  
  
  merged[isMusic==T]
  con.libros$find()
  

# update ------------------------------------------------------------------
  .simpleCap <- function(x) {
    s <- strsplit(x, " ")[[1]]
    paste(toupper(substring(s, 1,1)), substring(s, 2),
          sep="", collapse=" ")
  }
  (sample <- merged[66])
  query <- paste0('{"libroId" : ', sample$libroId,'}')
  
  
  # con.libros.sum$find(query)
  upd <- paste0('{"$set":{"fakeTitle" : "', sample$fake%>% .simpleCap(), 
                '" , "fakeAuthor" : "', sample$autor%>% .simpleCap(), '" }}')
  # cat(upd)
  
  con.libros.sum$update(query,
                        update = upd,
                        upsert = FALSE, 
                        multiple = FALSE)

# borramos ----------------------------------------------------------------
  
  id <- 111
  query.sum <- paste0('{"libroId" : ', id , '}')
  query.caps <- paste0('{"nLibro" : ', id , '}')
  con.libros.sum$remove(query.sum, multiple = FALSE)
  con.libros$remove(query.sum, multiple = TRUE)
  
# Selección libros --------------------------------------------------------
  aut <- function(x){
    ruta.partes <- strsplit(x, "(/| - |\\.epub)")[[1]] %>% rev
    return(ruta.partes[1])
  }
  tit <- function(x){
    ruta.partes <- strsplit(x, "(/| - |\\.epub)")[[1]] %>% rev
    return(ruta.partes[2])
  }

  path <- "e:/08 Libros/03 Lectura/"
  rutas <-
    list.files(path,
               pattern = "epub$",
               recursive = T) #5.688
  
  
  dt.biblioteca <- data.table(ruta = rutas)
  
  dt.biblioteca[, ':='(
    autor = lapply(.SD[, ruta], aut),
    titulo = lapply(.SD[, ruta], tit)
  )]
  
  dt.biblioteca[, leido := 0]
  
  dir.new <- "c:/bufLibros/"
  # dir.create("c:/bufLibros")

  # ruta <- rutas %>% sample(1)
  
  selected <- dt.biblioteca %>% sample_n(20)
  # selected <- dt.biblioteca[titulo == "Dracula"]
  dt.biblioteca[ruta %in% selected$ruta, leido:=1]
  # saveRDS(dt.biblioteca, "dt.biblioteca.RDS")
  dt.biblioteca <- readRDS( "datos/dt.biblioteca.RDS")
  
  
  dt.biblioteca[leido==1]
  # selected <- selected[-6]
  for (ruta in selected$ruta) {
    # dir.old <- paste0(path, dirname(ruta))
    dir.old <- paste0(path, ruta)
    file.copy(dir.old, dir.new, recursive = T)
  }
  
  # REPAIR ------------------------------------------------------------------

  # dt.fakes[listo==T] %>% select(-texto)
  # 
  # #veamos cuales tienen 816 y los borramos y ponemos en listo = F
  # libros.sum <- con.libros.sum$find() %>% as.data.table
  # ids.malos <- libros.sum[nCapitulos==861]$libroId
  # borra.libros(ids.malos)
  # 
  # dt.fakes[, listo:=F]
  # dt.fakes[titulo=="Cerebro", listo:=T]
  
# borrar ------------------------------------------------------------------

# dt.fakes <- readRDS("datos/20180327_22.RDS")
  # preparamos para poner el número de capitulos de cada uno de ellos.

  #  dt.summary <- data.table(fakeAuthor = "aa", 
  #                          fakeTitle = "aa",
  #                          nCapitulos = 999, 
  #                          author = "aa",
  #                          title = "aa",
  #                          libroId = 99,
  #                          idioma = "lang",
  #                          createdAt = Sys.time(),
  #                          updatedAt = Sys.time()
  #                          )
  # 
  # con.libros.sum$insert(dt.summary)
#   
#   #borramos los libros del sum
#   
#    q <- paste0('{"title" : {"$in" :["', lista(dt.fakes$titulo, T),'"]}}')
#    q <- paste0('{"title" : {"$in" :["', lista("aa", T),'"]}}')
#      cat(q)
#      a <- con.libros.sum$find(q)
#   
#   # Contamos los capitulos para cada uno de ellos:
#      ids <- a$libroId
#      id <- ids[1]
#      q <- paste0('{"nLibro" : {"$in" :[', id,']}}')
#      cat(q)
#     con.libros$count(q)
#      
#     ns <- lapply(ids, function(id){con.libros$count(paste0('{"nLibro" : {"$in" :[', id,']}}'))})
#     
#     dt.fakes$id <- NULL
#     
#     dt.rows <- data.table(libroId = ids, nCapitulosOk = unlist(ns))
#     
#     me <- merge(a, dt.rows) %>% as.data.table
#     me[, nCapitulos := nCapitulosOk]
#     
#     # write.csv(me %>% select(-nCapitulosOk),paste0("datos/Repair_nrows", ".csv"), row.names = F)
#     
# me %>% str
