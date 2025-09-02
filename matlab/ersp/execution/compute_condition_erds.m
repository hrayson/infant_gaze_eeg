function [erds, included_subjects]=compute_condition_erds(subject_ids,...
    subj_ersps, allfreqs, foi, min_trials, varargin)

% Parse inputs
defaults=struct('outlier_method', '');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));

erds=zeros(1,length(subject_ids));
subj_num_trials=zeros(1,length(subject_ids));
for subj_idx=1:length(subject_ids)    
    subj_ersp=subj_ersps{subj_idx};
    subj_erds=squeeze(mean(mean(mean(subj_ersp(:,freq_idx,:,:),1),2),3));
    if strcmp(params.outlier_method,'iqr')
        cond_median=median(subj_erds);
        r=iqr(subj_erds);
        subj_erds=subj_erds(find((subj_erds-cond_median)<=1.5*r));
    elseif strcmp(params.outlier_method,'mdm')
        c=outmdm(subj_erds);
        subj_erds=subj_erds(find(c==0));            
    end
    erds(subj_idx)=mean(subj_erds);
    subj_num_trials(subj_idx)=length(subj_erds);
end
final_included_subj_idx=find(subj_num_trials>=min_trials);
erds=erds(final_included_subj_idx);
included_subjects=subject_ids(final_included_subj_idx);