# Creación de mp3s de libros, en cápsulas de unos 15 mins, con nombres significativos obtenidos de tf-idf

# TODO ------------------------------------------------------------------------------------------------------------
  # Coger directamente los wav desde la sd

# MAIN -------------------------------------------------------------------------------------------------

  rm(list = ls())
  library(data.table)
  source('funciones_mp3.R')
  source('mongo_utils.R')

  config <- config::get() 
  con    <- m.conectar(config$pass)
  sumario <- as.data.table(con$summary$find())
  
  #todo mirar qué carpertas hay en datos y hacer un For
  id <- '17' # id del libro
  
  pars <- get.parametros(id)
  path_out <- paste0(pars$path, 'out/')
  res <- sumario[libroId == id, .(libroId,title, author, fakeTitle, fakeAuthor, idioma)]
  print(paste('** Procesando', res$title))
  
  genera.mp3s(id) # convierte desde los wavs
  resumen <- genera.resumen.chapters(pars) # tf-idf para cada gnuevo chapter (10 cápsulas)
  pars <- get.parametros(id)
  concatena.mp3s(resumen, pars) # une de 10 en 10 los mp3s
  fwrite(res, paste0(path_out, 'resumen_libro.csv'),sep = ';')
  
  files <- list.files(path_out)
  print(paste('**Se han guardado ',length(files), 'archivos en la carpeta out'))
  
  # borrado ficheros intermedios si todo salió ok
  file.remove(list.files(pars$path, "txt|mp3", full.names = T))
  file.remove(list.files(pars$path, "wav", full.names = T))
  
  
  