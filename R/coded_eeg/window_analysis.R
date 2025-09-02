window_analysis <- function(non_aoi_missing, data_file, output_dir) {

	# Loads eyetrackingR library so can use software
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	library("car")
	library("lsmeans")

	# Reads file containing preprocessed data from all subjects.
	data <-read.csv(file= data_file)

	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)

	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target', 'AntiTarget', 'Face'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Condition','Age'))

	# Re-zero times when mov1 message appears - beginning of movie
	eyetrackingr_data <- subset_by_window(eyetrackingr_data, window_start_msg = "mov1", msg_col = "Message", rezero = TRUE)

	# Only use up to 3s after start of movie stimulus
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=3, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	trackloss <- trackloss_analysis(data=response_window)
	print(trackloss)

	trackloss$Condition<-''
	for(i in 1:nrow(trackloss)) {
		subj <- trackloss$Subject[i]
		trial <- trackloss$Trial[i]
		trackloss$Condition[i] <- as.character(response_window$Condition[response_window$Subject==subj & response_window$Trial==trial & response_window$Message=='mov1'])
        }
	trackloss$Condition<-as.factor(trackloss$Condition)
	trackloss_model<-lmer(TracklossSamples ~ Condition + (1|Subject), data=trackloss, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	print(Anova(trackloss_model))

	# Remove trials with over 40% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)
	# Sanity checks. Looks at some descriptive statitics 
	data_summary <- describe_data(response_window_clean, describe_column = 'Face', group_columns = c('Condition', 'Subject'))
	print(data_summary)

	# Writes data summary to csv.  NOTE, as non-AOI looks are not treated as missing, proportion
	write.csv(data_summary, file = paste(output_dir, "all_subjects_means_face.csv"))

	# Plots data summary 
	dev.new()
	p<-plot(data_summary)
	print(p)
	ggsave(file=paste(output_dir,"participant_mean_face_lineplot.eps"))
	ggsave(file=paste(output_dir,"participant_mean_face_lineplot.png"))

	# Sanity checks. Looks at some descriptive statitics 
	data_summary <- describe_data(response_window_clean, describe_column = 'Target', group_columns = c('Condition', 'Subject'))
	print(data_summary)

	# Writes data summary to csv.  NOTE, as non-AOI looks are not treated as missing, proportion
	write.csv(data_summary, file = paste(output_dir,"all_subjects_means_target.csv"))

	# Plots data summary 
	dev.new()
	p<-plot(data_summary)
	print(p)
	ggsave(file=paste(output_dir,"participant_mean_target_lineplot.eps"))
	ggsave(file=paste(output_dir,"participant_mean_target_lineplot.png"))

	# Sanity checks. Looks at some descriptive statitics 
	data_summary <- describe_data(response_window_clean, describe_column = 'AntiTarget', group_columns = c('Condition', 'Subject'))
	print(data_summary)

	# Writes data summary to csv.  NOTE, as non-AOI looks are not treated as missing, proportion
	write.csv(data_summary, file = paste(output_dir,"all_subjects_means_antitarget.csv"))

	# Plots data summary 
	dev.new()
	p<-plot(data_summary)
	print(p)
	ggsave(file=paste(output_dir,"participant_mean_antitarget_lineplot.eps"))
	ggsave(file=paste(output_dir,"participant_mean_antitarget_lineplot.png"))

	# Averages proportion of looks to target/face/antitarget over trials (per subject) in eyetrackingR format
	response_window_agg_by_subject <- make_time_window_data(response_window_clean, aois= c('Face', 'Target', 'AntiTarget'), predictor_columns=c('Condition', 'Age'),summarize_by="Subject")

	# Plots mean looking time to angry and sad per subject. Note: used ArcSin transofrmation, but can use others (e.g Elog).
	dev.new()
	p<-plot(response_window_agg_by_subject, predictor_columns= c('Condition', 'Age'), dv="ArcSin")
	print(p)
	ggsave(file=paste(output_dir,"participant_mean_aoi_arcsin_barplot.eps"))
	ggsave(file=paste(output_dir,"participant_mean_aoi_arcsin_barplot.png"))

	# Sanity check: Prints out condition means over all subjects for (arcsine of) the proportion 
	print(describe_data(response_window_agg_by_subject,describe_column = "ArcSin", group_columns= c('AOI','Condition', 'Age')))


	# Averages proportion of looks over trials (makes in eyetrakingR format without aggregating over subject)
	response_window_agg <- make_time_window_data(response_window_clean, aois= c('Face', 'Target', 'AntiTarget'), predictor_columns=c('Condition', 'Age'))


	# Mixed model
	model_time_window_logit <- lmer(LogitAdjusted ~ AOI*Condition*Age + (1+Condition| Subject), data=response_window_agg, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	dev.new()
	p<-plot(model_time_window_logit)
	print(p)

	# use model comparison to get p values
	print(Anova(model_time_window_logit))

	lsm.options(pbkrtest.limit = 5031)

	condition_aoi<-lsmeans(model_time_window_logit,pairwise~Condition*AOI|AOI,adjust='tukey')
	print(summary(condition_aoi)$contrasts)

	aoi_condition<-lsmeans(model_time_window_logit,pairwise~Condition*AOI|Condition,adjust='tukey')
	print(summary(aoi_condition)$contrasts)

	age_aoi<-lsmeans(model_time_window_logit,pairwise~Age*AOI|AOI,adjust='tukey')
	print(summary(age_aoi)$contrasts)

	sink()
}
