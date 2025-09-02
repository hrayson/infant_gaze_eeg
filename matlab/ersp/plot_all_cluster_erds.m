% clusters=create_cluster_structure();
% freq_bands=create_freq_band_structure();
% wois=[0 1000;1000 2000];
% for woi_idx=1:size(wois,1)
%    woi=wois(woi_idx,:);
%    plot_all_cluster_erds(clusters,[2 4;5 8;6 9;9 20;10 21],{'unshuffled_congruent','unshuffled_incongruent','shuffled'},'mov1','static',woi,[0 400],5,'output_dir','/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/ersp/clusters/v7/');
% end
function plot_all_cluster_erds(clusters, fois, conditions, time_zero_event,...
    baseline_time_zero_event, woi, baseline_woi, min_trials_per_cond,...
    varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '', 'output_dir', '');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

for foi_idx=1:size(fois,1)
    foi=fois(foi_idx,:);
    
    foi_dir=fullfile(params.output_dir, sprintf('%d-%dms', woi(1), woi(2)), sprintf('%d-%dHz', foi(1), foi(2)),'no_outliers');
    mkdir(foi_dir);
    for cluster_idx=1:length(clusters)
        cluster=clusters(cluster_idx);

        fname='';
        if length(params.output_dir)
            fname=fullfile(foi_dir, sprintf('%s.no_headturn.png', cluster.name));
        end
        plot_cluster_erd(conditions, time_zero_event,...
            baseline_time_zero_event, foi, woi, baseline_woi, min_trials_per_cond,...
            cluster, 'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
            'outlier_method', params.outlier_method, 'filename', fname);
    end
    close all;
    
    foi_dir=fullfile(params.output_dir, sprintf('%d-%dms', woi(1), woi(2)), sprintf('%d-%dHz', foi(1), foi(2)));
    mkdir(foi_dir);
    for cluster_idx=1:length(clusters)
        cluster=clusters(cluster_idx);

        fname='';
        if length(params.output_dir)
            fname=fullfile(foi_dir, sprintf('%s.no_headturn.png', cluster.name));
        end
        plot_cluster_erd(conditions, time_zero_event,...
            baseline_time_zero_event, foi, woi, baseline_woi, min_trials_per_cond,...
            cluster, 'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
            'outlier_method', params.outlier_method, 'filename', fname);
    end
    close all;    
end
