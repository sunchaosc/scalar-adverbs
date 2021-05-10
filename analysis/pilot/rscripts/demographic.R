library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data')
demo = read.csv("example-subject_information.csv", header = TRUE)

# look at comments
unique(demo$comments,demo$workerid)

# look at problems
unique(demo$problems,demo$workerid)

# fair price
# ggplot(demo, aes(x=fairprice)) +
#   geom_histogram(stat="count")

# overall assessment
ggplot(demo, aes(x=asses)) +
  geom_histogram(stat="count")

# enjoyment (3 levels)
ggplot(demo, aes(x=enjoyment)) +
  geom_histogram(stat="count")

# age
ggplot(demo, aes(x=age)) +
  geom_histogram(stat="count")

# gender
ggplot(demo, aes(x=gender)) +
  geom_histogram(stat="count")

# education
ggplot(demo, aes(x=education)) +
  geom_histogram(stat="count")

# language
ggplot(demo, aes(x=language)) +
  geom_histogram(stat="count") +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1))

# average time 
df = read.csv("example-trials.csv", header = TRUE)

times = df %>%
  select(workerid,Answer.time_in_minutes) %>%
  unique()

times = times %>% 
  left_join(demo,by = c("workerid"))

ggplot(times, aes(x=Answer.time_in_minutes)) +
  geom_histogram()

ggplot(times, aes(x=age, y=Answer.time_in_minutes)) +
  geom_point()+
  geom_smooth(method="lm")

times %>%
  filter(Answer.time_in_minutes<5) %>%
  select(workerid,Answer.time_in_minutes)
