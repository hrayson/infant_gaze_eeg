function export_aligned_clusters_erd(conditions, freq_bands, wois, baseline_woi, min_trials_per_cond,...
    clusters, align_event, filename, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
    conditions, 'whole', min_trials_per_cond, 'trial_type', params.trial_type);

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, 'whole', min_trials_per_cond, 'trial_type', params.trial_type);

fid=fopen(filename,'w');
fprintf(fid, 'Subject,Age,Region,Hemisphere,WOI,FreqBand,Condition,ERD\n');

for cluster_idx=1:length(clusters)
    cluster=clusters(cluster_idx);
    
    for freq_idx=1:length(freq_bands)
        freq_band=freq_bands(freq_idx);
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'6m')
            
            % Load all subjects ERSPs
            [sixm_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
                conditions, 'whole', [0 5500], 'whole', baseline_woi, 'channels', cluster.channels,...
                'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
                'scale','abs');
            % Load all subjects trial events
            sixm_subjects_events=load_whole_trial_events(sixm_included_subjects, '6m', conditions,...
                'trial_type', params.trial_type);

            % Idx of align events in each trial, for each condition
            sixm_trials_evt_idx={};
            sixm_trials_ersp={};
            % Number of trials per subject for each condition
            subj_trials_per_condition=zeros(length(conditions),length(sixm_included_subjects));

            dt=14;

            for cond_idx=1:length(conditions)

                % Matrix of ERSP for this condition - all trials
                cond_ersp=[];
                % For aligned event type - list of time step indices for each trial
                cond_evt_idx=[];
                start_idx=0;

                for subj_idx=1:length(sixm_included_subjects)

                    % Get ERSP and log ERSP for this subject for this condition
                    subj_cond_ersp=sixm_subjects_ersp{subj_idx}{cond_idx};

                    % Number of trials
                    ntrials=size(subj_cond_ersp,4);
                    subj_trials_per_condition(cond_idx,subj_idx)=ntrials;

                    % Average over electrodes, frequencies
                    cond_ersp(:,:,:,start_idx+1:start_idx+ntrials)=subj_cond_ersp;
                    start_idx=start_idx+ntrials;

                    % Go through events to find trial limits
                    cond_events=sixm_subjects_events{subj_idx,cond_idx};

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
                sixm_trials_ersp{cond_idx}=cond_ersp;
                sixm_trials_evt_idx{cond_idx}=cond_evt_idx;        
            end

            % Realign
            cond_max_align_evts=zeros(1,length(conditions));
            cond_min_align_evts=zeros(1,length(conditions));
            cond_min_aligned_trial_times=zeros(1,length(conditions));
            cond_aligned_trial_times={};
            for cond_idx=1:length(conditions)
                align_evts=sixm_trials_evt_idx{cond_idx};
                cond_max_align_evts(cond_idx)=max(align_evts);
                cond_min_align_evts(cond_idx)=min(align_evts);    
                trial_times=repmat([1:length(alltimes)]',1,size(sixm_trials_ersp{cond_idx},4));
                aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
                cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
                cond_aligned_trial_times{cond_idx}=aligned_trial_times;
            end
            new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
            min_time_idx=min(cond_min_aligned_trial_times);
            aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

            for w=1:size(wois,1)
                woi=wois(w,:);
                woi_idx=intersect(find(aligned_times>=woi(1)), find(aligned_times<=woi(2)));
                aligned_subj_ersps={};
                for cond_idx=1:length(conditions)
                    cond_ersp=sixm_trials_ersp{cond_idx};
                    cond_aligned_ersp=zeros(length(cluster.channels),length(allfreqs),new_num_times,size(cond_ersp,4));

                    aligned_trial_times=cond_aligned_trial_times{cond_idx};

                    for trial_idx=1:size(cond_ersp,4)
                        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
                        cond_aligned_ersp(:,:,skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,:,:,trial_idx);                
                    end

                    start_trial_idx=0;
                    for subj_idx=1:length(sixm_included_subjects)
                        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
                        aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,woi_idx,start_trial_idx+1:start_trial_idx+ntrials);
                        start_trial_idx=start_trial_idx+ntrials;
                    end
                end

                [erds, subjs]=compute_condition_erds(conditions, ...
                    sixm_included_subjects, aligned_subj_ersps, allfreqs, freq_band.foi, min_trials_per_cond, 'outlier_method', params.outlier_method);
                
                for cond_idx=1:length(conditions)
                    condition=conditions{cond_idx};
                    for subj_idx=1:length(subjs)
                        subj_id=subjs(subj_idx);
                        fprintf(fid, '%d,6m,%s,%s,%d-%dms,%s,%s,%.4f\n', subj_id, ...
                            cluster.region, cluster.hemisphere, woi(1), woi(2), freq_band.name, ...
                            condition, erds(cond_idx,subj_idx));
                    end
                end
            end
        end
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'9m')
            % Load all subjects ERSPs
            [ninem_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
                conditions, 'whole', [0 5500], 'whole', baseline_woi, 'channels', cluster.channels,...
                'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
                'scale','abs');
            % Load all subjects trial events
            ninem_subjects_events=load_whole_trial_events(ninem_included_subjects, '9m', conditions,...
                'trial_type', params.trial_type);

            % Idx of align events in each trial, for each condition
            ninem_trials_evt_idx={};
            ninem_trials_ersp={};
            % Number of trials per subject for each condition
            subj_trials_per_condition=zeros(length(conditions),length(ninem_included_subjects));

            dt=14;

            for cond_idx=1:length(conditions)

                % Matrix of ERSP for this condition - all trials
                cond_ersp=[];
                % For aligned event type - list of time step indices for each trial
                cond_evt_idx=[];
                start_idx=0;

                for subj_idx=1:length(ninem_included_subjects)

                    % Get ERSP and log ERSP for this subject for this condition
                    subj_cond_ersp=ninem_subjects_ersp{subj_idx}{cond_idx};

                    % Number of trials
                    ntrials=size(subj_cond_ersp,4);
                    subj_trials_per_condition(cond_idx,subj_idx)=ntrials;

                    % Average over electrodes, frequencies
                    cond_ersp(:,:,:,start_idx+1:start_idx+ntrials)=subj_cond_ersp;
                    start_idx=start_idx+ntrials;

                    % Go through events to find trial limits
                    cond_events=ninem_subjects_events{subj_idx,cond_idx};

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
                ninem_trials_ersp{cond_idx}=cond_ersp;
                ninem_trials_evt_idx{cond_idx}=cond_evt_idx;        
            end

            % Realign
            cond_max_align_evts=zeros(1,length(conditions));
            cond_min_align_evts=zeros(1,length(conditions));
            cond_min_aligned_trial_times=zeros(1,length(conditions));
            cond_aligned_trial_times={};
            for cond_idx=1:length(conditions)
                align_evts=ninem_trials_evt_idx{cond_idx};
                cond_max_align_evts(cond_idx)=max(align_evts);
                cond_min_align_evts(cond_idx)=min(align_evts);    
                trial_times=repmat([1:length(alltimes)]',1,size(ninem_trials_ersp{cond_idx},4));
                aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
                cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
                cond_aligned_trial_times{cond_idx}=aligned_trial_times;
            end
            new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
            min_time_idx=min(cond_min_aligned_trial_times);
            aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

            for w=1:size(wois,1)
                woi=wois(w,:);
                woi_idx=intersect(find(aligned_times>=woi(1)), find(aligned_times<=woi(2)));
                aligned_subj_ersps={};
                for cond_idx=1:length(conditions)
                    cond_ersp=ninem_trials_ersp{cond_idx};
                    cond_aligned_ersp=zeros(length(cluster.channels),length(allfreqs),new_num_times,size(cond_ersp,4));

                    aligned_trial_times=cond_aligned_trial_times{cond_idx};

                    for trial_idx=1:size(cond_ersp,4)
                        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
                        cond_aligned_ersp(:,:,skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,:,:,trial_idx);                
                    end

                    start_trial_idx=0;
                    for subj_idx=1:length(ninem_included_subjects)
                        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
                        aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,woi_idx,start_trial_idx+1:start_trial_idx+ntrials);
                        start_trial_idx=start_trial_idx+ntrials;
                    end
                end

                [erds, subjs]=compute_condition_erds(conditions, ...
                    ninem_included_subjects, aligned_subj_ersps, allfreqs, freq_band.foi, min_trials_per_cond, 'outlier_method', params.outlier_method);
                
                for cond_idx=1:length(conditions)
                    condition=conditions{cond_idx};
                    for subj_idx=1:length(subjs)
                        subj_id=subjs(subj_idx);
                        fprintf(fid, '%d,9m,%s,%s,%d-%dms,%s,%s,%.4f\n', subj_id, ...
                            cluster.region, cluster.hemisphere, woi(1), woi(2), freq_band.name, ...
                            condition, erds(cond_idx,subj_idx));
                    end
                end
            end
        end
    end
end
fclose(fid);