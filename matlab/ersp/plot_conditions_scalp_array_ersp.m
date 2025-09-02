function plot_conditions_scalp_array_ersp(age, conditions, time_zero_event,...
    baseline_time_zero_event, woi, baseline_woi, min_trials_per_cond, varargin)

% Parse inputs
defaults=struct('no_headturn', false);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

if length(age)
    [included_subjects, excluded_subjects]=exclude_subjects(age,...
        conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

    [ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
        conditions, time_zero_event, woi, baseline_time_zero_event,...
        baseline_woi, 'no_headturn', params.no_headturn);

    EEG=pop_loadset(fullfile('/data/infant_gaze_eeg', age, 'preprocessed/',...
        num2str(included_subjects(1)),sprintf('%d.%s.epoch_reject.set',...
        included_subjects(1),time_zero_event)));
else
    [sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
        conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

    [sixm_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
        conditions, time_zero_event, woi, baseline_time_zero_event,...
        baseline_woi, 'no_headturn', params.no_headturn);
    
    [ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
        conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

    [ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
        conditions, time_zero_event, woi, baseline_time_zero_event,...
        baseline_woi, 'no_headturn', params.no_headturn);

    ersp=permute([permute(sixm_ersp,[5 1 2 3 4]); permute(ninem_ersp,[5 1 2 3 4])],[2 3 4 5 1]);
    
    EEG=pop_loadset(fullfile('/data/infant_gaze_eeg', '6m', 'preprocessed/',...
        num2str(sixm_included_subjects(1)),sprintf('%d.%s.epoch_reject.set',...
        sixm_included_subjects(1),time_zero_event)));
end
nchans=size(ersp,2);
chanlocs=EEG.chanlocs;

cond_mean_ersp={};
chan_mean_ersp={};
for cond_idx=1:length(conditions)
    for c=1:nchans
        cond_mean_ersp{cond_idx,c}=squeeze(mean(ersp(cond_idx,c,:,:,:),5));   
        chan_mean_ersp{cond_idx,c}=squeeze(ersp(cond_idx,c,:,:,:));   
    end
end
chan_p_vals={};
for c=1:nchans
    [pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(chan_mean_ersp(:,c),...
        'condstats', 'on', 'paired', {'on', 'on'});
    chan_p_vals{c}=pcond{1};
end

clims=zeros(nchans,2);
for c=1:nchans
    cond_min=[];
    cond_max=[];
    for cond_idx=1:length(conditions)
        tmp=cond_mean_ersp{cond_idx,c};
        cond_min(cond_idx)=min(tmp(:));
        cond_max(cond_idx)=max(tmp(:));
    end
    clims(c,:)=[min(cond_min) max(cond_max)];
end
for cond_idx=1:length(conditions)
    plot_tf_scalp_array(cond_mean_ersp(cond_idx,:), alltimes, allfreqs, chanlocs,...
        'colormap','jet', 'clim', clims);
end
plot_tf_scalp_array(chan_p_vals, alltimes, allfreqs, chanlocs, 'colormap', 'hot', ...
    'flipcolormap', true, 'clim', [0 0.05]);
