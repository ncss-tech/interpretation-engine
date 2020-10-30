# 0   Load packages, define workspace, load data ####
require(tidyverse) 
require(soilDB)
require(dplyr)


# pull_SDA() is a soilDB helper function -- for a set of area symbols, return a named list of tables (component, chorizon, etc)
# which tables to pull is hard coded, and defines "all the tables Joe has needed to use so far"

source("E:/NMSU/interpretation-engine/pull_SDA.r")

# 1 get data to work with ####
# download sda
asym <- c('AK651', 'CT600', 'NE043', 'UT616', 'NM632')

l.t <- pull_SDA(asym)

# store the joins (Properties) in a list, collapse later to component data with reduce(left_join()) 
l.i <- list()

# leftmost has to have all cokeys for reduce(left()) to work
l.i$cokey <- data.frame(cokey = unique(l.t$component$cokey))

# count cokeys (used to check for missing data)
n.cokey <- length(unique(l.t$component$cokey))

### VARIABLES NEEDED BY DWB
# 1 - depth to bedrock (hard)
# 2 - flooding frequency
# 3 - om content class of the last layer above bedrock / deepest layer 
# 4 - large stone content
# 5 - depth to permafrost
# 6 - ponding duration
# 7 - depth to bedrock (soft)
# 8 - shrink-swell
# 9 - slope
# 10 - depth to cemented pan (thick)
# 11 - depth to cemented pan (thin)
# 12 - subsidence(cm)
# 13 - depth to saturated zone
# 14 - unstable fill
# 15 - subsidence due to gypsum

# pull in all the data. aggregate to component

# 1 - depth to bedrock (hard) ####
l.i$brockhard <-
  l.t$component %>%
  left_join(
    l.t$corestrictions,
    by = "cokey"
  ) %>%
  filter(
    tolower(str_trim(reskind)) %in% c("lithic bedrock", "permafrost")
  ) %>%
  arrange(cokey,
          resdept_r,
          resdept_l
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    depbrockhard = first(resdept_r),
    .groups = "drop"
  )

l.i$brockhard

# 7 - depth to bedrock (soft) ####
l.i$brocksoft <-
  l.t$component %>%
  left_join(
    l.t$corestrictions,
    by = "cokey"
  ) %>%
  filter(
    tolower(str_trim(reskind)) %in% c("paralithic bedrock")
  ) %>%
  arrange(resdept_r,
          resdept_l) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    depbrocksoft = first(resdept_r)
  )

l.i$brocksoft


# #### depth to all bedrock ####
l.i$brockall <-
  l.t$component %>%
  left_join(
    l.t$corestrictions,
    by = "cokey"
  ) %>%
  arrange(resdept_r,
          resdept_l) %>%
  group_by(
    cokey,
  ) %>%
  summarize(
    depbrockall = first(resdept_r)
  )

l.i$brockall 


# 2 - flooding frequency   #### this one goes further than the property, returning a T/F "does it flood" rather than freq 

l.i$floodfreq <-
  l.t$component %>%
  left_join(
    l.t$comonth,
    by = "cokey"
  ) %>%
  mutate( # go from string to factor (ie, ordered) to numeric (ie, ranked flood freq)
    floodfreqnum = as.numeric(factor(tolower(str_trim(flodfreqcl)),
                                         levels = c("none",
                                                    "very rare",
                                                    "rare",
                                                    "occasional",
                                                    "frequent",
                                                    "very frequent")))
  ) %>%
  arrange(
    cokey,
    -floodfreqnum) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    maxfloodfreqnum = first(floodfreqnum)
  ) %>%
  mutate(
    maxfloodfreq = str_replace_all(as.character(maxfloodfreqnum),
                                   c("1" = "none",
                                     "2" = "very rare",
                                     "3" = "rare",
                                     "4" = "occasional",
                                     "5" = "frequent",
                                     "6" = "very frequent")),
    floodlim = !(maxfloodfreqnum == 1 | is.na(maxfloodfreqnum))
  ) %>%
  dplyr::select(
    cokey,
    maxfloodfreq,
    floodlim
  )

l.i$floodfreq

# 3 - om content class LOWEST LAYER ABOVE BEDROCK  ### ####
# similar to above, this returns a logical summarizing the property results

l.i$omclass <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chunified,
    by = "chkey"
  ) %>%
  left_join(
    l.i$brockall,
    by = "cokey"
  ) %>%
  filter(
    hzdepb_r <= depbrockall &
    hzdepb_r > hzdept_r
  ) %>%
  arrange(
    cokey,
    -hzdepb_r ### what happens to NA values, does this prefer NA's?
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    unifiedcl = first(unifiedcl),
  ) %>%
  mutate(
    omlim = grepl("(pt)|(ol)|(oh)", tolower(str_trim(unifiedcl)))
  )

l.i$omclass
sort(unique(l.i$omclass$unifiedcl))
sort(unique(l.t$chunified$unifiedcl))
subset(l.i$omclass, omlim == T)
unique(subset(l.i$omclass, omlim == F)[,"unifiedcl"])

# 4 - large stone content             ####
### "weighted average percentage of rock fragments of size greater than 75mm in the horizons above a restrictive feature 
### or from 0 to 100 cm deep."
### weighted by what? am going to calculate total pct in the entire soil column, so weighting by thickness

l.i$lgstonepct <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.i$brockall,
    by = "cokey"
  ) %>%
  filter(
    (hzdepb_r <= depbrockall | is.na(depbrockall)) &
      hzdepb_r > hzdept_r &
      hzdept_r < 100
  ) %>%
  mutate(
    frag3to10_r = replace_na(frag3to10_r, 0),
    fraggt10_r = replace_na(fraggt10_r, 0),
    
    # looking only in top 100cm. So cut off horizons there. Fragvol is in % so that value is still good. 
    ## Is there a better fn than clamp()?
    hzdepb_cap100 = raster::clamp(hzdepb_r, 0, 100),    
    
    hzthickness = hzdepb_cap100 - hzdept_r,
    fragsum = frag3to10_r + fraggt10_r
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
     fragvol_wmn = weighted.mean(x = fragsum, w = hzthickness, na.rm = T)
  )

l.i$lgstonepct



# 5 - depth to permafrost           ####
### skipped the lieutex section, might result in varied results in permafrost areas

l.i$permafrost <-
  l.t$component %>%
  left_join(
    l.t$corestrictions,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  filter(
    tolower(str_trim(reskind)) == "permafrost") %>%
  arrange(
    resdept_r
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    reskind = first(reskind),
    resdept_r = first(resdept_r)
  )

l.i$permafrost

# 6 - ponding duration             ####
l.i$ponddur <-
  l.t$component %>%
  left_join(
    l.t$comonth,
    by = "cokey"
  ) %>%
  mutate( # go from string to numeric (ie, ranked flood freq)
    ponddurfact = 
      factor(str_trim(tolower(ponddurcl)),
             levels = 
              c("none",
                "very brief (4 to 48 hours)",
                "brief (2 to 7 days)",
                "long (7 to 30 days)",
                "very long (more than 30 days)",
                NA)
            )
  ) %>%
  arrange(
    cokey,
    ponddurfact,
  ) %>%
  group_by(
    cokey,
  ) %>%
  summarize(
    maxponddurcl = first(ponddurcl),
    maxpondfreq = first(pondfreqcl)
  ) %>%
  mutate(pondlim = (tolower(str_trim(maxponddurcl)) != "none" & !is.na(maxponddurcl)) | 
           (tolower(str_trim(maxpondfreq)) != "none" & !is.na(maxpondfreq)))

l.i$ponddur
subset(l.i$ponddur, pondlim == T)


# 9 - slope                 
l.i$slope <-
  l.t$component %>%
  select(cokey,
         slope_r)

l.i$slope

# 10 - depth to cemented pan (thick)

l.i$cementthick <-
  l.t$component %>%
  left_join(l.t$corestrictions,
            by = "cokey") %>%
  filter(
    str_trim(tolower(reskind)) %in% c("petrocalcic", "petroferric", "petrogypsic", "duripan") &
      str_trim(tolower(reshard)) %in% c("indurated", "very strongly", "strongly", "extremely strong", "strongly cemented")
  ) %>%
  arrange(resdept_r) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    depcementthick = first(resdept_r)
  )

l.i$cementthick

# 11 - depth to cemented pan (thin)
l.i$cementsoft <-
  l.t$component %>%
  left_join(l.t$corestrictions,
            by = "cokey") %>%
  filter(
    str_trim(tolower(reskind)) %in% c("petrocalcic", "petroferric", "petrogypsic", "duripan", "fragipan") &
      !(str_trim(tolower(reshard)) %in% c("indurated", "very strongly", "strongly", "extremely strong", "strongly cemented"))
  ) %>%
  arrange(resdept_r) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    depcementsoft = first(resdept_r)
  )

l.i$cementsoft

# 12 - subsidence(cm)
l.i$subsidence <-
  l.t$component %>%
  select(
    cokey,
    totalsub_r
  )
l.i$subsidence

# 13 - depth to saturated zone aka wt

l.i$wt <-
  l.t$component %>%
  left_join(
    l.t$comonth,
    by = "cokey"
  ) %>%
  left_join(
    l.t$cosoilmoist,
    by = "comonthkey"
  ) %>%
  filter(
    tolower(str_trim(soimoiststat)) %in% c("wet", "saturation")
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    wt = min(soimoistdept_r,
             na.rm = F)
  )
l.i$wt

# 14 - unstable fill aka local phase  ### component

l.i$localphase <-
  l.t$component %>%
  select(cokey,
         localphase) %>%
  mutate(
    phaselim = str_trim(tolower(localphase)) == "unstable fill" & !is.na(localphase)
  )

l.i$localphase

sort(unique(l.t$component$localphase))

# 15 - subsidence due to gypsum       ### chorizon

# BASE TABLE COMPONENT.
# 
# 
# EXEC SQL
# SELECT hzdept_r, hzdepb_r, gypsum_r, dbthirdbar_r, fragvol_r, om_r, coiid
# FROM component, chorizon, outer chfrags
# WHERE JOIN component to chorizon AND JOIN chorizon to chfrags
# AND (fragkind not in ("wood", "logs and stumps") OR fragkind is null);
# SORT by coiid, hzdept_r
# AGGREGATE COLUMN hzdept_r NONE, hzdepb_r NONE, gypsum_r NONE, dbthirdbar_r NONE, fragvol_r NONE, om_r NONE.
# 

# DEFINE hzthick		hzdepb_r - hzdept_r.
# 
# DEFINE frags		REGROUP fragvol_r BY hzdept_r AGGREGATE SUM.
# ASSIGN gypsum_r 	REGROUP gypsum_r BY hzdept_r AGGREGATE FIRST.
# ASSIGN dbthirdbar_r 	REGROUP dbthirdbar_r BY hzdept_r AGGREGATE FIRST.
# ASSIGN dbthirdbar_r	isnull(dbthirdbar_r) ? 1.45 : dbthirdbar_r.
# ASSIGN hzthick	   	REGROUP hzthick BY hzdept_r AGGREGATE FIRST.
# 
# ASSIGN om_r		IF ISNULL(om_r) THEN 0 ELSE om_r.
# 

l.t$gypsum1 <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chfrags,
    by = "chkey"
  ) %>%
  filter(
    !(tolower(str_trim(fragkind)) %in% c("wood fragments", "wood", "logs and stumps")) | is.na(fragkind)
  ) %>%
  mutate(
    hzthick = hzdepb_r - hzdept_r
  ) %>%
  arrange(
    cokey,
    hzdept_r
  ) %>%
  group_by(
    cokey,
    chkey,
    hzdept_r
  ) %>%
  summarize(
    frags = sum(fragvol_r),
    gypsum_r = first(gypsum_r),
    dbthirdbar_r = first(dbthirdbar_r),
    hzthick = first(hzthick),
    om_r = first(om_r)
  ) %>%
  mutate(
    om_r = replace_na(om_r, 0),
    gypsum_r = replace_na(gypsum_r, 0), #### should this be here? no isnull statement in cvir, but otherwise r gives lots of na's
    dbthirdbar_r = replace_na(dbthirdbar_r, 1.45)     # ASSIGN dbthirdbar_r	isnull(dbthirdbar_r) ? 1.45 : dbthirdbar_r.
  )

l.t$gypsum1

sort(unique(l.t$chfrags$fragkind))

# EXEC SQL
# SELECT hzdept_r hzdep, fragvol_r frag2_20, fragsize_r, fragsize_l, fragsize_h, coiid coid
# FROM component, chorizon, outer chfrags
# WHERE JOIN component to chorizon AND JOIN chorizon to chfrags;
# SORT by coid, hzdep
# AGGREGATE COLUMN hzdep NONE, frag2_20 NONE, fragsize_r NONE, fragsize_l NONE, fragsize_h NONE.
# 

# assign hzdep	isnull(hzdep) ? 1/0 : hzdep.
# 

# ASSIGN frag2_20		
# IF fragsize_h <= 20 AND NOT ISNULL(fragsize_h) THEN frag2_20 
# ELSE IF fragsize_h > 20 AND NOT ISNULL(fragsize_h) THEN 1/0
# ELSE IF fragsize_r <= 20 AND NOT ISNULL(fragsize_r) THEN ((20-fragsize_r)/(fragsize_h-fragsize_r)*0.5 + 0.5)*frag2_20
# ELSE IF fragsize_l < 20 AND NOT ISNULL(fragsize_l) THEN ((20-fragsize_l)/(fragsize_r-fragsize_l)*0.5)*frag2_20 
# ELSE 1/0.
# 
# ASSIGN frag2_20		REGROUP frag2_20 BY hzdep AGGREGATE SUM.
# ASSIGN frag2_20		IF ISNULL(frag2_20) THEN 0 ELSE frag2_20.


l.t$gypsum2 <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chfrags,
    by = "chkey"
  ) %>%
  mutate(
    hzdep = replace_na(hzdept_r, 0),
    frag2_20 = 
      case_when( ### case_when has some particular input needs. Convert everything from integer to double
        fragsize_h <= 20 ~ as.double(fragvol_r),
        fragsize_h > 20 ~ NA_real_,
        fragsize_r <= 20 ~ (((20-fragsize_r)/(fragsize_h-fragsize_r)*0.5 + 0.5)*fragvol_r),
        fragsize_l < 20 ~ (((20-fragsize_l)/(fragsize_r-fragsize_l)*0.5)*fragvol_r),
        TRUE ~ NA_real_
      ) %>%
      replace_na(0)
  ) %>%
  group_by(
    cokey,
    chkey,
    hzdep
  ) %>%
  summarize(
    frag2_20 = sum(frag2_20)
  )

l.t$gypsum2
subset(l.t$gypsum2, frag2_20 != 0)

# EXEC SQL
# SELECT hzdept_r hzdep2, fragvol_r gyp20, fragsize_r fgsize, fragsize_l fgsize_l, fragsize_h fgsize_h, coiid cid
# FROM component, chorizon, outer chfrags
# WHERE JOIN component to chorizon AND JOIN chorizon to chfrags
# AND fragkind in ("gypsum, rock");
# SORT by cid, hzdep2
# AGGREGATE COLUMN hzdep2 NONE, gyp20 NONE, fgsize NONE, fgsize_l NONE, fgsize_h NONE.

# assign hzdep2	isnull(hzdep2) ? 1/0 : hzdep2.

# ASSIGN gyp20		IF fgsize_l >= 20 AND NOT ISNULL(fgsize_l) THEN gyp20 
# ELSE IF fgsize_l < 20 AND NOT ISNULL(fgsize_l) THEN 1/0
# ELSE IF fgsize >= 20 AND NOT ISNULL(fgsize) THEN ((fgsize-20)/(fgsize-fgsize_l)*0.5 + 0.5)*gyp20
# ELSE IF fgsize_h > 20 AND NOT ISNULL(fgsize_h) THEN ((fgsize_h-20)/(fragsize_h-fgsize)*0.5 + 0.5)*gyp20 
# ELSE 1/0.
# 
# ASSIGN gyp20		REGROUP gyp20 BY hzdep2 AGGREGATE SUM.
# ASSIGN gyp20		IF ISNULL(gyp20) THEN 0 ELSE gyp20.

l.t$gypsum3 <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chfrags,
    by = "chkey"
  ) %>%
  filter(
    grepl("gyps", fragkind, ignore.case = T)
  ) %>%
  mutate(
    hzdep2 = replace_na(hzdept_r, 0),
    gyp20 = 
      case_when(
        fragsize_l >= 20 ~ as.double(fragvol_r),
        fragsize_l < 20 ~ NA_real_,
        fragsize_r >= 20 ~ ((fragsize_r-20)/(fragsize_r-fragsize_l)*0.5 + 0.5)*fragvol_r,
        fragsize_h > 20 ~ ((fragsize_h-20)/(fragsize_h-fragsize_r)*0.5 + 0.5)*fragvol_r,
        TRUE ~ NA_real_
      ) %>%
      replace_na(0)
  ) %>%
  group_by(
    cokey,
    chkey,
    hzdep2
  ) %>%
  summarize(
    gyp20 = sum(gyp20)
  ) 

l.t$gypsum3

# exec sql select lieutex, chtiid, chiid, hzdept_r hdept_3, hzdepb_r hdepb_3, rvindicator
# from component, chorizon,
# chtexturegrp, chtexture
# where join component to chorizon
# and join chorizon to chtexturegrp
# and join chtexturegrp to chtexture
# AND (desgnmaster is null or not 
#      (desgnmaster in ("O", "O'", "O''"))); 
# sort by hzdept_r, chiid, rvindicator desc, chtiid
# aggregate column hzdept_r none, chiid none, lieutex none.
# 

l.t$gypsum4 <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.t$chtexturegrp,
    by = "chkey"
  ) %>%
  filter( ## moved the filter up, this section sometimes errs with too much data
    !grepl("o", desgnmaster, ignore.case = T) | is.na(desgnmaster)
  ) %>%
  distinct( ## also moved distinct, same reason
  ) %>%
  left_join(
    l.t$chtexture,
    by = "chtgkey"
  ) %>%
  arrange(chkey,
          chtgkey,
          hzdept_r) %>% # dropped rvindicator sort
  select(
    cokey,
    compname,
    mukey,
    chkey,
    #chtgkey,
    hdept_3 = hzdept_r,
    hdepb_3 = hzdepb_r,
    #rvindicator,
    lieutex,
    desgnmaster
  )

sort(unique(l.t$chorizon$desgnmaster))
#sort(unique(l.t$chtexture$lieutex))
#sort(unique(l.t$gypsum4$lieutex))
sort(unique(l.t$gypsum4$desgnmaster))


###### skipped these
# # Bulk density of the fragments.
# DEFINE Db_frags		2.65.
Db_frags <- 2.65 # 

# DEFINE lieu_tex codename(lieutex).

# # Average particle density.
# DEFINE Dp		IF om_r + (gypsum_r-frag2_20) > 100 THEN 2.65 ELSE 100/(om_r/1.4 + (gypsum_r-frag2_20)/2.31 + (100-(om_r+(gypsum_r-frag2_20)))/2.65).
# 

# use gypsum1, joined to gypsum 2???
# need 3 for gyp20, to define subsid

l.i$gypsum <-
  full_join(
    l.t$gypsum1, 
    l.t$gypsum2,
    by = c("chkey","cokey")
  ) %>%
  full_join(
    l.t$gypsum3,
    by = c("cokey", "chkey")
  ) %>%
  full_join(
    l.t$gypsum4,
    by = c("cokey", "chkey")
  ) %>%
  mutate(
    # # Calculates the bulk density of the whole soil <= 20mm (includes fragments <= 20mm).
    # DEFINE Db_20mm		(dbthirdbar_r*(1-frag2_20/(100-(frags-frag2_20))))+((frag2_20/(100-(frags-frag2_20)))*Db_frags).
    
    Dp = case_when(
      om_r + (gypsum_r - frag2_20) > 100 ~ 2.65,
      TRUE ~ 100 / (om_r/1.4 + (gypsum_r - frag2_20) / 2.31 + (100-(om_r+(gypsum_r-frag2_20)))/2.65)
    ),
    # # Porosity (percent)
    # DEFINE porosity		IF ISNULL(frags) THEN (1-(dbthirdbar_r/Dp))*100 ELSE 100-frags *(1-(dbthirdbar_r/Dp)).
    
    Db_20mm = (dbthirdbar_r*(1-frag2_20/(100-(frags-frag2_20))))+((frag2_20/(100-(frags-frag2_20)))*Db_frags),
    porosity = case_when(
      is.na(frags) ~ (1 - (dbthirdbar_r / Dp)) * 100,
      TRUE ~ 100-frags * (1 - (dbthirdbar_r/Dp))
    ),
    
    # # Calculates the amount of subsidence from the loss of gypsum; includes a portion of the pore space associated with the < 2 mm gypsum.
    # DEFINE subsid		IF ISNULL(frags) THEN ((gypsum_r/100*dbthirdbar_r/2.31)*hzthick) #+ (gypsum_r/100*porosity/100*hzthick)
    # ELSE (((gypsum_r/100*Db_20mm/2.31*100/(100+frags-frag2_20))+gyp20/100)*hzthick). #+ ((gypsum_r-frag2_20)/100*porosity/100*hzthick).
    # #Soils having gypsum bedrock are also suscetible to subsidence, so look for in-lieu texture of "gyp".
    # 
    # ASSIGN subsid	if lieu_tex imatches "gyp" then (hzthick*0.75) else subsid.
    
    subsid = case_when(
      grepl("gyp", str_trim(tolower(lieutex))) ~ hzthick * 0.75,
      is.na(frags) ~ ((gypsum_r/100*dbthirdbar_r/2.31)*hzthick),
      TRUE ~ (((gypsum_r/100*Db_20mm/2.31*100/(100+frags-frag2_20))+gyp20/100)*hzthick)
    ) %>%
      replace_na(0),
    
    # assign gypsum_r	if lieu_tex imatches "gyp" then 85 else gypsum_r.
    gypsum_r =  case_when(
      grepl("gyp", str_trim(tolower(lieutex))) ~ 85,
      TRUE ~ gypsum_r
    ),
    
    gyp20 = replace_na(gyp20, 0),
    gypsum_r = replace_na(gypsum_r, 0),
    
    # DEFINE rv		ARRAYSUM(subsid).
    # 
    # # If there is no gypsum in the soil or gypsum fragments, then zero subsidence is assigned. 
    # ASSIGN rv		IF (ISNULL(ARRAYSUM(gyp20)) OR ARRAYSUM(gyp20)== 0) AND (ISNULL(ARRAYSUM(gypsum_r)) OR ARRAYSUM(gypsum_r) == 0) THEN 0 ELSE rv.
    # 
    # 
    # # If rv bulk density 1/3 bar water is null, then a NULL is assigned.
    # DEFINE chckdb		IF NOT ISNULL(gypsum_r) AND ISNULL(dbthirdbar_r) THEN 1 ELSE 0.
    # DEFINE chck		ARRAYSUM(chckdb).
    # ASSIGN rv		IF chck >= 1 THEN 0 ELSE rv.

    chckdb = case_when(
      !is.na(gypsum_r) & is.na(dbthirdbar_r) ~ 1,
      TRUE ~ 0
    )
    
  ) %>%
    group_by(
      cokey, 
      compname, 
      mukey
      ) %>%
  summarize(
    subsid = sum(subsid),
    gyp20 = sum(gyp20),
    gypsum_r = sum(gypsum_r),
    chck = sum(chckdb)
  ) %>%
  mutate(
    subsid = case_when(
      chck >= 1 ~ 0,
      TRUE ~ subsid
    )
  )
  


l.i$gypsum


# 8 - shrink-swell                    ### ???
### uses a fuzzy rule

l.i$shrinkswell <-
  l.t$component %>%
  left_join(
    l.t$chorizon,
    by = "cokey"
  ) %>%
  left_join(
    l.i$brockall,
    by = "cokey"
  ) %>%
  filter(
    hzdepb_r > hzdept_r,
    hzdept_r < 100,
    hzdept_r < depbrockall
  ) %>%
  mutate(
    hzthickness = hzdepb_r - hzdept_r,
  ) %>%
  arrange(
    -hzthickness
  ) %>%
  group_by(
    cokey
  ) %>%
  summarize(
    lep = first(lep_r)
  )
  
l.i$shrinkswell

### join it all to the cokey level ####


indata.dwb <- l.i  %>% reduce(left_join, by = "cokey")



#### SAVE IT!
#save(indata.dwb, file = "indata.dwb.rda")
