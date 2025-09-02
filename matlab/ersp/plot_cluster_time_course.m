% Example:
% plot_cluster_time_course({'unshuffled_congruent','unshuffled_incongruent','shuffled'},...
%     'mov1','static',foi,[0 2000],[0 400],5,cluster,'no_headturn',true,'filename',fname);
function plot_cluster_time_course(conditions, time_zero_event,...
    baseline_time_zero_event, sixm_foi, ninem_foi, woi, baseline_woi, min_trials_per_cond,...
    cluster, varargin)

% Parse inputs
defaults=struct('no_headturn', false, 'remove_outliers', false, 'filename', '', 'fileformat', 'png');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

[sixm_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'channels', cluster.channels, 'no_headturn', params.no_headturn,...
    'scale', 'abs');

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

[ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'channels', cluster.channels, 'no_headturn', params.no_headturn,...
    'scale', 'abs');

freq_idx=intersect(find(allfreqs>=sixm_foi(1)), find(allfreqs<=sixm_foi(2)));

sixm_cond_ersp=zeros(length(conditions),length(alltimes),length(sixm_included_subjects));
subj_min_trials_per_condition=zeros(1,length(sixm_included_subjects));
for subj_idx=1:length(sixm_included_subjects)
    subj_trials_per_condition=zeros(1,length(conditions));
    for cond_idx=1:length(conditions)
        subj_cond_ersp=sixm_ersp{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2),3));
        trials_to_include=[1:length(subj_cond_erds)];
        if params.remove_outliers
            cond_median=median(subj_cond_erds);
            r=iqr(subj_cond_erds);
            trials_to_include=find((subj_cond_erds-cond_median)<=1.5*r);
        end
        subj_trials_per_condition(cond_idx)=length(trials_to_include);
        sixm_cond_ersp(cond_idx,:,subj_idx)=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,trials_to_include),1),2),4));
    end
    subj_min_trials_per_condition(subj_idx)=min(subj_trials_per_condition);
end
final_included_subj_idx=find(subj_min_trials_per_condition>=min_trials_per_cond);
sixm_cond_ersp=sixm_cond_ersp(:,:,final_included_subj_idx);
sixm_cond_mean_ersp=squeeze(mean(sixm_cond_ersp,3));
sixm_cond_stderr_ersp=squeeze(std(sixm_cond_ersp,[],3))./sqrt(length(sixm_included_subjects));


freq_idx=intersect(find(allfreqs>=ninem_foi(1)), find(allfreqs<=ninem_foi(2)));

ninem_cond_ersp=zeros(length(conditions),length(alltimes),length(ninem_included_subjects));
subj_min_trials_per_condition=zeros(1,length(ninem_included_subjects));
for subj_idx=1:length(ninem_included_subjects)
    subj_trials_per_condition=zeros(1,length(conditions));
    for cond_idx=1:length(conditions)
        subj_cond_ersp=ninem_ersp{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2),3));
        trials_to_include=[1:length(subj_cond_erds)];
        if params.remove_outliers
            cond_median=median(subj_cond_erds);
            r=iqr(subj_cond_erds);
            trials_to_include=find((subj_cond_erds-cond_median)<=1.5*r);
        end
        subj_trials_per_condition(cond_idx)=length(trials_to_include);
        ninem_cond_ersp(cond_idx,:,subj_idx)=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,trials_to_include),1),2),4));
    end
    subj_min_trials_per_condition(subj_idx)=min(subj_trials_per_condition);
end
final_included_subj_idx=find(subj_min_trials_per_condition>=min_trials_per_cond);
ninem_cond_ersp=ninem_cond_ersp(:,:,final_included_subj_idx);
ninem_cond_mean_ersp=squeeze(mean(ninem_cond_ersp,3));
ninem_cond_stderr_ersp=squeeze(std(ninem_cond_ersp,[],3))./sqrt(length(ninem_cond_ersp));

sixm_cond_tc={};
ninem_cond_tc={};
for cond_idx=1:length(conditions)
    sixm_cond_tc{cond_idx}=squeeze(sixm_cond_ersp(cond_idx,:,:));   
    ninem_cond_tc{cond_idx}=squeeze(ninem_cond_ersp(cond_idx,:,:));   
end
[sixm_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(sixm_cond_tc',...
    'condstats', 'on', 'paired', {'on', 'on'});
[ninem_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(ninem_cond_tc',...
    'condstats', 'on', 'paired', {'on', 'on'});

dt=alltimes(2)-alltimes(1);

colors={'g','r','b'};
fig=figure('Position',[1 1 1000 800], 'PaperUnits','points','PaperPosition',[1 1 600 400],'PaperPositionMode','manual');
subplot(2,1,1);
hold all;
legend_labels={};
for cond_idx=1:length(conditions)
    %H=shadedErrorBar(alltimes,sixm_cond_mean_ersp(cond_idx,:),sixm_cond_stderr_ersp(cond_idx,:),colors{cond_idx});
    % Turn legendinformation off for all but the main lines
    %set(get(get(H.patch,'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.edge(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.edge(2),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.mainLine,'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
    plot(alltimes,sixm_cond_mean_ersp(cond_idx,:),colors{cond_idx});
    legend_labels{end+1}=strrep(conditions{cond_idx},'_',' ');
end
legend(legend_labels);
yl=ylim();
sig_time_idx=find(sixm_pcond{1}<0.05);
for idx=1:length(sig_time_idx)
    p = patch('vertices', [alltimes(sig_time_idx(idx)), yl(1); alltimes(sig_time_idx(idx)), yl(2); alltimes(sig_time_idx(idx))+dt, yl(2); alltimes(sig_time_idx(idx))+dt yl(1)], ...
          'faces', [1, 2, 3, 4], ...
          'FaceColor', 'y', ...
          'FaceAlpha', 0.5,...
          'EdgeColor','none',...
          'EdgeColor','y',...
          'EdgeAlpha',0.5);
    uistack(p,'bottom');
end
title('6m');
ylabel('\Delta Power (%)');


subplot(2,1,2);
hold all;
legend_labels={};
for cond_idx=1:length(conditions)
    %H=shadedErrorBar(alltimes,ninem_cond_mean_ersp(cond_idx,:),ninem_cond_stderr_ersp(cond_idx,:),colors{cond_idx});
    % Turn legendinformation off for all but the main lines
    %set(get(get(H.patch,'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.edge(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.edge(2),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
    %set(get(get(H.mainLine,'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
    plot(alltimes,ninem_cond_mean_ersp(cond_idx,:),colors{cond_idx});
    legend_labels{end+1}=strrep(conditions{cond_idx},'_',' ');
end
legend(legend_labels);
yl=ylim();
sig_time_idx=find(ninem_pcond{1}<0.05);
for idx=1:length(sig_time_idx)
    p = patch('vertices', [alltimes(sig_time_idx(idx)), yl(1); alltimes(sig_time_idx(idx)), yl(2); alltimes(sig_time_idx(idx))+dt, yl(2); alltimes(sig_time_idx(idx))+dt yl(1)], ...
          'faces', [1, 2, 3, 4], ...
          'FaceColor', 'y', ...
          'FaceAlpha', 0.5,...
          'EdgeColor','y',...
          'EdgeAlpha',0.5);
    uistack(p,'bottom');
end
title('9m');
xlabel('Time (ms)');
ylabel('\Delta Power (%)');

if length(params.filename)
    saveas(fig, params.filename, params.fileformat);
end