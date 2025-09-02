# Have to remove reinspections first
second_look<-function(data_file, out_file) {

	# Increases memory limit (by default R is restricted to using a certaint amount of RAM)
	memory.limit(size=100000)

	# Reads file (change path accordingly) containing preprocessed data from all subjects
	data <-read.csv(file= data_file)

	# All subjects
	subj_ids<-unique(data$Subject)

	# Create a new empty dataframe for first look data
	second_look_data <- data.frame()

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
				# If looked at target second - set antitarget and face to false
				if((first_look_target < first_look_antitarget && first_look_target>first_look_face) || (first_look_target > first_look_antitarget && first_look_target<first_look_face)) {
					trial_data$AntiTarget <- FALSE
					trial_data$Face <- FALSE
				}
				# If looked at antitarget second - set target and face to false
				else if((first_look_antitarget < first_look_target && first_look_antitarget > first_look_face) || (first_look_antitarget > first_look_target && first_look_antitarget < first_look_face)) {
					trial_data$Target <- FALSE
					trial_data$Face <- FALSE
				}		
				# If looked at face first - set antitarget and target to false
				else if((first_look_face < first_look_target && first_look_face > first_look_antitarget) || (first_look_face > first_look_target && first_look_face < first_look_antitarget)) {
					trial_data$Target <- FALSE
					trial_data$AntiTarget <- FALSE
				}
			}
			# If looked at target and antitarget at least once
			else if(trial_data$Target[first_look_target] && trial_data$AntiTarget[first_look_antitarget]) {
				# If looked at target first - set antitarget to false
				if(first_look_target > first_look_antitarget) {
					trial_data$AntiTarget <- FALSE
				}
				# If looked at antitarget first - set target to false
				else {
					trial_data$Target <- FALSE
				}
			}
			# If looked at target and face at least once
			if(trial_data$Target[first_look_target] && trial_data$Face[first_look_face]) {
				# If looked at target first - set face to false
				if(first_look_target > first_look_face) {
					trial_data$Face <- FALSE
				}						
				# If looked at face first - set face to false
				else {
					trial_data$Target <- FALSE
				}
			}
			# If looked at antitarget and face at least once
			if(trial_data$AntiTarget[first_look_antitarget] && trial_data$Face[first_look_face]) {
				# If looked at antitarget first - set face to false
				if(first_look_antitarget > first_look_face) {
					trial_data$Face <- FALSE
				}		
				# If looked at face first - set antitarget to false
				else {
					trial_data$AntiTarget <- FALSE
				}
			}	
			# Otherwise - set all to false
			else {
				trial_data$Face <- FALSE
				trial_data$AntiTarget <- FALSE
				trial_data$Target <- FALSE
			}

			# Add trial data to dataframe
			second_look_data <- rbind(second_look_data, trial_data)
		}
	}

	# Have to reset Target and AntiTarget and Face columns to NA where Trackloss is TRUE (because we set all rows following initial inspection to FALSE above)
	second_look_data$Target[second_look_data$Trackloss == TRUE] <- NA
	second_look_data$AntiTarget[second_look_data$Trackloss == TRUE] <- NA
	second_look_data$Face[second_look_data$Trackloss == TRUE] <- NA

	# Save pre-processed data frame to csv (change path accordingly) so don't have to run every time
	write.csv(second_look_data, file = out_file)
}
