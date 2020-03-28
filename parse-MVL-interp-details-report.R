library(rvest)
library(xml2)
library(stringi)

# example report
x <- xml2::read_html('interp-details-reports/ENG - Dwellings With Basements.html')

# tables, note that they have headers--thanks Mark!
ht <- html_table(x, header = TRUE, fill = TRUE, trim=TRUE)


# extract columns of interest
dl <- lapply(ht, '[[', 'Data Elements')
dl <- unlist(dl)


# Valley Fever is a little different than the other reports
# also requires some manual clean-up
x <- xml2::read_html('interp-details-reports/Valley Fever.html')

# tables, note that they have headers--thanks Mark!
ht <- html_table(x, header = FALSE, fill = TRUE, trim=TRUE)


# extract columns of interest
dl <- lapply(ht, '[[', 'X4')
dl <- unlist(dl)



## everything should run the same from here down

# collapse to single string
dl.txt <- paste(dl, collapse = '')

# clean junk
dl.txt <- gsub(pattern = ' ', replacement = '', dl.txt)
dl.txt <- gsub(pattern = '\r\n', replacement = '', dl.txt)

# split on ','
z <- stri_split_fixed(dl.txt, pattern=',')[[1]]

# format for reference
z <- sort(unique(z))
cat(z, sep = '\n')


