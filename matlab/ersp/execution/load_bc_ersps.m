function [ersps,alltimes,allfreqs]=load_bc_ersps(subj_ids, age, ...
    woi, baseline_woi, varargin)
%    baseline_type = type of baseline correction to use
%           trial = trial-specific baseline correction
%           global = global baseline correction
defaults=struct('channels',[], 'scale', 'log', 'baseline_type', 'global');
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
    
    fdir=fullfile('/data/infant_gaze_eeg', age, 'preprocessed',...
        num2str(subj_id));
    fname=sprintf('%d.head_turns.epoch_reject',subj_id);

    base_fname=sprintf('%d.whole.epoch_reject.either_cue', subj_id);
%         if strcmp(params.baseline_type,'trial') || strcmp(params.baseline_type,'condition')
%             base_fname=sprintf('%d.%s.%s.%s', subj_id,...
%                 baseline_time_zero_event, condition, params.trial_type);
%         end

    [tmpersp,p,alltimes,allfreqs] = std_readfile(fullfile(fdir,fname), 'channels',...
        {params.channels{1}}, 'timelimits', woi, 'measure', 'timef');
    subj_ersps=zeros(length(params.channels),length(allfreqs),length(alltimes),size(tmpersp,3));

    for chan_idx=1:length(params.channels)
        chan=params.channels{chan_idx};
        [tmpersp,p,ts,fs] = std_readfile(fullfile(fdir,fname), 'channels',...
            {chan}, 'timelimits', woi, 'measure', 'timef');
        tmpersp=tmpersp.*conj(tmpersp);

        [base_tmpersp,p,ts,fs] = std_readfile(fullfile(fdir, base_fname),...
            'channels', {chan}, 'timelimits', baseline_woi,...
            'measure', 'timef');
        base_tmpersp=base_tmpersp.*conj(base_tmpersp);
        %if strcmp(params.baseline_type,'global') || strcmp(params.baseline_type,'condition')
            base_tmpersp=squeeze(mean(base_tmpersp,3));
        %end

        for trial_idx=1:size(tmpersp,3)
            trial_ersp=squeeze(tmpersp(:,:,trial_idx));

            % Baseline correct
            P=trial_ersp;
            Pbase=base_tmpersp;
%             if strcmp(params.baseline_type,'trial')
%                 Pbase=squeeze(Pbase(:,:,trial_idx));
%             end
            mbase = mean(Pbase,2);
            if strcmp(params.scale,'abs')                    
                P = bsxfun(@rdivide, P-repmat(mbase,1,size(P,2)), mbase);
                P=P.*100;
            else
                P = bsxfun(@rdivide, P, mbase);
                P=10*log10(P);
            end
            subj_ersps(chan_idx,:,:,trial_idx)=P;
        end
    end
    ersps{subj_idx}=subj_ersps;
end