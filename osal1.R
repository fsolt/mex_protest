### Download PDFs from OSAL and convert to plain text files
# Dependencies: pcregrep, tesseract (plus dictionaries), imagemagick, parallel, and xpdf
#   1. Install MacPorts <https://www.macports.org/install.php>
#   2. In terminal: sudo port install pcre
#   3. In terminal: sudo port install tesseract
#       a. sudo port install tesseract-spa
#       b. sudo port install tesseract-por
#   4. In terminal: sudo port install imagemagick


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
all.texts <- gsub(".*=([0-9]*)\\.pdf", "\\1.txt", all.pdfs) # Make list of names of text files for all PDFs

dir.create("../Texts", showWarnings = FALSE) # Make Texts directory (outside of Git), if it doesn't already exist
old.texts <- list.files("../Texts") # Get list of files in Texts directory
new.texts <- all.texts[!all.texts %in% old.texts] # Make list of names of text files without text files

# Extract text
lapply(new.texts, function(i){
  system(paste0("java -jar pdfbox-app-1.8.8.jar ExtractText \"../PDFs/descargar.php?link=", 
                gsub("txt", "pdf", i), "\" \"../Texts/", i,"\"")) 
})



### Identify files without extracted text and use OCR to make text files
# https://ryanfb.github.io/etc/2014/11/13/command_line_ocr_on_mac_os_x.html
system("cd \"../Texts/\"; for f in *.txt; do echo \"$f\"; pcregrep -c '�' $f; done > \"crud.txt\"") # Count garbage characters in each text file
crud <- data.frame(matrix(readLines("../Texts/crud.txt"), ncol=2, byrow=T), stringsAsFactors = F) # Read in the counts
crud$X2 <- as.numeric(crud$X2) # Reformat count variable as numeric rather than string
crud <- crud[crud$X2 > 4, ] # Files with more than four lines of garbage characters have problems and need OCR'd

dir.create("../Scanned_PDFs", showWarnings = FALSE) # Make Scanned_PDFs directory (outside of Git), if it doesn't already exist
dir.create("../Bad_Texts", showWarnings = FALSE) # Make Scanned_Texts directory (outside of Git), if it doesn't already exist

# Move problematic texts from Texts directory to Bad_Texts directory, 
# copy corresponding PDFs to Scanned_PDFs directory and then OCR them, 
# then move result to Texts
lapply(crud$X1, function(i){
  ii <- gsub("txt", "pdf", i)
  system(paste0("mv ../Texts/", i, " ../Bad_Texts; ",
                "cp ../PDFs/descargar.php?link=", ii, " ../Scanned_PDFs/", ii, "; ",
                "./ocr.sh ../Scanned_PDFs/", ii, "; ",
                "mv ", i, " ../Texts"))
})



### Clean up text files
# "/Users/fredsolt/Documents/Projects/Lat Am Protest 2/OSAL/OSAL2/osal_text_test.do"

