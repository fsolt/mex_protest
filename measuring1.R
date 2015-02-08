library(RTextTools)

d1 <- as.data.frame(readLines("../OSAL/OSAL4/Texts/descargar.php?link=1650.txt"))
colnames(d1) <- "text"
d1$line <- 1:dim(d1)[1]
d1 <- d1[d1$text!="",]

j1 <- read.csv("Jacob/Argentina - 2012 - Enero.csv")
colnames(j1) <- tolower(colnames(j1))
j1[is.na(j1$protest), "protest"] <- 0

data1 <- merge(j1, d1)

d2 <- as.data.frame(readLines("../OSAL/OSAL4/Texts/descargar.php?link=421.txt"))
colnames(d2) <- "text"
d2$line <- 1:dim(d2)[1]
d2 <- d2[d2$text!="",]

j2 <- read.csv("Jacob/Uruguay - 2004 - Enero a Abril.csv")
colnames(j2) <- tolower(colnames(j2))
j2[is.na(j2$protest), "protest"] <- 0

data2 <- merge(j2, d2)

data <- rbind(data1, data2)
days <- c("Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado")
data <- data[grep(paste0("^", paste(days,collapse="|"), " [0-9]{1,2}$"), data$text, ignore.case=T, invert=T), ]
months <- c("Enero", "Febrero", "Marzo", "Mayo", "Abril", "Junio", "Julio", "Agosto", "Septiembre", "Octobre", "Novembre", "Diciembre")
data <- data[grep(paste0("^",paste(months,collapse="|"), " (de [0-9]{4})?$"), data$text, ignore.case=T, invert=T), ]




coded <- c(116, 303, 352, 368, 421, 494, 603, 636, 711, 834, 864, 1141, 1239, 1292, 1361, 1650, 1772)

for (i in 1:length(coded)) {
  d <- as.data.frame(readLines(paste0("../OSAL/OSAL4/Texts/descargar.php?link=",coded[i],".txt")))
  colnames(d) <- "text"
  d$line <- 1:dim(d)[1]
  d <- d[d$text!="",]
  
  j <- read.csv(paste0("Jacob/",coded[i],".csv"))
  colnames(j) <- tolower(colnames(j))
  j[is.na(j)] <- 0 
  
  dat <- merge(j, d)
}








matrix <- create_matrix(cbind(data["text"]), language="spanish",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
container <- create_container(matrix,data$protest,trainSize=1:83, testSize=84:149,
                              virgin=FALSE)
models <- train_models(container, algorithms=c("SVM","SLDA","BOOSTING","BAGGING", "RF","GLMNET","TREE","MAXENT")) #Also NNET
#models <- train_models(container, algorithms=c("SVM","GLMNET","MAXENT"))
results <- classify_models(container, models)
analytics <- create_analytics(container, results)

summary(analytics)
