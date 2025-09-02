# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/coded_eeg')

# Load process subject function
source('gca.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls gca function for all data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/all/")

# Calls gca function for without head turn data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/no_headturns/")

# Calls gca function for all data - no reinspections
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/all/no_reinspections/")

# Calls gca function for without head turn data - no reinspections
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/no_headturns/no_reinspections/")


# Calls gca function for all data - first look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/all/first_look/")

# Calls gca function for without head turn data - first look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/no_headturns/first_look/")


# Calls gca function for all data - second look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/all/second_look/")

# Calls gca function for without head turn data - second look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/no_headturns/second_look/")


# Calls gca function for all data - third look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_third_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/all/third_look/")

# Calls gca function for without head turn data - third look
#gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_no_headturns_third_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/gca/no_headturns/third_look/")

