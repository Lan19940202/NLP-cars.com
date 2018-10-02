# cars.com-sentiment analysis

This project is one of the three mini projects of Advance Business Analysis using R course, and the analysis object of this project is Toyota Camry (2012-2017):

In that project, I created a user interface using Shiny App to visualize my outcome. [server.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/server.R) and [ui.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/ui.R) are files of the Shiny App. The Shiny App can not only do sentiment analysis for Toyota Camry car review data but also allows users to give the car's Make, Model and Year they would like to explore. Then, the Shiny App would automatically do the analyses below:
* Download the rate and review;
* Calculate the average star rate score and sentiment score by adding the positive & negative score of each word in each review;
* Count the TF-IDF score for four features which are most concerned by customers(Service, Price, Handling, Interior);
* Build a model based on the calculated sentiment score to predict the star.


references:
* Web crawler: [Beginner’s Guide on Web Scraping in R (using rvest) with hands-on example](https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/)
* Sentiment analysis: [Text Mining with R](https://www.tidytextmining.com/)
