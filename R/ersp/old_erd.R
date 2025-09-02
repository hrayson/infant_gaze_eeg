# Make sure needed packages are installed and loaded
if(length(new<-(packages<-c("lme4", "afex", "lsmeans", "effects", "ggplot2","Rmisc"))[!(packages %in% installed.packages()[,"Package"])])){
  install.packages(new[!(new %in% installed.packages()[,"Package"])])
}
sapply(packages, require, character.only=T)

#Model selection function
modeldrop<-function(x){
  drop<-drop1(update(x,REML=FALSE),test="Chisq")
  model<-update(x,REML=FALSE)
  repeat {
    if (max(drop$"Pr(Chi)"[-1])>0.05){
      .env<-environment()
      model<-update(model,as.formula(paste0(".~.-",attr(drop,"row.names")[1+which.max(drop$"Pr(Chi)"[-1])])))
      form<-as.formula(model@call,env=.env)
      modelreml<-lmer(as.formula(form),data=model@frame)
      model<-lmer(as.formula(form),data=model@frame,REML=FALSE)
      drop<-drop1(model,test="Chisq")
    } else {
      modelreml<-model
      break
    }
  }
  return(modelreml)
}

# Read data
erd<-read.csv('/data/infant_gaze_eeg/6-9m.500-1000.csv')
erd_summary<-summarySE(erd, measurevar="mu_erd", groupvars=c("condition","region","age"))

# Using full model
erd.full<-mixed(mu_erd ~ condition * region * age + (1+condition | subject/region), data=erd, method="KR")
# Checking assumptions for full model
dev.new()
plot(fitted(erd.full$full.model),residuals(erd.full$full.model))
dev.new()
hist(residuals(erd.full$full.model))
dev.new()
qqnorm(residuals(erd.full$full.model))

# Plot data
dev.new()
#erd.full2<-lmer(mu_erd ~ condition * region * age + (1+condition | subject/region), data=erd, method="KR")
#ef <- effect("condition:region:age", erd.full2)
#x <- as.data.frame(ef)
#ggplot(x,aes(region,fit,color=condition,fill=condition))+facet_wrap(~age)+geom_bar(stat="summary",fun.y="mean",position="dodge")+geom_errorbar(aes(ymin=fit-se,ymax=fit+se),width=0.4,position=position_dodge(width=0.9)) + theme_bw(base_size=12) + ylim(-25,32)
ggplot(erd_summary, aes(x=region, y=mu_erd, fill=condition))+facet_wrap(~age)+geom_bar(position=position_dodge(), stat="identity")+geom_errorbar(aes(ymin=mu_erd-se,ymax=mu_erd+se),width=0.4,position=position_dodge(0.9))+theme_bw(base_size=12) + ylim(-25,15);

# LS means, and multiple contrasts for full model
condbyreg.full<-lsmeans(erd.full,pairwise~condition*region|region)
summary(condbyreg.full)$lsmeans
summary(condbyreg.full)$contrasts[summary(condbyreg.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

regbycond.full<-lsmeans(erd.full,pairwise~condition*region|condition)
summary(regbycond.full)$lsmeans
summary(regbycond.full)$contrasts[summary(regbycond.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

condbyage.full<-lsmeans(erd.full,pairwise~condition*age|condition)
summary(condbyage.full)$lsmeans
summary(condbyage.full)$contrasts[summary(condbyage.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

agebycond.full<-lsmeans(erd.full,pairwise~condition*age|age)
summary(agebycond.full)$lsmeans
summary(agebycond.full)$contrasts[summary(agebycond.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

regbyage.full<-lsmeans(erd.full,pairwise~region*age|region)
summary(regbyage.full)$lsmeans
summary(regbyage.full)$contrasts[summary(regbyage.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

agebyreg.full<-lsmeans(erd.full,pairwise~region*age|age)
summary(agebyreg.full)$lsmeans
summary(agebyreg.full)$contrasts[summary(agebyreg.full)$contrasts$p.value<=0.05,] #Only show significant comparisons

