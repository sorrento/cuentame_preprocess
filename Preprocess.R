
# TODO --------------------------------------------------------------------
  # fichero de config con las constraseñas y similares
  # GUardar diccionario en inglés
  # empaquetar las imagenes para Mathematica

# LIBRERIAS -------------------------------------------------------------------

  library(data.table)
  library(dplyr)  

  source('utils.R')
  source('mongo_utils.R')

# CONFIGURACION ---------------------------------------------------------------
  
  th     <- 1200 # letras maximas por cápsula
  th.min <- 500 # letras minimas por cápsula
  lang   <- "ES" #"EN"
  
  # path.calibre <- 'c:/Users/Milenko/Documents/Biblioteca de calibre/'
  path.calibre <- 'c:/Users/halatm//Documents/Biblioteca de calibre/'
  
# INIT --------------------------------------------------------------------

  con <- m.conectar()
  
  # i.id <- 1 # qué id libre vamos a usar
  # dt.summaries <- data.table()

  # Rutas de los txts de la fecha más reciente
    rutas <- seleccion.txts(path.calibre)

# BOOK SUMMARY ------------------------------------------------------------

  dt.analisis <- get.fakes(rutas$path)

  quitar <- c(6, 14, 15) # ids de los libros que no queremos incorporar
  
  dt.fakes <- dt.analisis$fakes[!(i %in% quitar)]
  palabras <- dt.analisis$diccionario
  
  # actualizamos el fichero de diccionario
    actualizar.diccionario(palabras)
  
  # fecha_número de libros
  session.id <- paste0(as.character(Sys.Date(), "%Y%m%d"), "_", nrow(dt.fakes))
   # saveRDS(dt.fakes %>% select(-texto), 
           # paste0("datos/", session.id, ".RDS"))
    
# AUTO DIVISION FULL----------------------------------------------------------------
  
  # id para subir
    cat("\14")
    libros.sum <-  con.libros.sum$find() %>% as.data.table
    ids.subidos <- libros.sum[!is.na(libroId), libroId] %>% sort
    (ids.candidatos <- setdiff(seq(min(ids.subidos), max(ids.subidos) + 31), ids.subidos))
    n.libro <- ids.candidatos[i.id]

  # selección de libro
    print(paste("queda por procesar", dt.fakes[listo == F] %>% nrow))
    libro <- dt.fakes[listo == F] %>% sample_n(1)
     # libro <- dt.fakes[autor=="George R. R. Martin"]
    print(paste("vamos con:", libro$titulo, "| id_libro = ", n.libro))

  dt.partes <- data.table(txt = strsplit(stringr::str_replace_all(libro$texto, "\t", ""),
                                         "\r\n")[[1]])
  # dt.partes <- data.table(txt = strsplit(libro$texto, "\r\n")[[1]])
  dt.partes[, ':='(letras = stringi::stri_length(txt),
                   preview = strtrim(txt, 100),
                   id = 1:.N)]
  dt.partes <- dt.partes[letras > 0]
  
# CABEZA Y COLA ------------------------------------------------------------------

  dt.partes[,.(id, preview)] %>% head(71) %>% as.data.frame
  dt.partes[,.(id, preview)] %>% tail(55) %>% as.data.frame
  
# AUTO CAPSULAS & INSERT --------------------------------------------------------------
  
  mini <- 7; maxi <- 1168 #es el id
  
  capsulas <- crea.capsulas(dt.partes[id >= mini & id <= maxi])
  # capsulas[,.(nCapitulo, letras, preview)]
  # capsulas[letras >2000] %>% sample_n(1)
  
  dt <- capsulas %>% select(-preview,-letras,-grupo)
  
  con.libros$insert(dt)
  # ESTO HACERLO EN MATHEMATICA PARA PODER INCLUIR LA FOTO
  dt.summary <- data.table(fakeAuthor = libro$fake.autor,
                           fakeTitle  = libro$fake.titulo,
                           nCapitulos = nrow(capsulas),
                           author     = libro$autor,
                           title      = libro$titulo,
                           libroId    = n.libro,
                           idioma     = lang
  )
  
  dt.summaries <- rbind(dt.summaries, dt.summary)
  
  # con.libros.sum$insert(dt.summary)

  dt.fakes[titulo == libro$titulo, listo := T] #<<<<<<agregar el id asignado a cada libro
  i.id <- i.id + 1

# PARA SUMMARY MATHEMATICA ------------------------------------------------
  
  write.csv(dt.summaries[,.(libroId, fakeAuthor, fakeTitle, nCapitulos, author, title, idioma)], 
            paste0("datos/summaries_" ,".csv"), row.names = F)
  
# UPDATE BIBLITECA --------------------------------------------------------

  dt.biblio <- readRDS("datos/dt.biblioteca.RDS")
  # veamos si hacen match
  # algunos estan dos veces, otros no estan
  (a <- dt.biblio[titulo %in% dt.fakes$titulo])
  dt.biblio[titulo %in% dt.fakes$titulo, leido := 1] # marcamos los duplicados
  
  setdiff(dt.fakes$titulo, dt.biblio$titulo) # estos ha cambiado el nombre porqe tiene guion, pero ya estan marcaos
  dt.fakes %>% select(-texto)
  
  # saveRDS(dt.biblio, "datos/dt.biblioteca.RDS")
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
