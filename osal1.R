# Download PDFs from OSAL and convert to plain text

url1 <- "http://www.clacso.org.ar/institucional/1h.php?idioma=" # Top page
p1 <- iconv(readLines(url1), "iso-8859-1", "UTF-8") # Read top page and convert encoding

lines <- grep("href=\\\".*link=.*\\\"", p1, value=T) # Identify lines with link stubs

all.docs <- gsub(pattern=".*href=\\\".*(link=[0-9]*\\.pdf).*", 
	replacement="http://www.clacso.org.ar/documentos_osal/descargar.php?\\1", x=lines) # Generate full links

dir.create("../PDFs", showWarnings = FALSE) # Make PDFs directory (outside of Git), if it doesn't already exist
old.docs <- paste0("http://www.clacso.org.ar/documentos_osal/", list.files("../PDFs")) # Get list of files in PDFs directory

new.docs <- all.docs[!all.docs %in% old.docs] # Make list of files available on website but not in PDFs directory
write(new.docs, file = "../PDFs/new_docs.txt", ncolumns = 1) # Write this list of new files to text file

system("cd \"../PDFs\"; wget -i new_docs.txt") # Download new files

