plot_interaction_eeg<-function(interaction_age, interaction_col, eeg_age, eeg_cluster, eeg_condition, eeg_woi) {

library("lme4")
library("car")
library("lsmeans")
library("Rmisc")
library("ggplot2")

eeg_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/eeg_data.csv')
eeg_data$Subject<-as.factor(eeg_data$Subject)
eeg_data$X<-NULL
interaction_data<-read.csv('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/interaction_data.csv')
interaction_data$Subject<-as.factor(interaction_data$Subject)
interaction_data$X<-NULL

interaction_data<-interaction_data[interaction_data$Age==interaction_age,]
interaction_data$Age<-NULL

eeg_data<-eeg_data[eeg_data$Age==eeg_age,]
eeg_data$Age<-NULL

mu_congruent<-eeg_data[eeg_data$Cluster==eeg_cluster & eeg_data$Condition==eeg_condition & eeg_data$WOI==eeg_woi,]
mu_congruent$Region<-NULL
mu_congruent$Hemisphere<-NULL
mu_congruent$WOI<-NULL
mu_congruent$FreqBand<-NULL
mu_congruent$Condition<-NULL
mu_congruent$Cluster<-NULL

merged_df<-merge(interaction_data,mu_congruent)

mod1= lm(formula(paste0('ERD ~ ', interaction_col)), data = merged_df)
summ<-summary(mod1)
p_val<-summ[4]$coefficients[8]			
print(paste0(woi,',',interaction_col))
print(summ)
dev.new()
g<-ggplot(merged_df, aes_string(x=interaction_col, y='ERD')) + geom_point(shape=1) + geom_smooth(method=lm,formula=y~x)+theme_bw()+ylab(paste0(eeg_cluster,': ',eeg_condition,' ERD (',eeg_woi,')'))
print(g)

}
