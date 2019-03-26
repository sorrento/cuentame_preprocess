
# REVISADAS ---------------------------------------------------------------

# Selecciona la ruta de todos los txt de a última fecha
  seleccion.txts <- function(path.calibre){
    txts <- list.files(path.calibre, pattern = "txt$", recursive = T, full.names = T)
    
    dt.files <- lapply(txts, file.info) %>% bind_rows %>% as.data.table
    dt.files[, ':='(path  = txts,
                    fecha = as.Date(mtime))]
    fechas <- dt.files$fecha %>% unique %>% sort(T)
    
    print(dt.files[, .N, fecha][order(-fecha)])
    
    res <- dt.files[fecha == fechas[1]]
    return(res)
  }
  
  # Dataset con los nombres falsos, rutas y textos completo. También devuelve el conteo de palabras
  get.fakes <- function(paths) {
    require(tidytext)
    # require(readr)
    
    libros <- data.table()
    for(ruta in paths){
      libros <- rbind(libros, get.libro.dt(ruta))
    }
    # libros %>% select(-texto)
    
    BUF <- libros %>% unnest_tokens(word, texto) %>% as.data.table
    book_words <- BUF[, .(n = .N), .(word, titulo)]
    book_words[, total := .N, titulo]
    
    book_words <- book_words %>%
      bind_tf_idf(word, titulo, n) %>% as.data.table %>% setorder(titulo, -tf_idf)
    
    best <- book_words[, .SD[1:70], titulo]
    
    # Ver si los 20 primeros salen alguna vez en minuscula
    best[, n.minus := stringi::stri_count(libros[titulo == titulom, texto],
                                          regex = paste0("\\W",word, "\\W")), 
         .(titulom = titulo)]
    best[, ratio := n.minus/n]
    nombres     <- best[ratio < 0.8]
    sustantivos <- best[ratio >= 0.8]
    
    dt.fakes <- merge(sustantivos[,.SD[1:6], titulo][, .(fake.titulo = simpleCap(paste(sample(.SD[, word], 3), collapse = " "))),
                                                     titulo],
                      nombres[,.SD[1:10], titulo][, .(fake.autor = simpleCap(paste(sample(.SD[, word], 2), collapse = " "))),
                                                  titulo], 
                      by = "titulo")
    dt.fakes <- merge(dt.fakes, libros[,.(titulo, autor, texto, path, listo = F)], by = "titulo")
    
    dt.fakes[, i:= 1:.N]
    dt.fakes %>% select(-texto) %>% print
    
    palabras <- book_words[, .(n.total = sum(n)), word][order(-n.total)]
    palabras[, r := rank(n.total) / nrow(palabras)]
    
     # resumen para las fotos en Mathematica
      file.nome <- paste0("datos/", as.character(Sys.Date(), "%Y%m%d"), "_", nrow(dt.fakes), ".csv")
      write.csv(libros %>% select(-texto),
                file.nome, 
                row.names = F)
      print(paste0('**Guardando fichero para Mathematica: ', file.nome))
    
    return(list(fakes = dt.fakes, diccionario = palabras))
  }
  
  # El guardado en fichero, palabras y ranking
   actualizar.diccionario <- function(palabras){
    
    dic <- readRDS('datos/diccionario.RDS')
    
    total <- merge(dic[, .(word, n.total.acc = n.total)],
                   palabras[, .(word, n.total.new = n.total)],
                   all = T, by = 'word',)
    total[is.na(total)] <- 0
    
    total <- total[, .(word, n.total = n.total.acc + n.total.new)][order(-n.total)][n.total > 2]
    total[, r := rank(n.total)/.N]
    
    # total[n.total == 3] %>% sample_n(10)
    
    saveRDS(total, 'datos/diccionario.RDS')
  }

# RESTO -------------------------------------------------------------------


get.libro.list <- function(ruta){
    # ruta <- rutas$path[3]
    ruta.partes <- strsplit(ruta, "(/|\\.txt)")[[1]] %>% rev
    path      <- paste0(rev(ruta.partes)[2:(length(ruta.partes)-1)], collapse = "/")
    autor     <- ruta.partes[3]
    titulo    <- stringi::stri_replace(ruta.partes[2], replacement = "", regex = " \\(\\d+\\)$")
    txt.total <- read_file(ruta)
    res <- list(titulo = titulo,
                autor  = autor,
                texto  = txt.total, 
                path   = path)
    return(res)
  }
  
  get.libro.dt <- function(ruta){
    return(get.libro.list(ruta) %>% as.data.table())
  }   #podemos incluir la opción de partir el texto          
  
  # poner en maysculas cada palabra
  simpleCap <- function(x) {
    s <- strsplit(x, " ")[[1]]
    paste(toupper(substring(s, 1, 1)),
          substring(s, 2),
          sep = "",
          collapse = " ")
  }

  crea.capsulas <- function(dt.partes) {
    dt.partes$grupo <- 0
    i <- 1
    while (nrow(dt.partes[grupo == 0]) > 0) {
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
      texto   = paste0(txt, collapse = "\r\n"),
      letras  = sum(letras),
      preview = .SD[1, preview],
      nLibro  = n.libro,
      autor   = libro$autor,
      titulo  = libro$titulo
    ), grupo][, nCapitulo := 1:.N]
    
    aver$letras %>% hist(breaks = 30, main = libro$titulo)
    aver$letras %>% summary %>% print
    
    return(aver)
  }