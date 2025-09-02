analyze_interactions_eeg<-function(eeg_ages=c(), eeg_clusters=c(), eeg_conditions=c(), interaction_ages=c(), interaction_cols=c()) {

library(MASS)
library("lme4")
library("car")
library("lsmeans")
library("Rmisc")
library("ggplot2")
library("sfsmisc")

eeg_data <-read.csv(file= '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/eeg_data.csv')
eeg_data$Subject<-as.factor(eeg_data$Subject)
eeg_data$X<-NULL
interaction_data<-read.csv('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/interaction_data.csv')
interaction_data$Subject<-as.factor(interaction_data$Subject)
interaction_data$X<-NULL

for(a in 1:length(interaction_ages)) {
	interaction_age<-interaction_ages[a]
	for(b in 1:length(eeg_ages)) {
		eeg_age<-eeg_ages[b]

		interaction_sub_data<-interaction_data[interaction_data$Age==interaction_age,]
		interaction_sub_data$Age<-NULL

		eeg_sub_data<-eeg_data[eeg_data$Age==eeg_age,]
		eeg_sub_data$Age<-NULL

		wois<-unique(eeg_sub_data$WOI)

		if(length(interaction_cols)==0) {
			interaction_cols=colnames(interaction_data)
		}

		for(l in 1:length(eeg_clusters)) {
			eeg_cluster<-eeg_clusters[l]
			for(m in 1:length(eeg_conditions)) {
				eeg_condition<-eeg_conditions[m]
				for(k in 1:length(wois)) {
					woi<-wois[k]
					mu_congruent<-eeg_sub_data[eeg_sub_data$Cluster==eeg_cluster & eeg_sub_data$Condition==eeg_condition & eeg_sub_data$WOI==woi,]
					mu_congruent$Region<-NULL
					mu_congruent$Hemisphere<-NULL
					mu_congruent$WOI<-NULL
					mu_congruent$FreqBand<-NULL
					mu_congruent$Condition<-NULL
					mu_congruent$Cluster<-NULL

					merged_df<-merge(interaction_sub_data,mu_congruent)
	
					for(i in 1:length(interaction_cols)) {
						col<-interaction_cols[i]
						if(col!='Subject') {
							mod1= rlm(formula(paste0('ERD ~ ', col)), data = merged_df, maxit=100)
							summ<-summary(mod1)
							test<-f.robftest(mod1)
							p_val<-test$p.value
							#p_val<-summ[4]$coefficients[8]			
							#print(p_val)
							if(!is.na(p_val) && p_val<0.05 && mod1$coefficients[2]<0) {
								#loo_sig<-TRUE
								#subjects<-unique(merged_df$Subject)
								#for(j in 1:length(subjects)) {
								#	sub_df<-merged_df[merged_df$Subject!=subjects[j],]
								#	mod1= lm(formula(paste0('ERD ~ ', col)), data = sub_df)
								#	loo_summ<-summary(mod1)
								#	loo_p_val<-loo_summ[4]$coefficients[8]		
								#	if(is.na(loo_p_val) || loo_p_val>=0.05 || mod1$coefficients[2]>=0) {	
								#		loo_sig<-FALSE
								#		break
								#	}
								#}
								#if(loo_sig) {
									print(paste0(interaction_age,',',eeg_age,',',eeg_cluster,',',eeg_condition,',',woi,',',col,',',p_val))
									#print(summ)
									#dev.new()
									#g<-ggplot(merged_df, aes_string(x=col, y='ERD')) + geom_point(shape=1) + geom_smooth(method=lm,formula=y~x)+theme_bw()+ylab(paste0(interaction_age,'-',eeg_age,': ',eeg_cluster,': ',eeg_condition,' ERD (',woi,')'))
									#print(g)
								#}
							}
						}
					}
				}
			}
		}
	}
}

}
