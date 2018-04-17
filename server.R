library('shiny')
library('shinythemes')
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
      # print(nrow(df))
      nextpage <- next_page(paste(url, nextpage, sep = ""))
      if (nextpage==''){
        break
      }
    }
  }
  return(df)
}


# url<-'https://www.cars.com/research/toyota-camry/'

normalize <- function(df) {
  #data(stop_words)
  df$Normalized = tolower(gsub("[[:punct:]]", " ", df$Review)) #%>% anti_join(stop_words)
  return(df)
}

# Token
get_token<-function(df){
  df<-df %>% unnest_tokens(tag, Normalized)
  return(df)
}


# Tags: 'service','price', 'handling', 'interior'
get_tag <- function(df, TAG){
  df <- filter(df, tag %in% TAG)
  return(df)
}


# Remove duplicated and merge tags
merge_tag<-function(df){
  df<-df[!duplicated(df), ]
  df<-df %>% group_by(Rating, Year, Review) %>% summarise(tags = paste(tag, collapse=", "))
  return(df)
}


# sentiment score
sentiment_score<-function(df){
  sentiment <- df %>% unnest_tokens(word, Normalized, drop = FALSE) %>% 
    inner_join(get_sentiments("afinn"), by='word') %>% 
    group_by(Normalized) %>% 
    summarise(Year = mean(Year), sentiment = sum(score), star_rating = mean(Rating))
  return(sentiment)
}

#compute the average for each tags
tag_average <- function(df){
  df6 <-  df %>% separate_rows(tags) %>%
    inner_join(sentiment_score(df), by = c('Normalized', 'Year'))
  
  tags_avg <- df6 %>% group_by(tags) %>% summarise(sentiment = mean(sentiment), star_rating = mean(star_rating))
  tags_avg$average_star <- rep(mean(sentiment_score(df)$star_rating))
  return(tags_avg)
}

server <- function(input, output) {
  #REACTIVE
  website <- renderText({ as.character(input$website) })
  train <- eventReactive(input$do, {
    year_scraping(website(), c(2012:2016))
  }
  )
  test <- eventReactive(input$do, {
    year_scraping(website(), c(2017))
  })
  train_tags <- eventReactive(input$do, {
    training <- normalize(train())
    training2 <- get_token(training)
    TAG <- c('service', 'price', 'handling', 'interior')
    training3 <- get_tag(training2, TAG)
    training4 <- merge_tag(training3)
    left_join(training, training4, by = c('Rating', 'Year', 'Review'))
  })
  test_tags <- eventReactive(input$do, {
    testing <- normalize(test())
    testing2 <- get_token(testing)
    TAG <- c('service', 'price', 'handling', 'interior')
    testing3 <- get_tag(testing2, TAG)
    testing4 <- merge_tag(testing3)
    left_join(testing, testing4, by = c('Rating', 'Year', 'Review'))
  })
  train_sentiment <- eventReactive(input$do, {
    sentiment_score(train_tags())
  })
  test_sentiment <- eventReactive(input$do, {
    sentiment_score(test_tags())
  })
  tf_idf <- eventReactive(input$do, {
    TF_IDF <-  subset(train_tags(), !is.na(train_tags()$tags)) %>% separate_rows(tags) %>% 
      unnest_tokens(word, Normalized, drop = FALSE) %>% 
      anti_join(stop_words, by='word') %>% filter(!str_detect(word, "[:punct:]|[:digit:]")) %>%
      count(tags, word, sort = TRUE) %>% bind_tf_idf(word, tags, n)
    TF_IDF
  })
  tf_idf_top10 <- eventReactive(input$do, {
    top10 <- tf_idf() %>%
      arrange(desc(tf_idf)) %>%
      group_by(tags) %>%
      slice(seq_len(10)) %>%
      ungroup %>%
      mutate(r = row_number())
    top10
  })
  #OUTPUT
  output$training <- renderTable(
    {
      head(train(), n = input$row1)
    }
  )
  # output$row_number1 <- renderPrint(
  #   {
  #     print(paste0('Number of Reviews: ',nrow(train())))
  #   }
  # )
  output$testing <- renderTable(
    {
      head(test(), n = input$row2)
    }
  )
  # output$row_number2 <- renderPrint(
  #   {
  #     print(paste0('Number of Reviews: ',nrow(test())))
  #   }
  # )
  output$normalized_train <- renderTable(
    {
      head(normalize(train()), n = input$row3)
    }
  )
  
  output$normalized_test <- renderTable(
    {
      
      head(normalize(test()), n = input$row4)
    }
  )
  output$tag_train <- renderTable(
    {
      head(train_tags(), n = input$row5)
    }
  )
  output$tag_test <- renderTable(
    {
      head(test_tags(), n = input$row6)
    }
  )
  output$sentiment_train <- renderTable(
    {
      head(train_sentiment(), n = input$row7)
    }
  )
  output$sentiment_test <- renderTable(
    {
      head(test_sentiment(), n = input$row8)
    }
  )
  output$train_senti_score <- renderPrint(
    {
      print('Sentiment Rating:')
      print(mean(train_sentiment()$sentiment))
      print('Star Rating:')
      print(mean(train_sentiment()$star_rating))
    }
  )
  output$test_senti_score <- renderPrint(
    {
      print('Sentiment Rating:')
      print(mean(test_sentiment()$sentiment))
      print('Star Rating:')
      print(mean(test_sentiment()$star_rating))
    }
  )
  output$average_train <- renderTable(
    {
      head(tag_average(train_tags()),4)
    }
  )
  output$average_test <- renderTable(
    {
      head(tag_average(test_tags()),4)
    }
  )
  output$plot <- renderPlot(
    {
      plot(train_sentiment()$star_rating, train_sentiment()$sentiment, 
           xlab = 'Star Rating', ylab = 'Sentiment Score') + 
        title('Star Rating and Sentiment Score') 
    }
  )
  output$confusion_matrix <- renderPrint(
    {
      sentiment <- data.frame(sentiment = train_sentiment()$sentiment)
      sentiment_test <- data.frame(sentiment = test_sentiment()$sentiment)
      sentiment2 = sentiment[ ,1]
      sentiment_test2 = sentiment_test[ ,1]
      prediction <- knn(train = sentiment2, test = sentiment_test, 
                           cl = train_sentiment()$star_rating, k=5)
      
      table(Predicted = prediction, Actual = test_sentiment()$star_rating)
    }
  )
  output$plot_TFIDF <- renderPlot(
    {
      tf_idf_top10() %>% ggplot(aes(-r, tf_idf, fill = tags)) +
        scale_x_continuous(  # This handles replacement of .r for x
          breaks = -tf_idf_top10()$r,     # notice need to reuse data frame
          labels = tf_idf_top10()$word
        ) +
        geom_col(show.legend = FALSE) +
        labs(x = NULL, y = "tf-idf") +
        facet_wrap(~tags, ncol = 2, scales = "free") +
        coord_flip()
    }
  )
}