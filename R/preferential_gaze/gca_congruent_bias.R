gca_congruent_bias <- function(bin_size, non_aoi_missing, data_file, output_dir) {

	# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
	memory.limit(size=10000)

	# Loads eyetrackingR library so can use software
	library("Matrix")
	library("lme4")
	library("ggplot2")
	library("car")
	library("lsmeans")
	library("eyetrackingR")
	source('helpers.R')

	# Reads file containing preprocessed data from all subjects.
	data <-read.csv(file= data_file,header=TRUE,sep=",")
	# Use first block, and next block where subject saw at least 20 EEG trials
	data <- data[data$Block==1 | data$TrialsSeen>=20,]
	data$Block[data$Block>1]=2

	# Sends all printed output to stats.txt file - don't execute if debugging
	output_file = paste(output_dir, 'stats.txt', sep='')
	sink(output_file)

	# Converts data into eyetrackingR format.
	eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent','Incongruent'), treat_non_aoi_looks_as_missing = non_aoi_missing, item_columns = c('Block'))

	# Only use up to 1500ms after start of face stimulus
	response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

	# Analyse amount of trackloss by subjects and trials
	(trackloss <- trackloss_analysis(data=response_window))

	# Remove trials with over 40% trackloss
	response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

	# Plots the time course of data
	response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Block", "Age"), aois = c("Congruent","Incongruent"))

	# Compute congruent - incongruent bias
	Subject<-c()
	Age<-c()
	Block<-c()
	Trial<-c()
	TimeBin<-c()
	Prop<-c()
	Time<-c()
	ot1<-c()
	ot2<-c()
	ot3<-c()
	ot4<-c()
	subjects<-unique(response_time$Subject)
	ages<-unique(response_time$Age)
	blocks<-unique(response_time$Block)
	trials<-unique(response_time$Trial)
	time_bins<-unique(response_time$TimeBin)
	for(i in 1:length(subjects)) {
		s<-subjects[i]
		for(j in 1:length(ages)) {
			a<-ages[j]
			for(k in 1:length(blocks)) {
				b<-blocks[k]
				for(l in 1:length(trials)) {
					t<-trials[l]
					for(m in 1:length(time_bins)) {
						tb<-time_bins[m]
						diff<-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent']-response_time$Prop[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Incongruent']
						if(length(diff)>0) {
							Subject <- c(Subject, as.character(s))
							Age <- c(Age, as.character(a))
							Block <- c(Block, b)
							Trial <- c(Trial, t)
							TimeBin <- c(TimeBin, tb)
							Prop <- c(Prop, diff)
							Time<-c(Time, response_time$Time[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
							ot1<-c(ot1, response_time$ot1[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
							ot2<-c(ot2, response_time$ot2[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
							ot3<-c(ot3, response_time$ot3[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
							ot4<-c(ot4, response_time$ot4[response_time$Subject==s & response_time$Age==a & response_time$Block==b & response_time$Trial==t & response_time$TimeBin==tb & response_time$AOI=='Congruent'])
						}
					}
				}
			}
		}
	}
	
	df_bias<-data.frame(Subject, Age, Block, Trial, TimeBin, Prop, Time, ot1, ot2, ot3, ot4)
	df_bias$Block<-as.factor(df_bias$Block)
	df_bias$AOI<-'x'

	# Plot it!
	dev.new()
	g <- ggplot(df_bias, aes_string(x = "Time", y="Prop", group="Block", color="Block", fill="Block")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + facet_wrap(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))+theme_bw()
	print(g)

	# Saves time course plots as png and eps
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".png", sep =""), width=15, height=7)
	ggsave(file = paste(output_dir, "all_timecourse_", bin_size, ".eps", sep =""), width=15, height=7)
	
	# Create predictor for block = .5 if 1, -.5 if 2
	df_bias$BlockC <- ifelse(df_bias$Block == '1', .5, -.5)
	# Center block variable
	df_bias$BlockC <- as.numeric(scale(df_bias$BlockC, center=TRUE, scale=FALSE))

	# Create predictor for age = .5 if 9m, -.5 if 6m
	df_bias$AgeC <- ifelse(df_bias$Age == '9m', .5, -.5)
	# Center anxiety group variable
	df_bias$AgeC <- as.numeric(scale(df_bias$AgeC, center=TRUE, scale=FALSE))

	# GCA- run model (LogitAdjusted transform), drop method, plot
	#model_time_sequence <- lmer(Prop ~ BlockC*AgeC*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	#model_time_sequence <- lmer(x ~ BlockC*AgeC*(ot1 + ot2)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	model_time_sequence <- lmer(Prop ~ Block*Age*(ot1 + ot2 + ot3 + ot4)  + (1|Subject), data = df_bias, REML=FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
	estimate<-broom::tidy(model_time_sequence, effects = "fixed")
	print("Full model (with age factor)")
	print("Model estimate")
	print(estimate)
	#results<-drop1(model_time_sequence, ~., test="Chi")
	print("Stats")
	#print(results)
	print(Anova(model_time_sequence))

	pw<-lsmeans(model_time_sequence,pairwise~Age*Block*ot2|Age)
	print(summary(pw)$contrasts)
	
	pw<-lsmeans(model_time_sequence,pairwise~Age*Block*ot2|Block)
	print(summary(pw)$contrasts)

	# Plot model fit - with age
	dev.new()
	formula_as_character <- Reduce(paste, deparse(formula(model_time_sequence)))
	df_bias$.Predicted = predict(model_time_sequence, df_bias, re.form = NA)
	df_plot <- group_by_.time_sequence_data(df_bias, .dots = c("Subject", "Time", "Block", "Age"))
	summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
	names(summarize_arg) <- 'Prop'
	summarize_arg[[".Predicted"]] <- ~mean(.Predicted, na.rm=TRUE)
	df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
	g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="Block", color="Block", fill="Block")) + xlab('Time in Trial')
	#g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
	g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', colour=NA)
	g <- g + stat_summary(aes(y = .Predicted), fun.y = 'mean', geom="line", size= 1.2) 
	g <- g + facet_grid(~Age) + ylab(paste0("Prop Congruent - Prop Incongruent"))+theme_bw()
	print(g)

	# Saves model fit plots as png and eps
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".png", sep =""), width=15, height=7)
	ggsave(file = paste(output_dir, "all_gca_", bin_size, ".eps", sep =""), width=15, height=7)

	sink()
}
