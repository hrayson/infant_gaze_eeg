# Goes to directory containing R scripts. Note, windows uses \ but need to change to / to work in R.
setwd('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/src/R/preferential_gaze/')

# Load process subject function
source('gca_actor.R')

# Specifies which bin size to use
bin_size <- 0.1

# Treat non-aoi looks as missing
non_aoi_missing <- FALSE

# Calls gca_actor function for with reinspection data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/with_reinspections/")

# Calls gca_actor function for without reinspection data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/without_reinspections/")

# Calls gca_actor function for first look data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_first_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/first_look/")

# Calls gca_actor function for second look data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_second_look.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/second_look/")

# Treat non-aoi looks as missing
non_aoi_missing <- TRUE

# Calls gca_actor function for with reinspection data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/non_aoi_missing/with_reinspections/")

# Calls gca_actor function for without reinspection data
gca_actor(bin_size, non_aoi_missing, "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects_no_reinspections.csv", "/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/analysis/gca_analysis/actor/non_aoi_missing/without_reinspections/")
