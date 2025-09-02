# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
memory.limit(size=100000)

# Reads file (change path accordingly) containing preprocessed data from all subjects
data <-read.csv(file= "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv")

# All subjects
subj_ids<-unique(data$Subject)

# Create a new empty dataframe for first look data
first_look_data <- data.frame()

# Process data from each subject
for(i in 1:length(subj_ids)) {
	# Get subject ID
	subj_id <- subj_ids[i]
	print(subj_id)
	# Get only the rows for this subject from the dataframe containing all subject data
	subj_data <- data[data$Subject==subj_id,]
	
	# Get trial IDs
	trial_ids <- unique(subj_data$Trial)

	# Process each trial for this subject
	for(j in 1:length(trial_ids)) {
		# Get trial ID
		trial_id <- trial_ids[j]

		# Get only the rows for this trial from the dataframe containing all trials for this subject
		trial_data <- subj_data[subj_data$Trial==trial_id,]

		# Find the first row where Congruent is true (first look to congruent face)
		first_look_congruent <- which.max(trial_data$Congruent)
		# Find the first row where Incongruent is true (first look to incongruent face)
		first_look_incongruent <- which.max(trial_data$Incongruent)

		# If looked at both at least once
		if(trial_data$Congruent[first_look_congruent] && trial_data$Incongruent[first_look_incongruent]) {
			# If looked at congruent face first - set incongruent to false
			if(first_look_congruent < first_look_incongruent) {
				trial_data$Incongruent <- FALSE
			}
			# If looked at incongruent face first - set congruent to false
			else {
				trial_data$Congruent <- FALSE
			}		
		}

		# Find the first row where FO is true (first look to FO face)
		first_look_FO <- which.max(trial_data$FO)
		# Find the first row where CG is true (first look to CG face)
		first_look_CG <- which.max(trial_data$CG)

		# If looked at both at least once
		if(trial_data$FO[first_look_FO] && trial_data$CG[first_look_CG]) {
			# If looked at FO face first - set CG to false
			if(first_look_FO < first_look_CG) {
				trial_data$CG <- FALSE
			}
			# If looked at CG face first - set FO to false
			else {
				trial_data$FO <- FALSE
			}		
		}

		# Find the first row where Left is true (first look to left face)
		first_look_left <- which.max(trial_data$Left)
		# Find the first row where Right is true (first look to right face)
		first_look_right <- which.max(trial_data$Right)

		# If looked at both at least once
		if(trial_data$Left[first_look_left] && trial_data$Right[first_look_right]) {
			# If looked at left face first - set Right to false
			if(first_look_left < first_look_right) {
				trial_data$Right <- FALSE
			}
			# If looked at right face first - set Left to false
			else {
				trial_data$Left <- FALSE
			}		
		}

		# Add trial data to dataframe
		first_look_data <- rbind(first_look_data, trial_data)
	}
}

# Save pre-processed data frame to csv (change path accordingly) so don't have to run every time
write.csv(first_look_data, file = "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_first_look.csv")
