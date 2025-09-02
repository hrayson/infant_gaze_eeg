# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/coded_eeg')

# Load process subject function
source('shuffled_window_analysis.R')

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls window_analysis function for all data
shuffled_window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/shuffled/all/")

# Calls window_analysis function for without head turn data
shuffled_window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/shuffled/no_headturns/")


