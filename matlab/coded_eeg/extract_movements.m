function extract_movements()

fid=fopen('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_movements.csv','w');
fprintf(fid, 'Subject,Age,Trial,Condition,Artifacts,Movements,Saccades,HeadTurns\n');


all_subjects={};
all_ages={};
all_trials=[];
all_conditions={};
all_artifacts=[];
all_movements=[];
all_saccades=[];
all_head_turns=[];

ages={'6m','9m'};

for age_idx=1:length(ages)
    base_dir=fullfile('/data','infant_gaze_eeg', ages{age_idx});
    d = dir(fullfile(base_dir, 'preprocessed'));
    isub = [d(:).isdir]; % returns logical vector
    subj_ids = {d(isub).name}';
    subj_ids(ismember(subj_ids,{'.','..'})) = [];

    for subj_idx=1:length(subj_ids)
        subj_id=subj_ids{subj_idx};
        data=pop_loadset(fullfile('/data/infant_gaze_eeg',ages{age_idx},'preprocessed',subj_id,sprintf('%s.events.set',subj_id)));
        epochs = pop_epoch(data, {'mov1'}, [-.3 2.3], 'epochinfo', 'yes');

        for epoch_idx=1:length(epochs.epoch)
            epoch_artifacts=0;
            epoch_saccades=0;
            epoch_head_turns=0;

            epoch_condition='';

            for evt_idx=1:length(epochs.epoch(epoch_idx).eventtype)
                evt_type=epochs.epoch(epoch_idx).eventtype{evt_idx};
                if strcmp(evt_type,'artifact')
                    epoch_artifacts=epoch_artifacts+1;
                elseif strcmp(evt_type,'saccade')
                    epoch_saccades=epoch_saccades+1;
                elseif strcmp(evt_type,'head')
                    epoch_head_turns=epoch_head_turns+1;
                elseif strcmp(evt_type,'mov1')
                    if strcmp(epochs.epoch(epoch_idx).eventshuf{evt_idx},'0')
                        epoch_condition='shuffled';
                    elseif strcmp(epochs.epoch(epoch_idx).eventgaze{evt_idx},'inco')
                        epoch_condition='unshuffled_incongruent';
                    elseif strcmp(epochs.epoch(epoch_idx).eventgaze{evt_idx},'cong')
                        epoch_condition='unshuffled_congruent';
                    end
                end
            end
            fprintf(fid, '%s,%s,%d,%s,%d,%d,%d,%d\n', subj_id, ages{age_idx}, epoch_idx,...
                epoch_condition, epoch_artifacts, (epoch_saccades+epoch_head_turns), ...
                epoch_saccades, epoch_head_turns);           
        end
    end
end
fclose(fid);
