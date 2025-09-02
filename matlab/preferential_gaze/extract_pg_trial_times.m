function extract_pg_trial_times(age, subj_id, fps, delay, varargin)

% Parse inputs
defaults=struct('run',0);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Open individual run file
if params.run>0
    raw_events=pop_loadset('filepath',...
        fullfile('/data','infant_gaze_eeg',age,'raw',num2str(subj_id),'EEG'),...
        'filename',sprintf('%d-%d.set', subj_id, params.run));
% Otherwise open concatenated file
else
    raw_events=pop_loadset('filepath',...
        fullfile('/data','infant_gaze_eeg','bak',age,'preprocessed_v2',num2str(subj_id)),...
        'filename',sprintf('%d.events.set',subj_id));
end

% PG block number
block=1;
% PG trial number
trial=1;
% PG trial start time
start_time=0;

disp('Block,Trial,Start,End');

% Iterate through events
for j=1:length(raw_events.event)
    event_code=raw_events.event(j).type;
    % Convert event latency from to seconds and add delay
    latency=raw_events.event(j).latency/raw_events.srate+delay;
    
    % If start of PG trial, get start time
    if strcmp(event_code,'pgst')
        start_time=latency;
    % If end of PG trial, get end time
    elseif strcmp(event_code,'pgen')
        end_time=latency;
        
        % Convert start time from seconds to frames
        start_time_frame=floor(start_time*fps);
        % Convert end time from seconds to frames
        end_time_frame=floor(end_time*fps);
        
        % Print block, trial, start and end frame
        disp([num2str(block) ',' num2str(trial) ',' num2str(start_time_frame) ',' num2str(end_time_frame)]);
        
        % Increment block number and reset trial number after 3 trials
        if trial==3
            block=block+1;
            trial=1;
        % Otherwise increment trial number
        else
            trial=trial+1;
        end
    end
end
