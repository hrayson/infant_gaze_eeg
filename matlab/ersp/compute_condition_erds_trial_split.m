function [early_erds, early_included_subjects, early_included_subj_idx, late_erds, late_included_subjects, late_included_subj_idx]=compute_condition_erds_trial_split(conditions, ...
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

early_erds=zeros(length(conditions),length(subject_ids));
late_erds=zeros(length(conditions),length(subject_ids));

early_subj_min_trials_per_condition=zeros(1,length(subject_ids));
early_subj_all_trials_per_condition=zeros(length(subject_ids),length(conditions));

late_subj_min_trials_per_condition=zeros(1,length(subject_ids));
late_subj_all_trials_per_condition=zeros(length(subject_ids),length(conditions));

for subj_idx=1:length(subject_ids)
    subj_trials_per_condition=zeros(1,length(conditions));
    for cond_idx=1:length(conditions)
        subj_cond_ersp=subj_cond_ersps{subj_idx}{cond_idx};
        subj_cond_erds=squeeze(mean(mean(mean(subj_cond_ersp(:,freq_idx,:,:),1),2),3));
        
        n_trials=length(subj_cond_erds);
        subj_cond_early_erds=subj_cond_erds(1:round(n_trials/2));
        subj_cond_late_erds=subj_cond_erds(round(n_trials/2)+1:end);
        
        if strcmp(params.outlier_method,'iqr')
            cond_median=median(subj_cond_erds);
            r=iqr(subj_cond_erds);
            subj_cond_early_erds=subj_cond_early_erds(find((subj_cond_early_erds-cond_median)<=1.5*r));
            subj_cond_late_erds=subj_cond_late_erds(find((subj_cond_late_erds-cond_median)<=1.5*r));
        elseif strcmp(params.outlier_method,'mdm')
            c=outmdm(subj_cond_early_erds);
            subj_cond_early_erds=subj_cond_early_erds(find(c==0));            
            c=outmdm(subj_cond_late_erds);
            subj_cond_late_erds=subj_cond_late_erds(find(c==0));            
        end
        early_subj_trials_per_condition(cond_idx)=length(subj_cond_early_erds);
        early_subj_all_trials_per_condition(subj_idx,cond_idx)=length(subj_cond_early_erds);
        
        late_subj_trials_per_condition(cond_idx)=length(subj_cond_late_erds);
        late_subj_all_trials_per_condition(subj_idx,cond_idx)=length(subj_cond_late_erds);
        
        early_erds(cond_idx,subj_idx)=mean(subj_cond_early_erds);
        late_erds(cond_idx,subj_idx)=mean(subj_cond_late_erds);
    end
    early_subj_min_trials_per_condition(subj_idx)=min(early_subj_trials_per_condition);
    late_subj_min_trials_per_condition(subj_idx)=min(late_subj_trials_per_condition);
end
early_included_subj_idx=find(early_subj_min_trials_per_condition>=min_trials_per_cond);
early_erds=early_erds(:,early_included_subj_idx);
early_included_subjects=subject_ids(early_included_subj_idx);

late_included_subj_idx=find(late_subj_min_trials_per_condition>=min_trials_per_cond);
late_erds=late_erds(:,late_included_subj_idx);
late_included_subjects=subject_ids(late_included_subj_idx);