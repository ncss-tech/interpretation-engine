library(sharpshootR)


## this isn't working...


url <- 'https://nasis.sc.egov.usda.gov/NasisReportsWebSite/limsreport.aspx?report_name=WEB-PROPERY-COMPONENT_property'

# prop_name: full property name
# cokey: component record ID, can be a comma-delim list
args <- list(prop_name='TAXONOMIC SUBORDER', cokey='1842387')

parseWebReport(url, args, index=1)


