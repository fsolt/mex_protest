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

meta <- gsub('.*link=([0-9]{1,4})\\.pdf&nombre=(.*[0-9]{4})\\\".*', "\\1 \\2", lines)
meta <- gsub("Cronolol?g[ií]as? ", "", meta) %>% data.frame(all = ., stringsAsFactors=F)
meta$file <- gsub("^([0-9]{1,4}).*", "\\1", meta$all) %>% as.numeric
meta <- arrange(meta, file)

countries <- c("Argentina", "Bolivia", "Brasil", "Chile", "Colombia", "Costa Rica", "Ecuador", 
               "El Salvador", "Guatemala", "Honduras", "México", "Mexico", "Nicaragua", "Panamá",
               "Panama", "Paraguay", "Perú", "Peru", "Puerto Rico", "República Dominicana",
               "Republica Dominicana", "Uruguay", "Venezuela")
months <- c("Enero", "Febrero", "Marzo", "Mayo", "Abril", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")

meta$country <- gsub(paste0(".*(", paste(countries, collapse="|"), ").*"), "\\1",  meta$all, ignore.case=T) 
meta$year <- gsub(".*([0-9]{4})$", "\\1", meta$all) %>% as.numeric
meta$months <- gsub(paste0(".*(", paste(countries, collapse="|"), ") (.*) [0-9]{4}"), "\\2",  meta$all, ignore.case=T)

meta$first_month[grep("-", meta$months, invert=T)] <- meta$months[grep("-", meta$months, invert=T)]
meta$first_month[grep("-", meta$months)] <- gsub(paste0("^(", paste(months, collapse="|"), ")-.*"), 
                                                 "\\1", meta$months[grep("-", meta$months)],
                                                 ignore.case=T) 
meta$first_month <- paste0(toupper(substring(meta$first_month, 1, 1)), substring(meta$first_month, 2))

meta$last_month[grep("-", meta$months, invert=T)] <- meta$first_month[grep("-", meta$months, invert=T)]
meta$last_month[grep("-", meta$months)] <- gsub(paste0(".*-(", paste(months, collapse="|"), ")$"), 
                                                 "\\1", meta$months[grep("-", meta$months)], ignore.case=T) 

for (i in seq_len(dim(meta)[1])) {
  meta$all_months[i] <- paste(months[which(months==meta$first_month[i]):which(months==meta$last_month[i])], collapse=" ")
}

meta <- select(meta, file:year, all_months)
write.csv(meta, "file_metadata.csv", row.names=F)

all.links <- gsub(pattern=".*href=\\\".*(link=[0-9]*\\.pdf).*", 
	replacement="http://www.clacso.org.ar/documentos_osal/descargar.php?\\1", x=lines) # Generate full links

dir.create("../PDFs", showWarnings = FALSE) # Make PDFs directory (outside of Git), if it doesn't already exist
all.pdfs <- list.files("../PDFs") # Get list of files in PDFs directory
old.links <- paste0("http://www.clacso.org.ar/documentos_osal/", all.pdfs) # Generate list of links for PDFs in PDFs directory

new.pdfs <- all.links[!all.links %in% old.links] # Make list of links to files available on website but not in PDFs directory
write(new.pdfs, file = "../PDFs/new_pdfs.txt", ncolumns = 1) # Write this list of new files to text file

system("cd \"../PDFs\"; wget -i new_pdfs.txt; rm new_pdfs.txt") # Download new files


### Extract text from PDFs and save (doesn't work for all files; some were scanned in by OSAL)
all.texts <- gsub(".*=([0-9]*)\\.pdf", "\\1.txt", all.pdfs) # Make list of names of text files for all PDFs

dir.create("../Texts", showWarnings = FALSE) # Make Texts directory (outside of Git), if it doesn't already exist
old.texts <- list.files("../Texts") # Get list of files in Texts directory
new.texts <- all.texts[!all.texts %in% old.texts] # Make list of names of text files without text files

# Extract text
lapply(new.texts, function(i){
  system(paste0("java -jar pdfbox-app-1.8.8.jar ExtractText \"../PDFs/descargar.php?link=", 
                gsub("txt", "pdf", i), "\" \"../Texts/", i,"\"")) 
})


### Identify files with problems and use OCR to make text files
# https://ryanfb.github.io/etc/2014/11/13/command_line_ocr_on_mac_os_x.html
system("cd \"../Texts/\"; for f in *.txt; do echo \"$f\"; pcregrep -c '�' $f;  pcregrep -ci '(m\\s?a\\s?r\\s?t\\s?e\\s?s|l\\s?u\\s?n\\s?e\\s?s|b\\s?a\\s?d\\s?o|feira|\\sos\\s)' $f; done > \"crud.txt\"") # Count lines of garbage characters (and days) in each text file
crud <- data.frame(matrix(readLines("../Texts/crud.txt"), ncol=3, byrow=T), stringsAsFactors = F) # Read in the counts
crud[, 2:3] <- lapply(crud[, 2:3], as.numeric) # Reformat count variable as numeric rather than string
crud <- crud[crud$X2 > 4 | crud$X3 == 0, ] # Files with more than four lines of garbage characters (or no mention of days) have problems and need OCR'd

dir.create("../Scanned_PDFs", showWarnings = FALSE) # Make Scanned_PDFs directory if it doesn't already exist
dir.create("../Bad_Texts", showWarnings = FALSE) # Make Bad_Texts directory if it doesn't already exist

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

system("mv ../Texts/crud.txt ../Bad_Texts/crud.txt")   # Move file with count of garbage characters out of Texts directory

### Clean up text files
# First cut in "OSAL/OSAL2/osal_text_test.do"
dir.create("../Clean_Texts", showWarnings = FALSE) # Make Clean_Texts directory if it doesn't already exist

for (i in seq(length(all.texts))) {
  text.file <- paste0("../Texts/", all.texts[i])
#  t <- readChar(text.file, file.info(text.file)$size) # Doesn't work because of embedded nuls in some text files (e.g., 100.txt)
  t0 <- readBin(text.file, file.info(text.file)$size, what="raw") # Work around to account for embedded nuls in text files
  t <- rawToChar(t0[t0!="00"])
  
  days <- c("Domingo", "Lunes", "Martes", "Miércoles", "Miercoles", "Jueves", "Viernes", "Sábado", "Sabado")
  days2 <- unlist(lapply(days, function(i) paste(unlist(strsplit(i, split="")), collapse=" ")))
  t2 <- gsub(paste0("\\n((?:", paste(days, collapse="|"), ")[[:blank:]]*[0-9]{1,2})\\n"), "\n\n\\1\n\n",  t, ignore.case=T) # Add extra line breaks around days
  t2 <- gsub(paste0("((?:", paste(days2, collapse="|"), ")[[:blank:]]*[0-9])([[:blank:]]*[0-9])?"), "\n\n\\1\\2\n\n",  t2, ignore.case=T) # Add extra line breaks around days
  months <- c("Enero", "Febrero", "Marzo", "Mayo", "Abril", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
  months2 <- unlist(lapply(months, function(i) paste(unlist(strsplit(i, split="")), collapse=" ")))
  t2 <- gsub(paste0("\\n((?:", paste(months, collapse="|"), ")[[:blank:]]*(de [0-9]{4})?)\\n"), "\n\n\\1\n\n",  t2, ignore.case=T) # Add extra line breaks around months
  t2 <- gsub(paste0("((?:", paste(months2, collapse="|"), ")[[:blank:]]*(de [0-9]{4})?)"), "\n\\1.\n",  t2, ignore.case=T) # Add extra line breaks around months
  t2 <- gsub("Glosario de Siglas", "Glosario de Siglas\n", t2, ignore.case=T)

  t2 <- gsub("([^\n]{75}\\.)\\n([[:upper:]])", "\\1 \\2", t2)   # Omit line breaks between sentences within paragraphs
  t2 <- gsub("\\n+\\s*\\d+\\s*\\n+", "\\\n", t2)   # Omit lines with just page numbers
  t2 <- gsub("\\n[^\n]*(Cronolog|OSAL|Osal)[^\n]*\\n", "\\\n", t2)  # Omit lines with headers
  t2 <- gsub("([[:alpha:]),])[[:blank:]]*\\n+\\s*([[:alnum:](“])", "\\1 \\2", t2) # Omit line breaks within sentences
  t2 <- gsub("([[:digit:]])[[:blank:]]*\\n+\\s*([[:lower:]])", "\\1 \\2", t2) # Omit line breaks at numbers within sentences
  t2 <- gsub("([[:alpha:]])\\s*\\-\\s*\\n\\s*([[:alpha:]])", "\\1\\2", t2)  # Omit line breaks within words
  
  t2 <- gsub("Glosario de Siglas", "Glosario de Siglas\n", t2, ignore.case=T)
  writeLines(t2, paste0("../Clean_Texts/", all.texts[i]))
}

for (i in seq(length(all.texts))) {
  t <- i %>% paste0("../Clean_Texts/", ., ".txt") %>% 
    readLines %>% 
    data.frame(file = i, text = ., stringsAsFactors=F)

  t <- left_join(t, meta)
  
