function [included_subjects excluded_subjects]=exclude_subjects(age, conditions, time_zero_event, min_trials, varargin)

% Parse inputs
defaults=struct('trial_type', 'saccade_cue');
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
        subj_num_trials=[];
        for k=1:length(conditions)
            condition=conditions{k};
            file_name=fullfile(subj_dir, sprintf('%d.%s.%s.%s.set', subj_id, time_zero_event, condition, params.trial_type));
            if exist(file_name, 'file') == 2
                data=pop_loadset(file_name);
                subj_num_trials(k)=data.trials;
                if data.trials<min_trials
                    exclude=1;
                    break
                end
            else
                exclude=1;
                break
            end
        end
        if exclude<1
            included_subjects(end+1)=subj_id;
            num_trials(end+1,:)=subj_num_trials;
        else
            excluded_subjects(end+1)=subj_id;
        end
    else
        excluded_subjects(end+1)=subj_id;
    end
end
disp(sprintf('%d subjects', length(included_subjects)));
disp(sprintf('overall # trials M=%.3f, SD=%.3f', mean(sum(num_trials,2)./length(conditions)), std(sum(num_trials,2)./length(conditions))));
for k=1:length(conditions)
    condition=conditions{k};
    disp(sprintf('%s # trials M=%.3f, SD=%.3f', condition,...
        mean(num_trials(:,k)), std(num_trials(:,k))));
end
