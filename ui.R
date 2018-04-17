ui <- fluidPage(
  # themes
  theme = shinytheme('sandstone'),
  # App title
  titlePanel("Lan_Wei_NLP_Project"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      textInput('website','Web Address:', 'https://www.cars.com/research/toyota-camry/'),
      actionButton('do', 'DownLoad')
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      tabsetPanel(
        # tabPanel('training data', numericInput('row1', 'Number of Rows', 5, min = 1),
        #          tableOutput('training')),
        # tabPanel('testing data',  numericInput('row2', 'Number of Rows', 5, min = 1),
        #          tableOutput('testing')),
        tabPanel('Normalized',  numericInput('row3', 'Number of Rows (TRAIN)', 3, min = 1),
                 tableOutput('normalized_train'),
                 numericInput('row4', 'Number of Rows (TEST)', 3, min = 1),
                 tableOutput('normalized_test')),
        tabPanel('Tags', h3("Tags: service, price, handling, interior"),
                 numericInput('row5', 'Number of Rows (TRAIN)', 3, min = 1),
                 tableOutput('tag_train'),
                 numericInput('row6', 'Number of Rows (TEST)', 3, min = 1),
                 tableOutput('tag_test')),
        tabPanel('Sentiment Score',  numericInput('row7', 'Number of Rows (TRAIN)', 3, min = 1),
                 tableOutput('sentiment_train'),
                 numericInput('row8', 'Number of Rows (TEST)', 3, min = 1),
                 tableOutput('sentiment_test')),
        tabPanel('Average', h3("Average Rating (TRAIN)"), verbatimTextOutput('train_senti_score'),
                 h3("Average Rating (TEST)"), verbatimTextOutput('test_senti_score'),
                 h3("Average Rating for 4 tags (TRAIN)"), tableOutput('average_train'),
                 h3("Average Rating for 4 tags (TEST)"), tableOutput('average_test'),
                 h3('The sentiment score and star rating of the four tags are basically higher than the average rating and sentiment score of all reviews totally. Therefor, we can infer that thses four features provid user withd excellent experience.')),
        tabPanel('Prediction', h3("Apply KNN: "),
                 plotOutput('plot'), verbatimTextOutput('confusion_matrix')),
        tabPanel('TF_IDF', plotOutput('plot_TFIDF'))
      )
    )
  )
)