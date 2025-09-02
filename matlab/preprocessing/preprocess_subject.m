function preprocess_info=preprocess_subject(subj_info, varargin)
% function subj_info=preprocess_subject(subj_id, age, zero_event, epoch_limits)
% Preprocess a single subject
% INPUT:
%     subj_info: data structure of subject to preprocess (from
%     create_subject_structure)
% OPTIONAL INPUTS:

% Parse inputs
defaults=struct();
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

for age_idx=1:length(subj_info.ages)
    age=subj_info.ages{age_idx};
    num_runs=subj_info.num_runs(age_idx);
    delay=subj_info.delay(age_idx);
    coder=subj_info.coder{age_idx};
    fps=subj_info.fps(age_idx,:);
    
    % Create the structure containing all the preprocessing parameters for this subject
    preprocess_info=[];
    preprocess_info.subj_id=subj_info.subj_id;
    preprocess_info.age=age;
    preprocess_info.fps=fps;
    preprocess_info.delay=delay;
    preprocess_info.num_runs=num_runs;
    preprocess_info.coder=coder;
    
    % lower freq limit
    preprocess_info.lower_freq_limit=2;
    % higher freq limit
    preprocess_info.upper_freq_limit=35;
    % impedance threshold
    preprocess_info.impedance_thresh=50;
    % lower channel threshold
    preprocess_info.lower_channel_thresh=-250;
    % upper channel threshold
    preprocess_info.upper_channel_thresh=250;
    % proportion of bad channels to reject epoch
    preprocess_info.prop_bad_channel_thresh=.15;
    % Channels removed
    preprocess_info.channels_to_remove=dict();
    % Epochs removed because of bad channels
    preprocess_info.ch_epochs_to_delete=dict();
    % Epochs removed because of noatn or cry artifacts
    preprocess_info.artifact_epochs_to_delete=dict();
    % ADJUST-identified artifact components
    preprocess_info.adjust_artifact_comps=[];
    % Number of trials - unshuffled congruent
    preprocess_info.unshuffled_congruent_trials=dict();
    % Number of trials - unshuffled incongruent
    preprocess_info.unshuffled_incongruent_trials=dict();
    % Number of trials - shuffled congruent
    preprocess_info.shuffled_congruent_trials=dict();
    % Number of trials - shuffled congruent
    preprocess_info.shuffled_congruent_trials=dict();
 
    % Where to save files
    base_dir=fullfile('/data/infant_gaze_eeg', age);
    output_dir=fullfile(base_dir,'preprocessed', num2str(subj_info.subj_id));
    if exist(output_dir,'dir')~=7
        mkdir(output_dir);
    end

    % Read in Netstation simple binary file and convert to EEGLab format
    if num_runs>1 % These two subjects had two session files - they were alread converted to EEGlab format and then concatenated, so just need to load them
        for idx=1:num_runs
            data=pop_readegi(fullfile(base_dir, 'raw', num2str(subj_info.subj_id), 'EEG',...
                sprintf('%d_%d.nsf', subj_info.subj_id, idx)));
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, data);
        end
        raw=pop_mergeset(ALLEEG, 1:num_runs, 0);

        del = 0;
        for j = 1:size(raw.event,2)
            if strcmp(raw.event(j-del).type, 'boundary')
                raw.event(j-del) = [];
                del = del + 1;
            end
        end
    else
        raw=pop_readegi(fullfile(base_dir, 'raw',...
            num2str(subj_info.subj_id),'EEG',...
            sprintf('%d.raw', subj_info.subj_id)));
    end
    
    % Update channel locations based on EGI electrode location file
    raw_events=update_channel_locations(raw);

    % Adjust event timings
    raw_events=adjust_timings(subj_info.subj_id, age, raw_events, delay);    

    % Add event codes
    raw_events=add_event_codes(base_dir, subj_info.subj_id, raw_events);
    
    % Add durations
    raw_events=add_event_durations(raw_events);
    
    % Add no attention artifacts
    raw_events=add_noat_artifacts(age, subj_info.subj_id, base_dir,...
        num_runs, raw_events);

    % Add behavioural events
    if num_runs>1 % These subjects had two session files - so have to do differently
        raw_events=add_gaze_events_multiple_sessions(raw_events, age,...
            subj_info.subj_id, coder, num_runs, fps);
    else
        raw_events=add_gaze_events(raw_events, age, subj_info.subj_id,...
            coder, fps);
    end

    % Add events marking initial gaze to target and face
    raw_events=mark_init_gaze(raw_events);

    % Save data
    raw_events=pop_saveset(raw_events,'filepath',output_dir,'filename', ...
        sprintf('%d.events.set', subj_info.subj_id));

    % Run PREP pipeline
    % Detect bad channels, interpolate bad channels, robust average re-referencing
    % Need to make sure that #ICs in ICA is < # of channels (see Makato preprocessing pipeline). This is because interpolation reduces rank of the data
    [prep_data com]=pop_prepPipeline(raw_events, struct('lineFrequencies', [50  100], 'sessionFilePath', fullfile(output_dir,'eventsReport.pdf'), 'summaryFilePath', fullfile(output_dir, 'eventsSummary.html')));

    % Filter
    filtered = pop_eegfiltnew(prep_data, preprocess_info.lower_freq_limit, preprocess_info.upper_freq_limit);
    filtered = pop_saveset(filtered,'filepath',output_dir,'filename',[num2str(subj_info.subj_id) '.filtered.set']);

    % Run ICA
    ica = pop_runica(filtered, 'extended',1,'interupt','on');
    ica = pop_saveset(ica,'filepath',output_dir,...
        'filename',sprintf('%d.ica.set', subj_info.subj_id));

    ica=pop_loadset('filepath',output_dir, 'filename', sprintf('%d.ica.set', subj_info.subj_id));

    % Run adjust
    [preprocess_info.adjust_artifact_comps, horiz, vert, blink, disc,...
        soglia_DV, diff_var, soglia_K, med2_K, meanK, soglia_SED,...
        med2_SED, SED, soglia_SAD, med2_SAD, SAD, soglia_GDSF, med2_GDSF,...
        GDSF, soglia_V, med2_V, nuovaV, soglia_D, maxdin]=ADJUST(ica,...
        fullfile(output_dir, 'adjust_report.txt'));

    % Reject adjust-identified components
    ica_pruned = pop_subcomp(ica, preprocess_info.adjust_artifact_comps);
    ica_pruned = pop_saveset(ica_pruned,'filepath',output_dir,...
        'filename',sprintf('%d.ica_pruned.set', subj_info.subj_id));

    % Epoch aligned to different events    
    preprocess_info.epoch_names={'static', 'mov1'};
    preprocess_info.epoch_zero_events={'ima1', 'mov1'};
    preprocess_info.epoch_durations=[-0.3 0.7; -.3 2.3];
    preprocess_info.split_condition=[1 1];

    for ep_idx=1:length(preprocess_info.epoch_names)
        epoch_name=preprocess_info.epoch_names{ep_idx};
        zero_event=preprocess_info.epoch_zero_events{ep_idx};
        duration=preprocess_info.epoch_durations(ep_idx,:);

        %try
            % Epoch
            epochs = pop_epoch(ica_pruned, {zero_event}, duration, 'epochinfo', 'yes');
            epochs = pop_saveset(epochs,'filepath',output_dir,'filename',...
                sprintf('%d.%s.epochs.set', subj_info.subj_id, epoch_name));

            % Epoch rejection
            % Reject epochs where percentage of channels outside of threshold greater than percentage limit
            ch_epochs_to_delete=[];
            % Number of channels remaining
            num_channels=size(epochs.data,1);
            % Call EEG thresh
            [Itmp Irej NS Erejtmp] = eegthresh(epochs.data, epochs.pnts,...
                [1:num_channels], preprocess_info.lower_channel_thresh,...
                preprocess_info.upper_channel_thresh, [epochs.xmin epochs.xmax],...
                epochs.xmin, epochs.xmax);
            num_affected_trials=size(Erejtmp,2);
            % Looping through all trials with bad channels
            for i=1:num_affected_trials
                % Get actual trial number - out of all trials (not just ones with bad channels
                trial_num=Irej(i);
                % Get number of bad channels for this trial
                affected_channels=sum(Erejtmp(:,i));

                % If percentage of bad channels > 15% then reject trial
                if affected_channels/num_channels>preprocess_info.prop_bad_channel_thresh
                    ch_epochs_to_delete(end+1)=trial_num;
                end
            end
            preprocess_info.ch_epochs_to_delete(epoch_name)=ch_epochs_to_delete;

            % Remove epochs with no attention artifacts
            artifact_epochs_to_delete=[];
            % Iterate through each epoch
            for i=1:length(epochs.epoch)
                total_noat_time=0.0;
                % Iterate through each event in the epoch
                for j=1:length(epochs.epoch(i).eventtype)
                    % If event type is artifact (corresponds to noat and cry events) - add to list of epochs to remove
                    if strcmp(epochs.epoch(i).eventtype{j},'artifact')
                        total_noat_time=total_noat_time+epochs.epoch(i).eventduration{j};
                    end
                end    
                %if total_noat_time/(epochs.xmax-epochs.xmin)>.2
                if total_noat_time>0
                    artifact_epochs_to_delete(end+1)=i;
                end
            end
            preprocess_info.artifact_epochs_to_delete(epoch_name)=artifact_epochs_to_delete;

            % Remove epochs filtered because of noisy channels or no attention
            epochs_to_delete=union(ch_epochs_to_delete, artifact_epochs_to_delete);
            epoch_reject = pop_rejepoch(epochs, epochs_to_delete ,0);
            epoch_reject=pop_saveset(epoch_reject,'filepath',output_dir,...
                'filename',sprintf('%d.%s.epoch_reject.set', subj_info.subj_id, epoch_name));

            if preprocess_info.split_condition(ep_idx)>0
                % Split by condition
                try
                    % Select unshuffled trials
                    unshuffled = pop_selectevent(epoch_reject, 'type', {zero_event},...
                        'shuf', 0, 'deleteevents', 'off', 'deleteepochs', 'on',...
                        'invertepochs', 'off');
                    unshuffled = pop_saveset(unshuffled,'filepath',output_dir,...
                        'filename', sprintf('%d.%s.unshuffled.set', subj_info.subj_id, epoch_name));
                catch
                end

                try
                    % Select unshuffled - congruent trials
                    unshuffled_congruent = pop_selectevent(unshuffled, 'type',...
                        {zero_event}, 'gaze', {'cong'}, 'deleteevents', 'off',...
                        'deleteepochs', 'on', 'invertepochs', 'off');
                    unshuffled_congruent = pop_saveset(unshuffled_congruent,...
                        'filepath',output_dir,...
                        'filename',sprintf('%d.%s.unshuffled_congruent.set', subj_info.subj_id, epoch_name));
                    preprocess_info.unshuffled_congruent_trials(epoch_name)=unshuffled_congruent.trials;
                catch
                    preprocess_info.unshuffled_congruent_trials(epoch_name)=0;
                end

                try
                    % Select unshuffled - incongruent trials
                    unshuffled_incongruent = pop_selectevent(unshuffled, 'type',...
                        {zero_event}, 'gaze', {'inco'}, 'deleteevents', 'off',...
                        'deleteepochs', 'on', 'invertepochs', 'off');
                    unshuffled_incongruent = pop_saveset(unshuffled_incongruent,...
                        'filepath',output_dir,...
                        'filename',sprintf('%d.%s.unshuffled_incongruent.set', subj_info.subj_id, epoch_name));
                    preprocess_info.unshuffled_incongruent_trials(epoch_name)=unshuffled_incongruent.trials;
                catch
                    preprocess_info.unshuffled_incongruent_trials(epoch_name)=0;
                end

                try
                    % Select shuffled trials
                    shuffled = pop_selectevent(epoch_reject, 'type', {zero_event}, ...
                        'shuf', 1, 'deleteevents', 'off', 'deleteepochs', 'on',...
                        'invertepochs', 'off');
                    shuffled = pop_saveset(shuffled,'filepath',output_dir,...
                        'filename',sprintf('%d.%s.shuffled.set', subj_info.subj_id, epoch_name));
                catch
                end

                try
                    % Select shuffled - congruent trials
                    shuffled_congruent = pop_selectevent(shuffled, 'type', {zero_event},...
                        'gaze', {'cong'}, 'deleteevents', 'off', 'deleteepochs', 'on',...
                        'invertepochs', 'off');
                    shuffled_congruent = pop_saveset(shuffled_congruent,...
                        'filepath',output_dir,...
                        'filename',sprintf('%d.%s.shuffled_congruent.set', subj_info.subj_id, epoch_name));
                    preprocess_info.shuffled_congruent_trials(epoch_name)=shuffled_congruent.trials;
                catch
                    preprocess_info.shuffled_congruent_trials(epoch_name)=0;
                end

                try
                    % Select shuffled - incongruent trials
                    shuffled_incongruent = pop_selectevent(shuffled, 'type', {zero_event},...
                        'gaze', {'inco'}, 'deleteevents', 'off', 'deleteepochs', 'on',...
                        'invertepochs', 'off');
                    shuffled_incongruent = pop_saveset(shuffled_incongruent,...
                        'filepath',output_dir,...
                        'filename',sprintf('%d.%s.shuffled_incongruent.set', subj_info.subj_id, epoch_name));
                    preprocess_info.shuffled_incongruent_trials(epoch_name)=shuffled_incongruent.trials;
                catch
                    preprocess_info.shuffled_incongruent_trials(epoch_name)=0;
                end
            end
        %catch
        %end
        
        remove_head_turns(subj_info, age, epoch_name, preprocess_info.split_condition(ep_idx));
    end
    save(fullfile(output_dir, 'preprocess_info.mat'),'preprocess_info');
end