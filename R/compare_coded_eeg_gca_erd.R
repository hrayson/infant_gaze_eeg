library("Matrix")
library("lme4")
library("ggplot2")
library("eyetrackingR")
library("Hmisc")
library("car")
#source('helpers.R')

bin_size <- 0.1

# Reads file containing preprocessed data from all subjects.
data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv',header=TRUE,sep=",")

# Converts data into eyetrackingR format.
#eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target', 'AntiTarget', 'Face'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Condition','Age'))
eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Face'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Condition','Age'))
#eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Target'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Condition','Age'))
#eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('AntiTarget'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Condition','Age'))

# Re-zero times when mov1 message appears - beginning of movie
eyetrackingr_data <- subset_by_window(eyetrackingr_data, window_start_msg = "mov1", msg_col = "Message", rezero = TRUE)

# Only use up to 3s after start of movie stimulus
response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=3, remove = TRUE)

# Analyse amount of trackloss by subjects and trials
(trackloss <- trackloss_analysis(data=response_window))

# Remove trials with over 30% trackloss
response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .4)

# Converts eyetrackingR data to time sequence data	
#response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Target","AntiTarget","Face"))
response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Face"))
#response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("Target"))
#response_time <- make_time_sequence_data(response_window_clean, time_bin_size = bin_size, predictor_columns = c("Condition","Age"), aois = c("AntiTarget"))

erd_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/obs.csv')
erd_data$Subject<-as.factor(erd_data$Subject)
erd_data<-erd_data[erd_data$FreqBand=='mu' & erd_data$WOI =='0-500ms' & (erd_data$Region=='C' | erd_data$Region=='O'| erd_data$Region=='F'),]
erd_data$Cluster<-''
erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'left']<-'C3'
erd_data$Cluster[erd_data$Region == 'C' & erd_data$Hemisphere == 'right']<-'C4'
erd_data$Cluster[erd_data$Region == 'F' & erd_data$Hemisphere == 'left']<-'F3'
erd_data$Cluster[erd_data$Region == 'F' & erd_data$Hemisphere == 'right']<-'F4'
erd_data$Cluster[erd_data$Region == 'O' & erd_data$Hemisphere == 'left']<-'O1'
erd_data$Cluster[erd_data$Region == 'O' & erd_data$Hemisphere == 'right']<-'O2'
erd_data$Cluster<-as.factor(erd_data$Cluster)

response_time$ERDCong<-0
response_time$ERDDiff<-0

subjects<-unique(erd_data$Subject)
ages<-unique(erd_data$Age)
for(i in 1:length(subjects)) {
	subject<-subjects[i]
	for(j in 1:length(ages)) {
		age<-ages[j]
		cong_erd<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_congruent']
		diff_erd<-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_congruent']-erd_data$ERD[erd_data$Subject==subject & erd_data$Age==age & erd_data$Cluster=='C4' & erd_data$Condition=='unshuffled_incongruent']
		if(length(cong_erd)>0) {
			response_time$ERDCong[response_time$Subject==paste(subject, age, sep ="_") & response_time$Age==age]<-cong_erd
			response_time$ERDDiff[response_time$Subject==paste(subject, age, sep ="_") & response_time$Age==age]<-diff_erd
		}
	}
}

sixm_median <- median(response_time$ERDCong[response_time$Age=='6m'], na.rm=TRUE)
#sixm_median <- median(response_time$ERDCong, na.rm=TRUE)
ninem_median <- median(response_time$ERDCong[response_time$Age=='9m'], na.rm=TRUE)
#ninem_median <- median(response_time$ERDCong, na.rm=TRUE)
response_time$ERDCongFactor[response_time$Age=='6m'] <- ifelse(response_time$ERDCong[response_time$Age=='6m'] > sixm_median, "High", "Low")
response_time$ERDCongFactor[response_time$Age=='9m'] <- ifelse(response_time$ERDCong[response_time$Age=='9m'] > ninem_median, "High", "Low")
response_time$ERDCongFactor<-as.factor(response_time$ERDCongFactor)

# Crazy plotting stuff - plot timecourse with age
dev.new()
df_plot <- group_by_.time_sequence_data(response_time, .dots = c("Subject", "Time", "AOI", "Condition", "Age","ERDCongFactor"))
summarize_arg <- list(lazyeval::interp(~mean(DV, na.rm=TRUE), DV = as.name('Prop')))
names(summarize_arg) <- 'Prop'
df_plot <- dplyr::summarize_(df_plot, .dots = summarize_arg)
g <- ggplot(df_plot, aes_string(x = "Time", y="Prop", group="ERDCongFactor", color="ERDCongFactor", fill="ERDCongFactor")) + xlab('Time in Trial')
g <- g + stat_summary(fun.y='mean', geom='line', linetype = 'F1') + stat_summary(fun.data=mean_se, geom='ribbon', alpha= .25, colour=NA)
g <- g + facet_grid(Condition ~ Age) + ylab(paste0("Looking to AOI (Prop)"))
print(g)
