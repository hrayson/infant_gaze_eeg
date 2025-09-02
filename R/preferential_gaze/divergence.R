divergence <- function(bin_size, non_aoi_missing, data_file, output_dir) {
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
	data <- data[data$Subject!='102_9m' & data$Subject!='111_6m',]
	# Use first block, and next block where subject saw at least 20 EEG trials
	data <- data[data$Block==1 | data$TrialsSeen>=20,]
	data$Block[data$Block>1]=2
	
	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)



	# Get 6m data
	print('6m')
	sixm_data <- data[data$Age=='6m',]
	sixm_data$Block <- as.factor(sixm_data$Block)
	
	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(sixm_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = non_aoi_missing)

	# Remove times >5s
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 40% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Block"), aois = c("Congruent","Incongruent"), summarize_by="Subject")

	# Compute congruent - incongruent bias
	Subject<-c()
	Block<-c()
	TimeBin<-c()
	Prop<-c()
	Time<-c()
	ot1<-c()
	ot2<-c()
	ot3<-c()
	ot4<-c()
	subjects<-unique(response_time$Subject)
	blocks<-unique(response_time$Block)
	time_bins<-unique(response_time$TimeBin)
	for(i in 1:length(subjects)) {
		s<-subjects[i]
		for(j in 1:length(blocks)) {
			b<-blocks[j]
			for(k in 1:length(time_bins)) {
				tb<-time_bins[k]
				diff<-response_time$Prop[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent']-response_time$Prop[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Incongruent']
				if(length(diff)>0) {
					Subject <- c(Subject, as.character(s))
					Block <- c(Block, b)
					TimeBin <- c(TimeBin, tb)
					Prop <- c(Prop, diff)
					Time<-c(Time, response_time$Time[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot1<-c(ot1, response_time$ot1[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot2<-c(ot2, response_time$ot2[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot3<-c(ot3, response_time$ot3[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot4<-c(ot4, response_time$ot4[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
				}
			}
		}
	}
	
	df_bias<-data.frame(Subject, TimeBin, Prop, Time, ot1, ot2, ot3, ot4)
	df_bias$Block<-factor(Block, levels=c(2,1))
	df_bias$AOI<-'x'

	# Plot it!
	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="Prop", group="Block", color="Block", fill="Block")) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "6m_timecourse_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_timecourse_", bin_size, ".eps", sep =""))

	data_options <- attr(response_window, "eyetrackingR")$data_options
	class(df_bias) <- c('time_sequence_data', class(df_bias))
	attr(df_bias,"eyetrackingR") <- list(
	      data_options = data_options,
	      summarized_by = 'Subject',
	      time_bin_size = bin_size)

	tb_analysis <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05)

	print('Time bin analysis')
	summary(tb_analysis)

	dev.new()
	g<-plot(tb_analysis, type = "estimate") + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_", bin_size, ".eps", sep =""))

	tb_analysis_bonf <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05, p_adjust_method = "bonferroni")

	print('Time bin analysis (Bonf corrected)')
	summary(tb_analysis_bonf)

	dev.new()
	g<-plot(tb_analysis_bonf) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_bonf_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_bonf_", bin_size, ".eps", sep =""))

	tb_analysis_holm <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05, p_adjust_method = "holm")

	print('Time bin analysis (Holm corrected)')
	summary(tb_analysis_holm)

	dev.new()
	g<-plot(tb_analysis_holm) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_holm_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_holm_", bin_size, ".eps", sep =""))

	tb_bootstrap <- analyze_time_bins(df_bias, predictor_column = 'Block', test= 'boot_splines', within_subj = TRUE, bs_samples = 1000, alpha = .05)
	
	print('Time bin analysis (Bootstrapped, smoothed)')
	summary(tb_bootstrap)

	dev.new()	
	g<-plot(tb_bootstrap) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_", bin_size, ".eps", sep =""))

	num_time_bins <- nrow(tb_analysis)
	tb_bootstrap_bonf <- analyze_time_bins(df_bias, predictor_column = 'Block', test= 'boot_splines', within_subj = TRUE, alpha = .05/num_time_bins)
	
	print('Time bin analysis (Bootstrapped, smoothed, Bonf corrected)')
	summary(tb_bootstrap_bonf)

	dev.new()	
	g<-plot(tb_bootstrap_bonf) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_bonf_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_bonf_", bin_size, ".eps", sep =""))


	num_sub = length(unique((response_window_clean$Subject)))
	threshold_t = qt(p = 1 - .05/2, df = num_sub-1) # pick threshold t based on alpha = .05 two tailed
	df_timeclust <- make_time_cluster_data(df_bias, test= "t.test", paired=TRUE, predictor_column = "Block", threshold = threshold_t) 

	dev.new()
	g<-plot(df_timeclust) +  ylab("T-Statistic") + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_clusters_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_clusters_", bin_size, ".eps", sep =""))

	print('Time bin analysis (Bootstrapped cluster-based, init clusters)')
	summary(df_timeclust)

	clust_analysis <- analyze_time_clusters(df_timeclust, within_subj=TRUE, paired=TRUE, samples=1000) # in practice, you should use a lot more

	dev.new()
	g<-plot(clust_analysis) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_cluster_analysis_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "6m_divergence_bootstrap_cluster_analysis_", bin_size, ".eps", sep =""))

	print('Time bin analysis (Bootstrapped cluster-based, final clusters)')
	summary(clust_analysis)


	# Get 9m data
	print('9m')
	ninem_data <- data[data$Age=='9m',]
	ninem_data$Block <- as.factor(ninem_data$Block)
	
	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(ninem_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Block'))

	# Remove times >5s
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 40% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Converts eyetrackingR data to time sequence data
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Block"), aois = c("Congruent","Incongruent"), summarize_by="Subject")

	# Compute congruent - incongruent bias
	Subject<-c()
	Block<-c()
	TimeBin<-c()
	Prop<-c()
	Time<-c()
	ot1<-c()
	ot2<-c()
	ot3<-c()
	ot4<-c()
	subjects<-unique(response_time$Subject)
	blocks<-unique(response_time$Block)
	time_bins<-unique(response_time$TimeBin)
	for(i in 1:length(subjects)) {
		s<-subjects[i]
		for(j in 1:length(blocks)) {
			b<-blocks[j]
			for(k in 1:length(time_bins)) {
				tb<-time_bins[k]
				diff<-response_time$Prop[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent']-response_time$Prop[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Incongruent']
				if(length(diff)>0) {
					Subject <- c(Subject, as.character(s))
					Block <- c(Block, b)
					TimeBin <- c(TimeBin, tb)
					Prop <- c(Prop, diff)
					Time<-c(Time, response_time$Time[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot1<-c(ot1, response_time$ot1[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot2<-c(ot2, response_time$ot2[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot3<-c(ot3, response_time$ot3[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
					ot4<-c(ot4, response_time$ot4[response_time$Subject==s & response_time$Block==b & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
				}
			}
		}
	}
	
	df_bias<-data.frame(Subject, TimeBin, Prop, Time, ot1, ot2, ot3, ot4)
	df_bias$Block<-factor(Block, levels=c(2,1))
	df_bias$AOI<-'x'

	# Plot it!
	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="Prop", group="Block", color="Block", fill="Block")) + xlab('Time in Trial')
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + ylab(paste0("Prop Congruent - Prop Incongruent"))
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "9m_timecourse_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_timecourse_", bin_size, ".eps", sep =""))

	data_options <- attr(response_window, "eyetrackingR")$data_options
	class(df_bias) <- c('time_sequence_data', class(df_bias))
	attr(df_bias,"eyetrackingR") <- list(
	      data_options = data_options,
	      summarized_by = 'Subject',
	      time_bin_size = bin_size)

	tb_analysis <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05)
	
	print('Time bin analysis')
	summary(tb_analysis)

	dev.new()
	g<-plot(tb_analysis, type = "estimate") + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_", bin_size, ".eps", sep =""))

	tb_analysis_bonf <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05, p_adjust_method = "bonferroni")

	print('Time bin analysis (Bonf corrected)')
	summary(tb_analysis_bonf)

	dev.new()
	g<-plot(tb_analysis_bonf) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_bonf_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_bonf_", bin_size, ".eps", sep =""))

	tb_analysis_holm <- analyze_time_bins(data = df_bias, predictor_column = "Block", test = "t.test", alpha = .05, p_adjust_method = "holm")

	print('Time bin analysis (Holm corrected)')
	summary(tb_analysis_holm)

	dev.new()
	g<-plot(tb_analysis_holm) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_holm_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_holm_", bin_size, ".eps", sep =""))

	tb_bootstrap <- analyze_time_bins(df_bias, predictor_column = 'Block', test= 'boot_splines', within_subj = TRUE, bs_samples = 1000, alpha = .05)

	print('Time bin analysis (Bootstrapped, smoothed)')
	summary(tb_bootstrap)

	dev.new()	
	g<-plot(tb_bootstrap) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_", bin_size, ".eps", sep =""))

	num_time_bins <- nrow(tb_analysis)
	tb_bootstrap_bonf <- analyze_time_bins(df_bias, predictor_column = 'Block', test= 'boot_splines', within_subj = TRUE, alpha = .05/num_time_bins)

	print('Time bin analysis (Bootstrapped, smoothed, Bonf corrected)')
	summary(tb_bootstrap_bonf)

	dev.new()	
	g<-plot(tb_bootstrap_bonf) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_bonf_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_bonf_", bin_size, ".eps", sep =""))

	num_sub = length(unique((response_window_clean$Subject)))
	threshold_t = qt(p = 1 - .05/2, df = num_sub-1) # pick threshold t based on alpha = .05 two tailed
	df_timeclust <- make_time_cluster_data(df_bias, test= "t.test", paired=TRUE, predictor_column = "Block", threshold = threshold_t) 

	dev.new()
	g<-plot(df_timeclust) +  ylab("T-Statistic") + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_clusters_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_clusters_", bin_size, ".eps", sep =""))

	print('Time bin analysis (Bootstrapped cluster-based, init clusters)')
	summary(df_timeclust)

	clust_analysis <- analyze_time_clusters(df_timeclust, within_subj=TRUE, paired=TRUE, samples=1000) # in practice, you should use a lot more

	dev.new()
	g<-plot(clust_analysis) + theme_light()
	print(g)

	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_cluster_analysis_", bin_size, ".png", sep =""))
	ggsave(file = paste(output_dir, "9m_divergence_bootstrap_cluster_analysis_", bin_size, ".eps", sep =""))

	print('Time bin analysis (Bootstrapped cluster-based, final clusters)')
	summary(clust_analysis)

	sink()
}

