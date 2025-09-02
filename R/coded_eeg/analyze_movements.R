library("lme4")
library("plyr")
library("car")
library("lsmeans")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/num_movements/stats.txt'
sink(output_file)

# Read num movemnets file
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_movements.csv')

# Fit model
basic_model <- glmer(Artifacts ~ Age*Condition  + (1+Condition|Subject), data = data, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

basic_model <- glmer(Movements ~ Age*Condition  + (1+Condition|Subject), data = data, family=poisson, control = glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

age_pw<-lsmeans(basic_model,pairwise~Age,adjust='Tukey')
print(summary(age_pw)$contrasts)


sink()
