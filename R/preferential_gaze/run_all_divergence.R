# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/preferential_gaze/')

# Load process subject function
source('divergence.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls divergence function for with reinspection data
divergence(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/divergence/congruent_incongruent/with_reinspections/")

# Calls divergence function for without reinspection data
divergence(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/divergence/congruent_incongruent/without_reinspections/")


