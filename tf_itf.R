# Librerias y funciones ---------------------------------------------------


  library(data.table)
  library(dplyr)
  # library(janeaustenr)
    library(tidytext)
    library(readr)
# extra -------------------------------------------------------------------
pos <- gregexpr('biólogo', txt)  
pos[4] 
posi <- pos[[1]][1]

keep = substr(txt, posi-20, posi+30)
saca <- function(posi){
  return(substr(txt, posi-20, posi+30))
}
a <- lapply(pos[[1]],saca)

# leemos mis libros: ------------------------------------------------------
  
  setwd("c:/Users/Milenko/Documents/Biblioteca de calibre/")
  files <- list.files(recursive = T, pattern = "*.txt")
  files.sample <- files %>% sample(3)
  # files.sample <- files[51:59]
  # files.sample <- files.sample[-10]#en ingles
  
  libros <- data.table()
  for(ruta in files.sample){
    libros <- rbind(libros,
                    get.libro.dt(ruta))
  }
  
  # libros %>% select(-texto)



  book_words <- libros %>% unnest_tokens(word, texto) %>%
    count(titulo, word, sort = TRUE) %>%
    ungroup()
  
  total_words <- book_words %>%
    group_by(titulo) %>%
    summarize(total = sum(n))
  
  book_words <- left_join(book_words, total_words)
  
  # freq_by_rank <- book_words %>% 
  #   group_by(titulo) %>% 
  #   mutate(rank = row_number(), 
  #          `term frequency` = n/total)
  
  book_words <- book_words %>%
    bind_tf_idf(word, titulo, n) %>% as.data.table() %>% setorder(titulo,-tf_idf)
  best <- book_words[, .SD[1:70], titulo]
  
  # mejor es ver si los 20 primeros salen alguna vez en minuscula
  best[,
       n.minus := stringi::stri_count(libros[titulo == titulom, texto],
                                      regex = word), 
       .(titulom = titulo)]
  nombres <- best[n.minus == 0]
  sustantivos <- best[n.minus > 5]
  
   nombres.acc <- nombres
   sustantivos.acc <- sustantivos
  nombres.acc <- rbind(nombres.acc,nombres)
  sustantivos.acc <- rbind(sustantivos.acc,sustantivos)
  
  # saveRDS(nombres.acc,"nombres.acc.RDS")
  # saveRDS(sustantivos.acc,"sustantivos.acc.RDS")
  
  a <- sustantivos[, .(lista = list(word)), titulo]
  
a[1,lista]
sueltas  <- sustantivos[32:38,word]
buf <- c()
for(i in 1:10){
  buf <- c(buf,sueltas %>% sample(3) %>% paste(collapse=" "))
}
buf <- buf %>% unique
  
  # lapply(sueltas,function(x){sample(x,3) %>% paste(collapse=" ")})
  # lapply(rep(sueltas,10),function(x){sample(x,3) %>% paste(collapse=" ")})
  # 
  # 
  # replicate(n = 3, function(x){sample(x,3) %>% paste(collapse=" ")},sueltas)  

# Nombres asignados -------------------------------------------------------

  nombres.acc <- readRDS("nombres.acc.RDS")
  sustantivos.acc <- readRDS("sustantivos.acc.RDS")
  
  nombres <- nombres.acc$titulo %>% unique()
  
  j <- 56
  (nom <- nombres[j])
  sueltas.nom <- nombres.acc[titulo == nom, word]
  sueltas <- sustantivos.acc[titulo == nom, word]
  # sustantivos.acc[titulo == nom]
  # sueltas <- sustantivos.acc[titulo == nom & n.minus>60, word]
  if(length(sueltas)>10){sueltas <- sueltas[1:10]}
  (candidatos <- data.table(titulo = nom,
                           fake = replicate(n = 6,
                                            sample(sueltas, 3) %>% paste(collapse = " ")),
                           autor = replicate(n = 6,
                                              sample(sueltas.nom[1:10], 2) %>% paste(collapse = " ")))
  )
  i <- 3
  sel <- rep(i, 2)
  # sel <- c(3,1)
  selected <- candidatos[sel[1]]
  selected$autor <- candidatos[sel[2],autor]
  
  # dt.titulos <- data.table()
  dt.titulos <- rbind(dt.titulos, selected)
  # saveRDS(dt.titulos, "dt.titulos.RDS")
  # falta el quijote, 1940, el viaje del  ELEFANDE, EL hombre que vendio la luna
  #   fundacino 2, recuerdos, un caso de urgencia
  dt.titulos[order(titulo)]
  
# demas -------------------------------------------------------------------

austen_books() %>% sample_n(10) %>% unnest_tokens(word, text) 
libros  %>% unnest_tokens(word, texto) 
book_words <- austen_books() %>%
  unnest_tokens(word, text) %>%
  count(book, word, sort = TRUE) %>%
  ungroup()

total_words <- book_words %>% 
  group_by(book) %>% 
  summarize(total = sum(n))

book_words <- left_join(book_words, total_words)

book_words

freq_by_rank <- book_words %>% 
  group_by(book) %>% 
  mutate(rank = row_number(), 
         `term frequency` = n/total)

freq_by_rank

book_words <- book_words %>%
  bind_tf_idf(word, book, n)
book_words %>% sample_n(10)
library(data.table)
book_words <- book_words %>% as.data.table()
book_words %>% setorder(book, -tf_idf)
best <- book_words[, .SD[1:10], .(book) ]


# detección de nombres ----------------------------------------------------
# libros <- austen_books() %>% as.data.table
texto1 <- libros[2, texto]

# a <- grep("[A-Z]\\w+",texto1, value = T)
#  grep("Emma",texto1, value = T)

nomes <- stringr::str_extract_all(texto1, "[A-Z]\\w+") %>% unique %>% unlist%>% stringi::stri_trans_tolower()
# nomes <- stringr::str_extract_all(texto1, "[A-Z]\\S+",) %>% unique %>% unlist%>% stringi::stri_trans_tolower()

book_words[book=="Emma"][!(word %in% nomes)][1:20]



# Canciones ---------------------------------------------------------------
# canciones$
libros <- canciones[,.(book=autor,texto)]

# austen_books() %>% sample_n(10) %>% unnest_tokens(word, text) 
libros %>% unnest_tokens(word, texto) 
# book_words <- austen_books() %>%
book_words <- libros %>%
  unnest_tokens(word, texto) %>%
  count(book, word, sort = TRUE) %>%
  ungroup()

total_words <- book_words %>% 
  group_by(book) %>% 
  summarize(total = sum(n))

book_words <- left_join(book_words, total_words)

book_words

freq_by_rank <- book_words %>% 
  group_by(book) %>% 
  mutate(rank = row_number(), 
         `term frequency` = n/total)

freq_by_rank

book_words <- book_words %>%
  bind_tf_idf(word, book, n)
book_words %>% sample_n(10)
library(data.table)
book_words <- book_words %>% as.data.table()
book_words %>% setorder(book, -tf_idf)
best <- book_words[, .SD[1:10], .(book) ]
