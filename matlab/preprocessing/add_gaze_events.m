function data=add_gaze_events(data, age, subj_id, coder, fps, varargin)
%%
% Add gaze events to data. Gaze events are:
%    movement type = (saccade or head turn)
%    movement direction = (left, right, centre or offscreen)
%    movement target = (antitarget, target, face, or offscreen)
% Duplicate events with movement type='movement' are added so can align
% independent of movement type
% 


defaults=struct();
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

raw_data_dir=fullfile('/data','infant_gaze_eeg', age, 'raw',...
    num2str(subj_id), 'EEG');

% Read in initial direction coding - direction the infant is looking in 
% when the object highlighting starts (ima2) along with trial type
init_dir_fid=fopen(fullfile(raw_data_dir, ...
    sprintf('%d%s%s-initialdirectioncoding.csv', subj_id, coder, age)));
% Read each line from file
lines=textscan(init_dir_fid,'%s','Delimiter','\n','CollectOutput',true);

% List of trial information
trials=[];

% Loop through each line of the file (starting on line 2 - first line
% contains header information)
for i=2:length(lines{1})
    % Split line into columns
    cols=strsplit(lines{1}{i},',');
    % Get trial number, frame for ima2 event, and initial gaze direction
    trial_num=str2num(cols{1});
    ima2_frame=str2num(cols{2});
    init_dir=cols{3};

%     % Direction of highlighted stimulus (left or right)
%     direction = '';
%     if strcmp(cols{4},'l')
%         direction = 'left';
%     elseif strcmp(cols{4}, 'r')
%         direction = 'right';
%     end

%     % Congruent or incongruent condition
%     congruence = '';
%     if strcmp(cols{5},'cong')
%         congruence = 'congruent';
%     elseif strcmp(cols{5},'inco')
%         congruence = 'incongruent';
%     end

%     % Scrambled or not condition
%     shuf = false;
%     if str2num(cols{6})==0
%         shuf=false;
%     elseif str2num(cols{6})==1
%         shuf=true;
%     end

    trials(trial_num).ima2_frame=ima2_frame;
    trials(trial_num).init_dir=init_dir;
%     trials(trial_num).direction=direction;
%     trials(trial_num).congruence=congruence;
%     trials(trial_num).shuf=shuf;
end
fclose(init_dir_fid);

% Took this out because we want to align to infant looking at target, 
% if they're already looking at highlighted object at ima2, we don't know
% when the infant's movement occurred
% Add saccade to target if init dir of trial is to target
%for trial_idx=1:length(trials)
%    if strcmp(trials(trial_idx).init_dir,trials(trial_idx).direction)

%        % ima2 event time (second)
%        ima2_latency_sec=trials(trial_idx).ima2_frame./params.fps;

%        % Find ima2 event in epoch
%        ima2_latency_sec=0;
%        last_ima2_idx=0;
%        mov1_latency_sec=0;
%        mov1_evts_seen=0;
%        for evt_idx=1:length(data.event)
%            if strcmp(data.event(evt_idx).type,'ima2')
%                last_ima2_idx=evt_idx;
%            elseif strcmp(data.event(evt_idx).type,'mov1')
%                mov1_evts_seen=mov1_evts_seen+1;
%                if mov1_evts_seen==trial_idx                
%                    mov1_latency_sec=data.event(evt_idx).latency/data.srate;
%                    ima2_latency_sec=data.event(last_ima2_idx).latency/data.srate;
%                    break
%                end
%            end                        
%        end
%        mvmt_start_rel_sec=1.0/data.srate;
%        if (ima2_latency_sec+mvmt_start_rel_sec)-mov1_latency_sec<2.0
%            data = pop_editeventvals(data,'append',{1 'saccade' (ima2_latency_sec+mvmt_start_rel_sec) length(data.event)+1 1.0/data.srate 'none' trials(trial_idx).init_dir 'none' 'target' 'none'});
%        end
%    end
%end

% Read in movements file
mvmt_fid=fopen(fullfile(raw_data_dir,...
    sprintf('%d%s%s-movementcoding.csv', subj_id, coder, age)));
% Read all lines in the file
lines=textscan(mvmt_fid,'%s','Delimiter','\n','CollectOutput',true);
% Loop through each line - starting at line 2 because line 1 contains header
for i=2:length(lines{1})
    % Split line into columns based on commas
    cols=strsplit(lines{1}{i},',');
    % Type of movement - saccade or head turn
    mvmt=cols{2};
    % Frame of movement onset
    onset_frame=str2num(cols{3});
    % Frame of movement offset
    offset_frame=str2num(cols{4});

    % Look for trial that this movement occurred in
    for trial_idx=1:length(trials)
        % If last trial and onset is after trial start time or onset is
        % between trial start time and next trial start time
        if (trial_idx==length(trials) && onset_frame>=trials(trial_idx).ima2_frame) || ... % If this is the last trial and movement occurred after ima2 event
            (trial_idx<length(trials) && onset_frame>trials(trial_idx).ima2_frame && onset_frame<=trials(trial_idx+1).ima2_frame) % Otherwise if it happened after ima2 event of this trial, but before ima2 event of next trial

            % Parse direction (mvmt can be saccade or head turn)
            mvmt_dir='offscreen';
            if length(strfind(mvmt, 'left'))>0
                mvmt_dir='left';
            elseif length(strfind(mvmt, 'right'))>0
                mvmt_dir='right';
            elseif length(strfind(mvmt, 'centre'))>0
                mvmt_dir='centre';
            end

            % Parse movement type (saccade or head turn)
            mvmt_type='head';
            if length(strfind(mvmt, 'Saccade'))>0
                mvmt_type='saccade';
            end            

            % Movement duration (frames)
            mvmt_duration_frames=offset_frame-onset_frame;
            mvmt_duration_sec=mvmt_duration_frames/fps;
                
            % Movement start time (relative to ima2 frame)
            mvmt_start_rel_frames=onset_frame-trials(trial_idx).ima2_frame;
            mvmt_start_rel_sec=mvmt_start_rel_frames/fps;

            % Find ima2 event corresponding to this movement - needs to be
            % ima2 event preceding mov1 event (otherwise it doesn't count
            % as a trial because movie never played)
            ima2_latency_sec=0;
            last_ima2_idx=0;
            mov1_evts_seen=0;

            % Iterate through events
            for evt_idx=1:length(data.event)
                % If this is an ima2 event - store index
                if strcmp(data.event(evt_idx).type,'ima2')
                    last_ima2_idx=evt_idx;
                % If this is an mov1 event - counts as a trial
                elseif strcmp(data.event(evt_idx).type,'mov1')
                    % Increment mov1 events seen
                    mov1_evts_seen=mov1_evts_seen+1;
                    % If mov1 events seen equal to current movement trial idx
                    if mov1_evts_seen==trial_idx                
                        ima2_latency_sec=(data.event(last_ima2_idx).latency-1)/data.srate;
                        shuf=data.event(evt_idx).shuf;
                        congruence=data.event(evt_idx).gaze;
                        direction=data.event(evt_idx).attn;
                        break
                    end
                end                                
            end
            
            if strcmp(direction,'l')
                direction = 'left';
            elseif strcmp(direction, 'r')
                direction = 'right';
            end

            % Congruent or incongruent condition
            if strcmp(congruence,'cong')
                congruence = 'congruent';
            elseif strcmp(congruence,'inco')
                congruence = 'incongruent';
            end

            % Scrambled or not condition
            if str2num(shuf)==0
                shuf=false;
            elseif str2num(shuf)==1
                shuf=true;
            end

            % Compute pattern - looking at highlighted obj (target),
            % other obj (antitarget), face or offscreen
            mvmt_pat='antitarget';
            if strcmp(mvmt_dir,direction)
                mvmt_pat='target';
            elseif strcmp(mvmt_dir,'centre')
                mvmt_pat='face';
            elseif strcmp(mvmt_dir,'offscreen')
                mvmt_pat='offscreen';
            end
            
            % Add event
            data = pop_editeventvals(data,'append',{1 mvmt_type...
                (ima2_latency_sec+mvmt_start_rel_sec) length(data.event)+1 ...
                shuf mvmt_dir 'none' mvmt_pat ...
                congruence mvmt_duration_sec});
            data = pop_editeventvals(data,'append',{1 'movement' ...
                (ima2_latency_sec+mvmt_start_rel_sec) length(data.event)+1 ...
                shuf mvmt_dir 'none' mvmt_pat ...
                congruence mvmt_duration_sec});
            break
        end
    end
end



