%%
% precompute_ersps(subjects, 'mov1', true,'type','either_cue');
% precompute_ersps(subjects, 'static', true,'type','either_cue');
%%
function precompute_ersps(subj_info, age, epoch_name, split_condition, varargin)

%    trial_type = where to remove head turns from
%           saccade_cue = remove trials with head turns anywhere
%           head_turn_cue = remove trials with head turn in static or movie
%               period, or saccade during cue period
%           either_cue = remove trials with head turn in static or movie
%               period
defaults=struct('trial_type', 'saccade_cue');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

conditions={'unshuffled','unshuffled_congruent','unshuffled_incongruent',...
    'shuffled','shuffled_congruent','shuffled_incongruent'};

preprocess_dir=fullfile('/data/infant_gaze_eeg/',age,'preprocessed',...
    num2str(subj_info.subj_id));

if split_condition
    for condition_idx=1:length(conditions)
        condition=conditions{condition_idx};
        fname=fullfile(preprocess_dir, sprintf('%d.%s.%s.%s.set',...
            subj_info.subj_id,epoch_name,condition,params.trial_type));
        if exist(fname,'file')==2
            % Load data file
            data=pop_loadset(fname);
            % Compute trial TF (not baseline-corrected)
            std_ersp(data, 'type', 'ersp',...
                'trialindices', [1:data.trials], 'cycles', 0,...
                'nfreqs', 100, 'ntimesout', 400,...
                'freqs', [2 35], 'freqscale', 'linear',...
                'baseline', NaN, 'winsize',128,...
                'padratio', 16, 'channels', {data.chanlocs.labels}',...
                'verbose', 'off', 'savefile', 'on', 'recompute', 'on',...
                'savetrials', 'on');
        end
    end
end
fname=fullfile(preprocess_dir, sprintf('%d.%s.epoch_reject.%s.set', ...
    subj_info.subj_id, epoch_name, params.trial_type));
if exist(fname,'file')==2
    % Load data file
    data=pop_loadset(fname);
    % Compute trial TF (not baseline-corrected)
    std_ersp(data, 'type', 'ersp',...
        'trialindices', [1:data.trials], 'cycles', 0,...
        'nfreqs', 100, 'ntimesout', 400,...
        'freqs', [2 35], 'freqscale', 'linear',...
        'baseline', NaN, 'winsize',128,...
        'padratio', 16, 'channels', {data.chanlocs.labels}',...
        'verbose', 'off', 'savefile', 'on', 'recompute', 'on',...
        'savetrials','on');
end
