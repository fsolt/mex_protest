# Convert Jacob's files to new line numbers

coded <- c(116, 303, 352, 368, 421, 494, 603, 636, 711, 834, 864, 1141, 1239, 1292, 1361, 1650, 1772)

for (i in 1:length(coded)) {
  d <- as.data.frame(readLines(paste0("../OSAL/OSAL4/Texts/descargar.php?link=",coded[i],".txt")), stringsAsFactors = F)
  colnames(d) <- "text"
  d$line <- 1:dim(d)[1]
  d <- d[d$text!="", ]
  d$text <- gsub("(^\\s*)", "", d$text)
  
  j <- read.csv(paste0("Jacob/",coded[i],".csv"))
  colnames(j) <- tolower(colnames(j))
  j[is.na(j)] <- 0 
  
  dat <- merge(j, d)
  
  dat$first_text0 <- substr(dat$text, 1, 150)
 
  t <- as.data.frame(readLines(paste0("../Clean_Texts/",coded[i],".txt")), stringsAsFactors = F)
  colnames(t) <- "text"
  t$new_line <- 1:dim(t)[1]  
  t <- t[t$text!="", ]
  t$text <- gsub("(^[[:space:]]+)", "", t$text)
  t$first_text <- substr(t$text, 1, 150)

  days <- c("Domingo", "Lunes", "Martes", "Miércoles", "Miercoles", "Jueves", "Viernes", "Sábado", "Sabado")
  dat <- dat[grep(paste0("^", paste(days,collapse="|"), " [0-9]{1,2}$"), dat$text, ignore.case=T, invert=T), ]

  dat$first_text <- lapply(dat$first_text0, function (ii) agrep(ii, t$first_text, value=T))
  dat$first_text <- unlist(lapply(dat$first_text, function(ii) ii[1]))

  dat2 <- merge(dat, t, by="first_text")

  dat2$text <- dat2$text.y
  dat3 <- dat2[order(dat2$new_line), c(20, 3:16, 21)]
   
  write.csv(dat3, file=paste0("Training/", coded[i], ".csv"))
}