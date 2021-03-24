require(data.tree)

### 1.1 define hsg tree #### 
# All trees are defined in the same way:
## create the empy tree
## add nodes one at a time -- three types, root, decision, and classification

## root node isn't used anywhere else. They get the default name "site" and no other attributes

## all decision nodes need three values: 
### name (not essential for the decision nodes, used for labelling)
### logical (essential, the logical statement evaluated by the decision)
### var (essential, the exact variable name evaluated. Same name must be used exactly in 'logical')

## all classification nodes need only a name, this is the value returned by the decision function 
### Here they also get "classification" for the var entry, which is a relic


### root ####
tr.hsg <- Node$new(
  name = "Site", 
  nextvar = "rl",
  nextlogical = "rl < 50; rl >= 50 & rl < 100; rl >= 100 | is.na(rl)"
)

###
tr.hsg$AddChild(
  name = "Shallow restrictive layer",
  result = "D",
  nextvar = NULL,
  nextlogical = NULL
)

tr.hsg$AddChild(
  name = "Moderate depth restrictive layer",
  nextvar = "wt",
  nextlogical = "wt < 60; wt >= 60"
)

tr.hsg$AddChild(
  name = "Deep restrictive layer",
  nextvar = "wt",
  nextlogical = "wt < 60; wt >= 60"
)

### moderate rl shallow wt ####
tr.hsg$`Moderate depth restrictive layer`$AddChild(
  name = "Shallow water table",
  nextvar = "ksat",
  nextlogical = "ksat > 40; ksat <= 40 & ksat > 10; ksat <= 10 & ksat > 1; ksat <= 1" #### DOUBLE CHECK THESE 
)

tr.hsg$`Moderate depth restrictive layer`$`Shallow water table`$AddChild(
  name = "High conductivity",
  result = "A/D"
)

tr.hsg$`Moderate depth restrictive layer`$`Shallow water table`$AddChild(
  name = "Moderate-high conductivity",
  result = "B/D"
)

tr.hsg$`Moderate depth restrictive layer`$`Shallow water table`$AddChild(
  name = "Moderate-low conductivity",
  result = "C/D"
)

tr.hsg$`Moderate depth restrictive layer`$`Shallow water table`$AddChild(
  name = "Low conductivity",
  result = "D"
)
### moderate rl deep wt ####
tr.hsg$`Moderate depth restrictive layer`$AddChild(
  name = "Deep water table",
  nextvar = "ksat",
  nextlogical = "ksat > 40; ksat <= 40 & ksat > 10; ksat <= 10 & ksat > 1; ksat <= 1" #### DOUBLE CHECK THESE 
)

tr.hsg$`Moderate depth restrictive layer`$`Deep water table`$AddChild(
  name = "High conductivity",
  result = "A"
)

tr.hsg$`Moderate depth restrictive layer`$`Deep water table`$AddChild(
  name = "Moderate-high conductivity",
  result = "B"
)

tr.hsg$`Moderate depth restrictive layer`$`Deep water table`$AddChild(
  name = "Moderate-low conductivity",
  result = "C"
)

tr.hsg$`Moderate depth restrictive layer`$`Deep water table`$AddChild(
  name = "Low conductivity",
  result = "D"
)

### deep rl shallow wt ####
tr.hsg$`Deep restrictive layer`$AddChild(
  name = "Shallow water table",
  nextvar = "ksat",
  nextlogical = "ksat > 10; ksat <= 10 & ksat > 4; ksat <= 4 & ksat > 0.4; ksat <= 0.4"
)

tr.hsg$`Deep restrictive layer`$`Shallow water table`$AddChild(
  name = "High conductivity",
  result = "A/D"
)

tr.hsg$`Deep restrictive layer`$`Shallow water table`$AddChild(
  name = "Moderate-high conductivity",
  result = "B/D"
)

tr.hsg$`Deep restrictive layer`$`Shallow water table`$AddChild(
  name = "Moderate-low conductivity",
  result = "C/D"
)

tr.hsg$`Deep restrictive layer`$`Shallow water table`$AddChild(
  name = "Low conductivity",
  result = "D"
)

### deep rl deep wt ####
tr.hsg$`Deep restrictive layer`$AddChild(
  name = "Deep water table",
  nextvar = "ksat",
  nextlogical = "ksat > 10; ksat <= 10 & ksat > 4; ksat <= 4 & ksat > 0.4; ksat <= 0.4"
)

tr.hsg$`Deep restrictive layer`$`Deep water table`$AddChild(
  name = "High conductivity",
  result = "A"
)

tr.hsg$`Deep restrictive layer`$`Deep water table`$AddChild(
  name = "Moderate-high conductivity",
  result = "B"
)

tr.hsg$`Deep restrictive layer`$`Deep water table`$AddChild(
  name = "Moderate-low conductivity",
  result = "C"
)

tr.hsg$`Deep restrictive layer`$`Deep water table`$AddChild(
  name = "Low conductivity",
  result = "D"
)

save(tr.hsg, file = "Engine Guts/HSG/datatree-hsg.rdata")

