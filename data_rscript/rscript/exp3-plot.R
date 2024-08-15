## ---- setup, include=FALSE--------------------------------------------------------------------------
pacman::p_load(reshape2,  Rmisc, tidyverse, bootstrap, ggplot2, lme4, lmerTest)
knitr::opts_chunk$set(   tidy=FALSE,     # display code as typed  
                         size="small")   # slightly smaller font for code


## ---------------------------------------------------------------------------------------------------

Exp <- read.csv("exp3_windows_114ppl.csv", header = TRUE)

timecourse.dat.summary = Rmisc::summarySE(Exp[Exp$Window!="Preview",] , 
                                          measurevar='Targetlook', 
                                          groupvars=c('Condition','Window','Bin'), 
                                          na.rm=T)

timecourse.dat.summary$Condition <- factor(timecourse.dat.summary$Condition, 
                                           levels = c("usually", "always", "rarely", 
                                                      "never" ))

timecourse.dat.summary$Polarity <- ifelse(timecourse.dat.summary$Condition %in% c("usually", "always"), "pos", "neg")
timecourse.dat.summary$Semprag <- ifelse(timecourse.dat.summary$Condition %in% c("usually", "rarely"), "prag", "sem")

pos <- timecourse.dat.summary[timecourse.dat.summary$Polarity!="neg",]
pos$Condition <- factor(pos$Condition)
p1 <- ggplot() +
  theme_light() + 
  geom_line(data = pos, aes(x=Bin, y=Targetlook, color=Condition, fill=Condition, linetype=Condition), lwd=1.2) +
  geom_ribbon(data=pos, aes(x=Bin,ymin=Targetlook-se,ymax=Targetlook+se,fill=Condition), size=.1, alpha=.3, lty="dashed", show.legend=F)  +
  labs(y="Proportion of target fixations", x="Time from the sentence onset (ms)") + 
  scale_color_manual('Condition', values=c("red","red")) +
  scale_fill_manual('Condition', values=c("red","red")) +
  scale_linetype_manual(values=c("twodash", "solid"))+
  
  theme(legend.key.width=unit(.6,"in")) +
  theme(legend.position="bottom")+
  theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 10))+
  annotate('text', x = 3000, y = .7, label="mean Adverb onset", angle=90) +
  annotate('text', x = 4000, y = .7, label="mean Color onset", angle=90) +
  annotate('text', x = 4500, y = .7, label="sentence offset", angle=90) +
  
  annotate('text', x = 2500, y = .95, label="The [object]") +
  annotate('text', x = 3600, y = .95, label="[adverb] lands on") +
  annotate('text', x = 4300, y = .95, label="[color]") +
  
  geom_vline(xintercept = 3100, linetype = "longdash") +
  geom_vline(xintercept = 4100, linetype = "longdash") +
  geom_vline(xintercept = 4600, linetype = "longdash") +
  
  scale_x_continuous(expand=c(0,0),breaks=seq(0, 5000, 1000)) +
  scale_y_continuous(limits=c(0,1),expand=c(0,0)) 
p1

neg <-  timecourse.dat.summary[timecourse.dat.summary$Polarity!="pos",]
neg$Condition <- factor(neg$Condition)
p2 <- ggplot() +
  theme_light() + 
  theme(legend.position="bottom")+
  geom_line(data = neg, aes(x=Bin, y=Targetlook, color=Condition, fill=Condition, linetype=Condition), lwd=1.2) +
  geom_ribbon(data=neg, aes(x=Bin,ymin=Targetlook-se,ymax=Targetlook+se,fill=Condition), size=.1, alpha=.3, lty="dashed", show.legend=F)  +
  labs(y="Proportion of target fixations", x="Time from the sentence onset (ms)") + 
  scale_color_manual('Condition', values=c("darkgreen","darkgreen")) +
  scale_fill_manual('Condition', values=c("darkgreen","darkgreen")) +
  scale_linetype_manual(values=c("twodash", "solid"))+
  
  theme(legend.key.width=unit(.6,"in")) +
  theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 10))+
  annotate('text', x = 3000, y = .7, label="mean Adverb onset", angle=90) +
  annotate('text', x = 4000, y = .7, label="mean Color onset", angle=90) +
  annotate('text', x = 4500, y = .7, label="sentence offset", angle=90) +
  
  annotate('text', x = 2500, y = .95, label="The [object]") +
  annotate('text', x = 3600, y = .95, label="[adverb] lands on") +
  annotate('text', x = 4300, y = .95, label="[color]") +
  
  geom_vline(xintercept = 3100, linetype = "longdash") +
  geom_vline(xintercept = 4100, linetype = "longdash") +
  geom_vline(xintercept = 4600, linetype = "longdash") +
  
  scale_x_continuous(expand=c(0,0),breaks=seq(0, 5000, 1000)) +
  scale_y_continuous(limits=c(0,1),expand=c(0,0))
p2


library(gridExtra)
p3 <- grid.arrange(p1, p2, ncol = 2)

ggsave(p3, filename = ".../proportions by conditions_twoplots.jpeg", 
       width = 9, height = 4, dpi = 300, units = "in", device='jpeg') 
