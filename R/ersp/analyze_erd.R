# Make sure needed packages are installed and loaded
if(length(new<-(packages<-c("lme4", "afex", "lsmeans", "effects", "ggplot2","Rmisc", "car"))[!(packages %in% installed.packages()[,"Package"])])){
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

data<-read.csv(file='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/ersp/clusters/v7/0-1000ms/erd_data.csv',header=TRUE,sep=',')
data$Subject<-as.character(data$Subject)
#data$Cluster<-''
#data$Cluster[data$Region=='C' & data$Hemisphere=='left']='C3';
#data$Cluster[data$Region=='C' & data$Hemisphere=='right']='C4';
#data$Cluster[data$Region=='F' & data$Hemisphere=='left']='F3';
#data$Cluster[data$Region=='F' & data$Hemisphere=='right']='F4';
#data$Cluster[data$Region=='P' & data$Hemisphere=='left']='P3';
#data$Cluster[data$Region=='P' & data$Hemisphere=='right']='P4';
#data$Cluster[data$Region=='O' & data$Hemisphere=='left']='O1';
#data$Cluster[data$Region=='O' & data$Hemisphere=='right']='O2';


theta_data<-data[data$FreqBand=='theta',]
theta_summary<-summarySE(theta_data, measurevar="ERD", groupvars=c("Condition","Region","Hemisphere","Age"))

dev.new()
ggplot(theta_summary, aes(x=Region, y=ERD, fill=Condition))+facet_wrap(Hemisphere~Age)+geom_bar(position=position_dodge(), stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=position_dodge(0.9))+theme_bw(base_size=12);

#Type 3 tests for fixed Effects of most complex model
mixed(ERD ~ Condition * Region * Hemisphere * Age + (1+Condition | Subject/Cluster), data=theta_data, method="KR")

# Start with most complex model - condition x region x age interaction, region nested within subjects, allow slope for the effect of condition to vary by subject, and select the most parsimonious model
erd.model1=modeldrop(lmer(ERD ~ Condition * Cluster * Age + (1+Condition | Subject/Cluster), data=theta_data))


#Type 3 tests for fixed Effects of parsimonious model
mixed(erd.model1@call$formula, data=theta_data, method="KR")

# Checking assumptions for full model
# Check assumptions
resid.fitted<-plot(fitted(erd.model1),residuals(erd.model1))
resid.hist<-hist(residuals(erd.model1))
resid.norm<-qqnorm(residuals(erd.model1))




#Least-squares means, and Tukey corrected pairwise comparisons
cluster<-lsmeans(erd.model1,pairwise~Cluster)
summary(cluster)$lsmeans #Means
summary(cluster)$contrasts[summary(cluster)$contrasts$p.value<=0.05,] #Only show significant comparisons
age<-lsmeans(erd.model1,pairwise~Age)
summary(age)$lsmeans #Means
summary(age)$contrasts[summary(age)$contrasts$p.value<=0.05,] #Only show significant comparisons





mu_data<-data[data$FreqBand=='mu' & data$Region=='C',]
mu_summary<-summarySE(mu_data, measurevar="ERD", groupvars=c("Condition","Region", "Hemisphere","Age"))

dev.new()
ggplot(mu_summary, aes(x=Region, y=ERD, fill=Condition))+facet_wrap(Hemisphere~Age)+geom_bar(position=position_dodge(), stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=position_dodge(0.9))+theme_bw(base_size=12);

#lmm<-lmer(ERD ~ Condition * Region * Hemisphere * Age + (1 + Condition | Subject/Hemisphere/Region), data=mu_data, REML=FALSE)
lmm<-lmer(ERD ~ Condition * Region * Hemisphere * Age + (1 | Subject/Hemisphere/Region), data=mu_data, REML=FALSE)
Anova(lmm)

# Start with most complex model - condition x region x age interaction, region nested within subjects, allow slope for the effect of condition to vary by subject, and select the most parsimonious model
erd.model1=modeldrop(lmm)

#Least-squares means, and Tukey corrected pairwise comparisons
condition<-lsmeans(erd.model1,pairwise~Condition)
summary(condition)$lsmeans #Means
summary(condition)$contrasts[summary(condition)$contrasts$p.value<=0.05,] #Only show significant comparisons

#Type 3 tests for fixed Effects of parsimonious model
mixed(erd.model1@call$formula, data=mu_data, method="KR")

# Checking assumptions for full model
# Check assumptions
resid.fitted<-plot(fitted(erd.model1),residuals(erd.model1))
resid.hist<-hist(residuals(erd.model1))
resid.norm<-qqnorm(residuals(erd.model1))









beta_data<-data[data$FreqBand=='beta',]
beta_summary<-summarySE(beta_data, measurevar="ERD", groupvars=c("Condition","Region","Hemisphere","Age"))

dev.new()
ggplot(beta_summary, aes(x=Region, y=ERD, fill=Condition))+facet_wrap(Hemisphere~Age)+geom_bar(position=position_dodge(), stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=position_dodge(0.9))+theme_bw(base_size=12);

lmm<-lmer(ERD ~ Condition * Region * Hemisphere * Age + (1 | Subject/Hemisphere/Region), data=beta_data, REML=FALSE)
Anova(lmm)

# Start with most complex model - condition x region x age interaction, region nested within subjects, allow slope for the effect of condition to vary by subject, and select the most parsimonious model
erd.model1=modeldrop(lmer(ERD ~ Condition * Cluster * Age + (1+Condition | Subject/Cluster), data=beta_data))
#Type 3 tests for fixed Effects of most complex model
mixed(ERD ~ Condition * Cluster * Age + (1+Condition | Subject/Cluster), data=beta_data, method="KR")

#Type 3 tests for fixed Effects of parsimonious model
mixed(erd.model1@call$formula, data=beta_data, method="KR")

# Checking assumptions for full model
# Check assumptions
resid.fitted<-plot(fitted(erd.model1),residuals(erd.model1))
resid.hist<-hist(residuals(erd.model1))
resid.norm<-qqnorm(residuals(erd.model1))



#Least-squares means, and Tukey corrected pairwise comparisons
cluster_age<-lsmeans(erd.model1,pairwise~Cluster|Age)
summary(cluster_age)$lsmeans #Means
summary(cluster_age)$contrasts[summary(cluster_age)$contrasts$p.value<=0.05,] #Only show significant comparisons


age_cluster<-lsmeans(erd.model1,pairwise~Age|Cluster)
summary(age_cluster)$lsmeans #Means
summary(age_cluster)$contrasts[summary(age_cluster)$contrasts$p.value<=0.05,] #Only show significant comparisons




mu_data<-data[data$FreqBand=='mu' & data$Cluster=='F4',]
mu_summary<-summarySE(mu_data, measurevar="ERD", groupvars=c("Condition","Age"))

# Start with most complex model - condition x region x age interaction, region nested within subjects, allow slope for the effect of condition to vary by subject, and select the most parsimonious model
erd.model1=modeldrop(lmer(ERD ~ Condition * Age + (1 | Subject), data=mu_data))
#Type 3 tests for fixed Effects of most complex model
mixed(ERD ~ Condition * Age + (1 | Subject), data=mu_data, method="KR")

#Type 3 tests for fixed Effects of parsimonious model
mixed(erd.model1@call$formula, data=mu_data, method="KR")

# Checking assumptions for full model
# Check assumptions
resid.fitted<-plot(fitted(erd.model1),residuals(erd.model1))
resid.hist<-hist(residuals(erd.model1))
resid.norm<-qqnorm(residuals(erd.model1))

dev.new()
ggplot(mu_summary, aes(x=Condition, y=ERD, fill=Condition))+facet_wrap(~Age)+geom_bar(position=position_dodge(), stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=position_dodge(0.9))+theme_bw(base_size=12);
