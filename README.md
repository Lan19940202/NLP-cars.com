# cars.com-sentiment analysis

This project is one of the three mini projects of Advance Business Analysis using R course, and the analysis object of this project is Toyota Camry (2012-2017):

In that project, I created a user interface using Shiny App to visualize my outcome. [server.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/server.R) and [ui.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/ui.R) are files of the Shiny App. The Shiny App can not only do sentiment analysis for Toyota Camry car review data but also allows users to give the car's Make, Model and Year they would like to explore. Then, the Shiny App would automatically do the analyses below:
* Download the rates and reviews;
* Calculate the average star and sentiment score of each review. The sentiment score is calculated by directly adding the positive & negative sentiment score of each word in the review;
* Count the TF-IDF score for four features - Service, Price, Handling, Interior - since they are the primary concerns when consumer selecting their ideal car;
* Build a model with K Nearest Neighbor to predict the star rating of review by its sentiment score.


references:
* Web crawler: [Beginner’s Guide on Web Scraping in R (using rvest) with hands-on example](https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/)
* Sentiment analysis: [Text Mining with R](https://www.tidytextmining.com/)
