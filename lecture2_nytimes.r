###################################################
# Loren Collingwood, University of Washington	  #
# UNC -- RTextTools workshop					  #
# Lecture 2 						  		      #
# Very Basic New York Times Example			      #
# Updated with info from (new) documentation      #
###################################################

# LOAD THE RTextTools LIBRARY
#install.packags("RTextTools") #Needs to be R-2.14.1 or greater
library(RTextTools)

#CHANGE WORKING DIRECTORY TO YOUR WORKING DIRECTORY
#setwd("/Users/lorencollingwood/Documents/consulting/rtexttools/unc_workshop")

# READ THE CSV DATA from the RTextTools package
data <- read_data(system.file("data/NYTimes.csv.gz",package="RTextTools"),type="csv",sep=";")


# [OPTIONAL] SUBSET YOUR DATA TO GET A RANDOM SAMPLE
data <- data[sample(1:3100,size=3000,replace=FALSE),]

#Examine the data
class(data) #make sure it is a data frame object
head(data) # Look at the first six lines or so
summary(data) #summarize the data
sapply(data, class) #look at the class of each column
dim(data) #Check the dimensions, rows and columns

# CREATE A TERM-DOCUMENT MATRIX THAT REPRESENTS WORD FREQUENCIES IN EACH DOCUMENT
# WE WILL TRAIN ON THE Title and Subject COLUMNS
matrix <- create_matrix(cbind(data["Title"],data["Subject"]), language="english", 
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
matrix # Sparse Matrix object

########################################
# 	  CORPUS AND CONTAINER CREATION	   #
########################################

# CREATE A CORPUS THAT IS SPLIT INTO A TRAINING SET AND A TESTING SET
# WE WILL BE USING Topic.Code AS THE CODE COLUMN. WE DEFINE A 2000 
# ARTICLE TRAINING SET AND A 1000 ARTICLE TESTING SET.
container <- create_container(matrix,data$Topic.Code,trainSize=1:2600, testSize=2601:3000,
                              virgin=FALSE)

# Quick look at Document Term Matrix
example_mat <- container@training_matrix
example_names <- container@column_names
example_mat2 <- as.matrix(example_mat)
colnames(example_mat2) <- example_names
example_mat2[1:10,1:10]
example_mat2[1:10, 3050:3065]

##########################################
#			   TRAIN MODELS				 #
##########################################
# THERE ARE TWO METHODS OF TRAINING AND CLASSIFYING DATA.
# ONE WAY IS TO DO THEM AS A BATCH (SEVERAL ALGORITHMS AT ONCE)
models <- train_models(container, algorithms=c("MAXENT","SVM"))

##########################################
# 			  CLASSIFY MODELS		     #
##########################################

results <- classify_models(container, models)

##########################################
# VIEW THE RESULTS BY CREATING ANALYTICS #
##########################################
analytics <- create_analytics(container, results)

# RESULTS WILL BE REPORTED BACK IN THE analytics VARIABLE.
# analytics@algorithm_summary: SUMMARY OF PRECISION, RECALL, F-SCORES, AND ACCURACY SORTED BY TOPIC CODE FOR EACH ALGORITHM
# analytics@label_summary: SUMMARY OF LABEL (e.g. TOPIC) ACCURACY
# analytics@document_summary: RAW SUMMARY OF ALL DATA AND SCORING
# analytics@ensemble_summary: SUMMARY OF ENSEMBLE PRECISION/COVERAGE. USES THE n VARIABLE PASSED INTO create_analytics()

# head(analytics@algorithm_summary)
# head(analytics@label_summary)
# head(analytics@document_summary)
# analytics@ensemble_summary

summary(analytics)

# WRITE OUT THE DATA TO A CSV --- look in your working directory
write.csv(analytics@algorithm_summary,"SampleData_AlgorithmSummary.csv")
write.csv(analytics@label_summary,"SampleData_LabelSummary.csv")
write.csv(analytics@document_summary,"SampleData_DocumentSummary.csv")
write.csv(analytics@ensemble_summary,"SampleData_EnsembleSummary.csv")

#Clear all the objects to restore memory settings
rm( list=ls() )