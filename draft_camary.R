# install.packages('rvest')
# install.packages('tidytext')
# install.packages('dplyr')
# install.packages('tidytext')
# install.packages('tidyr')
# install.packages('ggplot2')
# install.packages('nnet')
# install.packages('caret')
# install.packages('class')

library('rvest')
library('tidytext')
library('dplyr')
library('tidyr') #separate_rows
library('ggplot2')
library('nnet') # multinom
library('class')
library('stringr')
#library('caret') #confusionMatrix
#scrapign data from certain web page
scraping <- function(url){
  webpage <- read_html(url)
  #rating
  star <- webpage %>% html_nodes('header cars-star-rating') %>% 
    html_attr('rating') %>% as.numeric()
  
  #review
  review_text <- webpage %>% html_nodes('header div.mmy-reviews__blurb span') %>% 
    html_text()
  #head(review_text)
  
  #date  
  date <- webpage %>% html_nodes('header p span.mmy-reviews__date meta') %>% 
    html_attr('content')
  year <- gsub(".*, ","",date) %>% as.numeric()
  #head(year)
  
  df<-data.frame(Rating = star, Year = year,Review = review_text)
  return(df)
}


#Next Page
#t<-next_page('https://www.cars.com/research/toyota-camry-2018/consumer-reviews/?pg=19&nr=10')
next_page <- function(url){
  webpage <- read_html(url)
  Next <- webpage %>% html_nodes('div.paginationButtonContainer a:nth-child(2)') %>% 
    html_attr('href')
  return (Next)
}




#url_ori <- https://www.cars.com/research/toyota-camry/
year_scraping <- function(url_ori, years){
  url_ori <- substr(url_ori, 1, nchar(url_ori)-1)
  df <- data.frame(Rating=numeric(0), Year=numeric(0), Review=character(0))
  for (year in years)
  {
    url <- paste(url_ori, '-', year, '/consumer-reviews/', sep = "")
    print(year)
    df1 <- scraping(url)
    df <- rbind(df, df1)
    nextpage <- next_page(url)
    repeat{
      df_2 <- scraping(paste(url, nextpage, sep = ""))
      df <- rbind(df, df_2)
      print(nrow(df))
      nextpage <- next_page(paste(url, nextpage, sep = ""))
      if (nextpage==''){
        break
      }
    }
  }
  return(df)
}


url<-'https://www.cars.com/research/toyota-camry/'
training<-year_scraping(url, c(2012:2016))
testing<-year_scraping(url, c(2017))

normalize <- function(df) {
  #data(stop_words)
  df$Normalized = tolower(gsub("[[:punct:]]", " ", df$Review)) #%>% anti_join(stop_words)
  return(df)
}

#training$Normalized %>% anti_join(stop_words)

training <- normalize(training)
testing <- normalize(testing)

# Token
get_token<-function(df){
  df<-df %>% unnest_tokens(tag, Normalized)
  return(df)
}

training2 <- get_token(training)
testing2 <- get_token(testing)

# Tags: 'service','price', 'handling', 'interior'
TAG <- c('service', 'price', 'handling', 'interior')
get_tag <- function(df, TAG){
  df <- filter(df, tag %in% TAG)
  return(df)
}

training3 <- get_tag(training2, TAG)
testing3 <- get_tag(testing2, TAG)

# Remove duplicated and merge tags
merge_tag<-function(df){
  df<-df[!duplicated(df), ]
  df<-df %>% group_by(Rating, Year, Review) %>% summarise(tags = paste(tag, collapse=", "))
  return(df)
}

training4<-merge_tag(training3)
testing4<-merge_tag(testing3)


training <- left_join(training, training4, by = c('Rating', 'Year', 'Review'))
testing <- left_join(testing, testing4, by = c('Rating', 'Year', 'Review'))

# sentiment score
sentiment_score<-function(df){
  sentiment <- df %>% unnest_tokens(word, Normalized, drop = FALSE) %>% 
    inner_join(get_sentiments("afinn"), by='word') %>% 
    group_by(Normalized) %>% 
    summarise(Year = mean(Year), sentiment = sum(score), star_rating = mean(Rating))
  return(sentiment)
}

training5 <- sentiment_score(training)
testing5 <- sentiment_score(testing)
# training5 <- training %>% unnest_tokens(word, Normalized, drop = FALSE) %>% 
#   inner_join(get_sentiments("afinn"), by='word') %>% 
#   group_by(Normalized) %>% 
#   summarise(Year = mean(Year), sentiment = sum(score), star_rating = mean(Rating)) ##### mean??
#   
# testing5 <- testing %>% unnest_tokens(word, Normalized, drop = FALSE) %>% 
#   inner_join(get_sentiments("afinn"), by='word') %>% 
#   group_by(Normalized) %>% 
#   summarise(Year = mean(Year), sentiment = sum(score), star_rating = mean(Rating))
#summarise(Year = mean(Year), sentiment = sum(score), star_rating = mean(Rating))


#training <- inner_join(training, training5, by = c('Normalized'))
#testing <- inner_join(testing, testing5, by = c('Normalized'))

# average sentiment rating
sentiment_avg_train <- mean(training5$sentiment)
sentiment_avg_test <- mean(testing5$sentiment)
# average star rating
star_avg_train <- mean(training5$star_rating)
star_avg_test <- mean(testing5$star_rating)

#compute the average for each tags
tag_average <- function(df){
  df6 <-  df %>% separate_rows(tags) %>%
    inner_join(sentiment_score(df), by = c('Normalized', 'Year'))

  tags_avg <- df6 %>% group_by(tags) %>% summarise(sentiment = mean(sentiment), star_rating = mean(star_rating))
  tags_avg$average_star <- rep(mean(sentiment_score(df)$star_rating))
  return(tags_avg)
}
#train
tags_avg_train <- tag_average(training)
#test
tags_avg_test <- tag_average(testing)

# Build a model to predict the star rating
plot(training5$star_rating, training5$sentiment, 
     xlab = 'Star Rating', ylab = 'Sentiment Score') + 
  title('Star Rating and Sentiment Score') 
# Multinomial regression
re <- multinom(star_rating ~ sentiment, data=training5)
summary(re)

sentiment <- data.frame(sentiment = training5$sentiment)
pre_rating <- predict(re, sentiment)

sentiment_test <- data.frame(sentiment = testing5$sentiment)
pre_rating <- predict(re, sentiment_test)
test<-table(pre_rating, testing5$star_rating)
test
# KNN 
sentiment2 = sentiment[ ,1]
sentiment_test2 = sentiment_test[ ,1]
prc_test_pred <- knn(train = sentiment2, test = sentiment_test,cl = training5$star_rating, k=5)

test2<-table(Predicted = prc_test_pred, Actual = testing5$star_rating)
test2


# TF-IDF
TF_IDF <-  subset(training, !is.na(training$tags)) %>% separate_rows(tags) %>% 
  unnest_tokens(word, Normalized, drop = FALSE) %>% 
  anti_join(stop_words, by='word') %>% filter(!str_detect(word, "[:punct:]|[:digit:]")) %>%
  count(tags, word, sort = TRUE) %>% bind_tf_idf(word, tags, n)


# Get top 10 TF-IDF for each tags
top10 <- TF_IDF %>%
  arrange(desc(tf_idf)) %>%
  group_by(tags) %>%
  slice(seq_len(10)) %>%
  ungroup %>%
  mutate(r = row_number())

# visualization
top10 %>% ggplot(aes(-r, tf_idf, fill = tags)) +
  scale_x_continuous(  # This handles replacement of .r for x
    breaks = -top10$r,     # notice need to reuse data frame
    labels = top10$word
  ) +
  geom_col(show.legend = FALSE) +
  labs(x = NULL, y = "tf-idf") +
  facet_wrap(~tags, ncol = 2, scales = "free") +
  coord_flip()