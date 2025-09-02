library("Matrix")
library("lme4")
library("ggplot2")
library("lsmeans")
library("car")
library("Rmisc")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/gaze_to_highlighted_obj_stats.txt'
sink(output_file)

logit_adj <- function(prop) {
      non_zero_ind <- which(prop!=0)
      if (length(non_zero_ind) < 1) return(NA)
      smallest <- min(prop[non_zero_ind], na.rm=TRUE)
      prop_adj <- prop
      prop_adj <- ifelse(prop_adj == 1, 1 - smallest/2, prop_adj)
      prop_adj <- ifelse(prop_adj == 0, smallest/2, prop_adj)
      return( log(prop_adj / (1-prop_adj)) )
}

data<-read.csv(file='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/looks_to_highlighted_obj.csv',header=TRUE,sep=',')

data$LogitAdjusted<-logit_adj(data$Prop)

model<-lmer(LogitAdjusted~Age*Condition+(1|Subject), data = data, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))

print(summary(model))
print(Anova(model, type = 3, test = "F"))

data_summary<-summarySE(data, measurevar="Prop", groupvars=c("Condition","Age"))
print(data_summary)

sink()
