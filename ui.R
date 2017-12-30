library(shiny)
cat(file=stderr())
shinyUI(fluidPage(
        theme = "style.css",
        
        titlePanel(div("Next Word Prediction", class="title"),
                   windowTitle = "Word Prediction App"),
        tags$head(tags$script(src="index.js")),
        hr(),
        
        fluidRow(column(10, offset=1,
                 tabsetPanel(type = "tabs",
                                   tabPanel("App",
                                            textInput("text", label = "", placeholder="Type"),
                                            fluidRow(
                                                    column(6,
                                                           actionButton("predict", "Guess my next word"),
                                                           p("I think your next word would be one of these ...",class="outputText"),
                                                           tableOutput("table")
                                                    )
                                            )
                                            
                                   ),
                                   tabPanel("Documentation",
                                            div(
                                                h3('Instructions'),
                                                p('The application Interface contains a text box and an output panel. As soon as you complete a word and put a space after that, the application will display the most relevant suggestions in the bottom panel for the word you might want to type next in decreasing order of their probability.'),
                                                span('* If you want to force the prediction anytime, please press Enter.',class="note"),
                                                class="instruction"),
                                            div(h3('How it works'),
                                                p('Three types of Engish text datasets (News,Blogs and Twitter) are used to build the n-gram model. When a user types a word, the application performs initial data cleaning on the input text such as removing the special characters, number, punctuation marks and extra spaces. Afterwards it checks the number of words in the input text based on the number of words it finds the relevant n-grams. For example, if the text has a single word then it searches for the all the bigrams which contains the given word as its first gram but if the number of words are more than two then it extracts the last two words of the text and then checks for the trigrams which contains these two words as the first two grams. Once it gets all such n-grams it generates the suggestions of the next possible words as the last grams of the most likely n-grams.'),
                                                class="details")
                                   )
                       )
                )
        )
        
        
                               
))