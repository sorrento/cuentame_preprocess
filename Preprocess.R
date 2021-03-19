
# TODO --------------------------------------------------------------------
  # Guardar diccionario en inglés
  # hacer retomable el proceso 

# LIBRERIAS -------------------------------------------------------------------

  library(data.table)
  library(dplyr)  

  source('utils.R')
  source('mongo_utils.R')

# CONFIGURACION ---------------------------------------------------------------
  
  th     <- 1200 # letras maximas por cápsula
  th.min <- 500 # letras minimas por cápsula
  lang   <- "ES" #"EN"
  Sys.setenv(R_CONFIG_ACTIVE = "trabajo")
  
# INIT --------------------------------------------------------------------

  config       <- config::get() 
  path.calibre <- config$ruta_calibre
  con          <- m.conectar(config$pass)
  dt.summaries <- data.table()
  i.id         <- 1
  
  mathematica.remove.covers()
  
  # Rutas de los txts de la fecha más reciente
    rutas <- seleccion.txts(path.calibre)

# BOOK SUMMARIES ------------------------------------------------------------

  dt.analisis <- get.fakes(rutas$path)
  quitar <- c() # ids de los libros que no queremos incorporar
  
  dt.fakes <- dt.analisis$fakes[!(i %in% quitar)]
  palabras <- dt.analisis$diccionario
  
  actualizar.diccionario(palabras)
  
  session.id <- dt.analisis$session.id
  saveRDS(dt.fakes %>% select(-texto),
          paste0("datos/", session.id, ".RDS"))
  

  rm(quitar, palabras, dt.analisis)
  
# BORRADO DE LIBROS ONLINE ------------------------------------------------
  
  # OPCIONAL <<<<<<<
    # m.show.books(con)
    # 
    # borrar <- c(195, 182, 152, 64, 62, 55, 34, 27) # ids
    # m.borra.libros(con, borrar)
    # 
    # rm(borrar)
  # OPCIONAL <<<<<<<
  
  ids.candidatos <- get.free.ids(con)
    
  if(!exists('dt.fakes')){
    print('**ERROR no está cargado del fichero de sumary (dt.fakes)')
  }
# AUTO DIVISION FULL----------------------------------------------------------------
  
  cat('\14')
  id.free <- ids.candidatos[i.id]
  
  # selección de libro
    print(paste("queda por procesar", dt.fakes[listo == F] %>% nrow))
    libro <- dt.fakes[listo == F] %>% sample_n(1)
    print(paste("vamos con:", libro$titulo, "| id_libro = ", id.free))

    dt.partes <- get.partes(libro)

# CABEZA Y COLA ------------------------------------------------------------------

  dt.partes[,.(id, preview)] %>% head(58) %>% as.data.frame
  dt.partes[,.(id, preview)] %>% tail(190) %>% as.data.frame
  
# AUTO CAPSULAS & INSERT --------------------------------------------------------------
  mini <- 78; maxi <- 2998 #es el id
  
  capsulas <- crea.capsulas(dt.partes[id >= mini & id <= maxi], id.free)
  # capsulas[,.(nCapitulo, letras, preview)]
  # capsulas[letras > 2000] %>% sample_n(1)
  
  dt <- capsulas %>% select(-preview, -letras, -grupo)
  
  con$texto$insert(dt)
  # EL RESUMEN SE GUARDA EN UN FICHERO, QUE LUEGO LEEMOS EN MATHEMATICA
  dt.summary <- data.table(fakeAuthor = libro$fake.autor,
                           fakeTitle  = libro$fake.titulo,
                           nCapitulos = nrow(capsulas),
                           author     = libro$autor,
                           title      = libro$titulo,
                           libroId    = id.free,
                           idioma     = lang
  )
  
  dt.summaries <- rbind(dt.summaries, dt.summary)
  
  dt.fakes[titulo == libro$titulo, listo := T]
  
  # la foto
    pic.name <- paste0(id.free, '_', str_standar(libro$titulo), '.jpg')
    file.copy(file.path('c:/', libro$path, 'cover.jpg'), 'MATHEMATICA')
    file.rename('MATHEMATICA/cover.jpg', paste0('MATHEMATICA/', pic.name))
  
  rm(pic.name, dt.summary, dt, capsulas, mini, maxi, libro, dt.partes) 
  
  i.id <- i.id + 1
  
# FINALLY, PARA SUMMARY MATHEMATICA ------------------------------------------------
  
  write.csv(dt.summaries[,.(libroId, fakeAuthor, fakeTitle, nCapitulos, author, title, idioma)], 
            paste0("MATHEMATICA/summaries.csv"), row.names = F)
  
# UPDATE BIBLIOTECA --------------------------------------------------------

  dt.biblio <- readRDS("datos/dt.biblioteca.RDS")
  # veamos si hacen match
  # algunos estan dos veces, otros no estan
  # (a <- dt.biblio[titulo %in% dt.fakes$titulo])
  dt.biblio[titulo %in% dt.fakes$titulo, leido := 1] # marcamos los duplicados
  
  # setdiff(dt.fakes$titulo, dt.biblio$titulo) # estos ha cambiado el nombre porqe tiene guion, pero ya estan marcaos
  
   saveRDS(dt.biblio, "datos/dt.biblioteca.RDS")
