function [included_subjects excluded_subjects]=exclude_subjects(age, min_trials, varargin)

% Parse inputs
defaults=struct();
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

base_dir=fullfile('/data','infant_gaze_eeg', age);
d = dir(fullfile(base_dir, 'preprocessed'));
isub = [d(:).isdir]; % returns logical vector
subj_ids = {d(isub).name}';
subj_ids(ismember(subj_ids,{'.','..'})) = [];

included_subjects=[];
excluded_subjects=[];
num_trials=[];
for i=1:length(subj_ids)
    subj_id=str2num(subj_ids{i});
    subj_dir=fullfile(base_dir,'preprocessed', num2str(subj_id));
    if exist(subj_dir,'dir')
        exclude=0;
        file_name=fullfile(subj_dir, sprintf('%d.head_turns.epoch_reject.set', subj_id));
        if exist(file_name, 'file') == 2
            data=pop_loadset(file_name);            
            if data.trials<min_trials
                exclude=1;
            end
        else
            exclude=1;
        end
        if exclude<1
            included_subjects(end+1)=subj_id;
            num_trials(end+1)=data.trials;
        else
            excluded_subjects(end+1)=subj_id;
        end
    else
        excluded_subjects(end+1)=subj_id;
    end
end
disp(sprintf('%d subjects, # trials M=%.3f, SD=%.3f', ...
    length(included_subjects), mean(num_trials), std(num_trials)));
