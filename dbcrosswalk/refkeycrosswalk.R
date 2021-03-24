### get a crosswalk between sda and nasis data
### need cokey - coiid, mukey - muiid, and lkey - liid
### THIS REQUIRES NASIS ON THE LOCAL MACHINE


setwd("E:/NMSU/interpretation-engine") # set to the interp engine

### 1 state at a time because nasis is fussy
state <- 'MN'

### 2.1 pull in ####
### NASIS how to
# log into nasis 
# queries > nssc pangaea >
#   A/L/M/DMU by areasymbol (official)
# 
# target legend
# download legend / mapunit / data mapunit
# 
# query eg %UT%
#   
#   wait
# 
# accept
# 
# wait
# 
# query local. 
# select legend, mapunit, and data mapunit
# add to selected set
# 
# now run the r script, setting the state above


require(soilDB)
require(tidyverse)

#### password may change depending on computer. usda machines use a different one?
options(soilDB.NASIS.credentials="DSN=nasis_local;UID=NasisSqlRO;PWD=nasisRe@d0n1y")

c.nasis <- get_component_data_from_NASIS_db()
m.nasis <- get_mapunit_from_NASIS()
l.nasis <- get_legend_from_NASIS()

l.nasis$areasymbol %>% unique
m.nasis$areasymbol %>% unique


raw.nasis <- 
  left_join(
    c.nasis,
    m.nasis,
    by = "dmuiid"
  ) %>%
  left_join(
    l.nasis,
    by = c("liid", "areasymbol")
  ) %>%
  filter(
    !is.na(areasymbol)
  ) %>%
  filter(
    grepl(state, areasymbol)
  )

head(raw.nasis)
if(nrow(raw.nasis) == 0) beep(9)

### SDA
source("Functions/pull_SDA2_compandup.r")
source("Functions/pull_SDA2.r")
raw.sda.all <- pull_SDA_compup(asym = state, fun = 'like')

raw.sda <- reduce(raw.sda.all, right_join)

head(raw.sda)

# ### check n cokeys
length(unique(raw.sda$cokey))
length(unique(raw.nasis$coiid))

#raw.sda.all$areasymbol %>% unique

### create join col
intersect(colnames(raw.nasis), colnames(raw.sda)) %>% sort

vec.intersectnames <- c(
  "areasymbol",
  "compname",
  "majcompflag",
  "comppct_r",
  "muname",
  "nationalmusym",
  "localphase"
  )




### 2.2 process ####

t.nasis <-
  raw.nasis %>%
  filter(grepl(state, areasymbol)) %>%
  dplyr::select(
    c("coiid", "liid", "muiid", "dmuiid", all_of(vec.intersectnames))
  ) %>%
  mutate(
    comppct = comppct_r
  ) %>%
  replace(is.na(.), "0") %>%
  mutate_if(is.character, str_trim) %>%
  mutate_if(is.character, tolower) %>%
  # dplyr::rename(key.nasis = coiid) %>%
  unite(
    "key.join", vec.intersectnames[1]:vec.intersectnames[length(vec.intersectnames)]
  )
t.nasis

t.sda <-
  raw.sda %>%
  dplyr::select(
    c("cokey", "mukey", "lkey", all_of(vec.intersectnames))
  ) %>%
  replace(is.na(.), "0") %>%
  mutate_if(is.character, str_trim) %>%
  mutate_if(is.character, tolower) %>%
  mutate(
    majcompflag = recode(majcompflag, "yes" = 1, "no" = 0)
  ) %>%
  unite(
    "key.join", vec.intersectnames[1]:vec.intersectnames[length(vec.intersectnames)]
  )

length(t.sda$key.join) - length(unique(t.sda$key.join)) # n of duplicated entries in sda. ideally, 0
length(t.nasis$key.join) - length(unique(t.nasis$key.join)) # n of duplicated entries. ideally, 0

sum(!(t.nasis$key.join %in% t.sda$key.join)) # n entries in nasis but not sda, ideally 0
sum(!(t.sda$key.join %in% t.nasis$key.join)) # n entries in nasis but not sda, ideally 0

head(t.sda)
head(t.nasis)

### 2.3 do the join ####
t.fulljoin <- full_join(t.sda, t.nasis, by = "key.join")
t.innerjoin <- inner_join(t.sda, t.nasis, by = "key.join") #%>%

### 2.4 trim out ambiguities: duplicated keys within a dataset ####
dbcrosswalk <- t.innerjoin

dbcrosswalk <- t.innerjoin[
  !duplicated(t.innerjoin$cokey) & 
#    !duplicated(t.innerjoin$key.ssurgo) &
  !duplicated(t.innerjoin$coiid) 

,]

##### SAVE ####

head(dbcrosswalk)
nrow(dbcrosswalk)

sum(duplicated(dbcrosswalk$key.sda))
#sum(duplicated(dbcrosswalk$key.ssurgo))
sum(duplicated(dbcrosswalk$key.nasis))
sum(duplicated(dbcrosswalk$key.join))

dbcrosswalk$state <- state

#save(dbcrosswalk, file = paste0("dbcrosswalk\\dbcrosswalk_inner_", state, ".rda"))
write.csv(dbcrosswalk,
          file = paste0("dbcrosswalk/dbcrosswalk_inner_", state, ".csv"),
          row.names = F)


