library("eyetrackingR")
library("lme4")
library("car")
library("lsmeans")

data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv',header=TRUE,sep=",")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gaze_shift_pattern/stats.txt'
sink(output_file)

# Converts data into eyetrackingR format.
eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target', 'AntiTarget', 'Face'), treat_non_aoi_looks_as_missing = TRUE, item_columns = c('Condition','Age'))

# Re-zero times when mov1 message appears - beginning of movie
eyetrackingr_data <- subset_by_window(eyetrackingr_data, window_start_msg = "mov1", msg_col = "Message", rezero = TRUE)

# Only use up to 3s after start of movie stimulus
response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=3, remove = TRUE)

# Analyse amount of trackloss by subjects and trials
(trackloss <- trackloss_analysis(data=response_window))

# Remove trials with over 30% trackloss
response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

# Gaze shift
gs_data<-data.frame(Subject=character(), Age=character(), Condition=character(), FirstFaceLookTime=double(), FirstFaceLookProp=double(), FirstAdultTargetLookTime=double(), FirstAdultTargetLookProp=double(), AlternateAdultTargetProp=double(), AlternateAdultTargetLatency=double(), FirstCuedTargetLookTime=double, FirstCuedTargetLookProp=double(), AlternateCuedTargetProp=double(), AlternateCuedTargetLatency=double(), FirstUncuedTargetLookTime=double, FirstUncuedTargetLookProp=double(), AlternateUncuedTargetProp=double(), AlternateUncuedTargetLatency=double())

# Minimum time looking between face and object to declare alternate looking
min_alternate_time<-10
all_alternate_latencies<-c()

ages<-unique(response_window_clean$Age)
conditions<-unique(response_window_clean$Condition)

for(m in 1:length(ages)) {
	age<-ages[m]

	subjects<-unique(response_window_clean$Subject[response_window_clean$Age==age])


	for(i in 1:length(subjects)) {
		subj_id<-subjects[i]
		subj_data<-response_window_clean[response_window_clean$Subject==subj_id & response_window_clean$Age==age,]
	
		for(j in 1:length(conditions)) {
			condition<-conditions[j]
			cond_data<-subj_data[subj_data$Condition==condition,]
			trials<-unique(cond_data$Trial)

			# Time of first look to face for each trial in this condition
			cond_first_face_look_times<-c()
			# Time of first look to adult target (after face) for each trial in this condition
			cond_first_adult_target_look_times<-c()
			# Time of first look to cued target (after face) for each trial in this condition
			cond_first_cued_target_look_times<-c()
			# Time of first look to uncued target (after face) for each trial in this condition
			cond_first_uncued_target_look_times<-c()
			# Whether or not alternated between face and adult target (after initial look to face) for each trial in this condition
			cond_alternate_adult_target<-c()
			# Whether or not alternated between face and cued target (after initial look to face) for each trial in this condition
			cond_alternate_cued_target<-c()
			# Whether or not alternated between face and uncued target (after initial look to face) for each trial in this condition
			cond_alternate_uncued_target<-c()
			# Latency during alternated between face and adult target (after initial look to face) for each trial in this condition
			cond_alternate_adult_target_latency<-c()
			# Latency during alternated between face and cued target (after initial look to face) for each trial in this condition
			cond_alternate_cued_target_latency<-c()
			# Latency during alternated between face and uncued target (after initial look to face) for each trial in this condition
			cond_alternate_uncued_target_latency<-c()

			for(k in 1:length(trials)) {
				trial<-trials[k]
				trial_data<-cond_data[cond_data$Trial==trial,]

				# First look to face after target
				first_face_look_time<-NA
				first_face_look_idx<-NA
				for(l in 1:nrow(trial_data)) {
					if(!trial_data$Trackloss[l]) {
						if(trial_data$Face[l]==TRUE) {
							first_face_look_time<-trial_data$TrialTime[l]
							first_face_look_idx<-l
							break
						} else if(trial_data$AntiTarget[l]==TRUE) {
							break
						}
					}
				}
				cond_first_face_look_times<-c(cond_first_face_look_times,first_face_look_time)
	
				# First look to adult target after face
				first_adult_target_look_time<-NA
				first_adult_target_look_idx<-NA
				alternate_adult_target<-0
				alternate_adult_target_latency<-NA
				if(!is.na(first_face_look_time) & first_face_look_idx<nrow(trial_data)) {
					start<-first_face_look_idx+1
					for(l in start:nrow(trial_data)) {
						if(!trial_data$Trackloss[l]) {
							if((condition=='congruent' & trial_data$Target[l]==TRUE) | (condition=='incongruent' & trial_data$AntiTarget[l]==TRUE)) {
								first_adult_target_look_time<-trial_data$TrialTime[l]-first_face_look_time
								first_adult_target_look_idx<-l
								break
							} else if((condition=='congruent' & trial_data$AntiTarget[l]==TRUE) | (condition=='incongruent' & trial_data$Target[l]==TRUE)) {
								break
							}
						}
					}

					if(!is.na(first_adult_target_look_time) & first_adult_target_look_idx<nrow(trial_data) & first_adult_target_look_time<=min_alternate_time) {
						start<-first_adult_target_look_idx+1
						for(l in start:nrow(trial_data)) {
							if(!trial_data$Trackloss[l]) {
								latency<-trial_data$TrialTime[l]-first_adult_target_look_time
								if(trial_data$Face[l]==TRUE & latency<=min_alternate_time) {
									alternate_adult_target<-1
									alternate_adult_target_latency<-latency
									all_alternate_latencies<-c(all_alternate_latencies, first_adult_target_look_time, latency)
									break
								} else if((condition=='congruent' & trial_data$AntiTarget[l]==TRUE) | (condition=='incongruent' & trial_data$Target[l]==TRUE)) {
									break
								}
							}
						}
					}

				}
				cond_first_adult_target_look_times<-c(cond_first_adult_target_look_times,first_adult_target_look_time)
				cond_alternate_adult_target<-c(cond_alternate_adult_target, alternate_adult_target)
				cond_alternate_adult_target_latency<-c(cond_alternate_adult_target_latency, alternate_adult_target_latency)
	
				# First look to cued target after face
				first_cued_target_look_time<-NA
				first_cued_target_look_idx<-NA
				alternate_cued_target<-0
				alternate_cued_target_latency<-NA
				if(!is.na(first_face_look_time) & first_face_look_idx<nrow(trial_data)) {
					start<-first_face_look_idx+1
					for(l in start:nrow(trial_data)) {
						if(!trial_data$Trackloss[l]) {
							if(trial_data$Target[l]==TRUE)  {
								first_cued_target_look_time<-trial_data$TrialTime[l]-first_face_look_time
								first_cued_target_look_idx<-l
								break
							} else if(trial_data$AntiTarget[l]==TRUE) {
								break
							}
						}
					}

					if(!is.na(first_cued_target_look_time) & first_cued_target_look_idx<nrow(trial_data) & first_cued_target_look_time<=min_alternate_time) {
						start<-first_cued_target_look_idx+1
						for(l in start:nrow(trial_data)) {
							if(!trial_data$Trackloss[l]) {
								latency<-trial_data$TrialTime[l]-first_cued_target_look_time
								if(trial_data$Face[l]==TRUE & latency<=min_alternate_time) {
									alternate_cued_target<-1
									alternate_cued_target_latency<-latency
									all_alternate_latencies<-c(all_alternate_latencies, first_cued_target_look_time, latency)
									break
								} else if(trial_data$AntiTarget[l]==TRUE) {
									break
								}
							}
						}
					}
				}
				cond_first_cued_target_look_times<-c(cond_first_cued_target_look_times,first_cued_target_look_time)
				cond_alternate_cued_target<-c(cond_alternate_cued_target, alternate_cued_target)
				cond_alternate_cued_target_latency<-c(cond_alternate_cued_target_latency, alternate_cued_target_latency)
	
				# First look to uncued target after face
				first_uncued_target_look_time<-NA
				first_uncued_target_look_idx<-NA
				alternate_uncued_target<-0
				alternate_uncued_target_latency<-NA
				if(!is.na(first_face_look_time) & first_face_look_idx<nrow(trial_data)) {
					start<-first_face_look_idx+1
					for(l in start:nrow(trial_data)) {
						if(!trial_data$Trackloss[l]) {
							if(trial_data$AntiTarget[l]==TRUE)  {
								first_uncued_target_look_time<-trial_data$TrialTime[l]-first_face_look_time
								first_uncued_target_look_idx<-l
								break
							} else if(trial_data$Target[l]==TRUE) {
								break
							}
						}
					}

					if(!is.na(first_uncued_target_look_time) & first_uncued_target_look_idx<nrow(trial_data) & first_uncued_target_look_time<=min_alternate_time) {
						start<-first_uncued_target_look_idx+1
						for(l in start:nrow(trial_data)) {
							if(!trial_data$Trackloss[l]) {
								latency<-trial_data$TrialTime[l]-first_uncued_target_look_time
								if(trial_data$Face[l]==TRUE & latency<=min_alternate_time) {
									alternate_uncued_target<-1
									alternate_uncued_target_latency<-latency
									all_alternate_latencies<-c(all_alternate_latencies, first_uncued_target_look_time, latency)
									break
								} else if(trial_data$Target[l]==TRUE) {
									break
								}
							}
						}
					}
				}
				cond_first_uncued_target_look_times<-c(cond_first_uncued_target_look_times,first_uncued_target_look_time)
				cond_alternate_uncued_target<-c(cond_alternate_uncued_target, alternate_uncued_target)
				cond_alternate_uncued_target_latency<-c(cond_alternate_uncued_target_latency, alternate_uncued_target_latency)
			}
			mean_first_face_look_time<-mean(cond_first_face_look_times,na.rm=TRUE)
			first_face_look_prop<-length(cond_first_face_look_times[!is.na(cond_first_face_look_times)])/length(trials)

			mean_first_adult_target_look_time<-mean(cond_first_adult_target_look_times,na.rm=TRUE)
			first_adult_target_look_prop<-length(cond_first_adult_target_look_times[!is.na(cond_first_adult_target_look_times)])/length(trials)
			alternate_adult_target_prop<-sum(cond_alternate_adult_target)/length(trials)
			alternate_adult_target_latency<-mean(cond_alternate_adult_target_latency,na.rm=TRUE)

			mean_first_cued_target_look_time<-mean(cond_first_cued_target_look_times,na.rm=TRUE)
			first_cued_target_look_prop<-length(cond_first_cued_target_look_times[!is.na(cond_first_cued_target_look_times)])/length(trials)
			alternate_cued_target_prop<-sum(cond_alternate_cued_target)/length(trials)
			alternate_cued_target_latency<-mean(cond_alternate_cued_target_latency,na.rm=TRUE)

			mean_first_uncued_target_look_time<-mean(cond_first_uncued_target_look_times,na.rm=TRUE)
			first_uncued_target_look_prop<-length(cond_first_uncued_target_look_times[!is.na(cond_first_uncued_target_look_times)])/length(trials)
			alternate_uncued_target_prop<-sum(cond_alternate_uncued_target)/length(trials)
			alternate_uncued_target_latency<-mean(cond_alternate_uncued_target_latency,na.rm=TRUE)
	
			row<-list(Subject=subj_id, Age=age, Condition=condition, FirstFaceLookTime=mean_first_face_look_time, FirstFaceLookProp=first_face_look_prop, FirstAdultTargetLookTime=mean_first_adult_target_look_time, FirstAdultTargetLookProp=first_adult_target_look_prop, AlternateAdultTargetProp=alternate_adult_target_prop, AlternateAdultTargetLatency=alternate_adult_target_latency,  FirstCuedTargetLookTime=mean_first_cued_target_look_time, FirstCuedTargetLookProp=first_cued_target_look_prop, AlternateCuedTargetProp=alternate_cued_target_prop, AlternateCuedTargetLatency=alternate_cued_target_latency, FirstUncuedTargetLookTime=mean_first_uncued_target_look_time, FirstUncuedTargetLookProp=first_uncued_target_look_prop, AlternateUncuedTargetProp=alternate_uncued_target_prop, AlternateUncuedTargetLatency=alternate_uncued_target_latency)
			gs_data=rbind(gs_data, row, stringsAsFactors=FALSE)
		}
	}
}

gs_data$Subject<-as.character(gs_data$Subject)
gs_data$Subject<-substr(gs_data$Subject,1,nchar(gs_data$Subject)-3)
gs_data$Subject<-as.factor(gs_data$Subject)

sixm_data<-gs_data[gs_data$Age=='6m',]
for(i in 1:length(conditions)) {
	cond<-conditions[i]
	sixm_cond_data<-sixm_data[sixm_data$Condition==cond,]
	print(paste('6m ', cond))
	print(paste('First look face, prop: M=',mean(sixm_cond_data$FirstFaceLookProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstFaceLookProp,na.rm=TRUE)))
	print(paste('First look face, time: M=',mean(sixm_cond_data$FirstFaceLookTime,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstFaceLookTime,na.rm=TRUE)))
	print(paste('First look adult target, prop: M=',mean(sixm_cond_data$FirstAdultTargetLookProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstAdultTargetLookProp,na.rm=TRUE)))
	print(paste('First look adult target, time: M=',mean(sixm_cond_data$FirstAdultTargetLookTime,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstAdultTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look adult target, prop: M=',mean(sixm_cond_data$AlternateAdultTargetProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateAdultTargetProp,na.rm=TRUE)))
	print(paste('Alternating look adult target, latency: M=',mean(sixm_cond_data$AlternateAdultTargetLatency,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateAdultTargetLatency,na.rm=TRUE)))
	print(paste('First look cued target, prop: M=',mean(sixm_cond_data$FirstCuedTargetLookProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstCuedTargetLookProp,na.rm=TRUE)))
	print(paste('First look cued target, time: M=',mean(sixm_cond_data$FirstCuedTargetLookTime,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstCuedTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look cued target, prop: M=',mean(sixm_cond_data$AlternateCuedTargetProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateCuedTargetProp,na.rm=TRUE)))
	print(paste('Alternating look cued target, latency: M=',mean(sixm_cond_data$AlternateCuedTargetLatency,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateCuedTargetLatency,na.rm=TRUE)))
	print(paste('First look uncued target, prop: M=',mean(sixm_cond_data$FirstUncuedTargetLookProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstUncuedTargetLookProp,na.rm=TRUE)))
	print(paste('First look uncued target, time: M=',mean(sixm_cond_data$FirstUncuedTargetLookTime,na.rm=TRUE),', SD=',sd(sixm_cond_data$FirstUncuedTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look uncued target, prop: M=',mean(sixm_cond_data$AlternateUncuedTargetProp,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateUncuedTargetProp,na.rm=TRUE)))
	print(paste('Alternating look uncued target, latency: M=',mean(sixm_cond_data$AlternateUncuedTargetLatency,na.rm=TRUE),', SD=',sd(sixm_cond_data$AlternateUncuedTargetLatency,na.rm=TRUE)))
}

ninem_data<-gs_data[gs_data$Age=='9m',]
for(i in 1:length(conditions)) {
	cond<-conditions[i]
	ninem_cond_data<-ninem_data[ninem_data$Condition==cond,]
	print(paste('9m ', cond))
	print(paste('First look face, prop: M=',mean(ninem_cond_data$FirstFaceLookProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstFaceLookProp,na.rm=TRUE)))
	print(paste('First look face, time: M=',mean(ninem_cond_data$FirstFaceLookTime,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstFaceLookTime,na.rm=TRUE)))
	print(paste('First look adult target, prop: M=',mean(ninem_cond_data$FirstAdultTargetLookProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstAdultTargetLookProp,na.rm=TRUE)))
	print(paste('First look adult target, time: M=',mean(ninem_cond_data$FirstAdultTargetLookTime,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstAdultTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look adult target, prop: M=',mean(ninem_cond_data$AlternateAdultTargetProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateAdultTargetProp,na.rm=TRUE)))
	print(paste('Alternating look adult target, latency: M=',mean(ninem_cond_data$AlternateAdultTargetLatency,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateAdultTargetLatency,na.rm=TRUE)))
	print(paste('First look cued target, prop: M=',mean(ninem_cond_data$FirstCuedTargetLookProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstCuedTargetLookProp,na.rm=TRUE)))
	print(paste('First look cued target, time: M=',mean(ninem_cond_data$FirstCuedTargetLookTime,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstCuedTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look cued target, prop: M=',mean(ninem_cond_data$AlternateCuedTargetProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateCuedTargetProp,na.rm=TRUE)))
	print(paste('Alternating look cued target, latency: M=',mean(ninem_cond_data$AlternateCuedTargetLatency,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateCuedTargetLatency,na.rm=TRUE)))
	print(paste('First look uncued target, prop: M=',mean(ninem_cond_data$FirstUncuedTargetLookProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstUncuedTargetLookProp,na.rm=TRUE)))
	print(paste('First look uncued target, time: M=',mean(ninem_cond_data$FirstUncuedTargetLookTime,na.rm=TRUE),', SD=',sd(ninem_cond_data$FirstUncuedTargetLookTime,na.rm=TRUE)))
	print(paste('Alternating look uncued target, prop: M=',mean(ninem_cond_data$AlternateUncuedTargetProp,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateUncuedTargetProp,na.rm=TRUE)))
	print(paste('Alternating look uncued target, latency: M=',mean(ninem_cond_data$AlternateUncuedTargetLatency,na.rm=TRUE),', SD=',sd(ninem_cond_data$AlternateUncuedTargetLatency,na.rm=TRUE)))
}

.logit_adj <- function(prop) {
	non_zero_ind<-which(prop!=0)
	if(length(non_zero_ind)<1) return(NA)
	smallest <- min(prop[non_zero_ind],na.rm=TRUE)
	prop_adj<-prop
	prop_adj<-ifelse(prop_adj==1, 1-smallest/2, prop_adj)
	prop_adj<-ifelse(prop_adj==0, smallest/2, prop_adj)
	return( log(prop_adj/(1-prop_adj)) )
}

gs_data$LogitFirstFaceLookProp<-.logit_adj(gs_data$FirstFaceLookProp)
#model <- lmer(FirstFaceLookProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitFirstFaceLookProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
model <- lmer(FirstFaceLookTime ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Age)
print(summary(pw)$contrasts)

gs_data$LogitFirstAdultTargetLookProp<-.logit_adj(gs_data$FirstAdultTargetLookProp)
#model <- lmer(FirstAdultTargetLookProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitFirstAdultTargetLookProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
model <- lmer(FirstAdultTargetLookTime ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Age)
print(summary(pw)$contrasts)
gs_data$LogitAlternateAdultTargetProp<-.logit_adj(gs_data$AlternateAdultTargetProp)
#model <- lmer(AlternateAdultTargetProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitAlternateAdultTargetProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
model <- lmer(AlternateAdultTargetLatency ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Age)
print(summary(pw)$contrasts)

gs_data$LogitFirstCuedTargetLookProp<-.logit_adj(gs_data$FirstCuedTargetLookProp)
#model <- lmer(FirstCuedTargetLookProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitFirstCuedTargetLookProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
model <- lmer(FirstCuedTargetLookTime ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
gs_data$LogitAlternateCuedTargetProp<-.logit_adj(gs_data$AlternateCuedTargetProp)
#model <- lmer(AlternateCuedTargetProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitAlternateCuedTargetProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
model <- lmer(AlternateCuedTargetLatency ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))

gs_data$LogitFirstUncuedTargetLookProp<-.logit_adj(gs_data$FirstUncuedTargetLookProp)
#model <- lmer(FirstUncuedTargetLookProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitFirstUncuedTargetLookProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
model <- lmer(FirstUncuedTargetLookTime ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
pw<-lsmeans(model,pairwise~Age)
print(summary(pw)$contrasts)
pw<-lsmeans(model,pairwise~Condition)
print(summary(pw)$contrasts)
gs_data$LogitAlternateUncuedTargetProp<-.logit_adj(gs_data$AlternateUncuedTargetProp)
#model <- lmer(AlternateUncuedTargetProp ~ Age*Condition + (1+Condition|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
model <- lmer(LogitAlternateUncuedTargetProp ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))
model <- lmer(AlternateUncuedTargetLatency ~ Age*Condition + (1|Subject), data = gs_data, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
print(Anova(model))

sink()
