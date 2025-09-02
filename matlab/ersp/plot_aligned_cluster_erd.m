function plot_aligned_cluster_erd(conditions, fois, wois, baseline_woi, min_trials_per_cond,...
    cluster, align_event, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '', 'filename', '', 'fileformat', 'png');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

ages={'6m','9m'};

all_included_subjects={};
all_erds={};

for age_idx=1:length(ages)
    age=ages{age_idx};

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
    all_trials_ersp={};
    
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

    for w=1:size(wois,1)
        woi=wois(w,:);
        woi_idx=intersect(find(aligned_times>=woi(1)), find(aligned_times<=woi(2)));
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
                aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,woi_idx,start_trial_idx+1:start_trial_idx+ntrials);
                start_trial_idx=start_trial_idx+ntrials;
            end
        end

        [erds, subjs]=compute_condition_erds(conditions, ...
            included_subjects, aligned_subj_ersps, allfreqs, fois(age_idx,:), min_trials_per_cond, 'outlier_method', params.outlier_method);
        all_erds{age_idx}{w}=erds;
        all_included_subjects{age_idx}{w}=subjs;
    end
end

fig=figure();
nrows=round(sqrt(size(wois,1)));
ncols=round(size(wois,1)/nrows);
for w=1:size(wois,1)
    
    subplot(nrows,ncols,w);
    woi=wois(w,:);
    
    sixm_erds=all_erds{1}{w};
    size(all_erds{1}{w},2)
    ninem_erds=all_erds{2}{w};
    size(all_erds{2}{w},2)

    sixm_cond_mean_erd=squeeze(mean(sixm_erds,2));
    sixm_cond_stderr_erd=squeeze(std(sixm_erds,[],2))./sqrt(size(sixm_erds,2));
    ninem_cond_mean_erd=squeeze(mean(ninem_erds,2));
    ninem_cond_stderr_erd=squeeze(std(ninem_erds,[],2))./sqrt(size(ninem_erds,2));

    sixm_cond_erd={};
    ninem_cond_erd={};
    sixm_cond_base=[];
    ninem_cond_base=[];
    condition_labels={};
    for cond_idx=1:length(conditions)
        sixm_cond_erd{cond_idx}=sixm_erds(cond_idx,:);   
        [h,p,ci,stats] = ttest(sixm_erds(cond_idx,:));
        sixm_cond_base(cond_idx)=p<0.05;

        ninem_cond_erd{cond_idx}=ninem_erds(cond_idx,:);   
        [h,p,ci,stats] = ttest(ninem_erds(cond_idx,:));
        ninem_cond_base(cond_idx)=p<0.05;
        condition_labels{cond_idx}=strrep(conditions{cond_idx},'_',' ');
    end
    [sixm_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(sixm_cond_erd',...
        'condstats', 'on', 'paired', {'on', 'on'});
    [ninem_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(ninem_cond_erd',...
        'condstats', 'on', 'paired', {'on', 'on'});

    [hBar hErrorbar]=barwitherr([sixm_cond_stderr_erd ninem_cond_stderr_erd], [sixm_cond_mean_erd ninem_cond_mean_erd]);
    hold all;
    children=get(hBar,'Children');
    set(children{1},'FaceColor',[103 169 207]./255);
    set(children{2},'FaceColor',[239 138 98]./255);
    h=[children{1} children{2}];
    bar_children=get(hErrorbar,'Children');
    group1_children=bar_children{1};
    group2_children=bar_children{2};
    for cond_idx=1:length(conditions)
        x=get(children{1},'x');
        for subj_idx=1:size(sixm_erds,2)
            rand_x=x(1,cond_idx)+.1+rand()*(x(3,cond_idx)-x(1,cond_idx)-.2);
            plot(rand_x,sixm_erds(cond_idx,subj_idx),'.k');
        end
        if sixm_cond_base(cond_idx)        
            center=x(1,cond_idx)+.5*(x(3,cond_idx)-x(1,cond_idx));
            y=get(group1_children(2),'y');
            bottom=y((cond_idx-1)*9+2)-1;
            text(center,bottom,'*','HorizontalAlignment','Center','BackGroundColor','none','FontSize',24,'Color','red');
        end
        x=get(children{2},'x');
        for subj_idx=1:size(ninem_erds,2)
            rand_x=x(1,cond_idx)+.1+rand()*(x(3,cond_idx)-x(1,cond_idx)-.2);
            plot(rand_x,ninem_erds(cond_idx,subj_idx),'.k');
        end
        if ninem_cond_base(cond_idx)
            center=x(1,cond_idx)+.5*(x(3,cond_idx)-x(1,cond_idx));
            y=get(group2_children(2),'y');
            bottom=y((cond_idx-1)*9+2)-1;
            text(center,bottom,'*','HorizontalAlignment','Center','BackGroundColor','none','FontSize',24,'Color','red');
        end
    end
    set(gca, 'XTickLabel', condition_labels);
    sixm_label='6m';
    if sixm_pcond{1}<0.05
        sixm_label='6m *';
    end
    ninem_label='9m';
    if ninem_pcond{1}<0.05
        ninem_label='9m *';
    end
    legend(h, {sixm_label, ninem_label});
    ylabel('\Delta Power (%)');
    title(sprintf('%s - %d-%dms', cluster.name, woi(1), woi(2)));
end

% if length(params.filename)
%     saveas(fig, params.filename, params.fileformat);
% end

