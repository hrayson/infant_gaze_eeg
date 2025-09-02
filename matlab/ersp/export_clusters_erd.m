% Example
% export_clusters_erd({'unshuffled_congruent','unshuffled_incongruent','shuffled'},...
%     clusters, 'mov1', 'static', freq_bands, [0 2000],[ 0 400], 5, fname,...
%     'no_headturn',true, 'remove_outliers',true);
function export_clusters_erd(conditions, clusters, time_zero_event,...
    baseline_time_zero_event, freq_bands, woi, baseline_woi, min_trials_per_cond,...
    filename, varargin)

% Parse inputs
defaults=struct('no_headturn', false, 'remove_outliers', false);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

fid=fopen(filename,'w');
fprintf(fid, 'Subject,Age,Region,Hemisphere,FreqBand,Condition,ERD\n');

for cluster_idx=1:length(clusters)
    cluster=clusters(cluster_idx);
    
    for freq_idx=1:length(freq_bands)
        freq_band=freq_bands(freq_idx);
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'6m')
            [sixm_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
                conditions, time_zero_event, woi, baseline_time_zero_event,...
                baseline_woi, 'channels', cluster.channels, 'no_headturn', ...
                params.no_headturn, 'scale', 'abs');
            
            [sixm_cond_all_subj_erd, final_included_subjs]=compute_condition_erds(conditions, ...
                sixm_included_subjects, sixm_ersp, allfreqs, freq_band.foi, min_trials_per_cond, ...
                'remove_outliers', params.remove_outliers);            
            
            for cond_idx=1:length(conditions)
                condition=conditions{cond_idx};
                
                for subj_idx=1:length(final_included_subjs)
                    subj_id=final_included_subjs(subj_idx);
                    fprintf(fid, '%d,6m,%s,%s,%s,%s,%.4f\n', subj_id, ...
                        cluster.region, cluster.hemisphere, freq_band.name, ...
                        condition, sixm_cond_all_subj_erd(cond_idx,subj_idx));
                end
            end
        end
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'9m')
            [ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
                conditions, time_zero_event, woi, baseline_time_zero_event,...
                baseline_woi, 'channels', cluster.channels, 'no_headturn', params.no_headturn, 'scale', 'abs');
            
            [ninem_cond_all_subj_erd, final_included_subjs]=compute_condition_erds(conditions, ...
                ninem_included_subjects, ninem_ersp, allfreqs, freq_band.foi, min_trials_per_cond, ...
                'remove_outliers', params.remove_outliers);            
            
            for cond_idx=1:length(conditions)
                condition=conditions{cond_idx};
                
                for subj_idx=1:length(final_included_subjs)
                    subj_id=final_included_subjs(subj_idx);
                    fprintf(fid, '%d,9m,%s,%s,%s,%s,%.4f\n', subj_id, ...
                        cluster.region, cluster.hemisphere, freq_band.name, ...
                        condition, ninem_cond_all_subj_erd(cond_idx,subj_idx));
                end
            end
        end
    end
end
fclose(fid);