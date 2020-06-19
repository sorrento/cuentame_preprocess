# creación de mp3s

# TODO ------------------------------------------------------------------------------------------------------------
  # coger directamente desde la sd

# FLUJO -----------------------------------------------------------------------------------------------------------

  # Generar los wav en la app, apretando botón WAV. Se transcribe todo el libro actual a la sd en carpeta 
  # d:\Android\data\com.stupidpeople.dime\files\
  # Copiar en el pc en la carpeta datos/mp3, con la carpeta de su número de id
  # Con el script de python se editan los tags (proyecto Python test en Desktop)
  # Finalmente se les pone la imagen con la aplicación windows easytag
  
# MAIN -------------------------------------------------------------------------------------------------

  rm(list = ls())
  library(data.table)
  source('funciones_mp3.R')
  
  id <- '199' # id del libro
  
  pars <- get.parametros(id)
  genera.mp3s(id)
  resumen <- genera.resumen.chapters(pars)
  concatena.mp3s(resumen, pars)
  
  # borrado ficheros intermedios si todo salió ok
  # file.remove(list.files(pars$path, "txt|mp3", full.names = T))
  # file.remove(list.files(pars$path, "wav", full.names = T))