library(data.tree)

dt <- Node$new('a new node')
dt$AddChild('first child')
dt$AddChild('second child')

f1 <- function(i) i + 1
f2 <- function(i) i + 2

dt$`first child`$AddChildNode(f1)
