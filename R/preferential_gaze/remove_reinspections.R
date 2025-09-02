# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
memory.limit(size=100000)

# Reads file containing preprocessed data from all subjects (change path accordigly).
data <-read.csv(file= "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv")
data$Trial <- data$Trial+(data$Block-1)*3

# Creates variable listing all subject IDs to process
subj_ids<- unique(data$Subject)

# Creates a new empty dataframe for new data. 
new_data <- data.frame()

# Process data from each subject.
for(i in 1:length(subj_ids)) {
	# Get subject ID
	subj_id <- subj_ids[i]
	print(subj_id)
	# Get only the rows for this subject from the dataframe containing all subject data.
	subj_data <- data[data$Subject==subj_id,]
	
	# Get trial IDs for that subject.
	trial_ids <- unique(subj_data$Trial)

	# Process each trial for this subject
	for(j in 1:length(trial_ids)) {
		# Get trial ID
		trial_id <- trial_ids[j]

		# Get only the rows for this trial from the dataframe containing all trials for this subject
		trial_data <- subj_data[subj_data$Trial==trial_id,]

		# Find the first row where Congruent is true (first look to congruent face)
		# 
		first_look_congruent <- which.max(trial_data$Congruent)
		# If Congruent is never true, first_look_congruent will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$Congruent[first_look_congruent]) {
			# Find the first row after the initial look to congruent face where Congruent is false (end of initial inspection of congruent face)
			end_look_congruent <- first_look_congruent+which.min(trial_data$Congruent[first_look_congruent:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of congruent face doesn't go until the end of the trial
			if(end_look_congruent > first_look_congruent) {
				# Set Congruent columns equal to false for all rows after initial inspection of congruent face
				trial_data$Congruent[end_look_congruent:nrow(trial_data)] <- FALSE
			}
		}
		
		# Find the first row where Incongruent is true (first look to incongruent face)
		first_look_incongruent <- which.max(trial_data$Incongruent)
		# If Incongruent is never true, first_look_incongruent will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$Incongruent[first_look_incongruent]) {
			# Find the first row after the initial look to incongruent face where Incongruent is false (end of initial inspection of incongruent face)
			end_look_incongruent <- first_look_incongruent+which.min(trial_data$Incongruent[first_look_incongruent:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of incongruent face doesn't go until the end of the trial
			if(end_look_incongruent > first_look_incongruent) {
				# Set Incongruent columns equal to false for all rows after initial inspection of incongruent face
				trial_data$Incongruent[end_look_incongruent:nrow(trial_data)] <- FALSE
			}
		}

		# Find the first row where FO is true (first look to FO face)
		# 
		first_look_FO <- which.max(trial_data$FO)
		# If FO is never true, first_look_FO will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$FO[first_look_FO]) {
			# Find the first row after the initial look to FO face where FO is false (end of initial inspection of FO face)
			end_look_FO <- first_look_FO+which.min(trial_data$FO[first_look_FO:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of FO face doesn't go until the end of the trial
			if(end_look_FO > first_look_FO) {
				# Set FO columns equal to false for all rows after initial inspection of FO face
				trial_data$FO[end_look_FO:nrow(trial_data)] <- FALSE
			}
		}
		
		# Find the first row where CG is true (first look to CG face)
		first_look_CG <- which.max(trial_data$CG)
		# If CG is never true, first_look_CG will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$CG[first_look_CG]) {
			# Find the first row after the initial look to CG face where CG is false (end of initial inspection of CG face)
			end_look_CG <- first_look_CG+which.min(trial_data$CG[first_look_CG:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of CG face doesn't go until the end of the trial
			if(end_look_CG > first_look_CG) {
				# Set CG columns equal to false for all rows after initial inspection of CG face
				trial_data$CG[end_look_CG:nrow(trial_data)] <- FALSE
			}
		}

		# Find the first row where Left is true (first look to left face)
		# 
		first_look_left <- which.max(trial_data$Left)
		# If Left is never true, first_look_left will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$Left[first_look_left]) {
			# Find the first row after the initial look to left face where Left is false (end of initial inspection of left face)
			end_look_left <- first_look_left+which.min(trial_data$Left[first_look_left:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of left face doesn't go until the end of the trial
			if(end_look_left > first_look_left) {
				# Set Left columns equal to false for all rows after initial inspection of left face
				trial_data$Left[end_look_left:nrow(trial_data)] <- FALSE
			}
		}
		
		# Find the first row where Right is true (first look to right face)
		first_look_right <- which.max(trial_data$Right)
		# If Right is never true, first_look_right will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
		if(trial_data$Right[first_look_right]) {
			# Find the first row after the initial look to right face where Right is false (end of initial inspection of right face)
			end_look_right <- first_look_right+which.min(trial_data$Right[first_look_right:nrow(trial_data)])-1
			# Only have to set remaining rows to FALSE, when the inspection of right face doesn't go until the end of the trial
			if(end_look_right > first_look_right) {
				# Set Right columns equal to false for all rows after initial inspection of right face
				trial_data$Right[end_look_right:nrow(trial_data)] <- FALSE
			}
		}

		# Add trial data to dataframe
		new_data <- rbind(new_data, trial_data)
	}
}

# Save pre-processed data frame to csv (change path accordingly) so don't have to run every time
write.csv(new_data, file = "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv")
