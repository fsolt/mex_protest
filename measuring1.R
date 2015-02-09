library(RTextTools)
library(beepr)

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
  if (i==1) data <- dat else data <- rbind(data, dat)
}

days <- c("Domingo", "Lunes", "Martes", "Miércoles", "Miercoles", "Jueves", "Viernes", "Sábado", "Sabado")
data <- data[grep(paste0("^", paste(days,collapse="|"), " [0-9]{1,2}$"), data$text, ignore.case=T, invert=T), ]
months <- c("Enero", "Febrero", "Marzo", "Mayo", "Abril", "Junio", "Julio", "Agosto", "Septiembre", "Octobre", "Novembre", "Diciembre")
data <- data[grep(paste0("^",paste(months,collapse="|"), " (de [0-9]{4})?$"), data$text, ignore.case=T, invert=T), ]

matrix <- create_matrix(cbind(data["text"]), language="spanish",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
container1 <- create_container(matrix,data$protest,trainSize=1:517, testSize=518:646, virgin=FALSE)
models1 <- train_models(container1, algorithms=c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")) #Also NNET
#models1 <- train_models(container1, algorithms=c("SVM","GLMNET","MAXENT"))
results1 <- classify_models(container1, models1)
analytics1 <- create_analytics(container1, results1)

summary(analytics1)
beep()


algos <- c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")
cross.val <- list()
for (i in seq(length(algos))) {
  cross.val[i] <- cross_validate(container1, 3, algos[i])
}
