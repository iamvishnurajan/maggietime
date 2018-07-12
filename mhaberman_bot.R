#
#  NYT SCRAPER
#  THIS WILL FETCH AND POPULATE A DB TABLE FOR
#  ARTICLES BY THE SPECIFIED AUTHORS AND TWEET AS NEW
#  ARTICLES ARE DETECTED
#  

#  START TIME AND LOAD LIBRARIES

library(rvest)
library(rtweet)
library(lubridate)
library(plyr)
library(dplyr)

Sys.setenv(TZ='America/New_York')

#  USER CONFIGURABLE INPUT PARAMETERS

# Edit these  lines for the respective directory locations
# It is suggested to make backups as subdirectories of the main_dir
# i.e., bkup_dir = /main_dir/backups/
# Note - you must include the trailing slash and you must leave the quotation marks
main_dir <- "INSERT A DIRECTORY NAME HERE"
bkup_dir <- "INSERT A BACKUP DIRECTORY NAME HERE"

# For the file that will be saved and used for comparison to check for new articles
# what should the name be. For example, if you wanted to create a bot for Ronan Farrow,
# we could use just "rfarrow" here. The code will take care of adding
# any necessary extensions (i.e., "rfarrow.csv")
filename_header <- "mhaberman"

# List the author URL tag. For NYT, the full URL is 
# "https://www.nytimes.com/by/maggie-haberman". We just need to list the 
# "maggie-haberman" portion here. The code will take care of the rest.
authorstring = "maggie-haberman"

# What do you want the bot to say when it tweets.
whattimeisit = "#maggietime"

# Replace "INSERT YOUR TWITTER TOKEN FILENAME" with your twitter token file name
# As noted below, it is suggested to place this file in the main_dir
# See http://rtweet.info/articles/auth.html on how to create this twitter token
# You must leave the quotation marks and list your filename within those
twitter_token <- readRDS(paste0(main_dir,"INSERT YOUR TWITTER TOKEN FILENAME"))

# How frequently the loop should check for new articles
# The number here is how many seconds the loop will "sleep"
# in between checks
sleep_loop = 15

###  NOTHING BELOW THIS SHOULD NEED TO GET EDITED ###

#  INITIALIZATIONS

sink_msgs <- file(paste0(main_dir,"std_msgs.txt"), open="at")
sink(sink_msgs,type=c("message"),append = TRUE)
sink(sink_msgs,type=c("output"),append = TRUE)

tweet_max <- 275

#  INFINITE LOOP; WE WRITE THIS TO RUN EFFECTIVELY FOREVER
#  IF LOOP BROKEN HOWEVER DUE TO SYSTEM RESTART, ETC.
#  IT CAN PICKUP FROM WRITTEN .CSV FILE

while (Sys.Date() < "2200-01-01") {
  nyt_file <- paste0(main_dir,filename_header,".csv")
  nyt_file_bkup <- paste0(bkup_dir,filename_header,"_",format(Sys.time(), "%Y%m%d_%H%M%S"),".csv")
  nyt_file_csv <- read.csv(nyt_file, header = TRUE, sep = ",", check.names=FALSE, stringsAsFactors = FALSE)
  
  #  .CSV AND OTHER INITIALIZATIONS AND LINK SCRAPE LOOP
  
  nyt_file_csv$pub_date <- ymd(nyt_file_csv$pub_date)
  nyt_df0 <- nyt_file_csv
  
  nyt_diff <- anti_join(nyt_df0,nyt_df0,by=c("fulllink"))
  loop_count = 0
  
  while (nrow(nyt_diff)==0){
    nytstarttime <- proc.time()
    
    nytpage=read_html(paste0("https://www.nytimes.com/by/",authorstring))
    nytmain <- nytpage %>% html_nodes(xpath="//section[contains(@id,'latest-panel')]") %>% html_nodes(".theme-stream.initial-set")
    
    nyt_url_base <- sapply(nytmain,function(x) x  %>% html_nodes("a") %>% html_attr("href"))
    nyt_df <- data.frame("fulllink" = nyt_url_base,stringsAsFactors = FALSE)
    
    nyt_df <- nyt_df %>% mutate(
      headline = trimws(gsub("[\r\n]","",nytmain %>% html_nodes("h2") %>% html_text)),
      description = trimws(gsub("[\r\n]","",nytmain %>% html_nodes(".summary")  %>% html_text)),
      byline = trimws(gsub("[\r\n]","",nytmain %>% html_nodes(".byline")  %>% html_text)),
      tweet_text = paste0("It's ",whattimeisit,": ",headline,"\n",fulllink),
      num_char = nchar(tweet_text))
    
    nyt_df$pub_date <- ymd(gsub("/","-",gsub("^([^/]*/[^/]*/[^/]*).*", "\\1", gsub("https://www.nytimes.com/","",nyt_df$fulllink))))
    nyt_df <- nyt_df %>% group_by(pub_date) %>% mutate(pub_count = max(n())-seq(n())+1)
    
    nyt_df$tweet_text <- 
      ifelse(nyt_df$num_char > tweet_max,
             paste0("It's ",whattimeisit,": ",strtrim(nyt_df$headline,nchar(nyt_df$headline)-(nyt_df$num_char-tweet_max-3)),"...\n",nyt_df$fulllink),
             nyt_df$tweet_text)
    
    #  COMPARISONS AND DIFF
    
    nyt_df0 <- nyt_df0[order(nyt_df0$pub_date,nyt_df0$pub_count),]
    nyt_df <- nyt_df[order(nyt_df$pub_date,nyt_df$pub_count),]
    
    nyt_diff <- anti_join(nyt_df,nyt_df0,by = c("fulllink"))
    
    if (nrow(nyt_diff)>0) {
      for(nyttidx in 1:nrow(nyt_diff)) {
        post_tweet(status = nyt_diff$tweet_text[nyttidx],token = twitter_token)
      }
    }
    
    if(nrow(nyt_diff)>0){
      nyt_df <- bind_rows(nyt_df0,nyt_diff)
      
      nyt_df0 <- nyt_df0[order(nyt_df0$pub_date,nyt_df0$pub_count,decreasing = TRUE),]
      write.csv(nyt_df0,file = nyt_file_bkup,row.names=FALSE)
      
      nyt_df <- nyt_df[order(nyt_df$pub_date,nyt_df$pub_count,decreasing = TRUE),]
      write.csv(nyt_df,file = nyt_file,row.names=FALSE)
    }
    
    # FINAL TIME TO RUN CALCULATION
    
    if (nrow(nyt_diff)>0 | loop_count==((5*60)/sleep_loop)){
      nytendtime <- proc.time() - nytstarttime
      nytendsecs <- nytendtime[3]
      print(nytendsecs)
      print(Sys.time())
      cat("\n\n")
      if (loop_count==((5*60)/sleep_loop)){
        loop_count = 0
      }
    }
    
    loop_count = loop_count+1
    Sys.sleep(sleep_loop)
  }
}

sink(type="message")
sink(type="output")
close(sink_msgs)