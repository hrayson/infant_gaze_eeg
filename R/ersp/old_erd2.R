# Make sure needed packages are installed and loaded
if(length(new<-(packages<-c("lme4", "afex", "lsmeans"))[!(packages %in% installed.packages()[,"Package"])])){
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
      break
    }
  }
  return(modelreml)
}

# Read data
erd=read.csv('6-9m.500-1000.csv')

# Start with most complex model - condition x region x age interaction, region nested within subjects, allow slope for the effect of condition to vary by subject, and select the most parsimonious model
erd.model1=modeldrop(lmer(mu_erd ~ condition * region * age + (1+condition | subject/region), data=erd))

#Type 3 tests for fixed Effects of most complex model
mixed(mu_erd ~ condition * region * age + (1+condition | subject/region), data=erd, method="KR")

#Type 3 tests for fixed Effects of parsimonious model
mixed(erd.model1@call$formula, data=erd, method="KR")

# Check assumptions
resid.fitted<-plot(fitted(erd.model1),residuals(erd.model1))
resid.hist<-hist(residuals(erd.model1))
resid.norm<-qqnorm(residuals(erd.model1))


#Least-squares means, and Tukey corrected pairwise comparisons
condbyreg<-lsmeans(erd.model1,pairwise~condition*region)
summary(condbyreg)$lsmeans #Means
summary(condbyreg)$contrasts[summary(condbyreg)$contrasts$p.value<=0.05,] #Only show significant comparisons
regbyage<-lsmeans(erd.model1,pairwise~region*age)
summary(regbyage)$lsmeans #Means
summary(regbyage)$contrasts[summary(regbyage)$contrasts$p.value<=0.05,] #Only show significant comparisons
