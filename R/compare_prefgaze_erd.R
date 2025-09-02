compare_prefgaze_erd<-function(c) {

	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	library("Hmisc")

	output_file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_stats.txt',sep='')
	sink(output_file)

	# Specifies which bin size to use
	bin_size <- 0.1
 
	pg_data <-read.csv(file= "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv",header=TRUE,sep=",")
	# Use first block, and next block where subject saw at least 20 EEG trials
	pg_data <- pg_data[pg_data$Block==1 | pg_data$TrialsSeen>=20,]
	pg_data$Block[pg_data$Block>1]=2

	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(pg_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Age','Block'))

	# Remove times >5s
	#response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 1.6, window_end_time=2.2, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 30% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	response_window_agg_by_subject <- make_time_window_data(response_window_clean, aois=c('Congruent','Incongruent'), predictor_columns=c('Block'), summarize_by=c("Subject","Age", "Block"))
	response_window_agg_by_subject$AOI <- as.factor(response_window_agg_by_subject$AOI)

	x<-reshape(response_window_agg_by_subject, idvar=c("Subject","Age","Block"), timevar='AOI', direction="wide")
	x$Subject<-gsub('_6m','',x$Subject)
	x$Subject<-gsub('_9m','',x$Subject)
	x$PropDiff<-x$Prop.Congruent-x$Prop.Incongruent

	x<-x[,c("Subject","Age","Block","PropDiff")]
	x<-reshape(x, idvar=c("Subject","Age"), timevar='Block', direction="wide")
	x$ChangeDiff<-x$PropDiff.2-x$PropDiff.1
	x<-x[,c("Subject","Age","ChangeDiff")]
	x$Subject<-as.factor(x$Subject)

	print('500ms increments')
	erd_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue.csv')
	erd_data$Subject<-as.factor(erd_data$Subject)
	erd_data<-erd_data[erd_data$FreqBand=='mu' & (erd_data$WOI =='0-500ms'|erd_data$WOI =='500-1000ms'|erd_data$WOI=='1000-1500ms'|erd_data$WOI=='1500-2000ms'|erd_data$WOI=='2000-2500ms'|erd_data$WOI=='2500-3000ms') & (erd_data$Region=='C' | erd_data$Region=='P') & erd_data$Hemisphere=='right',]
	erd_data$Cluster<-''
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'left']<-'C3'
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'right']<-'C4'
	erd_data$Cluster[erd_data$Region == 'P' & erd_data$Hemisphere == 'left']<-'P3'
	erd_data$Cluster[erd_data$Region == 'P' & erd_data$Hemisphere == 'right']<-'P4'

	subjects<-unique(erd_data$Subject)
	ages<-unique(erd_data$Age)
	wois<-unique(erd_data$WOI)
	clusters<-unique(erd_data$Cluster)
	for(i in 1:length(subjects)) {
		subject<-subjects[i]
		for(j in 1:length(ages)) {
			age<-ages[j]
			for(k in 1:length(wois)) {
				woi<-wois[k]
				for(l in 1:length(clusters)) {
					cluster<-clusters[l]
					diff<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Cluster==cluster & erd_data$Condition=='unshuffled_congruent']-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Cluster==cluster & erd_data$Condition=='unshuffled_incongruent']
					if(length(diff)>0) {
						new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster=cluster, Condition='cong-incong', ERD=diff)
						erd_data <- rbind(erd_data, new_data)
					}
				}
				diff<-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_congruent'])-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_incongruent'])
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster='C4P4', Condition='cong-incong', ERD=diff)
					erd_data <- rbind(erd_data, new_data)
				}
				diff<-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_congruent'])
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster='C4P4', Condition='unshuffled_congruent', ERD=diff)
					erd_data <- rbind(erd_data, new_data)
				}
			}
		}
	}
	erd_data$Cluster<-as.factor(erd_data$Cluster)
	mu_congruent<-erd_data[erd_data$Cluster==c & erd_data$FreqBand=='mu' & erd_data$Condition=='cong-incong',]

	combined<-merge(x,mu_congruent,by=c('Subject','Age'))

	combined$WOIf<-factor(combined$WOI, levels=c('0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'))
	g<-ggplot(combined, aes(x=ERD, y=ChangeDiff)) + geom_point(shape=1) + geom_smooth(alpha=1.0,method=lm,formula=y~x)+facet_grid(WOIf~Age)+theme_bw()
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_cong-incong_block_diff_bias_500ms.png',sep=''))
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_cong-incong_block_diff_bias_500ms.eps',sep=''))

	print('Congruent-Incongruent')
	ages<-unique(combined$Age)
	wois<-unique(combined$WOI)
	for(i in 1:length(ages)) {
		age <- ages[i]
		for(j in 1:length(wois)) {
			woi <- wois[j]
			lm_data<-combined[combined$Age==age & combined$WOI==woi,]
			print(paste(age, ': ', woi, sep=''))
			erd.mod1 = lm(ChangeDiff ~ ERD, data = lm_data)
			print(summary(erd.mod1))
		}
	}



	mu_congruent<-erd_data[erd_data$Cluster==c & erd_data$FreqBand=='mu' & erd_data$Condition=='unshuffled_congruent',]

	combined<-merge(x,mu_congruent,by=c('Subject','Age'))

	combined$WOIf<-factor(combined$WOI, levels=c('0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'))
	g<-ggplot(combined, aes(x=ERD, y=ChangeDiff)) + geom_point(shape=1) + geom_smooth(alpha=1.0, method=lm,formula=y~x)+facet_grid(WOIf~Age)+theme_bw()
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_congruent_block_diff_bias_500ms.png',sep=''))
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_congruent_block_diff_bias_500ms.eps',sep=''))

	print('Congruent')
	ages<-unique(combined$Age)
	wois<-unique(combined$WOI)
	for(i in 1:length(ages)) {
		age <- ages[i]
		for(j in 1:length(wois)) {
			woi <- wois[j]
			lm_data<-combined[combined$Age==age & combined$WOI==woi,]
			print(paste(age, ': ', woi, sep=''))
			erd.mod1 = lm(ChangeDiff ~ ERD, data = lm_data)
			print(summary(erd.mod1))
		}
	}






	print('1000ms increments')
	erd_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue_coarse.csv')
	erd_data$Subject<-as.factor(erd_data$Subject)
	erd_data<-erd_data[erd_data$FreqBand=='mu' & (erd_data$WOI =='0-1000ms'|erd_data$WOI =='1000-2000ms'|erd_data$WOI=='2000-3000ms') & (erd_data$Region=='C' | erd_data$Region=='P') & erd_data$Hemisphere=='right',]
	erd_data$Cluster<-''
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'left']<-'C3'
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'right']<-'C4'
	erd_data$Cluster[erd_data$Region == 'P' & erd_data$Hemisphere == 'left']<-'P3'
	erd_data$Cluster[erd_data$Region == 'P' & erd_data$Hemisphere == 'right']<-'P4'

	subjects<-unique(erd_data$Subject)
	ages<-unique(erd_data$Age)
	wois<-unique(erd_data$WOI)
	clusters<-unique(erd_data$Cluster)
	for(i in 1:length(subjects)) {
		subject<-subjects[i]
		for(j in 1:length(ages)) {
			age<-ages[j]
			for(k in 1:length(wois)) {
				woi<-wois[k]
				for(l in 1:length(clusters)) {
					cluster<-clusters[l]
					diff<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Cluster==cluster & erd_data$Condition=='unshuffled_congruent']-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Cluster==cluster & erd_data$Condition=='unshuffled_incongruent']
					if(length(diff)>0) {
						new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster=cluster, Condition='cong-incong', ERD=diff)
						erd_data <- rbind(erd_data, new_data)
					}
				}
				diff<-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_congruent'])-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_incongruent'])
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster='C4P4', Condition='cong-incong', ERD=diff)
					erd_data <- rbind(erd_data, new_data)
				}
				diff<-mean(erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$WOI==woi & erd_data$Condition=='unshuffled_congruent'])
				if(length(diff)>0) {
					new_data <- data.frame(Subject=subject, Age=age, Region='', Hemisphere='', WOI=woi, FreqBand='mu', Cluster='C4P4', Condition='unshuffled_congruent', ERD=diff)
					erd_data <- rbind(erd_data, new_data)
				}
			}
		}
	}
	erd_data$Cluster<-as.factor(erd_data$Cluster)

	mu_congruent<-erd_data[erd_data$Cluster==c & erd_data$FreqBand=='mu' & erd_data$Condition=='cong-incong',]

	combined<-merge(x,mu_congruent,by=c('Subject','Age'))

	combined$WOIf<-factor(combined$WOI, levels=c('0-1000ms','1000-2000ms','2000-3000ms'))
	g<-ggplot(combined, aes(x=ERD, y=ChangeDiff)) + geom_point(shape=1) + geom_smooth(alpha=1.0, method=lm,formula=y~x)+facet_grid(WOIf~Age)+theme_bw()
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_cong-incong_block_diff_bias_1000ms.png',sep=''))
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_cong-incong_block_diff_bias_1000ms.eps',sep=''))

	print('Congruent-Incongruent')
	ages<-unique(combined$Age)
	wois<-unique(combined$WOI)
	for(i in 1:length(ages)) {
		age <- ages[i]
		for(j in 1:length(wois)) {
			woi <- wois[j]
			lm_data<-combined[combined$Age==age & combined$WOI==woi,]
			print(paste(age, ': ', woi, sep=''))
			erd.mod1 = lm(ChangeDiff ~ ERD, data = lm_data)
			print(summary(erd.mod1))
		}
	}



	mu_congruent<-erd_data[erd_data$Cluster==c & erd_data$FreqBand=='mu' & erd_data$Condition=='unshuffled_congruent',]

	combined<-merge(x,mu_congruent,by=c('Subject','Age'))

	combined$WOIf<-factor(combined$WOI, levels=c('0-1000ms','1000-2000ms','2000-3000ms'))
	g<-ggplot(combined, aes(x=ERD, y=ChangeDiff)) + geom_point(shape=1) + geom_smooth(alpha=1.0, method=lm,formula=y~x)+facet_grid(WOIf~Age)+theme_bw()
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_congruent_block_diff_bias_1000ms.png',sep=''))
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/window/',c,'_congruent_block_diff_bias_1000ms.eps',sep=''))

	print('Congruent')
	ages<-unique(combined$Age)
	wois<-unique(combined$WOI)
	for(i in 1:length(ages)) {
		age <- ages[i]
		for(j in 1:length(wois)) {
			woi <- wois[j]
			lm_data<-combined[combined$Age==age & combined$WOI==woi,]
			print(paste(age, ': ', woi, sep=''))
			erd.mod1 = lm(ChangeDiff ~ ERD, data = lm_data)
			print(summary(erd.mod1))
		}
	}

	sink()
}
