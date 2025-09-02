function epoch_subject_whole_trial(subj_info, age, epoch_name, zero_event, split_condition, time_window)

output_dir=fullfile('/data/infant_gaze_eeg/',age,'/preprocessed/',num2str(subj_info.subj_id));

load(fullfile(output_dir, 'preprocess_info.mat'));

ica_pruned=pop_loadset(fullfile(output_dir,sprintf('%d.ica_pruned.set',subj_info.subj_id)));

%try
    % Epoch
    epochs = pop_epoch(ica_pruned, {zero_event}, time_window, 'epochinfo', 'yes');
    epochs = pop_saveset(epochs,'filepath',output_dir,'filename',...
        sprintf('%d.%s.epochs.set', subj_info.subj_id, epoch_name));
    
    % Epoch rejection
    % Reject epochs where percentage of channels outside of threshold greater than percentage limit
    ch_epochs_to_delete=[];
    % Number of channels remaining
    num_channels=size(epochs.data,1);
    % Call EEG thresh
    for trial_idx=1:length(epochs.epoch)
        start_s=-1;
        end_s=-1;
        for j=1:length(epochs.epoch(trial_idx).eventtype)
            if strcmp(epochs.epoch(trial_idx).eventtype{j},'ima1')
                % If this is the second ima1 event without an mov1 event -
                % exclude
                if start_s>-1
                    break
                end
                start_s=epochs.epoch(trial_idx).eventlatency{j}/1000;
            elseif strcmp(epochs.epoch(trial_idx).eventtype{j},'mov1')
                end_s=epochs.epoch(trial_idx).eventlatency{j}/1000+2.5;
                break
            end
        end
        
        if end_s<0
            ch_epochs_to_delete(end+1)=trial_idx;
        else
            [Itmp Irej NS Erejtmp] = eegthresh(epochs.data(:,:,trial_idx), epochs.pnts,...
                [1:num_channels], preprocess_info.lower_channel_thresh,...
                preprocess_info.upper_channel_thresh, [start_s end_s],...
                start_s, end_s);
            if length(Irej)>0
                % Get number of bad channels for this trial
                affected_channels=sum(Erejtmp);

                % If percentage of bad channels > 15% then reject trial
                if affected_channels/num_channels>preprocess_info.prop_bad_channel_thresh
                    ch_epochs_to_delete(end+1)=trial_idx;
                end
            end
        end
    end
    preprocess_info.ch_epochs_to_delete(epoch_name)=ch_epochs_to_delete;
    
    % Remove epochs with no attention artifacts
    artifact_epochs_to_delete=[];
    % Iterate through each epoch
    for i=1:length(epochs.epoch)
        total_noat_time=0.0;
        start_data_ms=-1;
        end_data_ms=-1;
        for j=1:length(epochs.epoch(i).eventtype)
            if strcmp(epochs.epoch(i).eventtype{j},'ima1')
                start_data_ms=epochs.epoch(i).eventlatency{j};
            elseif strcmp(epochs.epoch(i).eventtype{j},'mov1')
                end_data_ms=epochs.epoch(i).eventlatency{j}+2.5*1000;
                break
            end
        end
        if end_data_ms>0
            % Iterate through each event in the epoch
            for j=1:length(epochs.epoch(i).eventtype)
                % If event type is artifact (corresponds to noat and cry events) - add to list of epochs to remove
                if strcmp(epochs.epoch(i).eventtype{j},'artifact') && epochs.epoch(i).eventlatency{j}>=start_data_ms && epochs.epoch(i).eventlatency{j}<=end_data_ms
                    total_noat_time=total_noat_time+epochs.epoch(i).eventduration{j};
                end
            end
            if total_noat_time/(end_data_ms-start_data_ms)>.2
            %if total_noat_time>0
                artifact_epochs_to_delete(end+1)=i;
            end
        end
    end
    preprocess_info.artifact_epochs_to_delete(epoch_name)=artifact_epochs_to_delete;
    
    % Remove epochs filtered because of noisy channels or no attention
    epochs_to_delete=union(ch_epochs_to_delete, artifact_epochs_to_delete);
    epoch_reject = pop_rejepoch(epochs, epochs_to_delete ,0);
    epoch_reject=pop_saveset(epoch_reject,'filepath',output_dir,...
        'filename',sprintf('%d.%s.epoch_reject.set', subj_info.subj_id, epoch_name));
    
    if split_condition
        % Split by condition
        %try
            % Select unshuffled trials
            unshuffled = pop_selectevent(epoch_reject, 'type', {zero_event},...
                'shuf', 0, 'deleteevents', 'off', 'deleteepochs', 'on',...
                'invertepochs', 'off');
            unshuffled = pop_saveset(unshuffled,'filepath',output_dir,...
                'filename', sprintf('%d.%s.unshuffled.set', subj_info.subj_id, epoch_name));
        %catch
        %end
        
        %try
            % Select unshuffled - congruent trials
            unshuffled_congruent = pop_selectevent(unshuffled, 'type',...
                {zero_event}, 'gaze', {'cong'}, 'deleteevents', 'off',...
                'deleteepochs', 'on', 'invertepochs', 'off');
            unshuffled_congruent = pop_saveset(unshuffled_congruent,...
                'filepath',output_dir,...
                'filename',sprintf('%d.%s.unshuffled_congruent.set', subj_info.subj_id, epoch_name));
            preprocess_info.unshuffled_congruent_trials(epoch_name)=unshuffled_congruent.trials;
        %catch
        %    preprocess_info.unshuffled_congruent_trials(epoch_name)=0;
        %end
        
        %try
            % Select unshuffled - incongruent trials
            unshuffled_incongruent = pop_selectevent(unshuffled, 'type',...
                {zero_event}, 'gaze', {'inco'}, 'deleteevents', 'off',...
                'deleteepochs', 'on', 'invertepochs', 'off');
            unshuffled_incongruent = pop_saveset(unshuffled_incongruent,...
                'filepath',output_dir,...
                'filename',sprintf('%d.%s.unshuffled_incongruent.set', subj_info.subj_id, epoch_name));
            preprocess_info.unshuffled_incongruent_trials(epoch_name)=unshuffled_incongruent.trials;
        %catch
        %    preprocess_info.unshuffled_incongruent_trials(epoch_name)=0;
        %end
        
        %try
            % Select shuffled trials
            shuffled = pop_selectevent(epoch_reject, 'type', {zero_event}, ...
                'shuf', 1, 'deleteevents', 'off', 'deleteepochs', 'on',...
                'invertepochs', 'off');
            shuffled = pop_saveset(shuffled,'filepath',output_dir,...
                'filename',sprintf('%d.%s.shuffled.set', subj_info.subj_id, epoch_name));
        %catch
        %end
        
        %try
            % Select shuffled - congruent trials
            shuffled_congruent = pop_selectevent(shuffled, 'type', {zero_event},...
                'gaze', {'cong'}, 'deleteevents', 'off', 'deleteepochs', 'on',...
                'invertepochs', 'off');
            shuffled_congruent = pop_saveset(shuffled_congruent,...
                'filepath',output_dir,...
                'filename',sprintf('%d.%s.shuffled_congruent.set', subj_info.subj_id, epoch_name));
            preprocess_info.shuffled_congruent_trials(epoch_name)=shuffled_congruent.trials;
        %catch
        %    preprocess_info.shuffled_congruent_trials(epoch_name)=0;
        %end
        
        %try
            % Select shuffled - incongruent trials
            shuffled_incongruent = pop_selectevent(shuffled, 'type', {zero_event},...
                'gaze', {'inco'}, 'deleteevents', 'off', 'deleteepochs', 'on',...
                'invertepochs', 'off');
            shuffled_incongruent = pop_saveset(shuffled_incongruent,...
                'filepath',output_dir,...
                'filename',sprintf('%d.%s.shuffled_incongruent.set', subj_info.subj_id, epoch_name));
            preprocess_info.shuffled_incongruent_trials(epoch_name)=shuffled_incongruent.trials;
        %catch
        %    preprocess_info.shuffled_incongruent_trials(epoch_name)=0;
        %end
    end
%catch
%end

save(fullfile(output_dir, 'preprocess_info.mat'),'preprocess_info');