function prepare_pg_data(subjects)

% File to write all data to
fid=fopen('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/all_subjects.csv','w');
fwrite(fid, sprintf('Subject,Age,TrialsSeen,Block,Trial,TrialTime,FO,CG,Left,Right,Congruent,Incongruent,Trackloss\n'));

% Iterate through each subject
for subj_idx=1:length(subjects)
    subj_info=subjects(subj_idx);

    % Iterate through each age
    for age_idx=1:length(subj_info.ages)
        age=subj_info.ages{age_idx};
        num_runs=subj_info.num_runs(age_idx);
        fps=subj_info.fps(age_idx,:);
        coder=subj_info.coder{age_idx};
        cong_actor=subj_info.congruent_actor{age_idx};
        incong_actor=subj_info.incongruent_actor{age_idx};
        
        age_dir=fullfile('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/',age);
        % 106 - skip. 1st run - didn't see any head turn movies and
        % PG restarted in second run, only saw 8 trials before
        % second PG block in second run
        if subj_info.subj_id==106 && strcmp(age,'6m')
            continue;
        end

        % If more than one run
        if num_runs>1
            start_frames=[];
            end_frames=[];
            
            block_offset=0;
            total_trials_seen=0;
            for run_num=1:num_runs
                
                [pg_blocks,eeg_trials_seen]=read_pg_events(subj_info.subj_id, age, 'run', run_num);
                
                % Read trial times
                trial_times_fname=fullfile(age_dir,sprintf('%d-%d%s_trial_times.csv',subj_info.subj_id,run_num,coder));
                if exist(fullfile(age_dir,sprintf('%d-%d%s_ed_trial_times.csv',subj_info.subj_id,run_num,coder)),'file')==2
                    trial_times_fname=fullfile(age_dir,sprintf('%d-%d%s_ed_trial_times.csv',subj_info.subj_id,run_num,coder));
                    disp(sprintf('Using ed for subj %d, age %s, run %d', subj_info.subj_id,age, run_num));
                end
                trial_times_fid=fopen(trial_times_fname,'r');
                tline=fgetl(trial_times_fid);
                while tline>-1
                    tline=fgetl(trial_times_fid);
                    if tline>-1
                        cols=textscan(tline,'%s','delimiter',',');
                        x=cols{1};
                        block=str2num(x{1});
                        trial=str2num(x{2});
                        start_frame=str2num(x{3});
                        end_frame=str2num(x{4});
                        start_frames(block,trial)=start_frame;
                        end_frames(block,trial)=end_frame;
                    end
                end
                fclose(trial_times_fid);
                
                % Read each block
                for block_num=1:size(start_frames,1)
                    
                    % subj 105 6m - skip 1st block of second run
                    if subj_info.subj_id==105 && strcmp(age,'6m') && run_num==2 && block_num==1
                        continue
                    end
                    block_fname=fullfile(age_dir,sprintf('%d-%d%s_block_%d.csv',subj_info.subj_id,run_num,coder,block_num));
                    if exist(fullfile(age_dir,sprintf('%d-%d%s_ed_block_%d.csv',subj_info.subj_id,run_num,coder,block_num)),'file')==2
                        block_fname=fullfile(age_dir,sprintf('%d-%d%s_ed_block_%d.csv',subj_info.subj_id,run_num,coder,block_num));
                        disp(sprintf('Using ed for subj %d, age %s, run %d, block %d', subj_info.subj_id,age,run_num,block_num));
                    end
                    % Not all blocks coded yet
                    if exist(block_fname,'file')==2
                        block_fid=fopen(block_fname,'r');
                        tline=fgetl(block_fid);
                        trials=[];
                        fixation_num=1;
                        while tline>-1
                            tline=fgetl(block_fid);
                            if tline>-1
                                cols=textscan(tline,'%s','delimiter',',');
                                x=cols{1};
                                if length(x{1})>0
                                    trial=str2num(x{1});
                                    direction=x{2};
                                    start_frame=str2num(x{3});
                                    end_frame=str2num(x{4});
                                    rel_start_frame=start_frame-start_frames(block_num,trial);
                                    rel_end_frame=end_frame-start_frames(block_num,trial);
                                    if trial>length(trials)
                                        trials(trial).fixations=[];
                                        fixation_num=1;
                                    end
                                    trials(trial).fixations(fixation_num).direction=direction;
                                    trials(trial).fixations(fixation_num).start_frame=rel_start_frame;
                                    trials(trial).fixations(fixation_num).end_frame=rel_end_frame;
                                    fixation_num=fixation_num+1;
                                end
                            end          
                        end
                        fclose(block_fid);

                        for trial_idx=1:length(trials)
                            num_frames=end_frames(block_num,trial_idx)-start_frames(block_num,trial_idx);
                            for frame=1:num_frames
                                time_s=frame/fps(run_num);
                                gaze_dir='';
                                for fixation_idx=1:length(trials(trial_idx).fixations)
                                    if frame>=trials(trial_idx).fixations(fixation_idx).start_frame && frame<=trials(trial_idx).fixations(fixation_idx).end_frame
                                        gaze_dir=trials(trial_idx).fixations(fixation_idx).direction;
                                        break;
                                    end
                                end
                                trackloss='FALSE';
                                if strcmp(gaze_dir,'Offscreen')
                                    trackloss='TRUE';
                                end
                                FO='FALSE';
                                if (strcmp(gaze_dir,'Left') && strcmp(pg_blocks(block_num).trials(trial_idx).left,'FO')) || (strcmp(gaze_dir,'Right') && strcmp(pg_blocks(block_num).trials(trial_idx).right,'FO'))
                                    FO='TRUE';
                                end
                                CG='FALSE';                 
                                if (strcmp(gaze_dir,'Left') && strcmp(pg_blocks(block_num).trials(trial_idx).left,'CG')) || (strcmp(gaze_dir,'Right') && strcmp(pg_blocks(block_num).trials(trial_idx).right,'CG'))
                                    CG='TRUE';
                                end
                                Left='FALSE';
                                if strcmp(gaze_dir,'Left')
                                    Left='TRUE';
                                end
                                Right='FALSE';
                                if strcmp(gaze_dir,'Right')
                                    Right='TRUE';
                                end
                                Congruent='FALSE';
                                if (strcmp(FO,'TRUE') && strcmp(cong_actor,'FO')) || (strcmp(CG,'TRUE') && strcmp(cong_actor,'CG'))
                                    Congruent='TRUE';
                                end
                                Incongruent='FALSE';
                                if (strcmp(FO,'TRUE') && strcmp(incong_actor,'FO')) || (strcmp(CG,'TRUE') && strcmp(incong_actor,'CG'))
                                    Incongruent='TRUE';
                                end
                                fwrite(fid, sprintf('%d_%s,%s,%d,%d,%d,%0.4f,%s,%s,%s,%s,%s,%s,%s\n', subj_info.subj_id, age, age, total_trials_seen+pg_blocks(block_num).eeg_trials_seen,block_num+block_offset, (block_num+block_offset-1)*3+trial_idx, time_s, FO, CG, Left, Right, Congruent, Incongruent, trackloss));
                            end
                        end
                    end
                end
                total_trials_seen=total_trials_seen+eeg_trials_seen;
                block_offset=block_offset+length(pg_blocks);
                if subj_info.subj_id==105 && strcmp(age,'6m') && run_num==1
                    block_offset=block_offset-1;
                end
                    
            end
        else

            [pg_blocks,eeg_trials_seen]=read_pg_events(subj_info.subj_id, age);

            start_frames=[];
            end_frames=[];

            % Read trial times
            trial_times_fname=fullfile(age_dir,sprintf('%d%s_trial_times.csv',subj_info.subj_id,coder));
            if exist(fullfile(age_dir,sprintf('%d%s_ed_trial_times.csv',subj_info.subj_id,coder)),'file')==2
                trial_times_fname=fullfile(age_dir,sprintf('%d%s_ed_trial_times.csv',subj_info.subj_id,coder));
                disp(sprintf('Using ed for subj %d, age %s', subj_info.subj_id, age));
            end
            trial_times_fid=fopen(trial_times_fname,'r');
            tline=fgetl(trial_times_fid);
            while tline>-1
                tline=fgetl(trial_times_fid);
                if tline>-1
                    cols=textscan(tline,'%s','delimiter',',');
                    x=cols{1};
                    block=str2num(x{1});
                    trial=str2num(x{2});
                    start_frame=str2num(x{3});
                    end_frame=str2num(x{4});
                    start_frames(block,trial)=start_frame;
                    end_frames(block,trial)=end_frame;
                end
            end
            fclose(trial_times_fid);

            % Read each block
            for block_num=1:size(start_frames,1)
                block_fname=fullfile(age_dir,sprintf('%d%s_block_%d.csv',subj_info.subj_id,coder,block_num));
                if exist(fullfile(age_dir,sprintf('%d%s_ed_block_%d.csv',subj_info.subj_id,coder,block_num)),'file')==2
                    block_fname=fullfile(age_dir,sprintf('%d%s_ed_block_%d.csv',subj_info.subj_id,coder,block_num));
                    disp(sprintf('Using ed for subj %d, age %s, block %d', subj_info.subj_id,age,block_num));
                end
                % Not all blocks coded yet
                if exist(block_fname,'file')==2
                    block_fid=fopen(block_fname,'r');
                    tline=fgetl(block_fid);
                    trials=[];
                    fixation_num=1;
                    while tline>-1
                        tline=fgetl(block_fid);
                        if tline>-1
                            cols=textscan(tline,'%s','delimiter',',');
                            x=cols{1};
                            if length(x{1})>0
                                trial=str2num(x{1});
                                direction=x{2};
                                start_frame=str2num(x{3});
                                end_frame=str2num(x{4});
                                rel_start_frame=start_frame-start_frames(block_num,trial);
                                rel_end_frame=end_frame-start_frames(block_num,trial);
                                if trial>length(trials)
                                    trials(trial).fixations=[];
                                    fixation_num=1;
                                end
                                trials(trial).fixations(fixation_num).direction=direction;
                                trials(trial).fixations(fixation_num).start_frame=rel_start_frame;
                                trials(trial).fixations(fixation_num).end_frame=rel_end_frame;
                                fixation_num=fixation_num+1;
                            end
                        end          
                    end
                    fclose(block_fid);

                    for trial_idx=1:length(trials)
                        num_frames=end_frames(block_num,trial_idx)-start_frames(block_num,trial_idx);
                        for frame=1:num_frames
                            time_s=frame/fps;
                            gaze_dir='';
                            for fixation_idx=1:length(trials(trial_idx).fixations)
                                if frame>=trials(trial_idx).fixations(fixation_idx).start_frame && frame<=trials(trial_idx).fixations(fixation_idx).end_frame
                                    gaze_dir=trials(trial_idx).fixations(fixation_idx).direction;
                                    break;
                                end
                            end
                            trackloss='FALSE';
                            if strcmp(gaze_dir,'Offscreen')
                                trackloss='TRUE';
                            end
                            FO='FALSE';
                            if (strcmp(gaze_dir,'Left') && strcmp(pg_blocks(block_num).trials(trial_idx).left,'FO')) || (strcmp(gaze_dir,'Right') && strcmp(pg_blocks(block_num).trials(trial_idx).right,'FO'))
                                FO='TRUE';
                            end
                            CG='FALSE';                 
                            if (strcmp(gaze_dir,'Left') && strcmp(pg_blocks(block_num).trials(trial_idx).left,'CG')) || (strcmp(gaze_dir,'Right') && strcmp(pg_blocks(block_num).trials(trial_idx).right,'CG'))
                                CG='TRUE';
                            end
                            Left='FALSE';
                            if strcmp(gaze_dir,'Left')
                                Left='TRUE';
                            end
                            Right='FALSE';
                            if strcmp(gaze_dir,'Right')
                                Right='TRUE';
                            end
                            Congruent='FALSE';
                            if (strcmp(FO,'TRUE') && strcmp(cong_actor,'FO')) || (strcmp(CG,'TRUE') && strcmp(cong_actor,'CG'))
                                Congruent='TRUE';
                            end
                            Incongruent='FALSE';
                            if (strcmp(FO,'TRUE') && strcmp(incong_actor,'FO')) || (strcmp(CG,'TRUE') && strcmp(incong_actor,'CG'))
                                Incongruent='TRUE';
                            end
                            fwrite(fid, sprintf('%d_%s,%s,%d,%d,%d,%0.4f,%s,%s,%s,%s,%s,%s,%s\n', subj_info.subj_id, age, age, pg_blocks(block_num).eeg_trials_seen, block_num, (block_num-1)*3+trial_idx, time_s, FO, CG, Left, Right, Congruent, Incongruent, trackloss));
                        end
                    end
                end
            end
        end
    end
end
fclose(fid);
