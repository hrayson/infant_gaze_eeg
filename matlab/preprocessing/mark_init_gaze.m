function data=mark_init_gaze(data)
%% 
% Mark initial gaze to face and target
% Adds duplicate events marking the initial gaze to the target, end of initial
% gaze to target, initial gaze to face, and end of initial gaze to face



% Mark initial gaze to target - after ima2 (object highlighting), but before
% mov1 (head turn start)

% Index of last ima2 event
last_ima2_idx=0;
% Iterate through all events
for evt_idx=1:length(data.event)
    % Found ima2 - look for head turn or saccade to target after this, but
    % before mov1
    if strcmp(data.event(evt_idx).type,'ima2')
        last_ima2_idx=evt_idx;
    % Head turn or saccade to target
    elseif last_ima2_idx>0 && (strcmp(data.event(evt_idx).type,'head') || strcmp(data.event(evt_idx).type,'saccade')) && strcmp(data.event(evt_idx).code,'target')
        % Get event info
        mvmt_type=data.event(evt_idx).type;
        gaze_latency_sec=(data.event(evt_idx).latency-1)/data.srate;
        gaze_duration_sec=data.event(evt_idx).duration/data.srate;
        mvmt_dir=data.event(evt_idx).attn;
        mvmt_pat=data.event(evt_idx).code;
        mvmt_shuf=data.event(evt_idx).shuf;
        mvmt_gaze=data.event(evt_idx).gaze;
        % Add duplicate event for initial gaze to target
        data = pop_editeventvals(data,'append',{1 'init_gaze_target' ...
            gaze_latency_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze gaze_duration_sec});
        % Add head turn or saccade duplicate event for initial gaze to
        % target
        data = pop_editeventvals(data,'append',{1 sprintf('init_%s_target',mvmt_type) ...
            gaze_latency_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze gaze_duration_sec});
        % Add event for end of initial gaze to target
        data = pop_editeventvals(data,'append',{1 'init_gaze_target_end' ...
            gaze_latency_sec+gaze_duration_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze 0.001});
        % Add head turn or saccade duplicate event for end of initial gaze to
        % target
        data = pop_editeventvals(data,'append',{1 sprintf('init_%s_target_end',mvmt_type) ...
            gaze_latency_sec+gaze_duration_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze 0.001});
        % Reset ima2 index
        last_ima2_idx=0;
    % Found mov1 or imov event - reset ima2 index
    elseif strcmp(data.event(evt_idx).type,'mov1') || strcmp(data.event(evt_idx).type,'imov')
        last_ima2_idx=0;
    end
end


% Mark initial gaze to face - after initial gaze to target, but before
% mov1 (head turn start)

% Index of last initial gaze to target event
last_gaze_target_idx=0;
% Iterate through all events
for evt_idx=1:length(data.event)
    % Found gaze target - look for head turn or saccade to face after this,
    % but before mov1
    if strcmp(data.event(evt_idx).type,'init_gaze_target')
        last_gaze_target_idx=evt_idx;
    % Head turn or saccade to face
    elseif last_gaze_target_idx>0 && (strcmp(data.event(evt_idx).type,'head') || strcmp(data.event(evt_idx).type,'saccade')) && strcmp(data.event(evt_idx).code,'face')
        % Get event info
        mvmt_type=data.event(evt_idx).type;
        gaze_latency_sec=(data.event(evt_idx).latency-1)/data.srate;
        gaze_duration_sec=data.event(evt_idx).duration/data.srate;
        mvmt_dir=data.event(evt_idx).attn;
        mvmt_pat=data.event(evt_idx).code;
        mvmt_shuf=data.event(evt_idx).shuf;
        mvmt_gaze=data.event(evt_idx).gaze;
        % Add duplicate event for initial gaze to face
        data = pop_editeventvals(data,'append',{1 'init_gaze_face' ...
            gaze_latency_sec length(data.event)+1  mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze gaze_duration_sec});
        % Add head turn or saccade duplicate event for initial gaze to
        % face
        data = pop_editeventvals(data,'append',{1 sprintf('init_%s_face', mvmt_type) ...
            gaze_latency_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
            'none' mvmt_pat mvmt_gaze gaze_duration_sec});
        % Add event for end of initial gaze to face
        data = pop_editeventvals(data,'append',{1 'init_gaze_face_end' ...
            gaze_latency_sec+gaze_duration_sec length(data.event)+1 mvmt_shuf ...
            mvmt_dir 'none' mvmt_pat mvmt_gaze 0.001});
        % Add head turn or saccade duplicate event for end of initial gaze to
        % face
        data = pop_editeventvals(data,'append',{1 sprintf('init_%s_face_end', mvmt_type) ...
            gaze_latency_sec+gaze_duration_sec length(data.event)+1 mvmt_shuf ...
            mvmt_dir 'none' mvmt_pat mvmt_gaze 0.001});
        last_gaze_target_idx=0;
    % Found mov1 or imov event - reset gaze target index
    elseif strcmp(data.event(evt_idx).type,'mov1') || strcmp(data.event(evt_idx).type,'imov')
        last_gaze_target_idx=0;
    end
end

% Mark initial gaze to face - within 1s after mov1 (head turn start)

% Index of last initial gaze to target event
last_gaze_target_idx=0;
% Index of last mov1 event
last_mov1_idx=0;
% Iterate through all events
for evt_idx=1:length(data.event)
    % Found initial gaze target - look for head turn or saccade to face after, also after mov1
    if strcmp(data.event(evt_idx).type,'init_gaze_target')
        last_gaze_target_idx=evt_idx;
    elseif strcmp(data.event(evt_idx).type,'mov1')
        last_mov1_idx=evt_idx;
    % Head turn or saccade to face
    elseif last_gaze_target_idx>0 && last_mov1_idx>0 && (strcmp(data.event(evt_idx).type,'head') || strcmp(data.event(evt_idx).type,'saccade')) && strcmp(data.event(evt_idx).code,'face')
        gaze_latency_sec=(data.event(evt_idx).latency-1)/data.srate;
        last_mov1_latency_sec=(data.event(last_mov1_idx).latency-1)/data.srate;
        % If occurs within 1s of last mov1 event
        if gaze_latency_sec-last_mov1_latency_sec<1.0
            mvmt_type=data.event(evt_idx).type;
            gaze_duration_sec=data.event(evt_idx).duration/data.srate;
            mvmt_dir=data.event(evt_idx).attn;
            mvmt_pat=data.event(evt_idx).code;
            mvmt_shuf=data.event(evt_idx).shuf;
            mvmt_gaze=data.event(evt_idx).gaze;
            % Add duplicate event for initial gaze to face
            data = pop_editeventvals(data,'append',{1 'init_gaze_face' ...
                gaze_latency_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
                'none' mvmt_pat mvmt_gaze gaze_duration_sec});
            % Add head turn or saccade duplicate event for initial gaze to
            % face
            data = pop_editeventvals(data,'append',{1 sprintf('init_%s_face', mvmt_type) ...
                gaze_latency_sec length(data.event)+1 mvmt_shuf mvmt_dir ...
                'none' mvmt_pat mvmt_gaze gaze_duration_sec});
            % Add event for end of initial gaze to face
            data = pop_editeventvals(data,'append',{1 'init_gaze_face_end' ...
                gaze_latency_sec+gaze_duration_sec length(data.event)+1 ...
                mvmt_shuf mvmt_dir 'none' mvmt_pat mvmt_gaze 0.001});
            % Add head turn or saccade duplicate event for end of initial gaze to
            % face
            data = pop_editeventvals(data,'append',{1 sprintf('init_%s_face_end', mvmt_type) ...
                gaze_latency_sec+gaze_duration_sec length(data.event)+1 ...
                mvmt_shuf mvmt_dir 'none' mvmt_pat mvmt_gaze 0.001});        
        end
        last_gaze_target_idx=0;
        last_mov1_idx=0;
    % Found imov event - reset indices
    elseif strcmp(data.event(evt_idx).type,'imov')
        last_gaze_target_idx=0;
        last_mov1_idx=0;
    end
end
