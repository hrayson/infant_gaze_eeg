library("lme4")
library("car")
library("lsmeans")
library("Rmisc")
library("ggplot2")

#For observation
eeg_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue_all.csv')
eeg_data$Subject<-as.factor(eeg_data$Subject)
# Select eeg_data in mu band, 4 WOIs, and C, O, or F region
eeg_data<-eeg_data[eeg_data$FreqBand =='mu' & (eeg_data$Region=='C' | eeg_data$Region=='O'| eeg_data$Region=='F'| eeg_data$Region=='P') & (eeg_data$Hemisphere=='left' | eeg_data$Hemisphere=='right'),]
# Rename hemisphere/region combinations to clusters
eeg_data$Cluster<-''
eeg_data$Cluster[eeg_data$Region == 'C' & eeg_data$Hemisphere == 'left']<-'C3'
eeg_data$Cluster[eeg_data$Region == 'C' & eeg_data$Hemisphere == 'right']<-'C4'
eeg_data$Cluster[eeg_data$Region == 'F' & eeg_data$Hemisphere == 'left']<-'F3'
eeg_data$Cluster[eeg_data$Region == 'F' & eeg_data$Hemisphere == 'right']<-'F4'
eeg_data$Cluster[eeg_data$Region == 'P' & eeg_data$Hemisphere == 'left']<-'P3'
eeg_data$Cluster[eeg_data$Region == 'P' & eeg_data$Hemisphere == 'right']<-'P4'
eeg_data$Cluster[eeg_data$Region == 'O' & eeg_data$Hemisphere == 'left']<-'O1'
eeg_data$Cluster[eeg_data$Region == 'O' & eeg_data$Hemisphere == 'right']<-'O2'
subjects<-unique(eeg_data$Subject)
ages<-unique(eeg_data$Age)
wois<-unique(eeg_data$WOI)
conditions<-unique(eeg_data$Condition)
for(i in 1:length(subjects)) {
	subject<-subjects[i]
	for(j in 1:length(ages)) {
		age<-ages[j]
		for(k in 1:length(wois)) {
			woi<-wois[k]
			for(l in 1:length(conditions)) {
				condition<-conditions[l]
				c4_erd<-eeg_data$ERD[eeg_data$Subject==subject & eeg_data$Age==age & eeg_data$WOI==woi & eeg_data$Condition==condition & eeg_data$Cluster=='C4']
				p4_erd<-eeg_data$ERD[eeg_data$Subject==subject & eeg_data$Age==age & eeg_data$WOI==woi & eeg_data$Condition==condition & eeg_data$Cluster=='P4']
				if(length(c4_erd)>0 && length(p4_erd)>0) {
					eeg_data<-rbind(eeg_data, data.frame(Subject=subject, Age=age, Region='CP', Hemisphere='right', WOI=woi, FreqBand='mu', Cluster='C4P4', Condition=condition, ERD=(c4_erd+p4_erd)/2))
				}
			}
		}
	}
}
eeg_data$Cluster<-as.factor(eeg_data$Cluster)
clusters<-unique(eeg_data$Cluster)
for(i in 1:length(subjects)) {
	subject<-subjects[i]
	for(j in 1:length(ages)) {
		age<-ages[j]
		for(k in 1:length(wois)) {
			woi<-wois[k]
			for(l in 1:length(clusters)) {
				cluster<-clusters[l]
				region<-unique(eeg_data$Region[eeg_data$Cluster==cluster])[1]
				hemisphere<-unique(eeg_data$Hemisphere[eeg_data$Cluster==cluster])[1]
				cong_erd<-eeg_data$ERD[eeg_data$Subject==subject & eeg_data$Age==age & eeg_data$WOI==woi & eeg_data$Cluster==cluster & eeg_data$Condition=='unshuffled_congruent']
				incong_erd<-eeg_data$ERD[eeg_data$Subject==subject & eeg_data$Age==age & eeg_data$WOI==woi & eeg_data$Cluster==cluster & eeg_data$Condition=='unshuffled_incongruent']
				if(length(cong_erd)>0 && length(incong_erd)>0) {
					eeg_data<-rbind(eeg_data, data.frame(Subject=subject, Age=age, Region=region, Hemisphere=hemisphere, WOI=woi, FreqBand='mu', Cluster=cluster, Condition='unshuffled_congruent-unshuffled_incongruent', ERD=(cong_erd-incong_erd)))
				}
			}
		}
	}
}
write.csv(eeg_data,'/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/eeg_data.csv')

interaction_data_3m<-read.csv('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/3.5months_derived_events.csv')
interaction_data_6m<-read.csv('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/6.5months_derived_events.csv')
interaction_data<-data.frame()
interaction_data<-rbind(interaction_data,interaction_data_3m)
interaction_data<-rbind(interaction_data,interaction_data_6m)
write.csv(interaction_data,'/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/interaction_data.csv')
