function extract_epoch_reject()

fid=fopen('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_epoch_reject.csv','w');
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
        epochs=pop_loadset(fullfile('/data/infant_gaze_eeg',ages{age_idx},'preprocessed',subj_id,sprintf('%s.mov1.epoch_reject.set',subj_id)));

        num_congruent=0;
        num_incongruent=0;
        num_shuffled=0;

        for epoch_idx=1:length(epochs.epoch)
            for evt_idx=1:length(epochs.epoch(epoch_idx).eventtype)
                evt_type=epochs.epoch(epoch_idx).eventtype{evt_idx};
                if strcmp(evt_type,'mov1')
                    if strcmp(epochs.epoch(epoch_idx).eventshuf{evt_idx},'0')
                        num_shuffled=num_shuffled+1;
                    elseif strcmp(epochs.epoch(epoch_idx).eventgaze{evt_idx},'inco')
                        num_incongruent=num_incongruent+1;
                    elseif strcmp(epochs.epoch(epoch_idx).eventgaze{evt_idx},'cong')
                        num_incongruent=num_congruent+1;
                    end
                end
            end            
        end
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Shuffled', num_shuffled);           
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Incongruent', num_incongruent);
        fprintf(fid, '%s,%s,%s,%d\n', subj_id, ages{age_idx}, 'Congruent', num_congruent);                      
    end
end
fclose(fid);
