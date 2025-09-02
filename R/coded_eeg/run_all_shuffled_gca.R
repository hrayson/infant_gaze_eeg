# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/coded_eeg')

# Load process subject function
source('shuffled_gca.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls gca function for all data
shuffled_gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/shuffled/all/")

# Calls gca function for without head turn data
shuffled_gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/shuffled/no_headturns/")

