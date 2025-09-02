function data=add_noat_artifacts(age, subj_id, base_dir, num_runs, data)

% Add no attention artifact events
if strcmp(age,'9m') && subj_id==149 % This subject had to be done manually from the video locally
    % Opens file containing artifact times
    noat_artifacts_fid=fopen(fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_artifacts.evt', subj_id)));
    % Reads each line in the artifact file
    noat_artifacts=textscan(noat_artifacts_fid,'%s','Delimiter','\n','CollectOutput',true);
    % Iterate through each line in the file
    for i=1:length(noat_artifacts{1})
        line_str=noat_artifacts{1}{i};
        % Breaks up line based on commas
        cols=regexp(line_str,',','split');
        % Start of the artifact
        start_sec=str2num(cols{1});
        % End of the artifact
        end_sec=str2num(cols{2});
        % Duration = end-start
        dur_sec=end_sec-start_sec;
        % Add this as an event
        data = pop_editeventvals(data,'append',{1 'artifact' start_sec length(data.event)+1 dur_sec 'none' 'none' 'none' 'none' 'none'});
    end
else
    noat_artifacts_filename=fullfile(base_dir,'raw',num2str(subj_id),'EEG', sprintf('%d-events_artifacts.evt', subj_id));
    % Check if file exists
    if exist(noat_artifacts_filename,'file')==2
        % Opens file containing artifact times
        noat_artifacts_fid=fopen(noat_artifacts_filename);
        % Reads each line in the artifact file
        noat_artifacts=textscan(noat_artifacts_fid,'%s','Delimiter','\n','CollectOutput',true);

        % Artifact times are absolute - need relative to start of recording, so need to load data file and get time of recording start
        if num_runs>1  % These subjects had two session files - so need to load the first one
            [data_fid,message] = fopen(fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d_1.nsf', subj_id)),'rb','b');
        else
            [data_fid,message] = fopen(fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d.raw', subj_id)),'rb','b');
        end

        % Read header file - get hour, minute, second, ms of recording start
        data_head=readegihdr(data_fid);
        hour = data_head.hour;
        minute = data_head.minute;
        second = data_head.second;
        millisecond = data_head.millisecond;

        % Iterate through each line in the artifact file
        for i=1:length(noat_artifacts{1})
            % Read line
            line_str=noat_artifacts{1}{i};
            % Split line into columns where there are commas
            cols=regexp(line_str,',','split');

            % Read start hour, min, sec of artifact
            start_cols=regexp(cols{1},':','split');
            start_hour=str2num(start_cols{1});
            start_min=str2num(start_cols{2});
            start_sec=str2num(start_cols{3});
    
            % Read duration hour, min, sec of artifact
            dur_cols=regexp(cols{2},':','split');
            dur_hour=str2num(dur_cols{1});
            dur_min=str2num(dur_cols{2});
            dur_sec=str2num(dur_cols{3});
            
            % Compute relative start time in seconds
            start_rel=(start_hour*3600.0+start_min*60.0+start_sec) - (hour*3600.0+minute*60.0+second+.001*millisecond);
            % Compute duration time in seconds
            duration=dur_hour*3600.0+dur_min*60.0+dur_sec;
    
            % Add artifact as event
            data = pop_editeventvals(data,'append',{1 'artifact' start_rel length(data.event)+1 'none' 'none' 'none' 'none' 'none' duration});
        end
    end
end
