function optimize(subjects, age, foi, clusters)

base_dir=fullfile('/data/infant_gaze_eeg', age);
    
wois=[-500 0;0 500;500 1000];
% targets=[];
% targets(1,:,:)=[-30 -10 -10;-10 -10 -10;-2 -20 -20];
% targets(2,:,:)=[-40 -10 -10;-10 -10 -10;-2 -20 -20];
% targets(3,:,:)=[-20 -5 -5;-5 -5 -5;0 -10 -10];

targets=[-25 -25 -20 -20;0 -15 -15 -15;0 -15 -15 -15];

for subj_idx=1:length(subjects)
    subj_info=subjects(subj_idx);
    
    for age_idx=1:length(subj_info.ages)
        subj_age=subj_info.ages{age_idx};
        
        if strcmp(subj_age,age)
            output_dir=fullfile(base_dir,'preprocessed', num2str(subj_info.subj_id));
            
            % Reject adjust-identified components
            base_epochs=pop_loadset('filepath',output_dir,...
                'filename',sprintf('%d.head_turns.epoch_reject.set',subj_info.subj_id));
            
            score=compute_score(subj_info, age, clusters, foi, wois, targets);
            
            bad_components=[];
            for comp_idx=1:size(base_epochs.icaweights,1)
                components_to_try=[bad_components comp_idx];
    
                % Reject adjust-identified components
                epochs = pop_subcomp(base_epochs, components_to_try);
                
                % Compute trial TF (not baseline-corrected)
                std_ersp(epochs, 'type', 'ersp',...
                    'trialindices', [1:epochs.trials], 'cycles', 0,...
                    'nfreqs', 100, 'ntimesout', 400,...
                    'freqs', [2 35], 'freqscale', 'linear',...
                    'baseline', NaN, 'winsize',128,...
                    'padratio', 16, 'channels', {epochs.chanlocs.labels}',...
                    'verbose', 'on', 'savefile', 'on', 'recompute', 'on',...
                    'savetrials', 'on');
                
                new_score=compute_score(subj_info, age, clusters, foi, wois, targets);
                
                if new_score>score
                    score=new_score;
                    bad_components(end+1)=comp_idx;
                end
            end
            
            epochs = pop_subcomp(base_epochs, bad_components);
            epochs = pop_saveset(epochs,'filepath',output_dir,...
                    'filename',sprintf('%d.head_turns.epoch_reject.set',subj_info.subj_id));
            
            precompute_ersps(subj_info, age);                  
        end
    end
end
end
        
function score=compute_score(subj_info, age, clusters, foi, wois, targets)
    cluster_erds=[];
    % 1=C3, 2=C4, 5=F3, 6=F4
    cluster_idxs=[1 2 5 6];
    stds=[20 20 30 30];
    
    for c=1:length(cluster_idxs)
        cluster_idx=cluster_idxs(c);
        
        % Load all subjects ERSPs
        [all_subjects_ersp,alltimes,allfreqs]=load_bc_ersps([subj_info.subj_id], age, ...
            [-1000 1000], [100 400], 'channels', clusters(cluster_idx).channels,...
            'baseline_type', 'condition', 'scale','abs');
        
        freq_idx=intersect(find(allfreqs>=foi(1)), find(allfreqs<=foi(2)));
        
        for w=1:size(wois,1)
            woi=wois(w,:);
            woi_idx=intersect(find(alltimes>=woi(1)), find(alltimes<=woi(2)));
            subj_ersps=all_subjects_ersp{1};
            subj_erds=squeeze(mean(mean(mean(subj_ersps(:,freq_idx,woi_idx,:),1),2),3));
            cond_median=median(subj_erds);
            r=iqr(subj_erds);
            subj_erds=subj_erds(find((subj_erds-cond_median)<=1.5*r));
            cluster_erds(w,c)=mean(subj_erds);
        end        
    end
    score=1;
    for j=1:size(wois,1)
        for c=1:length(cluster_idxs)
            score=score*exp(-(cluster_erds(j,c)-targets(j,c)).^2/(2*stds(c)^2));        
        end
    end
end
                
                
            