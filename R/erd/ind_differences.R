library("lme4")
library("car")
library("Rmisc")
library("ggplot2")
library("Hmisc")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/ind_diff/stats.txt'
sink(output_file)

data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue_coarse.csv')
data$Subject<-as.factor(data$Subject)
data<-data[data$FreqBand =='mu' & (data$WOI =='0-1000ms'|data$WOI == '1000-2000ms'|data$WOI == '2000-3000ms'),]
data$Cluster<-''
data$Cluster[data$Region == 'C' & data$Hemisphere == 'left']<-'C3'
data$Cluster[data$Region == 'C' & data$Hemisphere == 'right']<-'C4'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'left']<-'F3'
data$Cluster[data$Region == 'F' & data$Hemisphere == 'right']<-'F4'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'left']<-'P3'
data$Cluster[data$Region == 'P' & data$Hemisphere == 'right']<-'P4'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'left']<-'O1'
data$Cluster[data$Region == 'O' & data$Hemisphere == 'right']<-'O2'
#data$Cluster<-as.factor(data$Cluster)

data_summary<-summarySE(data, measurevar="ERD", groupvars=c("Subject","Cluster","Condition","WOI","Age"))
subjects<-unique(data_summary$Subject)
ages<-unique(data_summary$Age)
wois<-unique(data_summary$WOI)
conditions<-unique(data_summary$Condition)
clusters<-unique(data_summary$Cluster)
for(i in 1:length(subjects)) {
	subject<-subjects[i]
	for(j in 1:length(ages)) {
		age<-ages[j]
		for(k in 1:length(wois)) {
			woi<-wois[k]
			for(l in 1:length(clusters)) {
				cluster<-clusters[l]
				diff<-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_congruent']-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_incongruent']
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster=cluster, Condition='cong-incong', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
					data_summary <- rbind(data_summary, new_data)
				}
				diff<-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_congruent']-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='shuffled']
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster=cluster, Condition='cong-shuf', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
					data_summary <- rbind(data_summary, new_data)
				}
				diff<-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_incongruent']-data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='shuffled']
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster=cluster, Condition='incong-shuf', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
					data_summary <- rbind(data_summary, new_data)
				}
				mean<-(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_congruent']+data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='unshuffled_incongruent']+data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & data_summary$Cluster==cluster & data_summary$Condition=='shuffled'])/3
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster=cluster, Condition='mean', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
					data_summary <- rbind(data_summary, new_data)
				}
			}
			erd<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_congruent'])
			if(length(erd)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='unshuffled_congruent', ERD=erd, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			erd<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_incongruent'])
			if(length(erd)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='unshuffled_incongruent', ERD=erd, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			erd<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='shuffled'])
			if(length(erd)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='shuffled', ERD=erd, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			diff<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_congruent'])-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_incongruent'])
			if(length(diff)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='cong-incong', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			diff<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_congruent'])-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='shuffled'])
			if(length(diff)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='cong-shuf', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			diff<-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_incongruent'])-mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='shuffled'])
			if(length(diff)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='incong-shuf', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
			mean<-(mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_congruent'])+mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='unshuffled_incongruent'])+mean(data_summary$ERD[data_summary$Subject==subject & data_summary$Age==age & data_summary$WOI==woi & (data_summary$Cluster=='C4' | data_summary$Cluster=='P4') & data_summary$Condition=='shuffled']))/3
			if(length(diff)>0) {
				new_data <- data.frame(Subject=subject, Age=age, WOI=woi, Cluster='C4P4', Condition='mean', ERD=diff, N=1, sd=NaN, se=NaN, ci=NaN)
				data_summary <- rbind(data_summary, new_data)
			}
		}
	}
}
data_summary$Cluster<-as.factor(data_summary$Cluster)

data_summary_wide<-reshape(data_summary, idvar = c("Subject","Cluster","Condition","WOI"), timevar = "Age", direction = "wide")
data_summary_wide$WOIf<-factor(data_summary_wide$WOI, levels=c('0-1000ms','1000-2000ms','2000-3000ms'))



clusters<-unique(data_summary_wide$Cluster)
conditions<-unique(data_summary_wide$Condition)
wois<-unique(data_summary_wide$WOI)
for(i in 1:length(clusters)) {
	cluster<-clusters[i]
	for(j in 1:length(conditions)) {
		condition<-conditions[j]

		cond_cluster_summary<-data_summary_wide[data_summary_wide$Cluster==cluster & data_summary_wide$Condition==condition,]

		g<-ggplot(cond_cluster_summary, aes(x=ERD.6m, y=ERD.9m)) + geom_point(shape=1) + geom_smooth(method='lm',formula=y~x)+facet_grid(WOIf~.)
		print(g)

		# Saves model fit plots as png and eps
		ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/ind_diff/mu_',cluster,'_',condition,'_erd_ind_diff.png', sep=''))
		ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/ind_diff/mu_',cluster,'_',condition,'_erd_ind_diff.eps', sep=''))


		for(k in 1:length(wois)) {
			woi <- wois[k]
			lm_data<-cond_cluster_summary[cond_cluster_summary$WOI==woi,]
			print(paste(cluster, '-', condition, '-', woi, sep=''))
			erd.mod1 = lm(ERD.9m ~ ERD.6m, data = lm_data)
			print(summary(erd.mod1))
		}
	}
}

sink()
