function plot_cluster_induced_image(age, conditions, foi, woi,...
    baseline_woi, min_trials_per_cond, cluster, align_event, varargin)

% Parse inputs
%    trial_type = where to remove head turns from
%           saccade_cue = remove trials with head turns anywhere
%           head_turn_cue = remove trials with head turn in static or movie
%               period, or saccade during cue period
%           either_cue = remove trials with head turn in static or movie
%               period
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition', ...
    'outlier_method', '', 'filename', '', 'fileformat', 'png');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Exclude subjects based on trials
[included_subjects, excluded_subjects]=exclude_subjects(age,...
    conditions, 'whole', min_trials_per_cond, 'trial_type', params.trial_type);

% Load all subjects log ERSPs
[all_subjects_log_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', woi, 'whole', baseline_woi, 'channels', cluster.channels,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type);
% Load all subjects ERSPs
[all_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', woi, 'whole', baseline_woi, 'channels', cluster.channels,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
    'scale','abs');
% Load all subjects trial events
all_subjects_events=load_whole_trial_events(included_subjects, age, conditions,...
    'trial_type', params.trial_type);

% Frequency index
freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));

% For each condition, each subject - trials to include
subj_trials_to_include={};
subj_min_trials_per_condition=zeros(1,length(included_subjects));
for subj_idx=1:length(included_subjects)
    subj_trials_per_condition=zeros(1,length(conditions));
    for cond_idx=1:length(conditions)
        subj_cond_ersp=all_subjects_ersp{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2),3));
        good_trials=[1:length(subj_cond_erds)];
        if strcmp(params.outlier_method,'iqr')
            cond_median=median(subj_cond_erds);
            r=iqr(subj_cond_erds);
            good_trials=find((subj_cond_erds-cond_median)<=1.5*r);
        elseif strcmp(params.outlier_method,'mdm')
            c=outmdm(subj_cond_erds);
            good_trials=find(c==0);            
        end        
        
        subj_trials_to_include{cond_idx,subj_idx}=good_trials;
        subj_trials_per_condition(cond_idx)=length(good_trials);
    end
    subj_min_trials_per_condition(subj_idx)=min(subj_trials_per_condition);
end
final_included_subj_idx=find(subj_min_trials_per_condition>=min_trials_per_cond);
subj_trials_to_include=subj_trials_to_include(:,final_included_subj_idx);
all_subjects_log_ersp=all_subjects_log_ersp(final_included_subj_idx);
all_subjects_ersp=all_subjects_ersp(final_included_subj_idx);
all_subjects_events=all_subjects_events(final_included_subj_idx,:);
included_subjects=included_subjects(final_included_subj_idx);

% Event types
event_types={'ima1','ima2','mov1','init_gaze_face'};

% Log ERSP of each trial for each condition
all_trials_log_ersp={};
% ERSP of each trial for each condition
all_trials_ersp={};
% Trial limits for all trials = 1 when within limits for each condition
all_trials_limits={};
% Idx of ima1, ima2, and mov1 events in each trial, for each condition
all_trials_evt_idx={};
% Number of trials per subject for each condition
subj_trials_per_condition=zeros(length(conditions),length(included_subjects));

% Log ERSP of each trial for each condition, after aligning
all_trials_aligned_log_ersp={};
% ERSP of each trial for each condition, after aligning
all_trials_aligned_ersp={};
% Trial limits for all aligned trials = 1 when within limits for each condition
all_trials_aligned_limits={};
% Mean ERSP for each subject in each condition
aligned_cond_mean_ersp={};

dt=14;

for cond_idx=1:length(conditions)
    
    % Matrix of log ERSP for this condition - all trials
    cond_log_ersp=[];
    % Matrix of ERSP for this condition - all trials
    cond_ersp=[];
    % Matrix of trial limits for this condition - all trials
    cond_trials_limits=[];
    % For each event type - list of time step indices for each trial
    cond_evt_idx=dict();
    % Initialize event indices for each event type
    for evt_type_idx=1:length(event_types)
        evt_type=event_types{evt_type_idx};
        cond_evt_idx(evt_type)=[];
    end
    
    for subj_idx=1:length(included_subjects)
        
        % Get ERSP and log ERSP for this subject for this condition
        subj_cond_log_ersp=all_subjects_log_ersp{subj_idx}{cond_idx};
        subj_cond_log_ersp=subj_cond_log_ersp(:,:,:,subj_trials_to_include{cond_idx,subj_idx});
        subj_cond_ersp=all_subjects_ersp{subj_idx}{cond_idx};
        subj_cond_ersp=subj_cond_ersp(:,:,:,subj_trials_to_include{cond_idx,subj_idx});
        
        % Number of trials
        ntrials=size(subj_cond_log_ersp,4);
        subj_trials_per_condition(cond_idx,subj_idx)=ntrials;
        
        % Average over electrodes, frequencies
        cond_log_ersp(:,end+1:end+ntrials)=squeeze(mean(mean(subj_cond_log_ersp(:,freq_idx,:,:),1),2));
        cond_ersp(:,end+1:end+ntrials)=squeeze(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2));
        
        % Go through events to find trial limits
        cond_events=all_subjects_events{subj_idx,cond_idx};
        cond_events=cond_events(subj_trials_to_include{cond_idx,subj_idx});
        for trial_idx=1:length(cond_events)
            trial_events=cond_events(trial_idx);
            
            % Find end event time in ms
            trial_end_ms=-1;
            for evt_idx=1:length(trial_events.eventtype)
                % End is 2.5s after mov1
                if strcmp(trial_events.eventtype{evt_idx},'mov1')
                    trial_end_ms=trial_events.eventlatency{evt_idx}+2.5*1000;
                    break
                end
            end
            % Set trials limits for this trial to 1 for all time steps
            % within limits
            cond_trials_limits(:,end+1)=alltimes<=trial_end_ms;
        end
        
        % For each event type - update list of event type time indices for
        % each trial
        for evt_type_idx=1:length(event_types)
            evt_type=event_types{evt_type_idx};
            trials_evt_idx=cond_evt_idx(evt_type);
            % Go through all trial events for this subject in this condition
            for t_idx=1:length(cond_events)
                trial_events=cond_events(t_idx);
                evt_ms=-1;
                % Go through each event in this trial
                for evt_idx=1:length(trial_events.eventtype)
                    if strcmp(trial_events.eventtype{evt_idx},evt_type)
                        evt_ms=trial_events.eventlatency{evt_idx};
                        break
                    end
                end
                time_idx=min(find(alltimes>=evt_ms));
                trials_evt_idx(end+1)=time_idx;
            end
            cond_evt_idx(evt_type)=trials_evt_idx;
        end                    
    end
    
    % Update log ERSP, trial limits, and event indices for this condition
    all_trials_log_ersp{cond_idx}=cond_log_ersp;
    all_trials_ersp{cond_idx}=cond_ersp;
    all_trials_limits{cond_idx}=cond_trials_limits;
    all_trials_evt_idx{cond_idx}=cond_evt_idx;        
end

% Realign
cond_max_align_evts=zeros(1,length(conditions));
cond_min_align_evts=zeros(1,length(conditions));
cond_min_aligned_trial_times=zeros(1,length(conditions));
cond_aligned_trial_times={};
for cond_idx=1:length(conditions)
    align_evts=all_trials_evt_idx{cond_idx};
    align_evts=align_evts(align_event);
    cond_max_align_evts(cond_idx)=max(align_evts);
    cond_min_align_evts(cond_idx)=min(align_evts);    
    trial_times=repmat([1:length(alltimes)]',1,size(all_trials_log_ersp{cond_idx},2));
    aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
    cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
    cond_aligned_trial_times{cond_idx}=aligned_trial_times;
end
new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
min_time_idx=min(cond_min_aligned_trial_times);
aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

for cond_idx=1:length(conditions)
    cond_log_ersp=all_trials_log_ersp{cond_idx};
    cond_ersp=all_trials_ersp{cond_idx};
    cond_trials_limits=all_trials_limits{cond_idx};
    cond_aligned_log_ersp=zeros(new_num_times,size(cond_log_ersp,2));
    cond_aligned_ersp=zeros(new_num_times,size(cond_ersp,2));
    cond_aligned_trials_limits=zeros(new_num_times,size(cond_log_ersp,2));
    
    aligned_trial_times=cond_aligned_trial_times{cond_idx};
    
    for trial_idx=1:size(cond_log_ersp,2)
        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
        cond_aligned_log_ersp(skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_log_ersp(:,trial_idx);
        cond_aligned_ersp(skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,trial_idx);
        cond_aligned_trials_limits(skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_trials_limits(:,trial_idx);
        
        for evt_type_idx=1:length(event_types)
            evt_type=event_types{evt_type_idx};
            cond_evt_idx=all_trials_evt_idx{cond_idx};
            trials_evt_idx=cond_evt_idx(evt_type);
            trials_evt_idx(trial_idx)=trials_evt_idx(trial_idx)+skip_rows;
            cond_evt_idx(evt_type)=trials_evt_idx;
            all_trials_evt_idx{cond_idx}=cond_evt_idx;
        end
    end
    
    all_trials_aligned_log_ersp{cond_idx}=cond_aligned_log_ersp;    
    all_trials_aligned_ersp{cond_idx}=cond_aligned_ersp;    
    all_trials_aligned_limits{cond_idx}=cond_aligned_trials_limits;
        
    aligned_mean_ersp=zeros(length(aligned_times), length(included_subjects));
    start_trial_idx=0;
    for subj_idx=1:length(included_subjects)
        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
        aligned_mean_ersp(:,subj_idx)=mean(cond_aligned_ersp(:,start_trial_idx+1:start_trial_idx+ntrials),2);
        start_trial_idx=start_trial_idx+ntrials;
    end
    aligned_cond_mean_ersp{cond_idx}=aligned_mean_ersp;
end

[pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(aligned_cond_mean_ersp',...
    'condstats', 'on', 'paired', {'on', 'on'});


colors={'g','r','b'};
fig=figure('Position',[1 1 1000 800], 'PaperUnits','points',...
    'PaperPosition',[1 1 600 400],'PaperPositionMode','manual');
cm=colormap();

% Find color limits 
cond_abs_max=[];
for cond_idx=1:length(conditions)
    cond_log_ersp=all_trials_log_ersp{cond_idx}';
    cond_abs_max(cond_idx)=max(abs(cond_log_ersp(:)));
end

% Add white to end of colormap
colormap([colormap; 1 1 1]);

for cond_idx=1:length(conditions)
    subplot(2,3,cond_idx);
    hold all;
    
    % Get all trials log ERSP for this condition
    all_subjects_log_ersp=all_trials_aligned_log_ersp{cond_idx}';
    % Set outside of trial limits to white
    all_subjects_log_ersp(find(all_trials_aligned_limits{cond_idx}'<1))=max(cond_abs_max)+1;
    
    % Plot
    imagesc(aligned_times,[1:size(all_subjects_log_ersp,1)],all_subjects_log_ersp,...
        [-max(cond_abs_max) max(cond_abs_max)]);
    
    % Plot events    
    for evt_type_idx=1:length(event_types)
        evt_type=event_types{evt_type_idx};
        cond_evt_idx=all_trials_evt_idx{cond_idx};
        trials_evt_idx=cond_evt_idx(evt_type);
        for t_idx=1:length(trials_evt_idx);
            evt_ms=aligned_times(trials_evt_idx(t_idx));
            plot(evt_ms, t_idx, '.k');
        end
    end
    
    min_time=min(find(any(all_trials_aligned_limits{cond_idx}')>0));
    max_time=max(find(any(all_trials_aligned_limits{cond_idx}')>0));
    
    % Plot dashed lines between subjects
    trial_idx=1;
    for subj_idx=1:length(included_subjects)-1
        trial_idx=trial_idx+subj_trials_per_condition(cond_idx,subj_idx);
        plot([aligned_times(min_time) aligned_times(max_time)],[trial_idx trial_idx],'k--');
    end
    
    xlim([aligned_times(min_time) aligned_times(max_time)]);
    ylim([1 trial_idx]);
    set(gca,'Yticklabel',[]);
    %colorbar();
    title(strrep(conditions{cond_idx},'_',' '));
    xlabel('Time (ms)');
    ylabel('Subject Trials');
end

subplot(2,3,[4:6]);
hold all;
legend_labels={};
cond_min_times=[];
cond_max_times=[];
cond_hs=[];
for cond_idx=1:length(conditions)
    trial_limits=all_trials_aligned_limits{cond_idx};
    aligned_mean_ersp=aligned_cond_mean_ersp{cond_idx};
    max_time=max(find(sum(trial_limits,2)==size(trial_limits,2)));
    cond_max_times(cond_idx)=max_time;
    min_time=min(find(sum(trial_limits,2)==size(trial_limits,2)));
    cond_min_times(cond_idx)=min_time;
    cond_hs(end+1)=plot(aligned_times(min_time:max_time),squeeze(mean(aligned_mean_ersp(min_time:max_time,:),2)),colors{cond_idx});
    legend_labels{end+1}=strrep(conditions{cond_idx},'_',' ');
end
plot([aligned_times(max(cond_min_times)) aligned_times(min(cond_max_times))],[0 0],'k--');
yl=ylim();
sig_time_idx=find(pcond{1}<0.05);
for idx=1:length(sig_time_idx)
    p = patch('vertices', [aligned_times(sig_time_idx(idx)), yl(1); aligned_times(sig_time_idx(idx)), yl(2); aligned_times(sig_time_idx(idx))+dt, yl(2); aligned_times(sig_time_idx(idx))+dt yl(1)], ...
          'faces', [1, 2, 3, 4], ...
          'FaceColor', 'y', ...
          'FaceAlpha', 0.25,...
          'EdgeColor','none');
    uistack(p,'bottom');
end
xlim([aligned_times(max(cond_min_times)) aligned_times(min(cond_max_times))]);
legend(cond_hs, legend_labels);
ylabel('\Delta Power (%)');
xlabel('Time (ms)');
title(cluster.name);

cond_idx=1;

figure();
hold all;
legend_labels={};
trial_limits=all_trials_aligned_limits{cond_idx};
max_time=max(find(sum(trial_limits,2)==size(trial_limits,2)));
min_time=min(find(sum(trial_limits,2)==size(trial_limits,2)));
aligned_mean_ersp=aligned_cond_mean_ersp{cond_idx};
for subj_idx=1:length(included_subjects)
    plot(aligned_times(min_time:max_time),squeeze(aligned_mean_ersp(min_time:max_time,subj_idx)));
    legend_labels{end+1}=num2str(included_subjects(subj_idx));
end
yl=ylim();
xlim([aligned_times(min_time) aligned_times(max_time)]);
legend(legend_labels);
ylabel('\Delta Power (%)');
xlabel('Time (ms)');


% cond_aligned_ersp=all_trials_aligned_ersp{cond_idx};    
% trial_limits=all_trials_aligned_limits{cond_idx};
% start_trial_idx=0;
% for subj_idx=1:length(included_subjects)
%     ntrials=subj_trials_per_condition(cond_idx,subj_idx);
%     figure();
%     legend_labels={};
%     hold all;
%     for t_idx=1:ntrials        
%         max_time=max(find(sum(trial_limits,2)==size(trial_limits,2)));
%         min_time=min(find(sum(trial_limits,2)==size(trial_limits,2)));
%         plot(aligned_times(min_time:max_time),squeeze(cond_aligned_ersp(min_time:max_time,start_trial_idx+t_idx)));
%         legend_labels{end+1}=num2str(t_idx);        
%     end
%     start_trial_idx=start_trial_idx+ntrials;
%     plot(aligned_times(min_time:max_time),squeeze(mean(cond_aligned_ersp(min_time:max_time,start_trial_idx+t_idx),2)),'k--');
%     legend_labels{end+1}='mean';
%     title(sprintf('subject %d', included_subjects(subj_idx)));
%     xlim([aligned_times(max(cond_min_times)) aligned_times(min(cond_max_times))]);
%     legend(legend_labels);
%     ylabel('\Delta Power (%)');
%     xlabel('Time (ms)');
% end

