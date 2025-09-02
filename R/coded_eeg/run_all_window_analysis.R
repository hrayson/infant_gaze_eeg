# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/coded_eeg')

# Load process subject function
source('window_analysis.R')

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls window_analysis function for all data
window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/all/")

# Calls window_analysis function for without head turn data
window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/no_headturns/")

# Calls window_analysis function for all data - no reinspections
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/all/no_reinspections/")

# Calls window_analysis function for without head turn data - no reinspections
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/no_headturns/no_reinspections/")

# Calls window_analysis function for all data - first look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/all/first_look/")

# Calls window_analysis function for without head turn data - first look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/no_headturns/first_look/")

# Calls window_analysis function for all data - second look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/all/second_look/")

# Calls window_analysis function for without head turn data - second look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/no_headturns/second_look/")

# Calls window_analysis function for all data - third look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_third_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/all/third_look/")

# Calls window_analysis function for without head turn data - third look
#window_analysis(non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_third_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/window_analysis/no_headturns/third_look/")

