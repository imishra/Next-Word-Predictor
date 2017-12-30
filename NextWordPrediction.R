# Split the whole content in single sentence
library(stringi)
library(stringr)
library(RWeka)
suppressMessages(library(data.table))
suppressMessages(library(tm))
textToSentences<-function(content){
        listOfSentances=unlist(strsplit(content,"[\\.!?]+"))
        listOfSentances<-stri_enc_toutf8(listOfSentances)
        if(length(listOfSentances)==0)
                listOfSentances<-""
        return(listOfSentances)
}
sentenceToWord<-function(sentence){
        if(!is.character (sentence)){
                print("error - sentenceCleanup")
                return(data.frame())
        }
        listOfWords=unlist(strsplit(sentence," "))
        return(listOfWords[nchar (listOfWords) > 0])
}
sentenceCleanup=function(sentences){
        if(!is.character (sentences) || length (sentences) < 1){
                print("error - sentenceCleanup")
                return(data.frame())
        }
        
        #Cleanup the sentence and remove unwanted chaarcter or replace form
        sentences <- stri_trans_tolower (sentences)
        sentences <- stri_replace_all_regex (sentences,"[^A-Za-z0-9 ']+", "")
        sentences <- stri_replace_all_regex (sentences,"[[:digit:]]+", "###")
        sentences <- stri_enc_toutf8 (sentences)
        #add a marker at the begining and at the end
        sentences <- stri_paste ("^", sentences, "$", sep = " ")
        return (sentences)
}
getLastWord <- function (sentence) {
        if(!is.character (sentence) || length (sentence) != 1){
                print("error - getLastWord")
                return(data.frame())
        }
        
        words <- sentenceToWord (sentence)
        words [length (words)]
}
removeLastWord <- function (sentence) {
        
        if(!is.character (sentence) || length (sentence) != 1){
                print("error - getLastWord")
                return(data.frame())
        }
        
        words <- sentenceToWord (sentence)
        words <- words [1:length (words)-1]
        paste (words, collapse = " ")
}

getNGrams<- function (sentences,min,max) {
        if(!is.character (sentences) || !is.numeric (min) || !is.numeric (max)){
                print("error - getNGrams")
                return(data.frame())
        }
        
        
        # create a tokenizer
        control <- RWeka::Weka_control(min = min, max = max, delimiters = ' \r\n\t.,;:\\"()?!')
        token <- function(x) NGramTokenizer (x, control)
        ngrams <- data.table (query = unlist (lapply (sentences, token)))
}
probability <- function (ngrams) {
        context <- ngrams [, sum (frequency), by = context]
        setnames (context, c("context", "context_frequency"))
        setkeyv (context, "context")
        setkeyv (ngrams, "context")
        ngrams [context, p := frequency / context_frequency]
}

#Fit models using Katz Back-off algorithm
getNGramModels<-function(content){
        N=c(1,2,3)
        if(!is.character (content) || length (content)==0 || !is.numeric (N)){
                print("error - fitNGramModels")
                return(data.frame())
        }
        sentences <- sentenceCleanup (textToSentences (content))
        ngrams <- getNgrams (sentences,min(N),max(N))
        ngrams <- ngrams [, list (frequency = .N), by = query]
        
        #extract the context and next word for ngrams
        ngrams [, word := getLastWord (query),by = query]
        ngrams [, context := removeLastWord (query), by = query]
        
        #calculate the probability
        ngrams <- probability (ngrams)
        
        #skip start and end of sentance
        ngrams <- ngrams [word != "^"]
        ngrams <- ngrams [!(context == ""  & word == "$")]
        ngrams <- ngrams [!(context == "^" & word == "$")]
        
        regex <- paste0 ('[\r\n\t.,;:\\"()?!]+')
        ngrams [, n := unlist (lapply (stri_split (query, regex = regex), length)) ]
        
        #take most likely words
        ngrams <- ngrams [ order (context, -p)]
        ngrams [, rank := 1:.N, by = context]
        ngrams <- ngrams [ rank <= 5 ]
        
        models <- list (ngrams= ngrams,
                        NumberOfModels= N)
        
        return (models)
}

predictNextWord<-function(models,query){
        if(!is.character (query) || length (query) != 1 || nchar(query)<1)
                return(data.frame())
        listOfWords <- sentenceToWord (sentenceCleanup (textToSentences (query)))
        
        #remove end markers if the sentence is not ending with usual characters
        if (!stri_detect (query, regex = ".*[\\.!?][[:blank:]]*$"))
                listOfWords <- head (listOfWords, -1)
        
        predictions<-NULL
        for (n in sort (models$NumberOfModels, decreasing = TRUE)) {
                if (length (listOfWords) >= n-1) {
                        ctx <- paste (tail (listOfWords, n-1), collapse = " ")
                        predictions <- models$ngrams [ context == ctx, list (word, p, n, rank)]
                }
                if (nrow (predictions) > 0) {
                        predictions [word == "$", word := "."]
                        predictions [word == "###", word := NA]
                        
                        # exclude NA
                        predictions <- predictions [complete.cases (predictions)]
                        
                        # only keep the desired numberof prediction
                        predictions <- predictions [rank <= 5]
                        break
                }
        }
        words<-data.frame("Word"=predictions$word)
        names(words)<-NULL
        rownames(words)<-NULL
        return (words)
        
}
