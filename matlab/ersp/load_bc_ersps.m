function [ersps,alltimes,allfreqs]=load_bc_ersps(subj_ids, age, ...
    conditions, time_zero_event, woi, baseline_time_zero_event,...
    baseline_woi, varargin)

%    trial_type = where to remove head turns from
%           saccade_cue = remove trials with head turns anywhere
%           head_turn_cue = remove trials with head turn in static or movie
%               period, or saccade during cue period
%           either_cue = remove trials with head turn in static or movie
%               period
%    baseline_type = type of baseline correction to use
%           trial = trial-specific baseline correction
%           condition = condition-specific baseline correction
%           global = global baseline correction
defaults=struct('channels',[], 'foi', [], 'trial_type', 'saccade_cue', 'scale', 'log',...
    'baseline_type', 'condition');
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

if length(params.channels)==0
    params.channels={};
    for i=1:128
        params.channels{i}=sprintf('E%d', i);
    end
else
    chans={};
    for i=1:length(params.channels)
        chans{i}=sprintf('E%d', params.channels(i));
    end
    params.channels=chans;
end

ersps={};
for subj_idx=1:length(subj_ids)
    subj_id=subj_ids(subj_idx);
    disp(sprintf('Subject %d', subj_id));
    
    subj_ersps={};
    for cond_idx=1:length(conditions)
        condition=conditions{cond_idx};        
        
        fdir=fullfile('/data/infant_gaze_eeg', age, 'preprocessed',...
            num2str(subj_id));
        fname=sprintf('%d.%s.%s.%s',subj_id,time_zero_event, condition,...
            params.trial_type);
        
        base_fname=sprintf('%d.%s.epoch_reject.%s', subj_id,...
            baseline_time_zero_event, params.trial_type);
        if strcmp(params.baseline_type,'trial') || strcmp(params.baseline_type,'condition')
            base_fname=sprintf('%d.%s.%s.%s', subj_id,...
                baseline_time_zero_event, condition, params.trial_type);
        end
        
        [tmpersp,p,alltimes,allfreqs] = std_readfile(fullfile(fdir,fname), 'channels',...
            {params.channels{1}}, 'timelimits', woi, 'measure', 'timef');
        freq_idx=[1:length(allfreqs)];
        if length(params.foi)>1
            freq_idx=intersect(find(allfreqs>=params.foi(1)), find(allfreqs<=params.foi(2)));
        end
        cond_ersps=zeros(length(params.channels),length(freq_idx),length(alltimes),size(tmpersp,3));
        
        for chan_idx=1:length(params.channels)
            chan=params.channels{chan_idx};
            [tmpersp,p,ts,fs] = std_readfile(fullfile(fdir,fname), 'channels',...
                {chan}, 'timelimits', woi, 'measure', 'timef');
            tmpersp=tmpersp.*conj(tmpersp);
            
            [base_tmpersp,p,ts,fs] = std_readfile(fullfile(fdir, base_fname),...
                'channels', {chan}, 'timelimits', baseline_woi,...
                'measure', 'timef');
            base_tmpersp=base_tmpersp.*conj(base_tmpersp);
            if strcmp(params.baseline_type,'global') || strcmp(params.baseline_type,'condition')
                if strcmp(params.scale,'abs')
                    base_tmpersp=squeeze(mean(base_tmpersp,3));
                else
                    base_tmpersp=squeeze(mean(log10(base_tmpersp),3));
                end
            end
                    
            for trial_idx=1:size(tmpersp,3)
                trial_ersp=squeeze(tmpersp(:,:,trial_idx));
                
                % Baseline correct
                P=trial_ersp;
                Pbase=base_tmpersp;
                if strcmp(params.baseline_type,'trial')
                    Pbase=squeeze(Pbase(:,:,trial_idx));
                end
                mbase = mean(Pbase,2);
                if strcmp(params.scale,'abs')                    
                    P = (P-repmat(mbase,[1,size(P,2)]))./repmat(mbase,[1,size(P,2)]);
                    P=P.*100;
                else
                    P = 10*(log10(P)-repmat(mbase, [1 size(P,2)]));
                end
                cond_ersps(chan_idx,:,:,trial_idx)=P(freq_idx,:);
            end
        end
        subj_ersps{cond_idx}=cond_ersps;
    end
    ersps{subj_idx}=subj_ersps;
end