function export_aligned_clusters_erd(freq_bands, wois, baseline_woi, min_trials,...
    clusters, filename, varargin)

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
    min_trials);

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    min_trials);

fid=fopen(filename,'w');
fprintf(fid, 'Subject,Age,Region,Hemisphere,WOI,FreqBand,ERD\n');

for cluster_idx=1:length(clusters)
    cluster=clusters(cluster_idx);
    
    for freq_idx=1:length(freq_bands)
        freq_band=freq_bands(freq_idx);
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'6m')
            
            % Load all subjects ERSPs
            [sixm_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
                [-1000 1000], baseline_woi, 'channels', cluster.channels,...
                'baseline_type', params.baseline_type,'scale','abs');
            
            for w=1:size(wois,1)
                woi=wois(w,:);
                woi_idx=intersect(find(alltimes>=woi(1)), find(alltimes<=woi(2)));
                woi_subj_ersps={};
                for subj_idx=1:length(sixm_included_subjects)
                    subj_ersp=sixm_subjects_ersp{subj_idx};
                    woi_subj_ersps{subj_idx}=subj_ersp(:,:,woi_idx,:);
                end

                [erds, subjs]=compute_condition_erds(sixm_included_subjects, ...
                    woi_subj_ersps, allfreqs, freq_band.foi, min_trials,...
                    'outlier_method', params.outlier_method);
                for subj_idx=1:length(subjs)
                    subj_id=subjs(subj_idx);
                    fprintf(fid, '%d,6m,%s,%s,%d-%dms,%s,%.4f\n', subj_id, ...
                        cluster.region, cluster.hemisphere, woi(1), woi(2), freq_band.name, ...
                        erds(subj_idx));
                end
            end           
        end
        
        if strcmp(freq_band.age,'') || strcmp(freq_band.age,'9m')
            % Load all subjects ERSPs
            [ninem_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
                [-1000 1000], baseline_woi, 'channels', cluster.channels,...
                'baseline_type', params.baseline_type, 'scale','abs');
            
            for w=1:size(wois,1)
                woi=wois(w,:);
                woi_idx=intersect(find(alltimes>=woi(1)), find(alltimes<=woi(2)));
                woi_subj_ersps={};
                for subj_idx=1:length(ninem_included_subjects)
                    subj_ersp=ninem_subjects_ersp{subj_idx};
                    woi_subj_ersps{subj_idx}=subj_ersp(:,:,woi_idx,:);
                end

                [erds, subjs]=compute_condition_erds(ninem_included_subjects, ...
                    woi_subj_ersps, allfreqs, freq_band.foi, min_trials,...
                    'outlier_method', params.outlier_method);
                for subj_idx=1:length(subjs)
                    subj_id=subjs(subj_idx);
                    fprintf(fid, '%d,9m,%s,%s,%d-%dms,%s,%.4f\n', subj_id, ...
                        cluster.region, cluster.hemisphere, woi(1), woi(2), freq_band.name, ...
                        erds(subj_idx));
                end
            end            
        end
    end
end
fclose(fid);