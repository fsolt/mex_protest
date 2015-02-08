# Set working directory and log file
setwd("/Users/fredsolt/Documents/Projects/Data/Protest/OSAL")

library(XML)

# Load top page
url1 <- ("http://www.clacso.org.ar/institucional/1h.php?idioma=")
p1 <- readLines(url1)
p2 <- iconv(x, "latin1", "UTF-8")

lines <- grep("href=\\\".*link=.*\\\"", p2, value=T)
docs <- gsub(pattern=".*href=\\\".*(link=[0-9]*\\.pdf).*", 
	replacement="http://www.clacso.org.ar/documentos_osal/descargar.php?\\1", x=lines)

write(docs, file = "PDFs/osal.txt", ncolumns = 1)
system("cd \"/Users/fredsolt/Documents/Projects/Data/Protest/OSAL/PDFs\";
		wget -i osal.txt")