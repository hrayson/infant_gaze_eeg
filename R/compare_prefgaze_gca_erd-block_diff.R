compare_pg_erd <- function(woi) {
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	library("Hmisc")
	library("car")

	output_file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_diff_stats.txt',sep='')
	sink(output_file)

	# Specifies which bin size to use
	bin_size <- 0.1

	# Read PG data 
	pg_data <-read.csv(file= "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv",header=TRUE,sep=",")
	# Use first block, and next block where subject saw at least 20 EEG trials
	pg_data <- pg_data[pg_data$Block==1 | pg_data$TrialsSeen>=20,]
	pg_data$Block[pg_data$Block>1]=2

	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(pg_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Age','Block'))

	# Remove times >5s
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 30% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Convert to time sequence data
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Age","Block"), aois = c("Congruent","Incongruent"), summarize_by=c('Subject','Age','Block'))

	# Compute congruent - incongruent bias
	Subject<-c()
	Age<-c()
	TimeBin<-c()
	PropDiff<-c()
	Time<-c()
	ot1<-c()
	ot2<-c()
	ot3<-c()
	ot4<-c()
	ot5<-c()
	subjects<-unique(response_time$Subject)
	ages<-unique(response_time$Age)
	time_bins<-unique(response_time$TimeBin)
	for(i in 1:length(subjects)) {
		s<-subjects[i]
		for(j in 1:length(ages)) {
			a<-ages[j]
			for(l in 1:length(time_bins)) {
				tb<-time_bins[l]
				block_one_diff<-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent']-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Incongruent']
				block_two_diff<-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==2 & response_time$TimeBin==tb & response_time$AOI=='Congruent']-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==2 & response_time$TimeBin==tb & response_time$AOI=='Incongruent']
				diff=block_two_diff-block_one_diff			
				if(length(diff)>0) {
					Subject <- c(Subject, as.character(s))
					Age <- c(Age, as.character(a))
					TimeBin <- c(TimeBin, tb)
					PropDiff <- c(PropDiff, diff)
					Time<-c(Time, response_time$Time[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot1<-c(ot1, response_time$ot1[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot2<-c(ot2, response_time$ot2[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot3<-c(ot3, response_time$ot3[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot4<-c(ot4, response_time$ot4[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot5<-c(ot5, response_time$ot4[response_time$Subject==s & response_time$Age==a & response_time$Block==1 & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
				}
			}
		}
	}
	df_bias<-data.frame(Subject, Age, TimeBin, PropDiff, Time, ot1, ot2, ot3, ot4, ot5)
	df_bias$AOI<-'x'

	# Plot bias
	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="PropDiff", group="Age", color="Age", fill="Age")) + guides(color= guide_legend(title= 'Age')) +xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias.png',sep=''))
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias.eps',sep=''))

	# Read and Process EEG data
	erd_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs_saccade_cue.csv')
	erd_data$Subject<-as.factor(erd_data$Subject)
	erd_data<-erd_data[erd_data$FreqBand=='mu' & (erd_data$WOI ==woi) & (erd_data$Region=='C'),]
	erd_data$Cluster<-''
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'left']<-'C3'
	erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'right']<-'C4'
	erd_data$Cluster<-as.factor(erd_data$Cluster)

	df_bias$ERDCong<-0
	df_bias$ERDDiff<-0

	subjects<-unique(erd_data$Subject)
	ages<-unique(erd_data$Age)
	for(i in 1:length(subjects)) {
		subject<-subjects[i]
		for(j in 1:length(ages)) {
			age<-ages[j]
			cong_erd<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_congruent']
			diff_erd<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_congruent']-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_incongruent']
			if(length(diff_erd)>0) {
				df_bias$ERDCong[df_bias$Subject==paste(subject, age, sep ="_") & df_bias$Age==age]<-cong_erd
				df_bias$ERDDiff[df_bias$Subject==paste(subject, age, sep ="_") & df_bias$Age==age]<-diff_erd
			}
		}
	}


	sixm_median <- median(df_bias$ERDDiff[df_bias$Age=='6m'], na.rm=TRUE)
	ninem_median <- median(df_bias$ERDDiff[df_bias$Age=='9m'], na.rm=TRUE)
	df_bias$ERDDiffFactor[df_bias$Age=='6m'] <- ifelse(df_bias$ERDDiff[df_bias$Age=='6m'] > sixm_median, "Low", "High")
	df_bias$ERDDiffFactor[df_bias$Age=='9m'] <- ifelse(df_bias$ERDDiff[df_bias$Age=='9m'] > ninem_median, "Low", "High")
	df_bias$ERDDiffFactor<-as.factor(df_bias$ERDDiffFactor)

	sixm_median <- median(df_bias$ERDCong[df_bias$Age=='6m'], na.rm=TRUE)
	ninem_median <- median(df_bias$ERDCong[df_bias$Age=='9m'], na.rm=TRUE)
	df_bias$ERDCongFactor[df_bias$Age=='6m'] <- ifelse(df_bias$ERDCong[df_bias$Age=='6m'] > sixm_median, "Low", "High")
	df_bias$ERDCongFactor[df_bias$Age=='9m'] <- ifelse(df_bias$ERDCong[df_bias$Age=='9m'] > ninem_median, "Low", "High")
	df_bias$ERDCongFactor<-as.factor(df_bias$ERDCongFactor)

	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="PropDiff", group="ERDDiffFactor", color="ERDDiffFactor", fill="ERDDiffFactor")) + guides(color= guide_legend(title= 'ERDDiff')) +xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)
	# Saves model fit plots as png and eps
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/', woi, '_block_diff_bias-erd_diff.png', sep=''), width=12, height=7)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/', woi, '_block_diff_bias-erd_diff.eps', sep=''), width=12, height=7)

	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="PropDiff", group="ERDCongFactor", color="ERDCongFactor", fill="ERDCongFactor")) + guides(color= guide_legend(title= 'ERDCong')) +xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)
	# Saves model fit plots as png and eps
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_cong.png', sep=''), width=12, height=7)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_cong.eps', sep=''), width=12, height=7)

	# Create predictor for age = .5 if 9m, -.5 if 6m
	df_bias$AgeC <- ifelse(df_bias$Age == '9m', .5, -.5)
	# Center anxiety group variable
	df_bias$AgeC <- as.numeric(scale(df_bias$AgeC, center=TRUE, scale=FALSE))

	# Center trials seen variable
	df_bias$ERDDiffC <- as.numeric(scale(df_bias$ERDDiff, center=TRUE, scale=FALSE))
	df_bias$ERDCongC <- as.numeric(scale(df_bias$ERDCong, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDDiffC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)

	# Plot model fit - with age
	dev.new()
	formula_as_character <- Reduce(paste, deparse(formula(model_time_sequence)))
	df_bias$.Predicted = predict(model_time_sequence, df_bias, re.form = NA)
	df_plot <- group_by_.time_sequence_data(df_bias, .dots = c("Subject", "Time", "Age","ERDDiffFactor"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('PropDiff')))
	names(summarize_arg) <- 'PropDiff'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="PropDiff", group="ERDDiffFactor", color="ERDDiffFactor", fill="ERDDiffFactor")) + guides(color= guide_legend(title= 'ERDDiff')) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_diff_gca.png',sep=''), width=12, height=7)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_diff_gca.eps',sep=''), width=12, height=7)

	sixm_df_bias<-df_bias[df_bias$Age=='6m',]
	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDDiffC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = sixm_df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)


	ninem_df_bias<-df_bias[df_bias$Age=='9m',]
	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDDiffC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = ninem_df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)




	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDCongC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)

	# Plot model fit - with age
	dev.new()
	formula_as_character <- Reduce(paste, deparse(formula(model_time_sequence)))
	df_bias$.Predicted = predict(model_time_sequence, df_bias, re.form = NA)
	df_plot <- group_by_.time_sequence_data(df_bias, .dots = c("Subject", "Time", "Age","ERDCongFactor"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('PropDiff')))
	names(summarize_arg) <- 'PropDiff'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="PropDiff", group="ERDCongFactor", color="ERDCongFactor", fill="ERDCongFactor")) + guides(color= guide_legend(title= 'ERDCong')) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_cong_gca.png',sep=''), width=12, height=7)
	ggsave(file = paste('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/eeg/gca/',woi,'_block_diff_bias-erd_cong_gca.eps',sep=''), width=12, height=7)

	sixm_df_bias<-df_bias[df_bias$Age=='6m',]
	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDCongC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = sixm_df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)


	ninem_df_bias<-df_bias[df_bias$Age=='9m',]
	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(PropDiff ~ ERDCongC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = ninem_df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(results)

	sink()
}
