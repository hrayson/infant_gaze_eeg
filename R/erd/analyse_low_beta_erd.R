library("lme4")
library("car")
library("lsmeans")
library("Rmisc")
library("ggplot2")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/low_beta_stats.txt'
sink(output_file)

#For observation
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs.csv')
data$Subject<-as.factor(data$Subject)
# Select data in low_beta band, 4 WOIs, and C, O, or F region
#data<-data[data$FreqBand =='low_beta' & (data$WOI =='0-500ms'|data$WOI =='500-1000ms'|data$WOI == '1000-1500ms'| data$WOI =='1500-2000ms') & (data$Region=='C' | data$Region=='O'| data$Region=='F'),]
data<-data[data$FreqBand =='low_beta' & (data$WOI =='0-500ms'|data$WOI =='500-1000ms'|data$WOI == '1000-1500ms'| data$WOI =='1500-2000ms') & (data$Region=='C' | data$Region=='O'| data$Region=='F'| data$Region=='P'),]
# Rename hemisphere/region combinations to clusters
data$Cluster<-''
data$Cluster[data$Region == 'C' & data$Hemisphere == 'left']<-'C3'
data$Cluster[data$Region == 'C' & data$Hemisphere == 'right']<-'C4'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'left']<-'F3'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'right']<-'F4'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'left']<-'P3'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'right']<-'P4'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'left']<-'O1'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'right']<-'O2'
data$Cluster<-as.factor(data$Cluster)

# Summarize results over subjects - compute mean, SE
data_summary<-summarySE(data, measurevar="ERD", groupvars=c("Condition","Cluster","WOI","Age"))
# Make WOI levels appear in correct order
data_summary$WOIf<-factor(data_summary$WOI, levels=c('0-500ms','500-1000ms','1000-1500ms','1500-2000ms'))

# Do one sample t-tests for each condition/cluster/woi/age to compare against baseline
data$p<-0.0
conditions<-unique(data_summary$Condition)
clusters<-unique(data_summary$Cluster)
wois<-unique(data_summary$WOI)
ages<-unique(data_summary$Age)
for(i in 1:length(conditions)) {
	condition <- conditions[i]
	for(j in 1:length(clusters)) {
		cluster <- clusters[j]
		for(k in 1:length(wois)) {
			woi <- wois[k]
			for(l in 1:length(ages)) {
				age <- ages[l]
				t_data <- data[data$Condition==condition & data$Cluster==cluster & data$WOI==woi & data$Age==age,]
				res<-t.test(t_data$ERD)
				data_summary$p[data_summary$Condition==condition & data_summary$Cluster==cluster & data_summary$WOI==woi & data_summary$Age==age]<-res$p.value
			}
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
g<-ggplot(data_summary, aes(x=Cluster, y=ERD, fill=Condition))+facet_grid(WOIf~Age)+geom_bar(position=dodge, stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=dodge)+geom_text(position=dodge, aes(y=ERD-se,label=star), colour="red", vjust=1.25, size=5)+theme_bw(base_size=12)+ylim(-40,10)
print(g)

# Saves model fit plots as png and eps
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/low_beta_erd.png', width=12, height=7)
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/low_beta_erd.eps', width=12, height=7)

basic_model <- lmer(ERD ~ Age*Cluster*Condition*WOI + (1+Condition|Subject), data = data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

# When not including P
#cluster2<-lsmeans(basic_model,pairwise~Cluster)
#print(summary(cluster2)$contrasts)

# Included when including P
cluster2<-lsmeans(basic_model,pairwise~Age*Cluster|Cluster)
print(summary(cluster2)$contrasts)

woi1<-lsmeans(basic_model,pairwise~WOI)
print(summary(woi1)$contrasts)

sink()


output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/exe/low_beta_stats.txt'
sink(output_file)

#For execution
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/exe.csv')
data$Subject<-as.factor(data$Subject)
# Select data in low_beta band, 2 WOIs, and C, O, or F region
#data<-data[data$FreqBand =='low_beta' & (data$WOI == '-500-0ms'| data$WOI =='0-500ms') & (data$Region=='C' | data$Region=='O' | data$Region=='F'),]
data<-data[data$FreqBand =='low_beta' & (data$WOI == '-500-0ms'| data$WOI =='0-500ms') & (data$Region=='C' | data$Region=='O' | data$Region=='F' | data$Region=='P'),]
# Rename hemisphere/region combinations to clusters
data$Cluster<-''
data$Cluster[data$Region == 'C' & data$Hemisphere == 'left']<-'C3'
data$Cluster[data$Region == 'C' & data$Hemisphere == 'right']<-'C4'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'left']<-'F3'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'right']<-'F4'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'left']<-'P3'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'right']<-'P4'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'left']<-'O1'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'right']<-'O2'
data$Cluster<-as.factor(data$Cluster)

# Summarize results over subjects - compute mean, SE
data_summary<-summarySE(data, measurevar="ERD", groupvars=c("Cluster","WOI","Age"))
# Make WOI levels appear in correct order
data_summary$WOIf<-factor(data_summary$WOI, levels=c('-500-0ms','0-500ms'))

# Do one sample t-tests for each cluster/woi/age to compare against baseline
data_summary$p<-0.0
clusters<-unique(data_summary$Cluster)
wois<-unique(data_summary$WOI)
ages<-unique(data_summary$Age)
for(j in 1:length(clusters)) {
	cluster <- clusters[j]
	for(k in 1:length(wois)) {
		woi <- wois[k]
		for(l in 1:length(ages)) {
			age <- ages[l]
			t_data <- data[data$Cluster==cluster & data$WOI==woi & data$Age==age,]
			res<-t.test(t_data$ERD)
			data_summary$p[data_summary$Cluster==cluster & data_summary$WOI==woi & data_summary$Age==age]<-res$p.value
		}
	}
}
# Create *'s depending on p value
data_summary$star <- ""
data_summary$star[data_summary$p <= .05]  <- "*"
data_summary$star[data_summary$p <= .01]  <- "**"
data_summary$star[data_summary$p <= .001] <- "***"

# plot
dodge<-position_dodge(width=0.9)
g<-ggplot(data_summary, aes(x=Cluster, y=ERD, fill=Age))+facet_grid(WOIf~.)+geom_bar(position=dodge, stat="identity")+geom_errorbar(aes(ymin=ERD-se,ymax=ERD+se),width=0.4,position=dodge)+geom_text(position=dodge, aes(y=ERD-se,label=star), colour="red", vjust=1.25, size=5)+theme_bw(base_size=12)
print(g)

# Saves model fit plots as png and eps
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/exe/low_beta_erd.png')
ggsave(file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/exe/low_beta_erd.eps')

basic_model <- lmer(ERD ~ Age*Cluster*WOI + (1|Subject), data = data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(basic_model))

# When not including P
#woi<-lsmeans(basic_model,pairwise~WOI)
#print(summary(woi)$contrasts)

# When including P
woi<-lsmeans(basic_model,pairwise~Age*WOI|WOI)
print(summary(woi)$contrasts)

cluster1<-lsmeans(basic_model,pairwise~Cluster*Age|Age)
print(summary(cluster1)$contrasts)

cluster2<-lsmeans(basic_model,pairwise~Cluster*Age|Cluster)
print(summary(cluster2)$contrasts)

sink()
