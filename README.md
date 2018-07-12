# maggietime
R code for bot that tweets at https://twitter.com/maggiet1m3

This code polls Maggie Haberman's author page at New York Times (https://www.nytimes.com/by/maggie-haberman), and tweets when there is a new article.

Install and Setup Guidance:

The info below is designed for an Linux/Ubuntu setup. It can likely be adpated with little change for MacOS as well.

R prerequisite libraries: rvest, rtweet, lubridate, plyr, dplyr

Save the R code to a directory. i.e., /Users/mhaberman_bot/mhaberman_bot.R

Edit the lines at the top of the code under the "USER CONFIGURABLE INPUT PARAMETERS" section This is done as follows:
1a. Directories: Pick whatever works for you. A suggested structure and notes are listed in the code comments.

1b. Filename: For the file that will be saved and used as the ongoing base to check for new articles, what do you want the filename to be

1c. Author String: List the author URL on New York Times. For Maggie Haberman, the full URL is https://www.nytimes.com/by/maggie-haberman. Just list the "maggie-haberman" portion here.

1d. Bot Tweet: What do you want the early porton of the tweet to say when the bot tweets.

1e. Twitter token: If you do not have an rtweet twitter token, the method for obtaining and saving one is here: http://rtweet.info/articles/auth.html

Save and rename the provided initial .csv file to the main_dir. This should be consistent with the file naming above in (1b). i.e., so if we picked "mhaberman" above, we should ensure the file name is named mhaberman.csv.

Create an empty file where errors can be logged. The file must be in the main_dir and must be specifically named std_msgs.txt (Linux/Ubuntu command to do this: touch std_msgs.txt)

At this time, if you run the code, it will populate the file and generate tweets for the articles since the initial .csv was generated (July 11, 2018).

If you want to continue polling and tweeting, schedule as needed with crontab (or other scheduling tool). Suggested run frequency is every 5-10 minutes.
