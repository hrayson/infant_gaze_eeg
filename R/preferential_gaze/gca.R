gca <- function(bin_size, non_aoi_missing, data_file, output_dir) {
	# Loads eyetrackingR library so can use software
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("eyetrackingR")
	source('helpers.R')

	# Reads file containing preprocessed data from all subjects.
	data <-read.csv(file= data_file,header=TRUE,sep=",")
	# Only use blocks 1 and 2
	#data <- data[data$Block<3,]
	# Remove 102_9m, 111_6m - had at least one block where didn't look at either face
	#data <- data[data$Subject!='102_9m' & data$Subject!='111_6m',]
	# Use first block, and next block where subject saw at least 20 EEG trials
	data <- data[data$Block==1 | data$TrialsSeen>=20,]
	data$Block[data$Block>1]=2
	
	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)
	
	
	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Block'))

	# Remove times >5s
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)
	
	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 30% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data	
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Block","Age"), aois = c("Congruent","Incongruent"))
	
	# Crazy plotting stuff - plot timecourse with age
	dev.new()
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Block", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_grid(Block ~ Age) + ylab(paste0("Looking to ", df_plot$AOI[1], " (Prop)"))
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".eps", sep =""))

	# Create predictor for face type = .5 if congruent, -.5 if incongruent
	response_time$FaceTypeC <- ifelse(response_time$AOI == 'Congruent', .5, -.5)
	# Center face type variable
	response_time$FaceTypeC <- as.numeric(scale(response_time$FaceTypeC, center=TRUE, scale=FALSE))

	# Create predictor for block = .5 if 1, -.5 if 2
	response_time$BlockC <- ifelse(response_time$Block == '1', .5, -.5)
	# Center block variable
	response_time$BlockC <- as.numeric(scale(response_time$BlockC, center=TRUE, scale=FALSE))

	# Create predictor for age = .5 if 9m, -.5 if 6m
	response_time$AgeC <- ifelse(response_time$Age == '9m', .5, -.5)
	# Center age variable
	response_time$AgeC <- as.numeric(scale(response_time$AgeC, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted), drop method, plot
	model_time_sequence <- lmer(LogitAdjusted ~ FaceTypeC*BlockC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = response_time, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
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
	response_time$.Predicted = predict(model_time_sequence, response_time, re.form = NA)
	df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Block", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('LogitAdjusted')))
	names(summarize_arg) <- 'LogitAdjusted'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="LogitAdjusted", group="AOI", color="AOI", fill="AOI")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_grid(Block ~ Age) + ylab(paste0("Looking to ", df_plot$AOI[1], " (LogitAdjusted)"))
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".eps", sep =""))


	sink()
}
