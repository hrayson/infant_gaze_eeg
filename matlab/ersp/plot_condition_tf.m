function plot_condition_tf(age, conditions, woi, baseline_woi, min_trials_per_cond,...
    cluster, align_event, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue', 'baseline_type', 'condition',...
    'outlier_method', '', 'clims',[],'scale','log',...
    'base_dir','/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/ersp/tf');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[included_subjects, excluded_subjects]=exclude_subjects(age, conditions,...
    'whole', min_trials_per_cond, 'trial_type', params.trial_type);
            
% Load all subjects ERSPs
[subjects_ersp,alltimes,allfreqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', [0 5500], 'whole', baseline_woi, 'channels', cluster.channels,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
    'scale',params.scale);
% Load all subjects trial events
subjects_events=load_whole_trial_events(included_subjects, age, conditions,...
    'trial_type', params.trial_type);

% Idx of align events in each trial, for each condition
trials_evt_idx={};
trials_ersp={};
% Number of trials per subject for each condition
subj_trials_per_condition=zeros(length(conditions),length(included_subjects));

dt=14;

for cond_idx=1:length(conditions)

    % Matrix of ERSP for this condition - all trials
    cond_ersp=[];
    % For aligned event type - list of time step indices for each trial
    cond_evt_idx=[];
    start_idx=0;

    for subj_idx=1:length(included_subjects)

        % Get ERSP and log ERSP for this subject for this condition
        subj_cond_ersp=subjects_ersp{subj_idx}{cond_idx};

        % Number of trials
        ntrials=size(subj_cond_ersp,4);
        subj_trials_per_condition(cond_idx,subj_idx)=ntrials;

        % Average over electrodes, frequencies
        cond_ersp(:,:,:,start_idx+1:start_idx+ntrials)=subj_cond_ersp;
        start_idx=start_idx+ntrials;

        % Go through events to find trial limits
        cond_events=subjects_events{subj_idx,cond_idx};

        % For each event type - update list of event type time indices for
        % each trial
        % Go through all trial events for this subject in this condition
        for t_idx=1:length(cond_events)
            trial_events=cond_events(t_idx);
            evt_ms=-1;
            % Go through each event in this trial
            for evt_idx=1:length(trial_events.eventtype)
                if strcmp(trial_events.eventtype{evt_idx},align_event)
                    evt_ms=trial_events.eventlatency{evt_idx};
                    break
                end
            end
            time_idx=min(find(alltimes>=evt_ms));
            cond_evt_idx(end+1)=time_idx;
        end
    end

    % Update log ERSP, trial limits, and event indices for this condition
    trials_ersp{cond_idx}=cond_ersp;
    trials_evt_idx{cond_idx}=cond_evt_idx;        
end

% Realign
cond_max_align_evts=zeros(1,length(conditions));
cond_min_align_evts=zeros(1,length(conditions));
cond_min_aligned_trial_times=zeros(1,length(conditions));
cond_aligned_trial_times={};
for cond_idx=1:length(conditions)
    align_evts=trials_evt_idx{cond_idx};
    cond_max_align_evts(cond_idx)=max(align_evts);
    cond_min_align_evts(cond_idx)=min(align_evts);    
    trial_times=repmat([1:length(alltimes)]',1,size(trials_ersp{cond_idx},4));
    aligned_trial_times=trial_times-repmat(align_evts,length(alltimes),1);        
    cond_min_aligned_trial_times(cond_idx)=min(aligned_trial_times(1,:));    
    cond_aligned_trial_times{cond_idx}=aligned_trial_times;
end
new_num_times=max(cond_max_align_evts)+length(alltimes)-min(cond_min_align_evts);    
min_time_idx=min(cond_min_aligned_trial_times);
aligned_times=([min_time_idx+1:(new_num_times-abs(min_time_idx))]-1).*dt;

woi_idx=intersect(find(aligned_times>=woi(1)), find(aligned_times<=woi(2)));
aligned_subj_erds={};
aligned_subj_ersps={};
for cond_idx=1:length(conditions)
    cond_ersp=trials_ersp{cond_idx};
    cond_aligned_ersp=zeros(length(cluster.channels),length(allfreqs),new_num_times,size(cond_ersp,4));

    aligned_trial_times=cond_aligned_trial_times{cond_idx};

    for trial_idx=1:size(cond_ersp,4)
        skip_rows=aligned_trial_times(1,trial_idx)-min_time_idx;
        cond_aligned_ersp(:,:,skip_rows+1:skip_rows+length(alltimes),trial_idx)=cond_ersp(:,:,:,trial_idx);                
    end

    start_trial_idx=0;
    for subj_idx=1:length(included_subjects)
        ntrials=subj_trials_per_condition(cond_idx,subj_idx);
        aligned_subj_erds{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,woi_idx,start_trial_idx+1:start_trial_idx+ntrials);
        aligned_subj_ersps{subj_idx}{cond_idx}=cond_aligned_ersp(:,:,:,start_trial_idx+1:start_trial_idx+ntrials);
        start_trial_idx=start_trial_idx+ntrials;
    end
end

[baseline_ersp,baseline_times,baseline_freqs]=load_bc_ersps(included_subjects, age, ...
    conditions, 'whole', [baseline_woi(1)-100 baseline_woi(2)+100], 'whole', baseline_woi, 'channels', cluster.channels,...
    'trial_type', params.trial_type, 'baseline_type', params.baseline_type,...
    'scale',params.scale);

h = fspecial('gaussian',20,4);

%subj_baseline_ersps=zeros(length(included_subjects),length(conditions),length(baseline_freqs),length(baseline_times));
%subj_ersps=zeros(length(included_subjects),length(conditions),length(allfreqs),new_num_times);

% cond_baseline_tf={};
% cond_baseline_subj_ids={};
% cond_tf={};
% cond_subj_ids={};
% 
% for cond_idx=1:length(conditions)
%     subj_baseline_tf=[];
%     subj_baseline_ids=[];
%     subj_baseline_trial_idx=1;
% 
%     subj_tf=[];
%     subj_ids=[];
%     subj_trial_idx=1;
% 
%     for subj_idx=1:length(included_subjects)
%     
%         tmp=aligned_subj_ersps{subj_idx}{cond_idx};        
%         subj_cond_erds=squeeze(mean(mean(mean(tmp(:,:,:,:),1),2),3));
%         cond_median=median(subj_cond_erds);
%         r=iqr(subj_cond_erds);
%         good_trial_idx=find((subj_cond_erds-cond_median)<=1.5*r);
%         %subj_ersps(subj_idx,cond_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4)),h,'same');
%         for t=1:length(good_trial_idx)
%             subj_tf(subj_trial_idx,:,:)=conv2(squeeze(mean(tmp(:,:,:,good_trial_idx(t)),1)),h,'same');
%             subj_ids(subj_trial_idx)=subj_idx;
%             subj_trial_idx=subj_trial_idx+1;
%         end
%         
%         tmp=baseline_ersp{subj_idx}{cond_idx};
%         subj_cond_erds=squeeze(mean(mean(mean(tmp(:,:,:,:),1),2),3));
%         cond_median=median(subj_cond_erds);
%         r=iqr(subj_cond_erds);
%         good_trial_idx=find((subj_cond_erds-cond_median)<=1.5*r);
%         %subj_baseline_ersps(subj_idx,cond_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4)),h,'same');
%         for t=1:length(good_trial_idx)
%             subj_baseline_tf(subj_baseline_trial_idx,:,:)=conv2(squeeze(mean(tmp(:,:,:,good_trial_idx(t)),1)),h,'same');
%             subj_baseline_ids(subj_baseline_trial_idx)=subj_idx;
%             subj_baseline_trial_idx=subj_baseline_trial_idx+1;
%         end
%     end
%     cond_baseline_tf{cond_idx}=subj_baseline_tf;
%     cond_baseline_subj_ids{cond_idx}=subj_baseline_ids;
%     cond_tf{cond_idx}=subj_tf;
%     cond_subj_ids{cond_idx}=subj_ids;
% end
% 
% rmpath('/home/jbonaiuto/Apps/spm12/external/fieldtrip/external/stats');
% cond_baseline_pvals=zeros(length(conditions),size(cond_baseline_tf{1},2),size(cond_baseline_tf{1},3));
% cond_baseline_tstats=zeros(length(conditions),size(cond_baseline_tf{1},2),size(cond_baseline_tf{1},3));
% cond_pvals=zeros(length(conditions),size(cond_tf{1},2),size(cond_tf{1},3));
% cond_tstats=zeros(length(conditions),size(cond_tf{1},2),size(cond_tf{1},3));
% 
% mean_condition_baseline_tf=zeros(length(conditions),size(cond_baseline_tf{1},2),size(cond_baseline_tf{1},3));
% mean_condition_tf=zeros(length(conditions),size(cond_tf{1},2),size(cond_tf{1},3));
% 
% for cond_idx=1:length(conditions)
%     subj_baseline_tf=cond_baseline_tf{cond_idx};
%     subj_baseline_ids=cond_baseline_subj_ids{cond_idx};
%     for f_idx=1:size(subj_baseline_tf,2)
%         for t_idx=1:size(subj_baseline_tf,3)
%             tbl=table(squeeze(subj_baseline_tf(:,f_idx,t_idx)),subj_baseline_ids','VariableName',{'Power','Subject'});
%             lme=fitlme(tbl,'Power~1+(1|Subject)');
%             [beta,betnames,stats]=fixedEffects(lme);
%             cond_baseline_pvals(cond_idx,f_idx,t_idx)=stats.pValue;
%             cond_baseline_tstats(cond_idx,f_idx,t_idx)=stats.tStat;
%         end
%     end
%     % Bonferroni correction
%     cond_baseline_pvals(cond_idx,f_idx,t_idx)=cond_baseline_pvals(cond_idx,f_idx,t_idx).*size(cond_baseline_pvals,2).*size(cond_baseline_pvals,3);
%
%     mean_condition_baseline_tf(cond_idx,:,:)=squeeze(mean(subj_baseline_tf));    
%     
%     subj_tf=cond_tf{cond_idx};
%     subj_ids=cond_subj_ids{cond_idx};
%     for f_idx=1:size(subj_tf,2)
%         for t_idx=1:size(subj_tf,3)
%             tbl=table(squeeze(subj_tf(:,f_idx,t_idx)),subj_ids','VariableName',{'Power','Subject'});
%             lme=fitlme(tbl,'Power~1+(1|Subject)');
%             [beta,betnames,stats]=fixedEffects(lme);
%             cond_pvals(cond_idx,f_idx,t_idx)=stats.pValue;
%             cond_tstats(cond_idx,f_idx,t_idx)=stats.tStat;
%         end
%     end
%     % Bonferroni correction
%     cond_pvals(cond_idx,f_idx,t_idx)=cond_pvals(cond_idx,f_idx,t_idx).*size(cond_pvals,2).*size(cond_pvals,3);
%     mean_condition_tf(cond_idx,:,:)=squeeze(mean(subj_tf));
% end
% 
% %mean_condition_baseline_ersps=squeeze(mean(subj_baseline_ersps(:,:,:,:)));
% %mean_condition_ersps=squeeze(mean(subj_ersps(:,:,:,:)));
% 
% if length(params.clims)==0
%     %max_abs_val=max([abs(mean_condition_baseline_ersps(:)); abs(mean_condition_ersps(:))]);
%     %params.clims=[-max_abs_val max_abs_val];
% 
%     max_val=max([mean_condition_baseline_tf(:); mean_condition_tf(:)]);
%     min_val=min([mean_condition_baseline_tf(:); mean_condition_tf(:)]);
%     params.clims=[min_val max_val];
% end
% 
% figure();
% for cond_idx=1:length(conditions)
%     subplot(3,6,(cond_idx-1)*6+1);
%     imagesc(baseline_times,baseline_freqs,squeeze(mean_condition_baseline_tf(cond_idx,:,:)),params.clims);
%     xlim(baseline_woi);
%     ylim([3 20]);
%     ylabel('Frequency (Hz');
%     set(gca,'ydir','normal');
%     subplot(3,6,[(cond_idx-1)*6+2:(cond_idx-1)*6+6]);
%     imagesc(aligned_times,allfreqs,squeeze(mean_condition_tf(cond_idx,:,:)),params.clims);
%     xlim([-100 3000]);
%     ylim([3 20]);
%     set(gca,'ydir','normal');
%     colorbar();
%     title(sprintf('%s: %s - %s', age, cluster.name, conditions{cond_idx}));    
% end
% xlabel('Time (ms)');
% 
% % Bonferroni correction
% cond_baseline_pvals=cond_baseline_pvals.*size(cond_baseline_pvals,2).*size(cond_baseline_pvals,3);
% cond_pvals=cond_pvals.*size(cond_pvals,2).*size(cond_pvals,3);
% 
% % Plot p-val mask
% baseline_alpha_data=zeros(size(cond_baseline_pvals));
% baseline_alpha_data(find(cond_baseline_pvals(:)<0.05))=1;
% alpha_data=zeros(size(cond_pvals));
% alpha_data(find(cond_pvals(:)<0.05))=1;
% 
% figure();
% for cond_idx=1:length(conditions)
%     subplot(3,6,(cond_idx-1)*6+1);
%     imagesc(baseline_times,baseline_freqs,squeeze(cond_baseline_pvals(cond_idx,:,:)));
%     xlim(baseline_woi);
%     ylim([3 20]);
%     ylabel('Frequency (Hz');
%     set(gca,'ydir','normal');
%     subplot(3,6,[(cond_idx-1)*6+2:(cond_idx-1)*6+6]);
%     imagesc(aligned_times,allfreqs,squeeze(cond_pvals(cond_idx,:,:)));
%     xlim([-100 3000]);
%     ylim([3 20]);
%     set(gca,'ydir','normal');
%     colorbar();
%     title(sprintf('%s: %s - %s', age, cluster.name, conditions{cond_idx}));    
% end
% xlabel('Time (ms)');






%%% Not mixed models
cond_baseline_tf=[];
cond_tf=[];

for cond_idx=1:length(conditions)
    for subj_idx=1:length(included_subjects)
    
        tmp=aligned_subj_ersps{subj_idx}{cond_idx};        
        subj_cond_erds=squeeze(mean(mean(mean(tmp(:,:,:,:),1),2),3));
        cond_median=median(subj_cond_erds);
        r=iqr(subj_cond_erds);
        good_trial_idx=find((subj_cond_erds-cond_median)<=1.5*r);
        cond_tf(cond_idx,subj_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4)),h,'same');
        %cond_tf(cond_idx,subj_idx,:,:)=squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4));
        %cond_tf(cond_idx,subj_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,:),1),4)),h,'same');                
        
        tmp=baseline_ersp{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(tmp(:,:,:,:),1),2),3));
        cond_median=median(subj_cond_erds);
        r=iqr(subj_cond_erds);
        good_trial_idx=find((subj_cond_erds-cond_median)<=1.5*r);
        cond_baseline_tf(cond_idx,subj_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4)),h,'same');        
        %cond_baseline_tf(cond_idx,subj_idx,:,:)=squeeze(mean(mean(tmp(:,:,:,good_trial_idx),1),4));        
        %cond_baseline_tf(cond_idx,subj_idx,:,:)=conv2(squeeze(mean(mean(tmp(:,:,:,:),1),4)),h,'same');                
    end
end

cond_baseline_pvals=zeros(length(conditions),size(cond_baseline_tf,3),size(cond_baseline_tf,4));
cond_baseline_tstats=zeros(length(conditions),size(cond_baseline_tf,3),size(cond_baseline_tf,4));
cond_pvals=zeros(length(conditions),size(cond_tf,3),size(cond_tf,4));
cond_tstats=zeros(length(conditions),size(cond_tf,3),size(cond_tf,4));

mean_condition_baseline_tf=squeeze(mean(cond_baseline_tf,2));
mean_condition_tf=squeeze(mean(cond_tf,2));

for cond_idx=1:length(conditions)
    subj_baseline_tf=squeeze(cond_baseline_tf(cond_idx,:,:,:));
    for f_idx=1:size(subj_baseline_tf,2)
        for t_idx=1:size(subj_baseline_tf,3)
            [H,P,CI,STATS] = ttest(squeeze(subj_baseline_tf(:,f_idx,t_idx)));
            % Bonferroni correction
            cond_baseline_pvals(cond_idx,f_idx,t_idx)=P.*size(cond_baseline_pvals,2).*size(cond_baseline_pvals,3);
            cond_baseline_tstats(cond_idx,f_idx,t_idx)=STATS.tstat;
        end
    end
    
    subj_tf=squeeze(cond_tf(cond_idx,:,:,:));
    for f_idx=1:size(subj_tf,2)
        for t_idx=1:size(subj_tf,3)
            [H,P,CI,STATS] = ttest(squeeze(subj_tf(:,f_idx,t_idx)));
            % Bonferroni correction
            %cond_pvals(cond_idx,f_idx,t_idx)=P.*size(cond_pvals,2).*size(cond_pvals,3);
            cond_pvals(cond_idx,f_idx,t_idx)=P;
            cond_tstats(cond_idx,f_idx,t_idx)=STATS.tstat;
        end
    end
end

%baseline_freq_idx=intersect(find(baseline_freqs>=3),find(baseline_freqs<=20));
%baseline_freq_idx=intersect(find(baseline_freqs>=3),find(baseline_freqs<=30));
%baseline_freq_idx=intersect(find(baseline_freqs>=1),find(baseline_freqs<=15));
baseline_freq_idx=intersect(find(baseline_freqs>=1),find(baseline_freqs<=12));
mean_condition_baseline_tf=mean_condition_baseline_tf(:,baseline_freq_idx,:);
cond_baseline_pvals=cond_baseline_pvals(:,baseline_freq_idx,:);
cond_baseline_tstats=cond_baseline_tstats(:,baseline_freq_idx,:);

%freq_idx=intersect(find(allfreqs>=3),find(allfreqs<=20));
%freq_idx=intersect(find(allfreqs>=3),find(allfreqs<=15));
%freq_idx=intersect(find(allfreqs>=1),find(allfreqs<=15));
freq_idx=intersect(find(allfreqs>=1),find(allfreqs<=12));
time_idx=intersect(find(aligned_times>=-100),find(aligned_times<=3000));
mean_condition_tf=mean_condition_tf(:,freq_idx,time_idx);
cond_pvals=cond_pvals(:,freq_idx,time_idx);
cond_tstats=cond_tstats(:,freq_idx,time_idx);

%mean_condition_baseline_ersps=squeeze(mean(subj_baseline_ersps(:,:,:,:)));
%mean_condition_ersps=squeeze(mean(subj_ersps(:,:,:,:)));

if length(params.clims)==0
    max_abs_val=max([abs(mean_condition_baseline_tf(:)); abs(mean_condition_tf(:))]);
    params.clims=[-max_abs_val max_abs_val];

    %max_val=max([mean_condition_baseline_tf(:); mean_condition_tf(:)]);
    %min_val=min([mean_condition_baseline_tf(:); mean_condition_tf(:)]);
    %params.clims=[min_val max_val];
end

fig=figure();
for cond_idx=1:length(conditions)
    subplot(3,6,(cond_idx-1)*6+1);
    %imagesc(baseline_times,baseline_freqs(baseline_freq_idx),...
    %    squeeze(mean_condition_baseline_tf(cond_idx,:,:)),params.clims);
    pcolor(baseline_times,baseline_freqs(baseline_freq_idx),...
        squeeze(mean_condition_baseline_tf(cond_idx,:,:)));
    shading interp;
    set(gca,'clim',params.clims);
    xlim(baseline_woi);
    ylabel('Frequency (Hz');
    set(gca,'ydir','normal');
    subplot(3,6,[(cond_idx-1)*6+2:(cond_idx-1)*6+6]);
    %imagesc(aligned_times(time_idx),allfreqs(freq_idx),...
    %    squeeze(mean_condition_tf(cond_idx,:,:)),params.clims);
    pcolor(aligned_times(time_idx),allfreqs(freq_idx),...
        squeeze(mean_condition_tf(cond_idx,:,:)));
    shading interp;
    set(gca,'clim',params.clims);
    set(gca,'ydir','normal');
    colorbar();
    title(sprintf('%s: %s - %s', age, cluster.name, conditions{cond_idx}));    
end
xlabel('Time (ms)');
saveas(fig, fullfile(params.base_dir, sprintf('%s_%s.png', age,cluster.name)), 'png');

fig=figure();
for cond_idx=1:length(conditions)
    subplot(3,6,(cond_idx-1)*6+1);
    imagesc(baseline_times,baseline_freqs(baseline_freq_idx),...
        squeeze(mean_condition_baseline_tf(cond_idx,:,:)),params.clims);
    xlim(baseline_woi);
    ylabel('Frequency (Hz');
    set(gca,'ydir','normal');
    subplot(3,6,[(cond_idx-1)*6+2:(cond_idx-1)*6+6]);
    imagesc(aligned_times(time_idx),allfreqs(freq_idx),...
        squeeze(mean_condition_tf(cond_idx,:,:)),params.clims);
    set(gca,'ydir','normal');
    colorbar();
    title(sprintf('%s: %s - %s', age, cluster.name, conditions{cond_idx}));    
end
xlabel('Time (ms)');
saveas(fig, fullfile(params.base_dir, sprintf('%s_%s.eps', age,cluster.name)), 'epsc');



% Plot p-val mask
baseline_alpha_data=zeros(size(cond_baseline_pvals));
baseline_alpha_data(find(cond_baseline_pvals(:)<0.05))=1;
alpha_data=zeros(size(cond_pvals));
alpha_data(find(fdr0(cond_pvals(:),0.05)==1))=1;
%alpha_data(find(cond_pvals(:)<0.05))=1;

fig=figure();
for cond_idx=1:length(conditions)
    subplot(3,6,(cond_idx-1)*6+1);
    imagesc(baseline_times,baseline_freqs(baseline_freq_idx),...
        squeeze(baseline_alpha_data(cond_idx,:,:)),[0 1]);
    xlim(baseline_woi);
    ylabel('Frequency (Hz');
    set(gca,'ydir','normal');
    subplot(3,6,[(cond_idx-1)*6+2:(cond_idx-1)*6+6]);
    imagesc(aligned_times(time_idx),allfreqs(freq_idx),...
        squeeze(alpha_data(cond_idx,:,:)),[0 1]);
    set(gca,'ydir','normal');
    colorbar();
    title(sprintf('%s: %s - %s', age, cluster.name, conditions{cond_idx}));    
end
xlabel('Time (ms)');
saveas(fig, fullfile(params.base_dir, sprintf('%s_%s_mask.png', age,cluster.name)), 'png');
saveas(fig, fullfile(params.base_dir, sprintf('%s_%s_mask.eps', age,cluster.name)), 'epsc');


