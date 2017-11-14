library(plyr)
library(httr)
library(lubridate)
library(ggplot2)
library(urltools)

## txt files from LexisNexis Database
setwd('/Users/KevinM/Desktop/Data Project')
fn = list.files(path="/Users/KevinM/Desktop/Data Project", pattern="^The_Associated_Press",
                full.names=T)

ap = character(0)
for (s in fn) {
  tmp = readLines(s)
  n = length(tmp)
  
  ## append, but ignore the last row
  ap = c(ap, tmp[-n])
}

k1 = grep("Results$", ap)
ap[k1] = ""

k1 = which(nchar(ap) == 0)
k2 = grep("The Associated Press, ", ap, fixed=T)

if (length(k2) == length(k1)) {
  
  title = character(length(k1))
  for (j in 1:length(k1)) {
    row_seq = seq(from=k1[j] + 1, to=k2[j]-1, by=1)
    tmp = ap[row_seq]
    
    tmp = gsub("^[0-9]+[.]?[ ]+", "", tmp)
    tmp = gsub("[^0-9A-Za-z ]", " ", tmp)
    tmp = gsub("[ ]{2,}", " ", tmp)
    
    title[j] = paste(tmp, collapse=" ")
  }
}

info = ap[k2]

info = gsub("^[0-9 .]+(?=The )", "", info, perl=T)
datetime = gsub("(^The Associated Press, )|((?<=GMT),.+$)", "", info, perl=T)

dt = strptime(datetime, "%B %d, %Y %A %I:%M %p GMT", tz="GMT")
stdatetime = strftime(dt, format="%Y%m%d%H%M%S")
stdatetime[1:20]

enddatetime = strftime(dt + 3*24*3600, format="%Y%m%d%H%M%S")

ap_story = list()

url = "https://api.gdeltproject.org/api/v2/doc/doc?mode=artlist&maxrecords=250&FORMAT=CSV&query=sourceCountry:US"
for (j in 1:length(title)) {
  url1 = URLencode(paste(url, ' "', title[j], '"', "&STARTDATETIME=", stdatetime[j], "&ENDDATETIME=", enddatetime[j], sep=""))
  s = GET(url1)
  cat("Processing record", j, "from", length(title), "Status code", status_code(s), "\n")
  if (status_code(s) == 200) {
    w = httr::content(s, as="text")
    ap_story[[j]] = read.csv(header=F, stringsAsFactors = F, text=w)
  }
}


res = data.frame()
for (j in 1:length(title)) {
  if (length(names(ap_story[[j]])) == 4) {
    tmp = ap_story[[j]]
    names(tmp) = c("URL", "Mobile", "Date", "Title")
    tmp$AP_Date = dt[j]
    tmp$AP_Title = title[j]
    res = rbind.fill(res, tmp)
  }
}

tmp = regexpr("^http[s]?://.*?/", res$URL)
tmp_t = regmatches(res$URL, tmp)

res$Domain = tmp_t 

p = res$URL == "URL"
res = res[!p, ]

res$Date = ymd_hms(res$Date)

## time difference between original story and repost, in minutes
res$Time_Dif = difftime(res$Date, res$AP_Date, units = "mins")

res$Domain = ''
## slow... really slow...
#for(j in 1:nrow(res)){
  #res$Domain[j] = strsplit(gsub("http://|https://|www\\.", "", res$URL), "/")[[c(j,1)]]
  #cat("Extracting domain", j, "from", nrow(res), "\n")
#}

## same as above, just using newer package: urltools
res$Domain = domain(res$URL)

sum_domains = table(unlist(res$Domain))
domaindf = data.frame(sum_domains)
res = merge(res, domaindf, by.x = "Domain", by.y = "Var1", all = F)

res$Mobile = NULL
names(res)[names(res)=='Freq'] = "Domain_Frequency"

write.csv(res, "/Users/KevinM/Desktop/Data Project/nov_reposts.csv", row.names=F)
save(file="/Users/KevinM/Desktop/Data Project/nov_reposts.RData",
     list=c("res", "ap_story", "title", "info", "datetime"))

library(dplyr)
library(ggplot2)

## Frequency Plot
## It seems as though the top four domains, 1310news, news957, 660news, 570news, are all erroneous...
## This is likely because of their website layout in which they present a page of various links, most of which are unrelated to our story
domaindf = domaindf[order(-domaindf$Freq), ]
top_freq = ggplot(data = domaindf[1:20, ], aes(x = Freq, y = reorder(Var1, Freq))) + geom_point(color = "darkorange") +
  geom_segment(aes(x = 0, y = Var1, xend = Freq, yend = Var1), color = "grey50") + labs(y = "Domain Name", x = "Repost Frequency",
                                                                                        title = "Domains With Highest Frequency", subtitle = "(of reposts from The Associated Press)", caption = "Data Source: LexisNexis \n Author: Kevin McMorrow")
plot(top_freq)


## Time difference plot 
tempdf = data.frame("Domain" = domaindf$Var1[1:20], "Time_Dif" = '')

## find average time_difference for top 20 repost outlets
for(i in 1:nrow(tempdf)){
  tempdf$Time_Dif[i] = mean(res$Time_Dif[res$Domain == tempdf$Domain[i]])
}

time = ggplot(data = tempdf, aes(x = Domain, y = Time_Dif)) + geom_bar(stat="identity", fill = 'cornflowerblue') + coord_flip() + labs(x = 'Average Time Difference', y = 'Domain Name', title = 'Average Time Difference Between Original Story and Reposted Story', subtitle = '(from news outlets with highest repost frequency)', caption = 'Data Source: LexisNexis \n Author: Kevin McMorrow')
plot(time)
