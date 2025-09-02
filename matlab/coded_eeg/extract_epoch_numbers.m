function extract_epoch_numbers()

fid=fopen('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_epoch_numbers.csv','w');
fprintf(fid, 'Subject,Age,Condition,NumTrials\n');


all_subjects={};
all_ages={};
all_conditions={};
all_num_trials=[];

ages={'6m','9m'};

for age_idx=1:length(ages)
    base_dir=fullfile('/data','infant_gaze_eeg', ages{age_idx});
    d = dir(fullfile(base_dir, 'preprocessed'));
    isub = [d(:).isdir]; % returns logical vector
    subj_ids = {d(isub).name}';
    subj_ids(ismember(subj_ids,{'.','..'})) = [];

    for subj_idx=1:length(subj_ids)
        subj_id=subj_ids{subj_idx};
        congruent=pop_loadset(fullfile('/data/infant_gaze_eeg',ages{age_idx},'preprocessed',subj_id,sprintf('%s.mov1.unshuffled_congruent.set',subj_id)));
        num_congruent=length(congruent.epoch);
        incongruent=pop_loadset(fullfile('/data/infant_gaze_eeg',ages{age_idx},'preprocessed',subj_id,sprintf('%s.mov1.unshuffled_incongruent.set',subj_id)));
        num_incongruent=length(incongruent.epoch);
        shuffled=pop_loadset(fullfile('/data/infant_gaze_eeg',ages{age_idx},'preprocessed',subj_id,sprintf('%s.mov1.shuffled.set',subj_id)));
        num_shuffled=length(shuffled.epoch);
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Shuffled', num_shuffled);           
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Incongruent', num_incongruent);
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Congruent', num_congruent);                      
    end
end
fclose(fid);
