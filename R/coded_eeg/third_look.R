# Have to remove reinspections first
third_look<-function(data_file, out_file) {

	# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
	memory.limit(size=100000)

	# Reads file (change path accordingly) containing preprocessed data from all subjects
	data <-read.csv(file= data_file)

	# All subjects
	subj_ids<-unique(data$Subject)

	# Create a new empty dataframe for first look data
	third_look_data <- data.frame()

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

			# Find the first row where Target is true (first look to target)
			first_look_target <- which.max(trial_data$Target)
			# Find the first row where AntiTarget is true (first look to antitarget)
			first_look_antitarget <- which.max(trial_data$AntiTarget)
			# Find the first row where Face is true (first look to face)
			first_look_face <- which.max(trial_data$Face)

			# If looked at all at least once
			if(trial_data$Target[first_look_target] && trial_data$AntiTarget[first_look_antitarget] && trial_data$Face[first_look_face]) {
				# If looked at target third - set antitarget and face to false
				if(first_look_target > first_look_antitarget && first_look_target>first_look_face) {
					trial_data$AntiTarget <- FALSE
					trial_data$Face <- FALSE
				}
				# If looked at antitarget third - set target and face to false
				else if(first_look_antitarget > first_look_target && first_look_antitarget > first_look_face) {
					trial_data$Target <- FALSE
					trial_data$Face <- FALSE
				}		
				# If looked at face third - set antitarget and target to false
				else if(first_look_face > first_look_target && first_look_face > first_look_antitarget) {
					trial_data$Target <- FALSE
					trial_data$AntiTarget <- FALSE
				}
			}
			# Otherwise set all to false
			else {
				trial_data$AntiTarget <- FALSE
				trial_data$Target <- FALSE
				trial_data$Face <- FALSE
			}

			# Add trial data to dataframe
			third_look_data <- rbind(third_look_data, trial_data)
		}
	}

	# Have to reset Target and AntiTarget and Face columns to NA where Trackloss is TRUE (because we set all rows following initial inspection to FALSE above)
	third_look_data$Target[third_look_data$Trackloss == TRUE] <- NA
	third_look_data$AntiTarget[third_look_data$Trackloss == TRUE] <- NA
	third_look_data$Face[third_look_data$Trackloss == TRUE] <- NA

	# Save pre-processed data frame to csv (change path accordingly) so don't have to run every time
	write.csv(third_look_data, file = out_file)
}
