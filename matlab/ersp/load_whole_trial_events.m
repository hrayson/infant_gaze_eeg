function subj_events=load_whole_trial_events(subj_ids, age, conditions, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

subj_events={};

for subj_idx=1:length(subj_ids)
    subj_id=subj_ids(subj_idx);
    subj_dir=fullfile('/data/infant_gaze_eeg/',age,'preprocessed', num2str(subj_id));
    
    for cond_idx=1:length(conditions)
        condition=conditions{cond_idx};
        fname=sprintf('%d.whole.%s.%s.set',subj_id, condition, params.trial_type);
        
        data=pop_loadset(fullfile(subj_dir,fname));
        subj_events{subj_idx,cond_idx}=data.epoch;
    end
end
    
    
    