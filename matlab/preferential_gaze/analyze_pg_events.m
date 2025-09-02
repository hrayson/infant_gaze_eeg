function analyze_pg_events(subjects)

sixm_block_2_trials_seen=[];
sixm_block_3_trials_seen=[];
sixm_block_4_trials_seen=[];

ninem_block_2_trials_seen=[];
ninem_block_3_trials_seen=[];
ninem_block_4_trials_seen=[];

figure();
title('6m');
sixm_ax=gca();
hold all;

figure();
title('9m');
ninem_ax=gca();
hold all;

% Iterate through each subject
for subj_idx=1:length(subjects)
    subj_info=subjects(subj_idx);

    % Iterate through each age
    for age_idx=1:length(subj_info.ages)
        age=subj_info.ages{age_idx};
        
        % 106 - skip 1st run - didn't see any head turn movies and
        % PG restarted in second run
        if subj_info.subj_id==106 && strcmp(age,'6m')
            continue;
        end
        
        num_runs=subj_info.num_runs(age_idx);
        subj_trials_seen=[];
        
        % If more than one run
        if num_runs>1
            block_offset=0;
            total_trials_seen=0;
            for run_num=1:num_runs                               
                
                [pg_blocks,eeg_trials_seen]=read_pg_events(subj_info.subj_id, age, 'run', run_num);
                for block_num=1:length(pg_blocks)
                    % subj 105 6m - skip 1st block of second run
                    if subj_info.subj_id==105 && strcmp(age,'6m') && run_num==2 && block_num==1
                        continue
                    end
                    if strcmp(age,'6m')
                        if block_offset+block_num==2
                            sixm_block_2_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        elseif block_offset+block_num==3
                            sixm_block_3_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        elseif block_offset+block_num==4
                            sixm_block_4_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        end
                    else
                        if block_offset+block_num==2
                            ninem_block_2_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        elseif block_offset+block_num==3
                            ninem_block_3_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        elseif block_offset+block_num==4
                            ninem_block_4_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                        end
                    end
                    subj_trials_seen(end+1)=total_trials_seen+pg_blocks(block_num).eeg_trials_seen;
                end
                total_trials_seen=total_trials_seen+eeg_trials_seen;
                block_offset=block_offset+length(pg_blocks);                
                % subj 105 6m - skip 1st block of second run
                if subj_info.subj_id==105 && strcmp(age,'6m') && run_num==1
                    block_offset=block_offset-1;
                end
            end
        else
            [pg_blocks,eeg_trials_seen]=read_pg_events(subj_info.subj_id, age);
            for block_num=1:length(pg_blocks)
                if strcmp(age,'6m')
                    if block_num==2
                        sixm_block_2_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    elseif block_num==3
                        sixm_block_3_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    elseif block_num==4
                        sixm_block_4_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    end
                else
                    if block_num==2
                        ninem_block_2_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    elseif block_num==3
                        ninem_block_3_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    elseif block_num==4
                        ninem_block_4_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
                    end
                end
                subj_trials_seen(end+1)=pg_blocks(block_num).eeg_trials_seen;
            end
        end
        if strcmp(age,'6m')
            plot(sixm_ax,subj_trials_seen);
        else
            plot(ninem_ax,subj_trials_seen);
        end
    end
end
xlabel('Block');
ylabel('Trials Seen');

figure();
title('6m');
hold all;
bins=[0:50];
[n,xout]=hist(sixm_block_2_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','b');
[n,xout]=hist(sixm_block_3_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','r');
[n,xout]=hist(sixm_block_4_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','g');
legend('Block 2','Block 3','Block 4');
xlabel('Trials Seen');
ylabel('Number of Subjects');

figure();
title('9m');
hold all;
bins=[0:50];
[n,xout]=hist(ninem_block_2_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','b');
[n,xout]=hist(ninem_block_3_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','r');
[n,xout]=hist(ninem_block_4_trials_seen,bins);
h=bar(xout,n);
set(h,'FaceColor','g');
legend('Block 2','Block 3','Block 4');
xlabel('Trials Seen');
ylabel('Number of Subjects');

