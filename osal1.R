### Download PDFs from OSAL
# Dependencies: tesseract (plus dictionaries), imagemagick, and pcregrep
#   1. Install MacPorts <https://www.macports.org/install.php>
#   2. In terminal: sudo port install tesseract
#       a. sudo port install tesseract-por
#       b. sudo port install tesseract-spa
#   3. In terminal: sudo port install imagemagick
#   4. In terminal: sudo port install pcre

url1 <- "http://www.clacso.org.ar/institucional/1h.php?idioma=" # Top page
p1 <- iconv(readLines(url1), "iso-8859-1", "UTF-8") # Read top page and convert encoding

lines <- grep("href=\\\".*link=.*\\\"", p1, value=T) # Identify lines with link stubs

all.links <- gsub(pattern=".*href=\\\".*(link=[0-9]*\\.pdf).*", 
	replacement="http://www.clacso.org.ar/documentos_osal/descargar.php?\\1", x=lines) # Generate full links

dir.create("../PDFs", showWarnings = FALSE) # Make PDFs directory (outside of Git), if it doesn't already exist
all.pdfs <- list.files("../PDFs") # Get list of files in PDFs directory
old.links <- paste0("http://www.clacso.org.ar/documentos_osal/", all.pdfs) # Generate list of links for PDFs in PDFs directory

new.pdfs <- all.links[!all.links %in% old.links] # Make list of links to files available on website but not in PDFs directory
write(new.pdfs, file = "../PDFs/new_pdfs.txt", ncolumns = 1) # Write this list of new files to text file

system("cd \"../PDFs\"; wget -i new_pdfs.txt; rm new_pdfs.txt") # Download new files


### Extract text from PDFs and save (doesn't work for all files; some were scanned)
all.texts <- gsub(".*=([0-9]*)\\.pdf", "\\1.txt", all.pdfs)

dir.create("../Texts", showWarnings = FALSE) # Make Texts directory (outside of Git), if it doesn't already exist
old.texts <- list.files("../Texts") # Get list of files in Texts directory
new.texts <- all.texts[!all.texts %in% old.texts]

lapply(new.texts, function(i){
  system(paste0("java -jar pdfbox-app-1.8.8.jar ExtractText \"../PDFs/descargar.php?link=", 
                gsub("txt", "pdf", i), "\" \"../Texts/", i,"\"")) 
})



### Identify files without extracted text and use OCR to get text files
# https://ryanfb.github.io/etc/2014/11/13/command_line_ocr_on_mac_os_x.html
system("cd \"../Texts/\"; for f in *.txt; do echo \"$f\"; pcregrep -c '�' $f; done > \"crud.txt\"")
crud <- data.frame(matrix(readLines("../Texts/crud.txt"), ncol=2, byrow=T), stringsAsFactors = F) 
crud[,2] <- as.numeric(crud[,2])
crud <- crud[crud$X2 > 4, ]



### Clean up text files
# "/Users/fredsolt/Documents/Projects/Lat Am Protest 2/OSAL/OSAL2/osal_text_test.do"

