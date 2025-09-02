gca <- function(bin_size, non_aoi_missing, data_file, output_dir) {
	# Loads eyetrackingR library so can use software
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	library("car")
	library("lsmeans")
	source('helpers.R')

	# Reads file containing preprocessed data from all subjects.
	data <-read.csv(file= data_file,header=TRUE,sep=",")
	
	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)
	
	
	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target', 'AntiTarget', 'Face'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Condition','Age'))

	# Re-zero times when mov1 message appears - beginning of movie
	eyetrackingr_data <- subset_by_window(eyetrackingr_data, window_start_msg = "mov1", msg_col = "Message", rezero = TRUE)

	# Only use up to 3s after start of movie stimulus
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=3, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 30% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data	
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Target","AntiTarget","Face"))
	
	# Crazy plotting stuff - plot timecourse with age
	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Condition", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial (s)')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Condition ~ Age) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	#ggsave(file = paste(output_dir, "all_timecourse_aoi_", bin_size, ".png", sep =""))
	#ggsave(file = paste(output_dir, "all_timecourse_aoi_", bin_size, ".eps", sep =""))

	# Crazy plotting stuff - plot timecourse with age
	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Condition", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="Age", color="Age", fill="Age")) + xlab('Time in Trial (s)')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Condition ~ AOI) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	#ggsave(file = paste(output_dir, "all_timecourse_age_", bin_size, ".png", sep =""))
	#ggsave(file = paste(output_dir, "all_timecourse_age_", bin_size, ".eps", sep =""))

	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Condition", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="Condition", color="Condition", fill="Condition")) + xlab('Time in Trial (s)')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Age ~ AOI) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	#ggsave(file = paste(output_dir, "all_timecourse_condition_", bin_size, ".png", sep =""))
	#ggsave(file = paste(output_dir, "all_timecourse_condition_", bin_size, ".eps", sep =""))

	# GCA- run model (LogitAdjusted), drop method, plot
	model_time_sequence <- lmer(LogitAdjusted ~ AOI*Condition*Age*(ot1 + ot2 + ot3 + ot4)  + (1+Condition|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	print("Stats")
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*Age*ot1|AOI*Condition)
	print(summary(pw)$contrasts)
	
	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*Age*ot1|AOI*Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*Age*ot1|Condition*Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot2|AOI)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot2|Condition)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot3|AOI)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot3|Condition)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot4|AOI)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Condition*ot4|Condition)
	print(summary(pw)$contrasts)

	# Plot model fit - with age
	dev.new()
	formula_as_character <- Reduce(paste, deparse(formula(model_time_sequence)))
	response_time$.Predicted = predict(model_time_sequence, response_time, re.form = NA)
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Condition", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('LogitAdjusted')))
	names(summarize_arg) <- 'LogitAdjusted'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="LogitAdjusted", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial (s)')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_grid(Condition ~ Age) + ylab(paste0("Looking to ", df_plot$AOI[1], " (LogitAdjusted)"))+theme_bw()
	print(g)

	# Saves model fit plots as png and eps
	#ggsave(file = paste(output_dir, "all_gca_", bin_size, ".png", sep =""))
	#ggsave(file = paste(output_dir, "all_gca_", bin_size, ".eps", sep =""))


	print('***** Target *****')
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Target"))
	# GCA- run model (LogitAdjusted), drop method, plot
	model_time_sequence <- lmer(LogitAdjusted ~ Condition*Age*(ot1 + ot2 + ot3 + ot4)  + (1+Condition|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	print("Stats")
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Condition)
	print(summary(pw)$contrasts)
	
	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot2)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot3)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot4)
	print(summary(pw)$contrasts)



	print('***** AntiTarget *****')
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("AntiTarget"))
	# GCA- run model (LogitAdjusted), drop method, plot
	model_time_sequence <- lmer(LogitAdjusted ~ Condition*Age*(ot1 + ot2 + ot3 + ot4)  + (1+Condition|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	print("Stats")
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Condition)
	print(summary(pw)$contrasts)
	
	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot2)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot3)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot4)
	print(summary(pw)$contrasts)



	print('***** Face *****')
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Face"))
	# GCA- run model (LogitAdjusted), drop method, plot
	model_time_sequence <- lmer(LogitAdjusted ~ Condition*Age*(ot1 + ot2 + ot3 + ot4)  + (1+Condition|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	print("Stats")
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Condition)
	print(summary(pw)$contrasts)
	
	pw<-lsmeans(model_time_sequence,pairwise~Condition*Age*ot1|Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot2)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot3)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~Condition*ot4)
	print(summary(pw)$contrasts)

	sink()
}
