function epoch_subject_head_turns(subj_info, age)

base_dir=fullfile('/data/infant_gaze_eeg', age);
output_dir=fullfile(base_dir,'preprocessed', num2str(subj_info.subj_id));
load(fullfile(output_dir, 'preprocess_info.mat'));

ica=pop_loadset('filepath',output_dir, 'filename', sprintf('%d.ica.set', subj_info.subj_id));

[adjust_artifact_comps, horiz, vert, blink, disc,...
    soglia_DV, diff_var, soglia_K, med2_K, meanK, soglia_SED,...
    med2_SED, SED, soglia_SAD, med2_SAD, SAD, soglia_GDSF, med2_GDSF,...
    GDSF, soglia_V, med2_V, nuovaV, soglia_D, maxdin]=ADJUST(ica,...
    fullfile(output_dir, 'adjust_report.txt'));

% Reject adjust-identified components
ica_pruned = pop_subcomp(ica, adjust_artifact_comps);

% Epoch
epochs = pop_epoch(ica_pruned, {'head'}, [-1.3 1.3], 'epochinfo', 'yes');
epochs = pop_saveset(epochs,'filepath',output_dir,'filename',...
    sprintf('%d.head_turns.epochs.set', subj_info.subj_id));

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

% Remove epochs filtered because of noisy channels or no attention
epochs_to_delete=union(ch_epochs_to_delete, artifact_epochs_to_delete);
if length(epochs_to_delete)<length(epochs.epoch)
    epoch_reject = pop_rejepoch(epochs, epochs_to_delete ,0);
    epoch_reject=pop_saveset(epoch_reject,'filepath',output_dir,...
        'filename',sprintf('%d.head_turns.epoch_reject.set', subj_info.subj_id));
end