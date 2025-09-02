function prepare_gaze_shift_data(subjects, exclude_head_turns)

% File to write all data to
fname='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_gaze_shifts.csv';
if exclude_head_turns
    fname='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/all_subjects_gaze_shifts_no_headturns.csv';
end
fid=fopen(fname,'w');
fwrite(fid, sprintf('Subject,Age,Condition,Congruence,Trial,MovementId,Pattern,Direction,Type\n'));

% Iterate through each subject
for subj_idx=1:length(subjects)
    subj_info=subjects(subj_idx);
    % Iterate through each age
    for age_idx=1:length(subj_info.ages)
        age=subj_info.ages{age_idx};
        num_runs=subj_info.num_runs(age_idx);
        fps=subj_info.fps(age_idx,:);
        coder=subj_info.coder{age_idx};
        raw_data_dir=fullfile('/data/infant_gaze_eeg',age,'raw',num2str(subj_info.subj_id),'EEG');
        
        data=pop_loadset('filepath',fullfile('/data/infant_gaze_eeg', age,'preprocessed', num2str(subj_info.subj_id)),'filename', ...
                sprintf('%d.events.set', subj_info.subj_id));
            
        % If more than one run
        if num_runs>1
            
            block_offset=0;
            for run_num=1:num_runs
                % List of trial information
                trials=[];
            
                % Read in initial direction coding - direction the infant is looking in 
                % when the object highlighting starts (ima2) along with trial type
                init_dir_fid=fopen(fullfile(raw_data_dir, ...
                    sprintf('%d%s%s-initialdirectioncoding-%d.csv', subj_info.subj_id, coder, age, run_num)));
                % Read each line from file
                lines=textscan(init_dir_fid,'%s','Delimiter','\n','CollectOutput',true);
                
                % Loop through each line of the file (starting on line 2 - first line
                % contains header information)
                for i=2:length(lines{1})
                    % Split line into columns
                    cols=strsplit(lines{1}{i},',');
                    % Get trial number, frame for ima2 event, and initial gaze direction
                    trial_num=str2num(cols{1});
                    ima2_frame=str2num(cols{2});
                    init_dir=cols{3};
                    trials(trial_num).ima2_frame=ima2_frame;
                    trials(trial_num).init_dir=init_dir;
                    trials(trial_num).movements=[];
                end
                fclose(init_dir_fid);

                % Read in movements file
                mvmt_fid=fopen(fullfile(raw_data_dir,...
                    sprintf('%d%s%s-movementcoding-%d.csv', subj_info.subj_id, coder, age, run_num)));
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
                            
                            % Parse movement type
                            mvmt_type='head_turn';
                            if length(strfind(mvmt, 'Saccade'))>0
                                mvmt_type='saccade';
                            end

                            % Movement duration (frames)
                            mvmt_duration_frames=offset_frame-onset_frame;

                            % Movement start time (relative to ima2 frame)
                            mvmt_start_rel_frames=onset_frame-trials(trial_idx).ima2_frame;

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
                                    if mov1_evts_seen==trial_idx+block_offset
                                        ima2_latency_sec=(data.event(last_ima2_idx).latency-1)/data.srate;
                                        mov1_latency_sec=(data.event(evt_idx).latency-1)/data.srate;
                                        trials(trial_idx).end_frame=trials(trial_idx).ima2_frame+floor((mov1_latency_sec+3-ima2_latency_sec)*fps(run_num));
                                        trials(trial_idx).mov1_frame=floor((mov1_latency_sec-ima2_latency_sec)*fps(run_num));
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

                            trials(trial_idx).shuffled=shuf;
                            trials(trial_idx).congruence=congruence;
                            if ~shuf && strcmp(congruence,'congruent')
                                trials(trial_idx).condition='congruent';
                            elseif ~shuf && strcmp(congruence,'incongruent')
                                trials(trial_idx).condition='incongruent';
                            elseif shuf
                                trials(trial_idx).condition='shuffled';
                            end
                            trials(trial_idx).direction=direction;
                            if mvmt_start_rel_frames>=trials(trial_idx).mov1_frame-trials(trial_idx).ima2_frame
                                mvmt_idx=length(trials(trial_idx).movements)+1;
                                trials(trial_idx).movements(mvmt_idx).start=mvmt_start_rel_frames;
                                trials(trial_idx).movements(mvmt_idx).end=mvmt_start_rel_frames+mvmt_duration_frames;
                                trials(trial_idx).movements(mvmt_idx).mvmt_pat=mvmt_pat;
                                trials(trial_idx).movements(mvmt_idx).mvmt_dir=mvmt_dir;
                                trials(trial_idx).movements(mvmt_idx).mvmt_type=mvmt_type;
                            end
                        end
                    end
                end
   
                excluded_trials=[];
                
                for trial_idx=1:length(trials)
                    for mvmt_idx=1:length(trials(trial_idx).movements)
                        if exclude_head_turns && strcmp(trials(trial_idx).movements(mvmt_idx).mvmt_type,'head_turn') && trials(trial_idx).movements(mvmt_idx).start>=(trials(trial_idx).mov1_frame-trials(trial_idx).ima2_frame)
                            excluded_trials(end+1)=trial_idx;
                        end
                    end                    
                end

                included_trials=setdiff([1:length(trials)],excluded_trials);
                for trial_num=1:length(included_trials)
                    trial_idx=included_trials(trial_num);
                    for mvmt_idx=1:length(trials(trial_idx).movements)
                        mvmt_pat=trials(trial_idx).movements(mvmt_idx).mvmt_pat;
                        mvmt_dir=trials(trial_idx).movements(mvmt_idx).mvmt_dir;
                        mvmt_type=trials(trial_idx).movements(mvmt_idx).mvmt_type;
                        fwrite(fid, sprintf('%d_%s,%s,%s,%s,%d,%d,%s,%s,%s\n', subj_info.subj_id, age, age, trials(trial_idx).condition, trials(trial_idx).congruence, trial_num+block_offset, mvmt_idx, mvmt_pat, mvmt_dir, mvmt_type));
                    end
                end
            
                block_offset=block_offset+length(trials);
            end
        else
            % Read in initial direction coding - direction the infant is looking in 
            % when the object highlighting starts (ima2) along with trial type
            init_dir_fid=fopen(fullfile(raw_data_dir, ...
                sprintf('%d%s%s-initialdirectioncoding.csv', subj_info.subj_id, coder, age)));
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
                trials(trial_num).ima2_frame=ima2_frame;
                trials(trial_num).init_dir=init_dir;
                trials(trial_num).movements=[];
            end
            fclose(init_dir_fid);
            
            % Read in movements file
            mvmt_fid=fopen(fullfile(raw_data_dir,...
                sprintf('%d%s%s-movementcoding.csv', subj_info.subj_id, coder, age)));
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
                        
                        % Parse movement type
                        mvmt_type='head_turn';
                        if length(strfind(mvmt, 'Saccade'))>0
                            mvmt_type='saccade';
                        end

                        % Movement duration (frames)
                        mvmt_duration_frames=offset_frame-onset_frame;
                        
                        % Movement start time (relative to ima2 frame)
                        mvmt_start_rel_frames=onset_frame-trials(trial_idx).ima2_frame;
                        
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
                                    mov1_latency_sec=(data.event(evt_idx).latency-1)/data.srate;
                                    trials(trial_idx).end_frame=trials(trial_idx).ima2_frame+floor((mov1_latency_sec+3-ima2_latency_sec)*fps);
                                    trials(trial_idx).mov1_frame=floor((mov1_latency_sec-ima2_latency_sec)*fps);
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
                        
                        trials(trial_idx).shuffled=shuf;
                        trials(trial_idx).congruence=congruence;
                        if ~shuf && strcmp(congruence,'congruent')
                            trials(trial_idx).condition='congruent';
                        elseif ~shuf && strcmp(congruence,'incongruent')
                            trials(trial_idx).condition='incongruent';
                        elseif shuf
                            trials(trial_idx).condition='shuffled';
                        end
                        trials(trial_idx).direction=direction;
                        
                        if mvmt_start_rel_frames>=trials(trial_idx).mov1_frame-trials(trial_idx).ima2_frame
                            mvmt_idx=length(trials(trial_idx).movements)+1;
                            trials(trial_idx).movements(mvmt_idx).start=mvmt_start_rel_frames;
                            trials(trial_idx).movements(mvmt_idx).end=mvmt_start_rel_frames+mvmt_duration_frames;
                            trials(trial_idx).movements(mvmt_idx).mvmt_pat=mvmt_pat;
                            trials(trial_idx).movements(mvmt_idx).mvmt_dir=mvmt_dir;
                            trials(trial_idx).movements(mvmt_idx).mvmt_type=mvmt_type;
                        end
                    end
                end
            end
            
            excluded_trials=[];
            
            for trial_idx=1:length(trials)
                for mvmt_idx=1:length(trials(trial_idx).movements)
                    if exclude_head_turns && strcmp(trials(trial_idx).movements(mvmt_idx).mvmt_type,'head_turn') && trials(trial_idx).movements(mvmt_idx).start>=(trials(trial_idx).mov1_frame-trials(trial_idx).ima2_frame)
                        excluded_trials(end+1)=trial_idx;
                    end
                end                
            end
            
            included_trials=setdiff([1:length(trials)],excluded_trials);
                        
            for trial_num=1:length(included_trials)
                trial_idx=included_trials(trial_num);
                for mvmt_idx=1:length(trials(trial_idx).movements)
                    mvmt_pat=trials(trial_idx).movements(mvmt_idx).mvmt_pat;
                    mvmt_dir=trials(trial_idx).movements(mvmt_idx).mvmt_dir;
                    mvmt_type=trials(trial_idx).movements(mvmt_idx).mvmt_type;
                    fwrite(fid, sprintf('%d_%s,%s,%s,%s,%d,%d,%s,%s,%s\n', subj_info.subj_id, age, age, trials(trial_idx).condition, trials(trial_idx).congruence, trial_num, mvmt_idx, mvmt_pat, mvmt_dir, mvmt_type));
                end
            end
        end
    end
end
fclose(fid);