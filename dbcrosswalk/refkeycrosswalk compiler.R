## crosswalk compiler
## take all the single state crosswalk files and make them into one


### 1 load data ####
setwd("E:/NMSU/interpretation-engine/dbcrosswalk")

## identify single state crosswalks by their naming convention (end with two letter code)
v.paths <- list.files(pattern = "dbcrosswalk_inner_[A-Z]{2}.csv")

## load them
l.tables <- lapply(v.paths, read.csv)

## rbind into a single table
dbcrosswalk <- do.call(rbind, l.tables)

head(dbcrosswalk)

### 2 save full crosswalk ####
## get list of states in data (to use in file name)
states <- unique(dbcrosswalk$state)

outname <- paste0("dbcrosswalk_", paste(states, collapse = "_"), ".csv")

write.csv(dbcrosswalk,
          file = outname,
          row.names = F)
