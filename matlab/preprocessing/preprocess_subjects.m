function preprocess_subjects(subjects)

% Iterate over subject IDs and call preprocess_subject on each
for idx=1:length(subjects)
    preprocess_subject(subjects(idx));
end