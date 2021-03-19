# FUNCIONES -------------------------------------------------------------------------------------------------------
  
  get.parametros <- function(folder){
    p <- paste0('datos/mp3/', folder, '/')
    
    return(list(
      path      = p,
      files.txt = list.files(p, pattern = "txt", full.names = F),
      files.mp3 = list.files(p, pattern = "mp3", full.names = F)
    ))
  }
  
  genera.mp3s <- function(id){
    s0 <- paste0('cd ', file.path(getwd(),'datos/mp3 && '))
    s1 <- paste0('wav2mp3.exe ', id)
    conjuro <- paste0(s0, s1)  
    # cat(conjuro)
    
    shell(conjuro)
  }
  
  genera.resumen.chapters <- function(pars){
    require(tidytext)
    require(dplyr)

    
    dt.textos <- data.table()
    
    for(i in 1:length(pars$files.txt)){
      f <- pars$files.txt[i]
      
      full.path <- paste0(pars$path, f)
      print(full.path)
      txt <- readr::read_file(full.path)
      dt.textos <- rbind(dt.textos, data.table(id = i, titulo = f, texto = txt))
    }
    
    BUF <- dt.textos %>% unnest_tokens(word, texto) %>% as.data.table
    book_words <- BUF[, .(n = .N), .(word, titulo)]
    book_words[, total := .N, titulo]
    
    book_words <- book_words %>% bind_tf_idf(word, titulo, n) %>% as.data.table %>% setorder(titulo, -tf_idf)
    
    best <- book_words[, .SD[1:3], titulo]
    
    fakes.song.titles <- best[,.(fake.title = paste(word, collapse = " ") %>% primera.mayuscula), titulo]
    # fakes.song.titles[ , fake.title :=primera.mayuscula(()), id]//a mayúscula
    fakes.song.titles[, id := 1:.N]
    fakes.song.titles[, filename := stringr::str_replace(titulo, '\\.txt', '.mp3')]
    fakes.song.titles <- fakes.song.titles %>% tidyr::separate(titulo, c("from", "to", 'ext'), "_|\\.", remove = F)  
    fakes.song.titles[ , filename.ok := paste0(stringr::str_pad(id, 2, pad='0'), " ", fake.title, '.mp3')]
    fakes.song.titles[, fake.title := paste(id, fake.title)]
    
    file <- paste0(pars$path ,'/', 'summary.csv')
    print(paste('*****Writing ', file))
    fwrite(fakes.song.titles, file)
    
    return(fakes.song.titles)
  }
  
  concatena.mp3s <- function(fakes.song.titles, pars){
    path <- pars$path
    
    fakes.song.titles[, pipe := generate.piping(from, to, pars$files.mp3), titulo]
    # fakes.song.titles[, conjuro]
    dir.create(paste0(path, '/out'), showWarnings = F)
    
    for(i in 1:nrow(fakes.song.titles)){
      # i <- 1
      r <- fakes.song.titles[i]
      
      s00 <- paste0('cd ', path , ' && ')
      s0 <- 'c:\\ffmpeg\\bin\\ffmpeg -i '
      s1 <- r$pipe
      s2 <- ' -acodec copy '
      # s3 <- paste0('out/', r$filename)
      s3 <- paste0('\"out/', r$filename.ok, '\"')
      
      print(paste('++++++++++++++++++++++++++', s3))
      conjuro <- paste0(s00, s0, s1, s2, s3)  
      cat(conjuro)
      
      shell(conjuro)
    }
    
    
    # lo movemos a la carpeta out
    f <- paste0(path, '/summary.csv')
    file.copy(f, paste0(path, 'out/summary.csv'))
    file.remove(f)
  }
  
  primera.mayuscula <- function(c){
     paste(toupper(substring(c, 1,1)), substring(c, 2),sep="", collapse=" ")
  }

  generate.piping <- function(from, to, files.mp3){
    # from <- '0001';to <- '0011' ; files.mp3 = pars$files.mp3
    f <- as.numeric(from)
    t <- as.numeric(to)
    res <- paste0(
      '\"concat:',
      paste0(
        intersect(
          paste0(stringr::str_pad(seq(f,t-1, 1), 4, 'left', '0'), '.mp3'),
          files.mp3),
        collapse = '|'),
      '\"') 
    
    return(res)
  }