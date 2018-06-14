library('rvest')
#scrapign data from certain web page
scraping <- function(url){
  webpage <- read_html(url)
  print('read url :')
  print(url)
  #rating
  rate <- webpage %>% html_nodes('article cars-star-rating') %>% 
    html_attr('rating') %>% as.numeric()
  rate <- rate[seq(1, length(rate), 7)]
  print('get rate')
  print(length(rate))
  
  #review
  review_text <- webpage %>% html_nodes('p.review-card-text') %>% 
    html_text()
  #head(review_text)
  print('get review')
  print(length(review_text))
  
  #date  
  user_date_area <- webpage %>% html_nodes('p.review-card-review-by') %>% html_text()
  #head(year)
  print('get date')
  print(length(user_date_area))
  
  # car_brand
  car_brand <- substring(url, 31)
  car_brands <- rep(car_brand, length(user_date_area))
  
  df<-data.frame(Rating = rate, Year = user_date_area, Review = review_text, Brand = car_brands)
  return(df)
}


#Next Page
next_page <- function(url){
  webpage <- read_html(url)
  Next <- webpage %>% html_nodes('div.page-buttons a:nth-child(2)') %>% html_attr('href')
  print(Next)
  return (Next)
}


year_scraping <- function(url_ori, years){
  url_ori <- substr(url_ori, 1, nchar(url_ori)-1)
  print(url_ori)
  df <- data.frame(Rating=character(0), Year=character(0), Review=character(0), Brand=character(0))
  for (year in years)
  {
    url <- paste(url_ori, '-', year, '/consumer-reviews/', sep = "")
    print(year)
    df1 <- scraping(url)
    df <- rbind(df, df1)
    print('Get first page')
    nextpage <- next_page(url)
    repeat{
      df_2 <- scraping(paste('https://www.cars.com', nextpage, sep = ""))
      print('already get next page')
      df <- rbind(df, df_2)
      print(nrow(df))
      nextpage <- next_page(paste('https://www.cars.com', nextpage, sep = ""))
      if (identical(nextpage, character(0))){
        break
      }
    }
  }
  return(df)
}


