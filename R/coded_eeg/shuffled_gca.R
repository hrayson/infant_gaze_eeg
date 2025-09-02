shuffled_gca <- function(bin_size, non_aoi_missing, data_file, output_dir) {
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
	data<-data[data$Condition=='shuffled',]

	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)	
	
	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target', 'AntiTarget', 'Face'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Congruence','Age'))

	# Re-zero times when mov1 message appears - beginning of movie
	eyetrackingr_data <- subset_by_window(eyetrackingr_data, window_start_msg = "mov1", msg_col = "Message", rezero = TRUE)

	# Only use up to 3s after start of movie stimulus
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=3, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 30% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data	
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Congruence","Age"), aois = c("Target","AntiTarget","Face"))
	
	# Crazy plotting stuff - plot timecourse with age
	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Congruence", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Congruence ~ Age) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_aoi_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_timecourse_aoi_", bin_size, ".eps", sep =""))

	# Crazy plotting stuff - plot timecourse with age
	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Congruence", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="Age", color="Age", fill="Age")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Congruence ~ AOI) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_age_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_timecourse_age_", bin_size, ".eps", sep =""))

	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Congruence", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="Congruence", color="Congruence", fill="Congruence")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Age ~ AOI) + ylab(paste0("Looking to AOI (Prop)"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_congruence_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_timecourse_congruence_", bin_size, ".eps", sep =""))

	# Create predictor for aoi = -.5 if antitarget, 0 if face, .5 if target
	#response_time$AOIC <- ifelse(response_time$AOI == 'Target', .5, ifelse(response_time$AOI == 'Face', 0, -.5))
	# Center aoi variable
	#response_time$AOIC <- as.numeric(scale(response_time$AOIC, center=TRUE, scale=FALSE))

	# Create predictor for condition = -.5 if shuffled, 0 if incongruent, .5 if congruent
	#response_time$ConditionC <- ifelse(response_time$Condition == 'congruent', .5, ifelse(response_time$Condition == 'incongruent', 0, -.5))
	# Center condition variable
	#response_time$ConditionC <- as.numeric(scale(response_time$ConditionC, center=TRUE, scale=FALSE))

	# Create predictor for age = .5 if 9m, -.5 if 6m
	#response_time$AgeC <- ifelse(response_time$Age == '9m', .5, -.5)
	# Center age variable
	#response_time$AgeC <- as.numeric(scale(response_time$AgeC, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted), drop method, plot
	#model_time_sequence <- lmer(LogitAdjusted ~ AOIC*ConditionC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	model_time_sequence <- lmer(LogitAdjusted ~ AOI*Congruence*Age*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	#results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Congruence*Age*ot1|AOI*Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Congruence*Age*ot2|AOI*Age)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Congruence*ot3|AOI)
	print(summary(pw)$contrasts)

	pw<-lsmeans(model_time_sequence,pairwise~AOI*Congruence*ot4|AOI)
	print(summary(pw)$contrasts)

	# Plot model fit - with age
	dev.new()
	formula_as_character <- Reduce(paste, deparse(formula(model_time_sequence)))
	response_time$.Predicted = predict(model_time_sequence, response_time, re.form = NA)
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Congruence", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('LogitAdjusted')))
	names(summarize_arg) <- 'LogitAdjusted'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="LogitAdjusted", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_grid(Congruence ~ Age) + ylab(paste0("Looking to ", df_plot$AOI[1], " (LogitAdjusted)"))+theme_bw()
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".eps", sep =""))


	sink()
}
