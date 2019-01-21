# NBA_Back_to_Back_Analysis
A statistical analysis on player efficiency in the second games of Back to Backs in the NBA

In recent years, the NBA has focused on limiting the number of Back to Backs (playing two games on two consecutive days) that players and teams participate in. Star players would often sit out the second game not wanting to fatigue themselves for a hopeful playoff run, or worse, injure themselves. While those are very valid concerns, and a good reason to reduce the number of games, I wanted to see if players played differently due to the fatigue. 
Measuring since 2012 and through the end of the 2017- 2018 season, what I first wanted to do was see if there was any correlation between the exhaustion the players might feel and a change (probably decrease) in efficiency. To best measure exhaustion I decided to use combined minutes played over the two games of the back to back. To measure efficiency, I first decided to analyze the following stat categories: points, assists, turnovers, steals, blocks, fouls, FG%, FT%, offensive rebounds, and total rebounds, converting the counting stats into per 36 minutes figures to normalize for time played and find how efficiently players were using their time on the court. I also looked at 2 and 3 pointers attempted, FT attempted, and Free Throw Rate to see if more minutes affected the choices players made e.g. pulling up for 3 more and not wanting to drive in the paint. To measure how efficiency changed, I found each players average stats in each category that wasn’t from the second game of a back to back and compared it to that stat category for each second game of a back to back creating categories such as Change in Points per 36 and Change in FT%. I considered just comparing the stats of the first game to the second game, but I decided I would rather have more accurate average stat categories considering that exhaustion levels in the first game of a back to back should be the same as any other game with days rest before it. I also eliminated any game pair where the player didn’t play at least 40 minutes over the two games, since per 36 stats can get pretty volatile with too few minutes and we don’t want too many of the minutes to come from the same game since that would eliminate the tiredness aspect of a back to back. You can find the data for each category in the .tsv files, each row representing a different back to back for a specific player.

I then made a scatterplot of each category with combined minutes on the x-axis and change in category on the y-axis which can be found here: https://public.tableau.com/profile/scott.fields#!/vizhome/B2BVisualizations/Points . You can hover over any dot and see all the information about that game including player, date, and stat information. You may also notice the line of best fit which on most of the graphs looks eerily similar to the x axis and that’s because on all of the comparisons I made, none has a strong correlation with the highest r-squared of the bunch being .005. But we can still learn some interesting things from these graphs. For instance, you may notice how on most of the categories, as total minutes increases, the residuals shrink for a narrowing effect. What does this mean? 1. NBA coaches know what they are doing. If a coach sees his player performing very inefficiently, he probably won’t play him as many minutes and that’s why you don’t see many low changes in efficiency with huge minutes. Although I don’t have any hard data to back this up, it would also make sense that the huge gains we see in the 40 – 55 minutes played range could perhaps come from players who would normally play 25 – 40 minutes in a two-game stretch and the coach sees this increase in efficiency and lets them play more. 2. As players play more and more data is collected, they tend to revert towards their averages thus, the closing in on a zero change in efficiency. Also worth noting is that starters on average only played 12 seconds less per game in the second game of a back to back than normal so their isn’t evidence to suggest key players are being played less in order to keep their efficiency normal.
So, even though using this method of measuring their appears to be no correlation between back to backs and on-court product, we can still compare players to see who did the best by category and in general. So, I took the players by category and the people with at least 40 pairs of back to backs to narrow down our pool to about 200 players and then ranked them in each category based on average change in that category. You can find these ranks in the Final_Ranks.xlsx.  I then took all the positive stats ranks (not shot attempts or free throw rate since having more or less of these isn’t inherently better) and found each person’s average ranks and ranked them overall. Does this overall ranking show who are the best players in the second games of back to backs? No, it only shows who improves the most vs. themselves, the worst player in the league could be first on this list as long as their best games came in the second game of a back to back. Is this overall ranking an accurate picture as to who improves the most in the second game of a back to back? Probably not since there’s a valid argument to say that as a PG there is more value to improving your assists or points over offensive rebounds. But I’m not here to play God and assign arbitrary weights to different categories, so I suppose you could say that this is a ranking of the best versatile improvers in the second games of back to backs since 2012. 
If I were to try this again, I may decide to compare only minutes of the first game and see if that alone affects performance in the second game, so that coaching decisions to give more minutes due to play in the second game don’t affect the minutes category. I also may change the change in efficiency categories to be based off of standard deviations away form the mean assuming that their normal stats distribution fell along a normal curve. 

Box Score Data from: https://www.kaggle.com/pablote/nba-enhanced-stats#2012-18_teamBoxScore.csv 
