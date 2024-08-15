## ---- setup, include=FALSE--------------------------------------------------------------------------
pacman::p_load(mosaic, plyr, bootstrap, tidyverse, ggplot2, lme4, lmerTest,buildmer)
 knitr::opts_chunk$set(   tidy=FALSE,     # display code as typed  
                          size="small")   # slightly smaller font for code


## ---------------------------------------------------------------------------------------------------


df <- read.csv("exp1_cleaned_data.csv", header = TRUE)

exp <- df[df$ExpFiller=="Exp",]

exp$polarity <- ifelse(exp$condition %in% c("usually", "always"), "pos", "neg")
exp$type <- ifelse(exp$condition %in% c("usually", "rarely"), "prag", "sem")

cols <- c('workerid', 'list', 'display', 'polarity', 'type')
exp[cols] <- lapply(exp[cols], factor)

# define target clicks, competitor clicks
exp = exp %>% select(list, workerid,ExpFiller,display,condition,polarity,type, 
                     click1,click2,click3,click4, target,competitor,trial_order,
                     trial_group) %>%
  gather(click_number,location, click1:click4) %>% 
  mutate(target_click=ifelse(location==target,1,0), competitor_click=ifelse(location==competitor,1,0) )



## ---------------------------------------------------------------------------------------------------
theta <- function(x,xdata,na.rm=T) {mean(xdata[x],na.rm=na.rm)}
ci.low <- function(x,na.rm=T) {
  mean(x,na.rm=na.rm) - quantile(bootstrap(1:length(x),1000,theta,x,na.rm=na.rm)$thetastar,.025,na.rm=na.rm)}
ci.high <- function(x,na.rm=T) {
  quantile(bootstrap(1:length(x),1000,theta,x,na.rm=na.rm)$thetastar,.975,na.rm=na.rm) - mean(x,na.rm=na.rm)}

toplot = exp %>%
  group_by(condition,click_number) %>%
  summarize(m_target=mean(target_click),
            m_competitor=mean(competitor_click),
            ci_low_target=ci.low(target_click),ci_high_target=ci.high(target_click),
            ci_low_competitor=ci.low(competitor_click),ci_high_competitor=ci.high
            (competitor_click)) %>%
  gather(location,Mean,m_target:m_competitor) %>%
  mutate(CILow=ifelse(location=="m_target",ci_low_target,
                      ifelse(location=="m_competitor",ci_low_competitor,0))) %>%
  mutate(CIHigh=ifelse(location=="m_target",ci_high_target,
                       ifelse(location=="m_competitor",ci_high_competitor,0))) %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh) %>%
  mutate(Region=fct_recode(location,"competitor"="m_competitor","target"="m_target")) %>%
  mutate(Region=fct_rev(Region)) %>%
  ungroup() %>%
  mutate(click_number=fct_recode(click_number,baseline="click1",object="click2",
                                 adverb="click3",color="click4"))%>%
  select(-c(ci_low_target, ci_high_target, ci_low_competitor, ci_high_competitor, 
            location ))

toplot$condition <- factor(toplot$condition, 
                           levels = c("usually", "always", "rarely", "never"))
condition.labs <- c("usually", "always", "rarely", "never")
names(condition.labs) <-c("usually", "always", "rarely", "never")

proportions <- ggplot(toplot, aes(x=click_number, y=Mean, group=Region)) +
  geom_line(aes(color=Region),size=1.3) +
  geom_point(aes(color=Region),size=2.5,shape="square") +
  geom_errorbar(aes(ymin=YMin, ymax=YMax), width=.2, alpha=.3) +
  facet_grid(~condition, labeller = labeller(condition = condition.labs) ) + 
  scale_color_manual(values=c("darkgreen","orange")) +
  ylab("Proportion of clicks") +
  theme(axis.text.x=element_text(angle=30,hjust=1,vjust=1),
        legend.position = "bottom",
        axis.title.x = element_blank(),
        legend.title = element_blank())
proportions
ggsave(filename = "prop-exp1.jpeg", proportions, width = 9, height = 4, dpi = 300, units = "in", device='jpeg')


## ---------------------------------------------------------------------------------------------------
dmodel.click = exp %>% 
  mutate(TorC=target_click == 1 | competitor_click == 1) %>% 
  filter(TorC == TRUE) %>% 
  mutate(target = as.factor(as.character(target))) %>% 
  droplevels()

dmodel.click %>%
  group_by(click_number, condition) %>%
  summarise(Rate = mean(target_click), .groups = "drop")

d_base = dmodel.click %>% 
  filter(click_number == "click1") %>% 
  droplevels()
d_object = dmodel.click %>% 
  filter(click_number == "click2") %>% 
  droplevels()
d_adverb = dmodel.click %>% 
  filter(click_number == "click3") %>% 
  droplevels()
d_color = dmodel.click %>% 
  filter(click_number == "click4") %>% 
  droplevels()



## ---------------------------------------------------------------------------------------------------

buildmer(target_click ~ type*polarity + 
           (type*polarity|workerid) + (type*polarity|display),
         data=d_base, family="binomial",
         buildmerControl = buildmerControl(include = ~ polarity * type 
                                           +(1|workerid)+(1|display),
                                           list(direction = "order")))

m.base = glmer(target_click ~ 1 + polarity + type + polarity:type + (1 | display),
                family="binomial",  data=d_base)
summary(m.base)

## ---------------------------------------------------------------------------------------------------
 
buildmer(target_click ~ type*polarity + (type*polarity|workerid) +
           (type*polarity|display),
        data=d_object, family="binomial",
        buildmerControl = buildmerControl(include = ~ polarity * type 
                                          +(1|workerid)+(1|display),
                                          list(direction = "order")))

m.object = glmer( target_click ~ 1 + polarity + type + polarity:type + (1 | display),   
                 family="binomial",  data=d_object) 
summary(m.object)


## ---------------------------------------------------------------------------------------------------

buildmer(target_click ~ type*polarity + 
           (type*polarity|workerid) + (type*polarity|display),
         data=d_adverb, family="binomial",
         buildmerControl = buildmerControl(include = ~ polarity * type 
                                           +(1|workerid)+(1|display),
                                           list(direction = "order")))

contrasts(d_adverb$polarity) <- c(-0.5, 0.5)
contrasts(d_adverb$type) <- c(-0.5, 0.5)

m.adverb = glmer(target_click ~ 1 + polarity + type + polarity:type 
                 + (1 | workerid) +(1|display), 
                 family="binomial", data=d_adverb)

summary(m.adverb)

summary(glmer(target_click ~ type + (1|workerid) +(1|display),
                 family="binomial", data=d_adverb[d_adverb$polarity=="pos",]))

summary(glmer(target_click ~ type + (1|workerid) +(1|display),                 
              family="binomial",data=d_adverb[d_adverb$polarity=="neg",]))

summary(glmer(target_click ~ polarity + (1|workerid) +(1|display),                  
              family="binomial", data=d_adverb[d_adverb$type=="prag",])) 

summary(glmer(target_click ~ polarity + (1|workerid)+(1|display) ,                 
              family="binomial", data=d_adverb[d_adverb$type=="sem",]))


## ---------------------------------------------------------------------------------------------------
citation() 
getRversion()
citation("buildmer")
citation("lme4")
packageVersion("lme4")
packageVersion("lmerTest")
