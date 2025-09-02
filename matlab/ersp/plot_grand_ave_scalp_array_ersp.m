function plot_grand_ave_scalp_array_ersp(time_zero_event,...
    baseline_time_zero_event, woi, baseline_woi, min_trials_per_cond,...
    varargin)

% Parse inputs
defaults=struct('no_headturn', false);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

conditions={'unshuffled_congruent','unshuffled_incongruent','shuffled'};

[sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);
[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

alltimes=[];
allfreqs=[];

ersp=[];
disp('6m');
[sixm_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
    {'epoch_reject'}, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'no_headturn', params.no_headturn);
disp('9m');
[ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
    {'epoch_reject'}, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'no_headturn', params.no_headturn);
ersp=permute([permute(sixm_ersp,[5 1 2 3 4]); permute(ninem_ersp,[5 1 2 3 4])],[2 3 4 5 1]);

EEG=pop_loadset(fullfile('/data/infant_gaze_eeg/6m/preprocessed/',...
    num2str(sixm_included_subjects(1)),sprintf('%d.%s.epoch_reject.set',sixm_included_subjects(1),time_zero_event)));
chanlocs=EEG.chanlocs;

chan_mean_ersp={};
chan_p_vals={};
for c=1:size(ersp,2)
    chan_mean_ersp{c}=squeeze(mean(mean(ersp(:,c,:,:,:),1),5));   
    [h,p,ci,stats]=ttest(permute(squeeze(mean(ersp(:,c,:,:,:),1)),[3 1 2]));
    chan_p_vals{c}=squeeze(p);
end

plot_tf_scalp_array(chan_mean_ersp, alltimes, allfreqs, chanlocs,'colormap','jet');
plot_tf_scalp_array(chan_p_vals, alltimes, allfreqs, chanlocs, 'colormap', 'hot', ...
    'flipcolormap', true, 'clim', [0 0.05]);
