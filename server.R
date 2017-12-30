library(shiny)
cat(file=stderr())
source("NextWordPrediction.R")
load("models.rda",envir=.GlobalEnv)
shinyServer(
        function(input, output) {
                
                query <-eventReactive(input$predict, {
                        paste(input$text)
                })
                output$text11 <- renderText({ query() })
                pred<-NULL;
                pred<-eventReactive(input$predict, {
                        isolate(predictNextWord(models,input$text))
                })
                
                output$table <- renderTable({pred()},include.colnames=FALSE,include.rownames=FALSE)
                
        }
        
)