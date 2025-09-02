% Example:
% plot_cluster_ersp({'unshuffled_congruent','unshuffled_incongruent','shuffled'},...
%     'mov1','static',[0 2000],[0 400],5,cluster,'no_headturn',true,'filename',fname);
function plot_cluster_ersp(conditions, time_zero_event,...
    baseline_time_zero_event, woi, baseline_woi, min_trials_per_cond,...
    cluster, varargin)

% Parse inputs
defaults=struct('no_headturn', false, 'filename', '', 'fileformat', 'png');
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
    baseline_woi, 'channels', cluster.channels, 'no_headturn', params.no_headturn);

sixm_cond_ersp=zeros(length(conditions),length(allfreqs),length(alltimes),length(sixm_included_subjects));
for subj_idx=1:length(sixm_included_subjects)
    for cond_idx=1:length(conditions)
        subj_cond_ersp=sixm_ersp{subj_idx}{cond_idx};
        sixm_cond_ersp(cond_idx,:,:,subj_idx)=squeeze(mean(mean(subj_cond_ersp(:,:,:,:),1),4));
    end
end

[ninem_included_subjects, ninem_excluded_subjects]=exclude_subjects('9m',...
    conditions, time_zero_event, min_trials_per_cond, 'no_headturn', params.no_headturn);

[ninem_ersp,alltimes,allfreqs]=load_bc_ersps(ninem_included_subjects, '9m', ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, 'channels', cluster.channels, 'no_headturn', params.no_headturn);

ninem_cond_ersp=zeros(length(conditions),length(allfreqs),length(alltimes),length(ninem_included_subjects));
for subj_idx=1:length(ninem_included_subjects)
    for cond_idx=1:length(conditions)
        subj_cond_ersp=ninem_ersp{subj_idx}{cond_idx};
        ninem_cond_ersp(cond_idx,:,:,subj_idx)=squeeze(mean(mean(subj_cond_ersp(:,:,:,:),1),4));
    end
end

sixm_cond_mean_ersp=squeeze(mean(sixm_cond_ersp(:,:,:,:,:),4));
ninem_cond_mean_ersp=squeeze(mean(ninem_cond_ersp(:,:,:,:,:),4));
clim=[min([sixm_cond_mean_ersp(:); ninem_cond_mean_ersp(:)]) max([sixm_cond_mean_ersp(:); ninem_cond_mean_ersp(:)])];
sixm_cond_stat_ersp={};
ninem_cond_stat_ersp={};
for cond_idx=1:length(conditions)
    sixm_cond_stat_ersp{cond_idx}=squeeze(sixm_cond_ersp(cond_idx,:,:,:,:));   
    ninem_cond_stat_ersp{cond_idx}=squeeze(ninem_cond_ersp(cond_idx,:,:,:,:));   
end
[sixm_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(sixm_cond_stat_ersp',...
    'condstats', 'on', 'paired', {'on', 'on'});
[ninem_pcond, pgroup, pinter, statscond, statsgroup, statsinter] = std_stat(ninem_cond_stat_ersp',...
    'condstats', 'on', 'paired', {'on', 'on'});

fig=figure('Position',[1 1 1800 800], 'PaperUnits','points','PaperPosition',[1 1 900 400],'PaperPositionMode','manual');
for cond_idx=1:length(conditions)
    ax=subplot(length(conditions)+1,2,cond_idx*2-1);
    imagesc(alltimes,allfreqs,squeeze(sixm_cond_mean_ersp(cond_idx,:,:)),clim);
    set(gca,'ydir','normal');
    hold on;
    plot([0 0], [allfreqs(1) allfreqs(end)], 'w--');
    h=colorbar();
    cbfreeze(h);
    ylabel('Frequency (Hz)');
    title(sprintf('6m - %s', strrep(conditions{cond_idx},'_',' ')));
    freezeColors(ax);
    
    ax=subplot(length(conditions)+1,2,cond_idx*2);
    imagesc(alltimes,allfreqs,squeeze(ninem_cond_mean_ersp(cond_idx,:,:)),clim);
    set(gca,'ydir','normal');
    hold on;
    plot([0 0], [allfreqs(1) allfreqs(end)], 'w--');
    h=colorbar();
    cbfreeze(h);
    ylabel('Frequency (Hz)');
    title(sprintf('9m - %s', strrep(conditions{cond_idx},'_',' ')));
    freezeColors(ax);
end
ax=subplot(length(conditions)+1,2,length(conditions)*2+1);
colormap(flipud(colormap('hot')));
imagesc(alltimes,allfreqs,sixm_pcond{1},[0 0.05]);
set(gca,'ydir','normal');
hold on;
plot([0 0], [allfreqs(1) allfreqs(end)], 'w--');
h=colorbar();
cbfreeze(h);
ylabel('Frequency (Hz)');
xlabel('Time (ms)');
freezeColors(ax);

ax=subplot(length(conditions)+1,2,length(conditions)*2+2);
colormap(flipud(colormap('hot')));
imagesc(alltimes,allfreqs,ninem_pcond{1},[0 0.05]);
set(gca,'ydir','normal');
hold on;
plot([0 0], [allfreqs(1) allfreqs(end)], 'w--');
h=colorbar();
cbfreeze(h);
ylabel('Frequency (Hz)');
xlabel('Time (ms)');
freezeColors(ax);

if length(params.filename)
    saveas(fig, params.filename, params.fileformat);
end