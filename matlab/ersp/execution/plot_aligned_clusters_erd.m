function plot_aligned_clusters_erd(fois, wois, baseline_woi, min_trials,...
    clusters, varargin)

% Parse inputs
defaults=struct('outlier_method', '', 'baseline_type', 'condition', 'filename', '', 'fileformat', 'png');
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
    [included_subjects, excluded_subjects]=exclude_subjects(age, min_trials);
    
    for cluster_idx=1:length(clusters)
        cluster=clusters(cluster_idx);
        % Load all subjects ERSPs
        [all_subjects_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
            [-1000 1000], baseline_woi, 'channels', cluster.channels,...
            'baseline_type', params.baseline_type,...
            'scale','abs');

        for w=1:size(wois,1)
            woi=wois(w,:);
            woi_idx=intersect(find(alltimes>=woi(1)), find(alltimes<=woi(2)));
            woi_subj_ersps={};
            for subj_idx=1:length(included_subjects)
                subj_ersp=all_subjects_ersp{subj_idx};
                woi_subj_ersps{subj_idx}=subj_ersp(:,:,woi_idx,:);
            end

            [erds, subjs]=compute_condition_erds(included_subjects, ...
                woi_subj_ersps, allfreqs, fois(age_idx,:), min_trials,...
                'outlier_method', params.outlier_method);
            disp(cluster.name);
            for idx=1:length(erds)
                disp(sprintf('%d-%dms, subj %d, age=%s, erd=%.4f', woi(1), woi(2), subjs(idx), age, erds(idx)));
            end
            all_erds{age_idx}{w}{cluster_idx}=erds;
            all_included_subjects{age_idx}{w}{cluster_idx}=subjs;
        end
    end
end

fig=figure();
nrows=round(sqrt(size(wois,1)));
ncols=round(size(wois,1)/nrows);
for w=1:size(wois,1)
    
    subplot(nrows,ncols,w);
    woi=wois(w,:);
    
    sixm_cluster_mean_erd=[];
    sixm_cluster_stderr_erd=[];
    ninem_cluster_mean_erd=[];
    ninem_cluster_stderr_erd=[];
    
    for cluster_idx=1:length(clusters)
        sixm_erds=all_erds{1}{w}{cluster_idx};
        ninem_erds=all_erds{2}{w}{cluster_idx};
    
        sixm_cluster_mean_erd(cluster_idx)=mean(sixm_erds);
        sixm_cluster_stderr_erd(cluster_idx)=std(sixm_erds)./sqrt(length(sixm_erds));
        ninem_cluster_mean_erd(cluster_idx)=mean(ninem_erds);
        ninem_cluster_stderr_erd(cluster_idx)=std(ninem_erds)./sqrt(length(ninem_erds));
    end
    
    sixm_cluster_base=[];
    ninem_cluster_base=[];
    cluster_labels={};
    for cluster_idx=1:length(clusters)
        [h,p,ci,stats] = ttest(all_erds{1}{w}{cluster_idx});
        sixm_cluster_base(cluster_idx)=p<0.05;

        [h,p,ci,stats] = ttest(all_erds{2}{w}{cluster_idx});
        ninem_cluster_base(cluster_idx)=p<0.05;
        cluster_labels{cluster_idx}=clusters(cluster_idx).name;
    end
    
    [hBar hErrorbar]=barwitherr([sixm_cluster_stderr_erd' ninem_cluster_stderr_erd'],...
        [sixm_cluster_mean_erd' ninem_cluster_mean_erd']);
    hold all;
    children=get(hBar,'Children');
    set(children{1},'FaceColor',[103 169 207]./255);
    set(children{2},'FaceColor',[239 138 98]./255);
    h=[children{1} children{2}];
    bar_children=get(hErrorbar,'Children');
    group1_children=bar_children{1};
    group2_children=bar_children{2};
    for cluster_idx=1:length(clusters)
        sixm_erds=all_erds{1}{w}{cluster_idx};
        ninem_erds=all_erds{2}{w}{cluster_idx};
        
        x=get(children{1},'x');
        for subj_idx=1:length(sixm_erds)
            rand_x=x(1,cluster_idx)+.1+rand()*(x(3,cluster_idx)-x(1,cluster_idx)-.2);
            plot(rand_x,sixm_erds(subj_idx),'.k');
        end
        if sixm_cluster_base(cluster_idx)        
            center=x(1,cluster_idx)+.5*(x(3,cluster_idx)-x(1,cluster_idx));
            y=get(group1_children(2),'y');
            bottom=y((cluster_idx-1)*9+2)-1;
            text(center,bottom,'*','HorizontalAlignment','Center','BackGroundColor','none','FontSize',24,'Color','red');
        end
        x=get(children{2},'x');
        for subj_idx=1:length(ninem_erds)
            rand_x=x(1,cluster_idx)+.1+rand()*(x(3,cluster_idx)-x(1,cluster_idx)-.2);
            plot(rand_x,ninem_erds(subj_idx),'.k');
        end
        if ninem_cluster_base(cluster_idx)
            center=x(1,cluster_idx)+.5*(x(3,cluster_idx)-x(1,cluster_idx));
            y=get(group2_children(2),'y');
            bottom=y((cluster_idx-1)*9+2)-1;
            text(center,bottom,'*','HorizontalAlignment','Center','BackGroundColor','none','FontSize',24,'Color','red');
        end
    end
    set(gca, 'XTickLabel', cluster_labels);
    legend(h, {'6m', '9m'});
    ylabel('\Delta Power (%)');
    title(sprintf('%d-%dms', woi(1), woi(2)));
end

% if length(params.filename)
%     saveas(fig, params.filename, params.fileformat);
% end

