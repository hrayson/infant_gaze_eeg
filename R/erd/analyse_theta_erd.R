library("lme4")
library("car")
library("lsmeans")
library("Rmisc")
library("ggplot2")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/theta_stats.txt'
sink(output_file)

#For observation
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue_all_theta.csv')
data$Subject<-as.factor(data$Subject)
# Select data in theta band, 4 WOIs, and C, O, or F region
#data<-data[data$FreqBand =='theta' & (data$WOI =='0-500ms'|data$WOI =='500-1000ms'|data$WOI == '1000-1500ms'| data$WOI =='1500-2000ms') & (data$Region=='C' | data$Region=='O'| data$Region=='F'),]
data<-data[data$FreqBand =='theta' & (data$WOI =='0-500ms'|data$WOI =='500-1000ms'|data$WOI == '1000-1500ms'| data$WOI =='1500-2000ms'| data$WOI =='2000-2500ms'| data$WOI =='2500-3000ms') & (data$Hemisphere=='medial'),]
# Rename hemisphere/region combinations to clusters
data$Cluster<-''
data$Cluster[data$Hemisphere == 'medial']<-'Fmedial'
data$Cluster<-as.factor(data$Cluster)

# Summarize results over subjects - compute mean, SE
data_summary<-summarySE(data, measurevar="ERD", groupvars=c("Condition","WOI","Age"))
# Make WOI levels appear in correct order
data_summary$WOIf<-factor(data_summary$WOI, levels=c('0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'))

# Do one sample t-tests for each condition/cluster/woi/age to compare against baseline
data$p<-0.0
conditions<-unique(data_summary$Condition)
wois<-unique(data_summary$WOIf)
ages<-unique(data_summary$Age)
for(i in 1:length(conditions)) {
	condition <- conditions[i]
	print(condition)
	for(k in 1:length(wois)) {
		woi <- wois[k]
		print(woi)
		for(l in 1:length(ages)) {
			age <- ages[l]
			print(age)
			t_data <- data[data$Condition==condition & data$WOI==woi & data$Age==age,]
			res<-t.test(t_data$ERD)
			print(res)
			data_summary$p[data_summary$Condition==condition & data_summary$WOIf==woi & data_summary$Age==age]<-res$p.value
		}
	}
}
# Create *'s depending on p value
data_summary$star <- ""
data_summary$star[data_summary$p <= .05]  <- "*"
data_summary$star[data_summary$p <= .01]  <- "**"
data_summary$star[data_summary$p <= .001] <- "***"

# Plot
dodge<-position_dodge(width=0.9)
g<-ggplot(data_summary, aes(x=Condition, y=ERD))+facet_grid(WOIf~Age)+geom_bar(position=dodge, stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=dodge)+geom_text(position=dodge, aes(y=ERD-se,label=star), colour="red", vjust=1.25, size=5)+theme_bw(base_size=12)+ylim(-45,20)
print(g)

# Saves model fit plots as png and eps
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/theta_erd.png', width=12, height=7)
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/theta_erd.eps', width=12, height=7)

basic_model <- lmer(ERD ~ Age*Condition*WOI + (1+Condition|Subject), data = data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

age1<-lsmeans(basic_model,pairwise~Age*Condition|Condition)
print(summary(age1)$contrasts)

age2<-lsmeans(basic_model,pairwise~Age*Condition|Age)
print(summary(age2)$contrasts)

dev.new()
pd <- position_dodge(0.1)
g<-ggplot(data_summary,aes(x=WOIf,y=ERD,color=Condition,linetype=Age,group=interaction(Condition,Age)))+geom_errorbar(aes(ymin=ERD-se, ymax=ERD+se), width=.1, color='black', position=pd)+geom_line(position=pd)+geom_point(position=pd,size=3,shape=21,fill='white')+xlab('Time window')+ylab('ERD')+theme_bw()+theme(legend.justification=c(0,1),legend.position=c(0,1))
print(g)

# Saves model fit plots as png and eps
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/theta_erd_fmedial_all.png')
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/theta_erd_fmedial_all.eps')


sink()



