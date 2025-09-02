function [erds, included_subjects, included_subj_idx]=compute_condition_erds(conditions, ...
    subject_ids, subj_cond_ersps, allfreqs, foi, min_trials_per_cond, varargin)

% Parse inputs
defaults=struct('outlier_method', '');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));

erds=zeros(length(conditions),length(subject_ids));
subj_min_trials_per_condition=zeros(1,length(subject_ids));
subj_all_trials_per_condition=zeros(length(subject_ids),length(conditions));
for subj_idx=1:length(subject_ids)
    subj_trials_per_condition=zeros(1,length(conditions));
    for cond_idx=1:length(conditions)
        subj_cond_ersp=subj_cond_ersps{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2),3));
        if strcmp(params.outlier_method,'iqr')
            cond_median=median(subj_cond_erds);
            r=iqr(subj_cond_erds);
            subj_cond_erds=subj_cond_erds(find((subj_cond_erds-cond_median)<=1.5*r));
        elseif strcmp(params.outlier_method,'mdm')
            c=outmdm(subj_cond_erds);
            subj_cond_erds=subj_cond_erds(find(c==0));            
        end
        subj_trials_per_condition(cond_idx)=length(subj_cond_erds);
        subj_all_trials_per_condition(subj_idx,cond_idx)=length(subj_cond_erds);
        erds(cond_idx,subj_idx)=mean(subj_cond_erds);
    end
    subj_min_trials_per_condition(subj_idx)=min(subj_trials_per_condition);
end
included_subj_idx=find(subj_min_trials_per_condition>=min_trials_per_cond);
erds=erds(:,included_subj_idx);
included_subjects=subject_ids(included_subj_idx);