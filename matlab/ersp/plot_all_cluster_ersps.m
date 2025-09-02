function plot_all_cluster_ersps(clusters, conditions, time_zero_event,...
    baseline_time_zero_event, woi, baseline_woi, min_trials_per_cond,...
    varargin)

% Parse inputs
defaults=struct('output_dir', '');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

for cluster_idx=1:length(clusters)
    cluster=clusters(cluster_idx);
    fname='';
    if length(params.output_dir)
        fname=fullfile(params.output_dir, sprintf('%s.png', cluster.name));
    end
    plot_cluster_ersp(conditions,time_zero_event,baseline_time_zero_event,...
        woi,baseline_woi,min_trials_per_cond,cluster,'no_headturn',false,'filename',fname);
    fname='';
    if length(params.output_dir)
        fname=fullfile(params.output_dir, sprintf('%s.no_headturn.png', cluster.name));
    end
    plot_cluster_ersp(conditions,time_zero_event,baseline_time_zero_event,...
        woi,baseline_woi,min_trials_per_cond,cluster,'no_headturn',true,'filename',fname);
end
        