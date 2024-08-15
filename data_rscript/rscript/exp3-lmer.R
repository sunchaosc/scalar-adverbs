## ---- setup, include=FALSE-----------------------------------------------------------------------------------------------------------
pacman::p_load(reshape2, tidyverse, bootstrap, ggplot2, gazeR, lme4, lmerTest, buildmer)
knitr::opts_chunk$set(   tidy=FALSE,     # display code as typed  
                         size="small")   # slightly smaller font for code
options(scipen = 999)

## ------------------------------------------------------------------------------------------------------------------------------------

ctw <- read.csv("exp3_adv_100msbin_114ppl.csv",header=TRUE)

ctw <- ctw%>% 
  mutate(
    Participant = Participant %>% as.factor(),
    DisplayID = DisplayID %>% as.factor(),
    TimeC = scale(ctw$Time, center=T, scale=F),
    Polarity = factor(Polarity, levels = c("Pos", "Neg")),
    Type =  factor(Type, levels = c("Sem", "Prag"))
  )
    

contrasts(ctw$Polarity) <- c(0.5, -0.5)
contrasts(ctw$Type) <- c(0.5, -0.5)


buildmer(elog ~ TimeC * Type * Polarity + (TimeC * Type * Polarity|Participant) 
         + (TimeC * Type * Polarity|DisplayID),
         data=ctw, 
         buildmerControl = buildmerControl(include = ~ TimeC * Type * Polarity 
                                           + (1|Participant) + (1|DisplayID),
                                           list(direction = "order")))

model <- lmer(elog ~ TimeC * Type * Polarity 
              + (1 + Polarity| Participant) + (1+ TimeC+ Polarity |DisplayID), 
              data=ctw)
summary(model) 

summary(lmer(elog ~ TimeC *  Type +  (1  | Participant) + (1+ TimeC  |DisplayID), ctw[ctw$Polarity=="Pos", ]) )

summary(lmer(elog ~ TimeC *  Type +  (1  | Participant) + (1+ TimeC |DisplayID), ctw[ctw$Polarity=="Neg", ]) )

summary(lmer(elog ~ TimeC *  Polarity + (1  +Polarity| Participant) + (1+TimeC+Polarity|DisplayID), ctw[ctw$Type=="Sem", ]) )

summary(lmer(elog ~ TimeC *  Polarity + (1  +Polarity| Participant) + (1+ Polarity+TimeC  |DisplayID), ctw[ctw$Type=="Prag", ]) )



