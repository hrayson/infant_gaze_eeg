function plot_all_cluster_time_courses(clusters, fois, conditions, time_zero_event,...
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

for foi_idx=1:size(fois,1)
    foi=fois(foi_idx,:);
    for cluster_idx=1:length(clusters)
        cluster=clusters(cluster_idx);
%         fname='';
%         if length(params.output_dir)
%             fname=fullfile(params.output_dir, sprintf('%d-%dHz', foi(1), foi(2)), sprintf('%s.png', cluster.name));
%         end
%         plot_cluster_time_course(conditions, time_zero_event,...
%             baseline_time_zero_event, foi, woi, baseline_woi, min_trials_per_cond,...
%             cluster, 'no_headturn', false, 'filename', fname);

        fname='';
        if length(params.output_dir)
            fname=fullfile(params.output_dir, sprintf('%d-%dHz', foi(1), foi(2)), sprintf('%s.no_headturn.png', cluster.name));
        end
        plot_cluster_time_course(conditions, time_zero_event,...
            baseline_time_zero_event, foi, woi, baseline_woi, min_trials_per_cond,...
            cluster, 'no_headturn', true, 'filename', fname);
    end
end