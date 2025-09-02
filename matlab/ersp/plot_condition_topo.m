function plot_condition_topo(age, conditions, foi, woi, baseline_woi, min_trials_per_cond,...
    times, align_event, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '', 'clims',[]);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[included_subjects, excluded_subjects]=exclude_subjects(age, conditions,...
    'whole', min_trials_per_cond, 'trial_type', params.trial_type);
            
% Load all subjects ERSPs
[subjects_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', [0 5500], 'whole', baseline_woi,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
    'scale','log','foi',foi);
% Load all subjects trial events
subjects_events=load_whole_trial_events(included_subjects, age, conditions,...
    'trial_type', params.trial_type);

% Idx of align events in each trial, for each condition
trials_evt_idx={};
trials_ersp={};
% Number of trials per subject for each condition
subj_trials_per_condition=zeros(length(conditions),length(included_subjects));

dt=14;

for cond_idx=1:length(conditions)

    % Matrix of ERSP for this condition - all trials
    cond_ersp=[];
    % For aligned event type - list of time step indices for each trial
    cond_evt_idx=[];
    start_idx=0;

    for subj_idx=1:length(included_subjects)

        % Get ERSP and log ERSP for this subject for this condition
        subj_cond_ersp=subjects_ersp{subj_idx}{cond_idx};

        % Number of trials
        ntrials=size(subj_cond_ersp,4);
        subj_trials_per_condition(cond_idx,subj_idx)=ntrials;

        % Average over electrodes, frequencies
        cond_ersp(:,:,:,start_idx+1:start_idx+ntrials)=subj_cond_ersp;
        start_idx=start_idx+ntrials;

        % Go through events to find trial limits
        cond_events=subjects_events{subj_idx,cond_idx};

        % For each event type - update list of event type time indices for
        % each trial
        % Go through all trial events for this subject in this condition
        for t_idx=1:length(cond_events)
            trial_events=cond_events(t_idx);
            evt_ms=-1;
            % Go through each event in this trial
            for evt_idx=1:length(trial_events.eventtype)
                if strcmp(trial_events.eventtype{evt_idx},align_event)
                    evt_ms=trial_events.eventlatency{evt_idx};
                    break
                end
            end
            time_idx=min(find(alltimes>=evt_ms));
            cond_evt_idx(end+1)=time_idx;
        end
    end

    % Update log ERSP, trial limits, and event indices for this condition
    trials_ersp{cond_idx}=cond_ersp;
    trials_evt_idx{cond_idx}=cond_evt_idx;        
end

% Realign
cond_max_align_evts=zeros(1,length(conditions));
cond_min_align_evts=zeros(1,length(conditions));
cond_min_aligned_trial_times=zeros(1,length(conditions));
cond_aligned_trial_times={};
for cond_idx=1:length(conditions)
    align_evts=trials_evt_idx{cond_idx};
    cond_max_align_evts(cond_idx)=max(align_evts);
    cond_min_align_evts(cond_idx)=min(align_evts);    
    trial_times=repmat([1:length(alltimes)]',1,size(trials_ersp{cond_idx},4));
    aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
    cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
    cond_aligned_trial_times{cond_idx}=aligned_trial_times;
end
new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
min_time_idx=min(cond_min_aligned_trial_times);
aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

woi_idx=intersect(find(aligned_times>=woi(1)), find(aligned_times<=woi(2)));
aligned_subj_erds={};
aligned_subj_ersps={};
for cond_idx=1:length(conditions)
    cond_ersp=trials_ersp{cond_idx};
    cond_aligned_ersp=zeros(128,size(cond_ersp,2),new_num_times,size(cond_ersp,4));

    aligned_trial_times=cond_aligned_trial_times{cond_idx};

    for trial_idx=1:size(cond_ersp,4)
        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
        cond_aligned_ersp(:,:,skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,:,:,trial_idx);                
    end

    start_trial_idx=0;
    for subj_idx=1:length(included_subjects)
        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
        aligned_subj_erds{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,woi_idx,start_trial_idx+1:start_trial_idx+ntrials);
        aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,:,start_trial_idx+1:start_trial_idx+ntrials);
        start_trial_idx=start_trial_idx+ntrials;
    end
end

subj_ersps=zeros(length(included_subjects),length(conditions),...
    size(aligned_subj_ersps{subj_idx}{cond_idx},1),...
    size(aligned_subj_ersps{subj_idx}{cond_idx},2),new_num_times);
for subj_idx=1:length(included_subjects)
    for cond_idx=1:length(conditions)
        tmp=aligned_subj_ersps{subj_idx}{cond_idx};        
        subj_cond_erds=squeeze(mean(mean(mean(tmp(:,:,:,:),1),2),3));
        cond_median=median(subj_cond_erds);
        r=iqr(subj_cond_erds);
        good_trial_idx=find((subj_cond_erds-cond_median)<=1.5*r);
        subj_ersps(subj_idx,cond_idx,:,:,:)=squeeze(mean(tmp(:,:,:,good_trial_idx),4));
        
    end
end

mean_condition_ersps=[];
for t_idx=1:size(times,1)
    t1=dsearchn(aligned_times',times(t_idx,1));
    t2=dsearchn(aligned_times',times(t_idx,2));
    mean_condition_ersps(:,:,:,t_idx)=squeeze(mean(mean(subj_ersps(:,:,:,:,[t1:t2])),5));
    
end
%mean_condition_ersps=squeeze(mean(subj_ersps(:,:,:,:,time_idxs)));

max_val=max(abs(mean_condition_ersps(:)));
if length(params.clims)==0
    params.clims=[-max_val max_val];
end
%freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));

RemChans_Idx=[1 8 14 17 21 25 32 38 43 44 48 49 57 64 69 74 82 89 95 100 113 114 119 120 121 125 126 127 128 56 63 68 73 81 88 94 99 107];
KeepChans_Idx=setdiff([1:128],RemChans_Idx);

if strcmp(age,'6m')
    EEG=pop_loadset('/data/infant_gaze_eeg/6m/preprocessed/103/103.mov1.epoch_reject.set');
else
    EEG=pop_loadset('/data/infant_gaze_eeg/9m/preprocessed/102/102.mov1.epoch_reject.set');
end

fig=figure();
for cond_idx=1:length(conditions)
    for t_idx=1:length(times)
        subplot(length(conditions),length(times),(cond_idx-1)*size(times,1)+t_idx);
        
        topoplot(squeeze(mean(mean_condition_ersps(cond_idx,:,:,t_idx),3))',...
            EEG.chanlocs,'maplimits',params.clims,'plotchans',KeepChans_Idx,'style','map','shading','interp');
        title(sprintf('%s - %s: %d-%d', age, conditions{cond_idx}, times(t_idx,1), times(t_idx,2)));
        
    end
end
saveas(fig, fullfile('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/figures/scalp_topography', sprintf('age_%s_%d-%dHz.png', age, foi(1), foi(2))));

fig=figure();
for cond_idx=1:length(conditions)
    for t_idx=1:length(times)
        subplot(length(conditions),length(times),(cond_idx-1)*size(times,1)+t_idx);
        
        topoplot(squeeze(mean(mean_condition_ersps(cond_idx,:,:,t_idx),3))',...
            EEG.chanlocs,'maplimits',params.clims,'plotchans',KeepChans_Idx,'style','map','shading','flat');
        title(sprintf('%s - %s: %d-%d', age, conditions{cond_idx}, times(t_idx,1), times(t_idx,2)));
        
    end
end
saveas(fig, fullfile('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/figures/scalp_topography', sprintf('age_%s_%d-%dHz.eps', age, foi(1), foi(2))),'epsc');

fig=figure();
topoplot(squeeze(mean(mean_condition_ersps(1,:,:,1),3))',EEG.chanlocs,...
    'maplimits',params.clims,'plotchans',KeepChans_Idx,'style','map');
colorbar();
saveas(fig, fullfile('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/figures/scalp_topography', sprintf('age_%s_%d-%dHz_colorbar.png', age, foi(1), foi(2))));
saveas(fig, fullfile('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/figures/scalp_topography', sprintf('age_%s_%d-%dHz_colorbar.eps', age, foi(1), foi(2))),'epsc');