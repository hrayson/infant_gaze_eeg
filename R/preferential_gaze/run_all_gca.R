# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/preferential_gaze/')

# Load process subject function
source('gca.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls gca function for with reinspection data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/with_reinspections/")

# Calls gca function for without reinspection data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/without_reinspections/")

# Calls gca function for first look data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/first_look/")

# Calls gca function for second look data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/second_look/")


# Treat non-aoi looks as missing
non_aoi_missing <- TRUE

# Calls gca function for with reinspection data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/non_aoi_missing/with_reinspections/")

# Calls gca function for without reinspection data
gca(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/congruent_incongruent/non_aoi_missing/without_reinspections/")


