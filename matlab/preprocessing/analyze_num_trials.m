function analyze_num_trials(conditions, time_zero_event)

base_dir=fullfile('/data','infant_gaze_eeg', '6m');
d = dir(fullfile(base_dir, 'preprocessed'));
isub = [d(:).isdir]; % returns logical vector
subj_ids = {d(isub).name}';
subj_ids(ismember(subj_ids,{'.','..'})) = [];

sixm_with_headturn_trials=zeros(1,length(subj_ids));
sixm_without_headturn_trials=zeros(1,length(subj_ids));

for i=1:length(subj_ids)
    subj_id=str2num(subj_ids{i});
    subj_dir=fullfile(base_dir,'preprocessed', num2str(subj_id));
    if exist(subj_dir,'dir')==7
        cond_trials_with_headturns=zeros(1,length(conditions));
        cond_trials_without_headturns=zeros(1,length(conditions));
        for k=1:length(conditions)
            condition=conditions{k};
            file_name=fullfile(subj_dir, sprintf('%d.%s.%s.set', subj_id, time_zero_event, condition));
            if exist(file_name, 'file') == 2
                data=pop_loadset(file_name);
                cond_trials_with_headturns(k)=data.trials;
            end
            file_name=fullfile(subj_dir, sprintf('%d.%s.%s.no_headturn.set', subj_id, time_zero_event, condition));
            if exist(file_name, 'file') == 2
                data=pop_loadset(file_name);
                cond_trials_without_headturns(k)=data.trials;
            end
        end
        sixm_with_headturn_trials(i)=min(cond_trials_with_headturns);
        sixm_without_headturn_trials(i)=min(cond_trials_without_headturns);
    end
end


base_dir=fullfile('/data','infant_gaze_eeg', '9m');
d = dir(fullfile(base_dir, 'preprocessed'));
isub = [d(:).isdir]; % returns logical vector
subj_ids = {d(isub).name}';
subj_ids(ismember(subj_ids,{'.','..'})) = [];

ninem_with_headturn_trials=zeros(1,length(subj_ids));
ninem_without_headturn_trials=zeros(1,length(subj_ids));

for i=1:length(subj_ids)
    subj_id=str2num(subj_ids{i});
    subj_dir=fullfile(base_dir,'preprocessed', num2str(subj_id));
    if exist(subj_dir,'dir')==7
        cond_trials_with_headturns=zeros(1,length(conditions));
        cond_trials_without_headturns=zeros(1,length(conditions));
        for k=1:length(conditions)
            condition=conditions{k};
            file_name=fullfile(subj_dir, sprintf('%d.%s.%s.set', subj_id, time_zero_event, condition));
            if exist(file_name, 'file') == 2
                data=pop_loadset(file_name);
                cond_trials_with_headturns(k)=data.trials;
            end
            file_name=fullfile(subj_dir, sprintf('%d.%s.%s.no_headturn.set', subj_id, time_zero_event, condition));
            if exist(file_name, 'file') == 2
                data=pop_loadset(file_name);
                cond_trials_without_headturns(k)=data.trials;
            end
        end
        ninem_with_headturn_trials(i)=min(cond_trials_with_headturns);
        ninem_without_headturn_trials(i)=min(cond_trials_without_headturns);
    end
end

bins=[0:max([max(sixm_with_headturn_trials) max(ninem_with_headturn_trials)])];
figure();
subplot(2,2,1);
[n,xout]=hist(sixm_with_headturn_trials,bins);
h=bar(xout,n);
ylim([0 5]);
xlabel('Trials/Condition');
ylabel('Num 6m Subjects');
title('With headturns');
subplot(2,2,2);
[n,xout]=hist(sixm_without_headturn_trials,bins);
h=bar(xout,n);
ylim([0 5]);
xlabel('Trials/Condition');
ylabel('Num 6m Subjects');
title('Without headturns');
subplot(2,2,3);
[n,xout]=hist(ninem_with_headturn_trials,bins);
h=bar(xout,n);
ylim([0 5]);
xlabel('Trials/Condition');
ylabel('Num 9m Subjects');
title('With headturns');
subplot(2,2,4);
[n,xout]=hist(ninem_without_headturn_trials,bins);
h=bar(xout,n);
ylim([0 5]);
xlabel('Trials/Condition');
ylabel('Num 9m Subjects');
title('Without headturns');
