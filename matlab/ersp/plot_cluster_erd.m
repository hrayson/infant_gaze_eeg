% Example
% plot_cluster_erd({'unshuffled_congruent','unshuffled_incongruent','shuffled'},...
%     'mov1','static',foi,[0 2000],[0 400],5,cluster,'no_headturn',true,'filename',fname);
function plot_cluster_erd(conditions, time_zero_event,...
    baseline_time_zero_event, foi, woi, baseline_woi, min_trials_per_cond,...
    cluster, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '', 'filename', '', 'fileformat', 'png');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[sixm_included_subjects, sixm_excluded_subjects]=exclude_subjects('6m',...
    conditions, time_zero_event, min_trials_per_cond, 'trial_type', params.trial_type);

[sixm_ersp,alltimes,allfreqs]=load_bc_ersps(sixm_included_subjects, '6m', ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'channels', cluster.channels, 'trial_type', params.trial_type,...
    'baseline_type', params.baseline_type, 'scale', 'abs');

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, time_zero_event, min_trials_per_cond, 'trial_type', params.trial_type);

[ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'channels', cluster.channels, 'trial_type', params.trial_type,...
    'baseline_type', params.baseline_type, 'scale', 'abs');

[sixm_cond_all_subj_erd, final_included_subjs]=compute_condition_erds(conditions, ...
    sixm_included_subjects, sixm_ersp, allfreqs, foi, min_trials_per_cond, ...
    'outlier_method', params.outlier_method);
disp(sprintf('6m: %d subjects initial, %d subjects final', length(sixm_included_subjects), length(final_included_subjs)));
    
[ninem_cond_all_subj_erd, final_included_subjs]=compute_condition_erds(conditions, ...
    ninem_included_subjects, ninem_ersp, allfreqs, foi, min_trials_per_cond, ...
    'outlier_method', params.outlier_method);
disp(sprintf('9m: %d subjects initial, %d subjects final', length(ninem_included_subjects), length(final_included_subjs)));

sixm_cond_mean_erd=squeeze(mean(sixm_cond_all_subj_erd,2));
sixm_cond_stderr_erd=squeeze(std(sixm_cond_all_subj_erd,[],2))./sqrt(length(sixm_included_subjects));
ninem_cond_mean_erd=squeeze(mean(ninem_cond_all_subj_erd,2));
ninem_cond_stderr_erd=squeeze(std(ninem_cond_all_subj_erd,[],2))./sqrt(length(ninem_included_subjects));

sixm_cond_tc={};
ninem_cond_tc={};
sixm_cond_base=[];
ninem_cond_base=[];
condition_labels={};
for cond_idx=1:length(conditions)
    sixm_cond_tc{cond_idx}=sixm_cond_all_subj_erd(cond_idx,:);   
    [h,p,ci,stats] = ttest(sixm_cond_all_subj_erd(cond_idx,:));
    sixm_cond_base(cond_idx)=p<0.05;
    
    ninem_cond_tc{cond_idx}=ninem_cond_all_subj_erd(cond_idx,:);   
    [h,p,ci,stats] = ttest(ninem_cond_all_subj_erd(cond_idx,:));
    ninem_cond_base(cond_idx)=p<0.05;
    condition_labels{cond_idx}=strrep(conditions{cond_idx},'_',' ');
end
[sixm_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(sixm_cond_tc',...
    'condstats', 'on', 'paired', {'on', 'on'});
[ninem_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(ninem_cond_tc',...
    'condstats', 'on', 'paired', {'on', 'on'});

fig=figure();
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
    for subj_idx=1:size(sixm_cond_all_subj_erd,2)
        rand_x=x(1,cond_idx)+.1+rand()*(x(3,cond_idx)-x(1,cond_idx)-.2);
        plot(rand_x,sixm_cond_all_subj_erd(cond_idx,subj_idx),'.k');
    end
    if sixm_cond_base(cond_idx)        
        center=x(1,cond_idx)+.5*(x(3,cond_idx)-x(1,cond_idx));
        y=get(group1_children(2),'y');
        bottom=y((cond_idx-1)*9+2)-1;
        text(center,bottom,'*','HorizontalAlignment','Center','BackGroundColor','none','FontSize',24,'Color','red');
    end
    x=get(children{2},'x');
    for subj_idx=1:size(ninem_cond_all_subj_erd,2)
        rand_x=x(1,cond_idx)+.1+rand()*(x(3,cond_idx)-x(1,cond_idx)-.2);
        plot(rand_x,ninem_cond_all_subj_erd(cond_idx,subj_idx),'.k');
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

if length(params.filename)
    saveas(fig, params.filename, params.fileformat);
end

