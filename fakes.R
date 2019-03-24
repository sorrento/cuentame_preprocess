# LIBRERIAS -------------------------------------------------------------------
  library(data.table)
  library(dplyr)  
  library(tidytext)
  library(readr)

# FUNCIONES ---------------------------------------------------------------
  
  th <- 1200 # letras maximas por seccion
  th.min <- 500
  
  get.libro.list <- function(ruta){
    # ruta <- rutas$path[3]
    ruta.partes <- strsplit(ruta, "(/|\\.txt)")[[1]] %>% rev
    path      <- paste0(rev(ruta.partes)[2:(length(ruta.partes)-1)], collapse = "/")
    autor     <- ruta.partes[3]
    titulo    <- stringi::stri_replace(ruta.partes[2], replacement = "", regex = " \\(\\d+\\)$")
    txt.total <- read_file(ruta)
    res <- list(titulo = titulo,
                autor = autor,
                texto = txt.total, 
                path = path)
    return(res)
  }
  
  get.libro.dt <- function(ruta){
    return(get.libro.list(ruta) %>% as.data.table())
  }   #podemos incluir la opción de partir el texto          
  
  # poner en maysculas cada palabra
  simpleCap <- function(x) {
    s <- strsplit(x, " ")[[1]]
    paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
  }

    crea.capsulas <- function(dt.partes){
    dt.partes$grupo <- 0
    i <- 1
    while (nrow(dt.partes[grupo == 0]) > 0){
      print(i)
      if(dt.partes[grupo == 0][1, letras] >= th) {
        idm <- dt.partes[grupo == 0][1, id]
        print(paste("uno Largo", dt.partes[grupo == 0][1, letras], "id=", idm ))
        dt.partes[id==idm, grupo := i]
        
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
      autor = libro$autor,
      titulo = libro$titulo
    ), grupo][, nCapitulo := 1:.N]

    aver$letras %>% hist(breaks=30, main = libro$titulo)
    aver$letras %>% summary %>% print
    
    return(aver)
  }


# INIT --------------------------------------------------------------------

  i.id <- 1 # qué id libre vamos a usar
  dt.summaries <- data.table()
  
# SELECCION DE LIBROS -----------------------------------------------------
  setwd("c:/Users/Milenko/Documents/Biblioteca de calibre/")

  txts <- list.files(".", pattern = "txt$", recursive = T, full.names = T)
  
  dt.files <- lapply(txts, file.info) %>% bind_rows %>% as.data.table
  dt.files[, ':='(path = txts,
                  fecha = as.Date(ctime))]
  (fechas <- dt.files$fecha %>% unique %>% sort(T))
  
  rutas <- dt.files[fecha == fechas[1]]# |
                      # path == "./Andy Weir/Artemis (93)/Artemis - Andy Weir.txt"]

# FAKES -----------------------------------------------------------------

  # para 20 libros lo hace en un tiempo razonable, 
  libros <- data.table()
  for(ruta in rutas$path){
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
  nombres <- best[ratio < 0.8]
  sustantivos <- best[ratio >= 0.8]

  dt.fakes <- merge(sustantivos[,.SD[1:6], titulo][, .(fake.titulo = simpleCap(paste(sample(.SD[, word], 3), collapse = " "))),
                                                   titulo],
                    nombres[,.SD[1:10], titulo][, .(fake.autor = simpleCap(paste(sample(.SD[, word], 2), collapse = " "))),
                                                titulo], 
                    by = "titulo")
  dt.fakes <- merge(dt.fakes, libros[,.(titulo, autor, texto, path, listo = F)], by = "titulo")

  # dt.fakes %>% select(-texto)
  
  lang <- "ES" #"EN"
  setwd("c:/Users/Milenko/Proyectos/Cuentame/")
  
   # saveRDS(dt.fakes %>% select(-texto), paste0("datos/", as.character(Sys.Date(), "%Y%m%d"), "_", nrow(dt.fakes), ".RDS"))
  
  #resumen  para las fotos en mathematica
  (file.nome <- paste0("datos/", as.character(Sys.Date(), "%Y%m%d"), "_", nrow(dt.fakes), ".csv"))
  write.csv(libros %>% select(-texto),
            file.nome, 
            row.names = F)
  

# DICCIONARIO -------------------------------------------------------------

palabras <- book_words[,.(n.total=sum(n)),word][order(-n.total)]
palabras[,r:=rank(n.total)/nrow(palabras)]
# saveRDS(palabras,"datos/diccionario.RDS")
# CONECTAR ----------------------------------------------------------------
  library(mongolite)
  library(readr)

  url.cuentame <- "mongodb://mhalat:spidey@ds135798.mlab.com:35798/cuentame"
  con.libros <- mongo(collection = "libros", url = url.cuentame)
  con.libros.sum <- mongo(collection = "librosSum",url = url.cuentame)
  
  con.libros.sum$count()
  # con.libros$count()

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
  
# CABEZA Y COLA -----------------------------------------------------------

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
                           fakeTitle = libro$fake.titulo,
                           nCapitulos = nrow(capsulas),
                           author = libro$autor,
                           title = libro$titulo,
                           libroId = n.libro,
                           idioma = lang
  )
  
  dt.summaries <- rbind(dt.summaries, dt.summary)
  
  # con.libros.sum$insert(dt.summary)

  dt.fakes[titulo == libro$titulo, listo := T]#<<<<<<agregar el id asignado a cada libro
  i.id <- i.id + 1

# PARA SUMMARY MATHEMATICA ------------------------------------------------
  write.csv(dt.summaries[,.(libroId, fakeAuthor, fakeTitle, nCapitulos, author, title, idioma)], 
            paste0("datos/summaries_" ,".csv"), row.names = F)
# UPDATE BIBLITECA--------------------------------
  dt.biblio <- readRDS("datos/dt.biblioteca.RDS")
  # veamos si hacen match
  #algunos estan dos veces, otros no estan
  (a <- dt.biblio[titulo %in% dt.fakes$titulo])
  dt.biblio[titulo %in% dt.fakes$titulo, leido := 1] #marcamos los duplicados
  
  setdiff(dt.fakes$titulo, dt.biblio$titulo) #estos ha cambiado el bnombre porqe tiene guion, pero ya estan marcaos
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
