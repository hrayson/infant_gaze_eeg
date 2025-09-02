library("lme4")
library("plyr")
library("car")
library("lsmeans")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/num_shifts/stats.txt'
sink(output_file)

# Read num gaze shifts file
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_gaze_shifts_no_headturns.csv')

# Aggregate over subject, age, condition, trial - count number of gaze shifts per trial for each subject/age/condition
data_agg<-count(data, c('Subject','Age','Condition','Trial'))

# Fit model
#basic_model <- lmer(freq ~ Age*Condition  + (1+Condition|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
basic_model <- glmer(freq ~ Age*Condition  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

condition1<-lsmeans(basic_model,pairwise~Condition)
print(summary(condition1)$contrasts)

# Aggregate over subject, age, condition, trial, pattern (AOI) - count number of gaze shifts per trial to each AOI for each subject/age/condition
data_agg<-count(data, c('Subject','Age','Condition','Trial','Pattern'))
#pat_model <- lmer(freq ~ Age*Condition*Pattern  + (1+Condition|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
pat_model <- glmer(freq ~ Age*Condition*Pattern  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(pat_model))

condition_pat<-lsmeans(pat_model,pairwise~Condition*Pattern|Pattern)
print(summary(condition_pat)$contrasts)

pat_condition<-lsmeans(pat_model,pairwise~Condition*Pattern|Condition)
print(summary(pat_condition)$contrasts)

# Aggregate over subject, age, condition, trial, direction - count number of gaze shifts per trial to each direction for each subject/age/condition
data_agg<-count(data, c('Subject','Age','Condition','Trial','Direction'))
#dir_model <- lmer(freq ~ Age*Condition*Direction  + (1+Condition|Subject), data = data_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
dir_model <- glmer(freq ~ Age*Condition*Direction  + (1|Subject), data = data_agg, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(dir_model))

condition_dir<-lsmeans(dir_model,pairwise~Condition*Direction|Direction)
print(summary(condition_dir)$contrasts)

dir_condition<-lsmeans(dir_model,pairwise~Condition*Direction|Condition)
print(summary(dir_condition)$contrasts)

sink()
