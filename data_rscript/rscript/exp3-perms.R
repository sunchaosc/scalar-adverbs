## ---- setup, include=FALSE-----------------------------------------------------------------------------------------------------------
pacman::p_load(reshape2, tidyverse, bootstrap, ggplot2, lme4, lmerTest, permutes, buildmer, permuco)
knitr::opts_chunk$set(   tidy=FALSE,     # display code as typed  
                         size="small")   # slightly smaller font for code

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

contrasts(ctw$Polarity)

contrasts(ctw$Polarity) <- c(0.5, -0.5)
contrasts(ctw$Type) <- c(0.5, -0.5)

###################################
###  permutation analysis ###
###################################


perms <- clusterperm.lmer(elog ~  Type * Polarity 
                          +  (1 + Polarity | Participant) + (1+Polarity |DisplayID), 
                         data=ctw,
                         series.var = ~Bin,
                         nperm = 1000)
cluster.sig =  perms[perms$Factor != '(Intercept)' & !is.na(perms$cluster_mass),]
cluster.sig <- cluster.sig[cluster.sig$p.cluster_mass < .05,]
cluster.sig$Bin # which bins are significant?


perms_pos <- clusterperm.lmer(elog ~  Type  + (1  | Participant) + (1 |DisplayID), 
                              data=ctw[ctw$Polarity == "Pos",],
                              series.var = ~Bin,
                              nperm = 1000)
cluster.sig_pos =  perms_pos[perms_pos$Factor != '(Intercept)' & !is.na(perms_pos$cluster_mass),]
cluster.sig_pos <- cluster.sig_pos[cluster.sig_pos$p.cluster_mass < .05,]
cluster.sig_pos$Bin 


perms_neg <- clusterperm.lmer(elog ~  Type  + (1| Participant) + (1 |DisplayID), 
                              data=ctw[ctw$Polarity == "Neg",],
                              series.var = ~Bin,
                              nperm = 1000)
cluster.sig_neg =  perms_neg[perms_neg$Factor != '(Intercept)' & !is.na(perms_neg$cluster_mass),]
cluster.sig_neg <- cluster.sig_neg[cluster.sig_neg$p.cluster_mass < .05,]
cluster.sig_neg$Bin 

perms_sem <- clusterperm.lmer(elog ~  Polarity  
                              + (1+Polarity  | Participant) + (1+Polarity |DisplayID), 
                          data=ctw[ctw$Type == "Sem",],
                          series.var = ~Bin,
                          nperm = 1000)
cluster.sig_sem =  perms_sem[perms_sem$Factor != '(Intercept)' & !is.na(perms_sem$cluster_mass),]
cluster.sig_sem <- cluster.sig_sem[cluster.sig_sem$p.cluster_mass < .05,]
cluster.sig_sem$Bin 

perms_prag <- clusterperm.lmer(elog ~  Polarity  
                               +  (1 +Polarity | Participant) + (1+Polarity |DisplayID),
                          data=ctw[ctw$Type == "Prag",],
                          series.var = ~Bin,
                          nperm = 1000)
cluster.sig_prag =  perms_prag[perms_prag$Factor != '(Intercept)' & !is.na(perms_prag$cluster_mass),]
cluster.sig_prag <- cluster.sig_prag[cluster.sig_prag$p.cluster_mass < .05,]
cluster.sig_Pos$Bin 

