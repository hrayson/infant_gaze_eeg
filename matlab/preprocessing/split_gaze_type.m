function split_gaze_type(subj_info, age, epoch_name, split_condition, varargin)

% Parse inputs
%    type = where to remove head turns from
%           saccade_cue = remove trials with head turns anywhere
%           head_turn_cue = remove trials with head turn in static or movie
%               period, or saccade during cue period
%           either_cue = remove trials with head turn in static or movie
%               period
defaults=struct('type', 'saccade_cue');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

output_dir=fullfile('/data/infant_gaze_eeg/',age,'/preprocessed/',num2str(subj_info.subj_id));

conditions={'epoch_reject'};
if split_condition
    conditions{end+1}='unshuffled';
    conditions{end+1}='unshuffled_congruent';
    conditions{end+1}='unshuffled_incongruent';
    conditions{end+1}='shuffled';
    conditions{end+1}='shuffled_congruent';
    conditions{end+1}='shuffled_incongruent';
end

for cond_idx=1:length(conditions)
    condition=conditions{cond_idx};
    epoch_reject=pop_loadset('filepath',output_dir,'filename',...
        sprintf('%d.%s.%s.set', subj_info.subj_id, epoch_name, condition));
    reject_trials=[];
    % Iterate through each epoch
    for i=1:length(epoch_reject.epoch)
        phase='';
        % Iterate through each event in the epoch
        for j=1:length(epoch_reject.epoch(i).eventtype)
            if strcmp(epoch_reject.epoch(i).eventtype{j},'ima1')
                phase='static';
            elseif strcmp(epoch_reject.epoch(i).eventtype{j},'ima2')
                phase='cue';
            elseif strcmp(epoch_reject.epoch(i).eventtype{j},'mov1')
                phase='movie';
            end
            switch params.type
                case 'saccade_cue'
                    % If head turn happens anywhere in trial
                    if strcmp(epoch_reject.epoch(i).eventtype{j},'head')
                        reject_trials(end+1)=i;
                    end
                case 'head_turn_cue'
                    % If head turn happens in static or movie period, or
                    % saccade to target happens in cue period
                    if ((strcmp(phase,'static') || strcmp(phase,'movie')) && strcmp(epoch_reject.epoch(i).eventtype{j},'head')) || (strcmp(phase,'cue') && strcmp(epoch_reject.epoch(i).eventtype{j},'init_saccade_target'))                   
                        reject_trials(end+1)=i;
                    end
                case 'either_cue'
                    % If head turn happens in static or movie period
                    if (strcmp(phase,'static') || strcmp(phase,'movie')) && strcmp(epoch_reject.epoch(i).eventtype{j},'head')
                       reject_trials(end+1)=i;
                    end
            end        
        end    
    end
    try
        epoch_reject = pop_rejepoch(epoch_reject, unique(reject_trials) ,0);
        epoch_reject=pop_saveset(epoch_reject,'filepath',output_dir,...
            'filename',sprintf('%d.%s.%s.%s.set', subj_info.subj_id, epoch_name, condition, params.type));
    catch
    end
end