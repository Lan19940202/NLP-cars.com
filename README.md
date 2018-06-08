# cars.com-sentiment analysis

This project is initially one of the three mini projects of Advance Business Analysis using R course and the analysis object of this project is Toyota Camry (2012-2017). 
In this project, I created a user interface using shiny App to visualize my outcome. [server.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/server.R) and [ui.R](https://github.com/Lanwei02/NLP-cars.com/blob/master/ui.R) are files of the Shiny App. The Shiny App allows users to give the car's Make, Model and Year that they would like to analyze. Then, the Shiny App would automatically download the rate and review, calculate the average rate score and sentiment score, count the TF-IDF score for four features which are most concerned by customers(Service, Price, Handling, Interior), and build a model based on customer review to predict the star.

However, since the available Carmy user reviews are too less for doing sentiment analysis, the accuracy of the prediction model is very low. Therefor, after dinished ths project, I updated the scapper and 
