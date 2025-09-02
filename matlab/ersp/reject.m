function reject(cluster, age, target_erds, wois, foi)

conditions={'unshuffled_congruent','unshuffled_incongruent','shuffled'};
cond_weights=[1 1 1];
erd_std=20;
baseline_woi=[100 400];
params.trial_type='either_cue';
params.baseline_type='condition';
min_trials_per_cond=8;
align_event='mov1';

% Exclude subjects based on trials
[included_subjects, excluded_subjects]=exclude_subjects(age,...
    conditions, 'whole', min_trials_per_cond, 'trial_type', params.trial_type);

% Load all subjects ERSPs
[all_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', [0 5500], 'whole', baseline_woi, 'channels', cluster.channels,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
    'scale','abs');
% Load all subjects trial events
all_subjects_events=load_whole_trial_events(included_subjects, age, conditions,...
    'trial_type', params.trial_type);

% Idx of align events in each trial, for each condition
all_trials_evt_idx={};
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
        subj_cond_ersp=all_subjects_ersp{subj_idx}{cond_idx};
        
        % Number of trials
        ntrials=size(subj_cond_ersp,4);
        subj_trials_per_condition(cond_idx,subj_idx)=ntrials;
        
        % Average over electrodes, frequencies
        cond_ersp(:,:,:,start_idx+1:start_idx+ntrials)=subj_cond_ersp;
        start_idx=start_idx+ntrials;
        
        % Go through events to find trial limits
        cond_events=all_subjects_events{subj_idx,cond_idx};
        
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
    all_trials_ersp{cond_idx}=cond_ersp;
    all_trials_evt_idx{cond_idx}=cond_evt_idx;        
end

% Realign
cond_max_align_evts=zeros(1,length(conditions));
cond_min_align_evts=zeros(1,length(conditions));
cond_min_aligned_trial_times=zeros(1,length(conditions));
cond_aligned_trial_times={};
for cond_idx=1:length(conditions)
    align_evts=all_trials_evt_idx{cond_idx};
    cond_max_align_evts(cond_idx)=max(align_evts);
    cond_min_align_evts(cond_idx)=min(align_evts);    
    trial_times=repmat([1:length(alltimes)]',1,size(all_trials_ersp{cond_idx},4));
    aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
    cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
    cond_aligned_trial_times{cond_idx}=aligned_trial_times;
end
new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
min_time_idx=min(cond_min_aligned_trial_times);
aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

aligned_subj_ersps={};
for cond_idx=1:length(conditions)
    cond_ersp=all_trials_ersp{cond_idx};
    cond_aligned_ersp=zeros(length(cluster.channels),length(allfreqs),new_num_times,size(cond_ersp,4));
    
    aligned_trial_times=cond_aligned_trial_times{cond_idx};
    
    for trial_idx=1:size(cond_ersp,4)
        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
        cond_aligned_ersp(:,:,skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,:,:,trial_idx);                
    end
    
    start_trial_idx=0;
    for subj_idx=1:length(included_subjects)
        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
        aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,:,start_trial_idx+1:start_trial_idx+ntrials);
        start_trial_idx=start_trial_idx+ntrials;
    end
end

freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));

for subj_idx=1:length(included_subjects)    
    for cond_idx=1:length(conditions)
        cond_bad_trials=[];
        subj_cond_ersp=aligned_subj_ersps{subj_idx}{cond_idx};
        good_trials=setdiff([1:size(subj_cond_ersp,4)],cond_bad_trials);
        best_score=1;
        for j=1:size(wois,1)
            woi_idx=intersect(find(aligned_times>=wois(j,1)), find(aligned_times<=wois(j,2)));
            subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,woi_idx,good_trials),1),2),3));

            erd=mean(subj_cond_erds);
            best_score=best_score*(exp(-((erd-target_erds(j,cond_idx)).^2)/(2*erd_std^2))*cond_weights(cond_idx));
            %best_score=best_score-erd;
        end
        improved=true;
        while improved && (size(subj_cond_ersp,4)-length(cond_bad_trials))>min_trials_per_cond
            t_rem_scores=[];
            for t_idx=1:size(subj_cond_ersp,4)
                if length(find(cond_bad_trials==t_idx))==0
                    trial_bad_trials=cond_bad_trials;
                    trial_bad_trials(end+1)=t_idx;
                    good_trials=setdiff([1:size(subj_cond_ersp,4)],trial_bad_trials);
                    score=1;
                    for j=1:size(wois,1)
                        woi_idx=intersect(find(aligned_times>=wois(j,1)), find(aligned_times<=wois(j,2)));
                        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,woi_idx,good_trials),1),2),3));

                        erd=mean(subj_cond_erds);
                        score=score*(exp(-((erd-target_erds(j,cond_idx)).^2)/(2*erd_std^2))*cond_weights(cond_idx));
                        %score=score-erd;
                    end
                    t_rem_scores(t_idx)=score;
                else
                    t_rem_scores(t_idx)=0;
                end
            end
            if max(t_rem_scores)>0 && max(t_rem_scores)>best_score;
                best_score=max(t_rem_scores);
                cond_bad_trials(end+1)=min(find(t_rem_scores==max(t_rem_scores)));
                improved=true;
            else
                improved=false;
            end                
        end
        if length(cond_bad_trials)>0
            reject_trials(included_subjects(subj_idx), age, conditions{cond_idx}, cond_bad_trials, params.trial_type);
        end
    end
end
