function analyze_trial_duration()

sixm_trial_durations=[];
ninem_trial_durations=[];

base_dir=fullfile('/data','infant_gaze_eeg', '6m');
d = dir(fullfile(base_dir, 'preprocessed'));
isub = [d(:).isdir]; % returns logical vector
subj_ids = {d(isub).name}';
subj_ids(ismember(subj_ids,{'.','..'})) = [];

for i=1:length(subj_ids)
    subj_id=subj_ids{i};
    subj_dir=fullfile(base_dir,'preprocessed', subj_id);
    if exist(subj_dir,'dir')==7
        file_name=fullfile(subj_dir, sprintf('%s.ica_pruned.set', subj_id));
        if exist(file_name, 'file') == 2
            data=pop_loadset(file_name);
            
            trial_start=-1;
            for evt_idx=1:length(data.event)
                event=data.event(evt_idx);
                
                if strcmp(event.type,'ima1')
                    trial_start=event.latency/data.srate;
                elseif strcmp(event.type,'mov1') && trial_start>-1
                    trial_end=event.latency/data.srate+2.5;
                    sixm_trial_durations(end+1)=trial_end-trial_start;
                    trial_start=-1;
                end
            end
        end
    end
end

base_dir=fullfile('/data','infant_gaze_eeg', '9m');
d = dir(fullfile(base_dir, 'preprocessed'));
isub = [d(:).isdir]; % returns logical vector
subj_ids = {d(isub).name}';
subj_ids(ismember(subj_ids,{'.','..'})) = [];

for i=1:length(subj_ids)
    subj_id=subj_ids{i};
    subj_dir=fullfile(base_dir,'preprocessed', subj_id);
    if exist(subj_dir,'dir')==7
        file_name=fullfile(subj_dir, sprintf('%s.ica_pruned.set', subj_id));
        if exist(file_name, 'file') == 2
            data=pop_loadset(file_name);
            
            trial_start=-1;
            for evt_idx=1:length(data.event)
                event=data.event(evt_idx);
                
                if strcmp(event.type,'ima1')
                    trial_start=event.latency/data.srate;
                elseif strcmp(event.type,'mov1') && trial_start>-1
                    trial_end=event.latency/data.srate+2.5;
                    ninem_trial_durations(end+1)=trial_end-trial_start;
                    trial_start=-1;
                end
            end
        end
    end
end

figure();
subplot(2,1,1);
hist(sixm_trial_durations);
subplot(2,1,2);
hist(ninem_trial_durations);
xlabel('Trial duration (s)');
            

