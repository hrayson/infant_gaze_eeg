gca_trials_seen <- function(bin_size, non_aoi_missing, data_file, output_dir) {

	# Loads eyetrackingR library so can use software
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	source('helpers.R')
	

	# Reads file containing preprocessed data from all subjects.
	data <-read.csv(file= data_file,header=TRUE,sep=",")
	# Remove 102_9m, 111_6m - had at least one block where didn't look at either face
	#data <- data[data$Subject!='102_9m' & data$Subject!='111_6m',]
	# Use first block, and next block where subject saw at least 20 EEG trials
	data <- data[data$Block==1 | data$TrialsSeen>=20,]
	data$Block[data$Block>1]=2
	# Get only second block
	data <- data[data$Block==2,]

	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)

	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = non_aoi_missing)

	# Remove times >5s
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 40% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Age","TrialsSeen"), aois = c("Congruent","Incongruent"))

	#response_time$Prop[response_time$AOI=='Incongruent'] <- response_time$Prop[response_time$AOI=='Incongruent']*-1

	#df_bias <- aggregate(response_time$Prop, by=list(Subject=response_time$Subject, Age=response_time$Age, TrialsSeen=response_time$TrialsSeen, TimeBin=response_time$TimeBin, Time=response_time$Time, ot1=response_time$ot1, ot2=response_time$ot2, ot3=response_time$ot3, ot4=response_time$ot4), FUN=sum)
	# Summarize over trials for each participant within each time bin - gives Prop trials spent looking at each AOI, per emotion type
	data_options = attr(response_time, "eyetrackingR")$data_options
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c(data_options$participant_column, "TrialsSeen", data_options$trial_column, "Time", "AOI", "ot1", "ot2", "ot3", "ot4", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	
	# Subtract Prop(Emotion)-Prop(Neutral) for each time bin for each subject, within emotion type
	df_bias<-aggregate(x~Subject+TrialsSeen+Time+ot1+ot2+ot3+ot4+Age, with(df_plot, data.frame(Subject=Subject, TrialsSeen=TrialsSeen, Trial=Trial, Time=Time, ot1=ot1, ot2=ot2, ot3=ot3, ot4=ot4, Age=Age, x=ifelse(AOI=='Congruent', 1, ifelse(AOI=='Incongruent', -1, 0))*Prop)), sum)

	data_options <- attr(response_window, "eyetrackingR")$data_options
	class(df_bias) <- c('time_sequence_data', class(df_bias))
	attr(df_bias,"eyetrackingR") <- list(
	      data_options = data_options,
	      summarized_by = NULL,
	      time_bin_size = bin_size)

	df_bias$Prop<-df_bias$x
	df_bias$AOI<-'x'

	the_median <- median(df_bias[['TrialsSeen']], na.rm=TRUE)
	df_bias[["TrialsSeenFactor"]] <- ifelse(df_bias[['TrialsSeen']] > the_median, paste0("High (>", round(the_median,2), ")"), "Low")

	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="x", group="TrialsSeenFactor", color="TrialsSeenFactor")) + guides(color= guide_legend(title= 'TrialsSeen')) +xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".png", sep =""), width=12, height=7)
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".eps", sep =""), width=12, height=7)

	# Create predictor for age = .5 if 9m, -.5 if 6m
	df_bias$AgeC <- ifelse(df_bias$Age == '9m', .5, -.5)
	# Center anxiety group variable
	df_bias$AgeC <- as.numeric(scale(df_bias$AgeC, center=TRUE, scale=FALSE))

	# Center trials seen variable
	df_bias$TrialsSeenC <- as.numeric(scale(df_bias$TrialsSeen, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(x ~ TrialsSeenC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
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
	df_plot <- group_by_.time_sequence_data(df_bias, .dots = c("Subject", "Time", "TrialsSeenFactor", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('x')))
	names(summarize_arg) <- 'x'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="x", group="TrialsSeenFactor", color="TrialsSeenFactor")) + guides(color= guide_legend(title= 'TrialsSeen')) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_grid(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".png", sep =""), width=12, height=7)
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".eps", sep =""), width=12, height=7)


	
	print('Combined')
	data_options = attr(response_time, "eyetrackingR")$data_options
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c(data_options$participant_column, "TrialsSeen", data_options$trial_column, "Time", "AOI", "ot1", "ot2", "ot3", "ot4"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	
	# Subtract Prop(Emotion)-Prop(Neutral) for each time bin for each subject, within emotion type
	df_bias<-aggregate(x~Subject+TrialsSeen+Time+ot1+ot2+ot3+ot4, with(df_plot, data.frame(Subject=Subject, TrialsSeen=TrialsSeen, Trial=Trial, Time=Time, ot1=ot1, ot2=ot2, ot3=ot3, ot4=ot4, x=ifelse(AOI=='Congruent', 1, ifelse(AOI=='Incongruent', -1, 0))*Prop)), sum)

	data_options <- attr(response_window, "eyetrackingR")$data_options
	class(df_bias) <- c('time_sequence_data', class(df_bias))
	attr(df_bias,"eyetrackingR") <- list(
	      data_options = data_options,
	      summarized_by = NULL,
	      time_bin_size = bin_size)

	df_bias$Prop<-df_bias$x
	df_bias$AOI<-'x'

	the_median <- median(df_bias[['TrialsSeen']], na.rm=TRUE)
	df_bias[["TrialsSeenFactor"]] <- ifelse(df_bias[['TrialsSeen']] > the_median, paste0("High (>", round(the_median,2), ")"), "Low")
	
	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="x", group="TrialsSeenFactor", color="TrialsSeenFactor")) + guides(color= guide_legend(title= 'TrialsSeen')) +xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "combined_timecourse_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "combined_timecourse_", bin_size, ".eps", sep =""))

	# Center trials seen variable
	df_bias$TrialsSeenC <- as.numeric(scale(df_bias$TrialsSeen, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted transform), drop method, plot
	model_time_sequence <- lmer(x ~ TrialsSeenC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
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
	df_plot <- group_by_.time_sequence_data(df_bias, .dots = c("Subject", "Time", "TrialsSeenFactor"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('x')))
	names(summarize_arg) <- 'x'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="x", group="TrialsSeenFactor", color="TrialsSeenFactor")) + guides(color= guide_legend(title= 'TrialsSeen')) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste(output_dir, "combined_gca_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "combined_gca_", bin_size, ".eps", sep =""))

	sink()
}
