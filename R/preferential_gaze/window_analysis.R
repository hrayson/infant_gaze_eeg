library("Matrix")
library("lme4")
library("ggplot2")
library("eyetrackingR")
library("car")
library("lsmeans")

output_file = '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/stats.txt'
sink(output_file)

data <-read.csv(file= "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv",header=TRUE,sep=",")
# Remove 102_9m, 111_6m - had at least one block where didn't look at either face
#data <- data[data$Subject!='102_9m' & data$Subject!='111_6m',]
# Use first block, and next block where subject saw at least 20 EEG trials
data <- data[data$Block==1 | data$TrialsSeen>=20,]
data$Block[data$Block>1]=2

# Get 6m data
print('6m')
sixm_data <- data[data$Age=='6m',]

# Converts data into eyetrackingR format.
eyetrackingr_data <- make_eyetrackingr_data(sixm_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Block'))

# Remove times >5s
response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

# Analyse amount of trackloss by subjects and trials
(trackloss <- trackloss_analysis(data=response_window))

# Remove trials with over 30% trackloss
response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

# Sanity checks. Looks at some descriptive statitics (e.g. proportion of time looking at congruent face).
cong_data_summary <- describe_data(response_window_clean, describe_column = 'Congruent', group_columns = c('Block','Subject'))
print(cong_data_summary)
incong_data_summary <- describe_data(response_window_clean, describe_column = 'Incongruent', group_columns = c('Block','Subject'))
print(incong_data_summary)

# Plots data summary
dev.new()
p<-plot(cong_data_summary)
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_congruent_lineplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_congruent_lineplot.png")

# Plots data summary
dev.new()
p<-plot(incong_data_summary)
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_incongruent_lineplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_incongruent_lineplot.png")

# Averages proportion of looks to congruent over trials (per subject) in eyetrackingR format
response_window_agg_by_subject <- make_time_window_data(response_window_clean, aois=c('Congruent','Incongruent'), predictor_columns=c('Block'), summarize_by="Subject")

# Plots mean looking time to congruent per subject. Note: used ArcSin transofrmation, but can use others (e.g Elog).
dev.new()
p<-plot(response_window_agg_by_subject, predictor_columns="Block", dv="ArcSin")
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_congruent_arcsin_barplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/6m_participant_mean_congruent_arcsin_barplot.png")

# Sanity check: Prints out condition means over all subjects for (arcsine of) the proportion to congruent and incongruent
print(describe_data(response_window_agg_by_subject,describe_column = "ArcSin", group_columns=c("AOI","Block")))

# Runs t-test to look at difference between congruent and incongruent mean proportion
#t.test(ArcSin ~ Block, data=response_window_agg_by_subject,paired=TRUE)
print('2x2 ANOVA')
fit<-lm(ArcSin ~ Block*AOI, data=response_window_agg_by_subject)
print(summary(fit))




# Get 9m data
print('9m')
ninem_data <- data[data$Age=='9m',]

# Converts data into eyetrackingR format.
eyetrackingr_data <- make_eyetrackingr_data(ninem_data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Block'))

# Remove times >5s
response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

# Analyse amount of trackloss by subjects and trials
(trackloss <- trackloss_analysis(data=response_window))

# Remove trials with over 30% trackloss
response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

# Sanity checks. Looks at some descriptive statitics (e.g. proportion of time looking at congruent face).
cong_data_summary <- describe_data(response_window_clean, describe_column = 'Congruent', group_columns = c('Block','Subject'))
print(cong_data_summary)
incong_data_summary <- describe_data(response_window_clean, describe_column = 'Incongruent', group_columns = c('Block','Subject'))
print(incong_data_summary)

# Plots data summary
dev.new()
p<-plot(cong_data_summary)
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_congruent_lineplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_congruent_lineplot.png")

# Plots data summary
dev.new()
p<-plot(incong_data_summary)
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_incongruent_lineplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_incongruent_lineplot.png")

# Averages proportion of looks to congruent over trials (per subject) in eyetrackingR format
response_window_agg_by_subject <- make_time_window_data(response_window_clean, aois=c('Congruent','Incongruent'), predictor_columns=c('Block'), summarize_by="Subject")

# Plots mean looking time to congruent per subject. Note: used ArcSin transofrmation, but can use others (e.g Elog).
dev.new()
p<-plot(response_window_agg_by_subject, predictor_columns="Block", dv="ArcSin")
print(p)
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_congruent_arcsin_barplot.eps")
ggsave(file="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/window_analysis/9m_participant_mean_congruent_arcsin_barplot.png")

# Sanity check: Prints out condition means over all subjects for (arcsine of) the proportion to congruent and incongruent
print(describe_data(response_window_agg_by_subject,describe_column = "ArcSin", group_columns=c("AOI","Block")))

# Runs t-test to look at difference between congruent and incongruent mean proportion
#t.test(ArcSin ~ Block, data=response_window_agg_by_subject,paired=TRUE)
print('2x2 ANOVA')
fit<-lm(ArcSin ~ Block*AOI, data=response_window_agg_by_subject)
print(summary(fit))


print('Combined')
# Converts data into eyetrackingR format.
eyetrackingr_data <- make_eyetrackingr_data(data, participant_column = "Subject", trial_column = "Trial", time_column = "TrialTime", trackloss_column = "Trackloss", aoi_columns = c('Congruent', 'Incongruent'), treat_non_aoi_looks_as_missing = FALSE, item_columns = c('Age','Block'))

# Remove times >5s
response_window <- subset_by_window(eyetrackingr_data, window_start_time = 0, window_end_time=5, remove = TRUE)

# Analyse amount of trackloss by subjects and trials
(trackloss <- trackloss_analysis(data=response_window))

# Remove trials with over 30% trackloss
response_window_clean <- clean_by_trackloss(data = response_window, trial_prop_thresh = .3)

response_window_agg <- make_time_window_data(response_window_clean, aois=c('Congruent','Incongruent'), predictor_columns=c('Block','Age'))
response_window_agg$AOI<-as.factor(response_window_agg$AOI)

# Create predictor for face type = .5 if congruent, -.5 if incongruent
#response_window_agg$FaceTypeC <- ifelse(response_window_agg$AOI == 'Congruent', .5, -.5)
# Center face type variable
#response_window_agg$FaceTypeC <- as.numeric(scale(response_window_agg$FaceTypeC, center=TRUE, scale=FALSE))

# Create predictor for block = .5 if 1, -.5 if 2
#response_window_agg$BlockC <- ifelse(response_window_agg$Block == '1', .5, -.5)
# Center block variable
#response_window_agg$BlockC <- as.numeric(scale(response_window_agg$BlockC, center=TRUE, scale=FALSE))

# Create predictor for age = .5 if 9m, -.5 if 6m
#response_window_agg$AgeC <- ifelse(response_window_agg$Age == '9m', .5, -.5)
# Center age variable
#response_window_agg$AgeC <- as.numeric(scale(response_window_agg$AgeC, center=TRUE, scale=FALSE))

# mixed-effects linear model on subject*trial data
model_time_window <- lmer(LogitAdjusted ~ AOI*Block*Age + (1 | Subject), data = response_window_agg, REML = FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
# cleanly show important parts of model (see `summary()` for more)
est <- broom::tidy(model_time_window, effects="fixed")

print("Full model (with age factor)")
print("Model estimate")
print(est)
#results<-drop1(model_time_window, ~., test="Chi")
print("Stats")
print(Anova(model_time_window))

age<-lsmeans(model_time_window,pairwise~Age)
print(summary(age)$contrasts)

print('**** Bias *****')
# Compute congruent - incongruent bias
Subject<-c()
Age<-c()
Block<-c()
Trial<-c()
Prop<-c()
subjects<-unique(response_window_agg$Subject)
ages<-unique(response_window_agg$Age)
blocks<-unique(response_window_agg$Block)
trials<-unique(response_window_agg$Trial)
for(i in 1:length(subjects)) {
	s<-subjects[i]
	for(j in 1:length(ages)) {
		a<-ages[j]
		for(k in 1:length(blocks)) {
			b<-blocks[k]
			for(l in 1:length(trials)) {
				t<-trials[l]
				diff<-response_window_agg$Prop[response_window_agg$Subject==s & response_window_agg$Age==a & response_window_agg$Block==b & response_window_agg$Trial==t & response_window_agg$AOI=='Congruent']-response_window_agg$Prop[response_window_agg$Subject==s & response_window_agg$Age==a & response_window_agg$Block==b & response_window_agg$Trial==t & response_window_agg$AOI=='Incongruent']
				if(length(diff)>0) {
					Subject <- c(Subject, as.character(s))
					Age <- c(Age, as.character(a))
					Block <- c(Block, b)
					Trial <- c(Trial, t)
					Prop <- c(Prop, diff)
				}
			}
		}
	}
}
	
df_bias<-data.frame(Subject, Age, Block, Trial, Prop)
df_bias$Block<-as.factor(df_bias$Block)
df_bias$AOI<-'x'

# mixed-effects linear model on subject*trial data
model_time_window <- lmer(Prop ~ Block*Age + (1 | Subject), data = df_bias, REML = FALSE, control = lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e6)))
# cleanly show important parts of model (see `summary()` for more)
est <- broom::tidy(model_time_window, effects="fixed")

print("Full model (with age factor)")
print("Model estimate")
print(est)
#results<-drop1(model_time_window, ~., test="Chi")
print("Stats")
print(Anova(model_time_window))


sink()
