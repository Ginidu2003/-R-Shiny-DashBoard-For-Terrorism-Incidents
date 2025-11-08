#install.packages("rsconnect")
library(rsconnect)



# Set your shinyapps.io account info
rsconnect::setAccountInfo(
  name = 'ginidu2003',
  token = '256FDA304B0203096C65FEBDA31511AD',
  secret = 'XaF6k30P2Ryj6zNeiDuYpKOPQg3wBMZmNndMB9Ke'
)

rsconnect::deployApp("C:\\Users\\ginid\\Desktop\\sem 4\\Data visualization\\R\\R Assignment\\terrorist")


rsconnect::showLogs("terrorist")
