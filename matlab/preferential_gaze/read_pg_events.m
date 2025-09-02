function [pg_blocks,eeg_trials_seen]=read_pg_events(subj_id, age, varargin)

% Parse inputs
defaults=struct('run',0);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

pg_blocks=[];

block_idx=1;
trial_idx=1;

fname=fullfile('/data/infant_gaze_eeg/',age,'raw',num2str(subj_id),'EEG', sprintf('%d-events_original.evt',subj_id));
if params.run>0
    fname=fullfile('/data/infant_gaze_eeg/',age,'raw',num2str(subj_id),'EEG', sprintf('%d-events_original-%d.evt',subj_id, params.run));
end

fid=fopen(fname, 'r');
tline=fgetl(fid);
eeg_trials_seen=0;
while tline>-1
    tline=fgetl(fid);
    if tline>-1
        cols=textscan(tline,'%s','delimiter','\t');
        x=cols{1};
        code=x{1};
        if strcmp(code,'pgst')
            right=x{8};
            left=x{10};
            if trial_idx==1
                pg_blocks(block_idx).trials=[];
                pg_blocks(block_idx).eeg_trials_seen=eeg_trials_seen;
            end
            pg_blocks(block_idx).trials(trial_idx).left=left;
            pg_blocks(block_idx).trials(trial_idx).right=right;
            trial_idx=trial_idx+1;
            if trial_idx>3
                block_idx=block_idx+1;
                trial_idx=1;
            end
        end
        if strcmp(code,'mov1')
            eeg_trials_seen=eeg_trials_seen+1;
        end
    end
end
fclose(fid);
