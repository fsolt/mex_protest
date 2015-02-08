library(RTextTools)

d1 <- as.data.frame(readLines("../OSAL/OSAL4/Texts/descargar.php?link=1650.txt"))
colnames(d1) <- "text"
d1$line <- 1:dim(d1)[1]

j1 <- read.csv("Jacob/Argentina - 2012 - Enero.csv")
colnames(j1) <- tolower(colnames(j1))
j1[is.na(j1$protest), "protest"] <- 0

data <- merge(j1, d1)
data <- data[data$text!="",]




matrix <- create_matrix(cbind(data["text"]), language="spanish",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
container <- create_container(matrix,data$protest,trainSize=1:75, testSize=76:107,
                              virgin=FALSE)
models <- train_models(container, algorithms=c("MAXENT","SVM", "GLMNET"))
results <- classify_models(container, models)
analytics <- create_analytics(container, results)

summary(analytics)
