# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/coded_eeg')

# Load process subject function
source('gca_adult_target.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls gca function for all data
gca_adult_target(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca_adult_target/all/")

# Calls gca function for without head turn data
gca_adult_target(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca_adult_target/no_headturns/")
