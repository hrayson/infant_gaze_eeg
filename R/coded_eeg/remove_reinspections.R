remove_reinspections<-function(data_file, out_file) {
	# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
	memory.limit(size=100000)

	# Reads file containing preprocessed data from all subjects (change path accordigly).
	data <-read.csv(file= data_file)

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

			# Find the first row where Target is true
			first_look_target <- which.max(trial_data$Target)
			# If Target is never true, first_look_target will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
			if(trial_data$Target[first_look_target]) {
				# Find the first row after the initial look to target where Target is false (end of initial inspection of target)
				end_look_target <- first_look_target+which.min(trial_data$Target[first_look_target:nrow(trial_data)])-1
				# Only have to set remaining rows to FALSE, when the inspection of target doesn't go until the end of the trial
				if(end_look_target > first_look_target) {
					# Set Target columns equal to false for all rows after initial inspection of target
					trial_data$Target[end_look_target:nrow(trial_data)] <- FALSE
				}
			}

			# Find the first row where AntiTarget is true
			first_look_antitarget <- which.max(trial_data$AntiTarget)
			# If AntiTarget is never true, first_look_antitarget will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
			if(trial_data$AntiTarget[first_look_antitarget]) {
				# Find the first row after the initial look to antitarget where AntiTarget is false (end of initial inspection of antitarget)
				end_look_antitarget <- first_look_antitarget+which.min(trial_data$AntiTarget[first_look_antitarget:nrow(trial_data)])-1
				# Only have to set remaining rows to FALSE, when the inspection of antitarget doesn't go until the end of the trial
				if(end_look_antitarget > first_look_antitarget) {
					# Set AntiTarget columns equal to false for all rows after initial inspection of antitarget
					trial_data$AntiTarget[end_look_antitarget:nrow(trial_data)] <- FALSE
				}
			}
		
			# Find the first row where Face is true (first look to face)
			first_look_face <- which.max(trial_data$Face)
			# If Face is never true, first_look_face will be 1, so need to tell whether or not the first row is TRUE, or its just never TRUE
			if(trial_data$Face[first_look_face]) {
				# Find the first row after the initial look to face where Face is false (end of initial inspection of face)
				end_look_face <- first_look_face+which.min(trial_data$Face[first_look_face:nrow(trial_data)])-1
				# Only have to set remaining rows to FALSE, when the inspection of face doesn't go until the end of the trial
				if(end_look_face > first_look_face) {
					# Set Face columns equal to false for all rows after initial inspection of face
					trial_data$Face[end_look_face:nrow(trial_data)] <- FALSE
				}
			}

			# Add trial data to dataframe
			new_data <- rbind(new_data, trial_data)
		}
	}

	# Have to reset Target and AntiTarget and Face columns to NA where Trackloss is TRUE (because we set all rows following initial inspection to FALSE above)
	new_data$Target[new_data$Trackloss == TRUE] <- NA
	new_data$AntiTarget[new_data$Trackloss == TRUE] <- NA
	new_data$Face[new_data$Trackloss == TRUE] <- NA

	# Save pre-processed data frame to csv (change path accordingly) so don't have to run every time
	write.csv(new_data, file = out_file)
}
