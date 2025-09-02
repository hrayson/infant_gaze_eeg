library("lme4")
library("plyr")
library("car")
library("lsmeans")



data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_gaze_shifts_no_headturns.csv')
data<-data[data$Condition=='shuffled',]

data_agg<-count(data, c('Subject','Age','Congruence','Trial'))
#basic_model <- lmer(freq ~ Age*Congruence  + (1|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
basic_model <- glmer(freq ~ Age*Congruence  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
Anova(basic_model)

data_agg<-count(data, c('Subject','Age','Congruence','Trial','Pattern'))
#pat_model <- lmer(freq ~ Age*Congruence*Pattern  + (1|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
pat_model <- glmer(freq ~ Age*Congruence*Pattern  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
Anova(pat_model)

pat<-lsmeans(pat_model,pairwise~Pattern)
print(summary(pat)$contrasts)

data_agg<-count(data, c('Subject','Age','Congruence','Trial','Direction'))
#dir_model <- lmer(freq ~ Age*Congruence*Direction  + (1|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
dir_model <- glmer(freq ~ Age*Congruence*Direction  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
Anova(dir_model)

dir<-lsmeans(dir_model,pairwise~Direction)
print(summary(dir)$contrasts)

