function data=add_event_codes(base_dir, subj_id, data)

data=pop_editeventfield(data,'shuf',fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_shuf.evt', subj_id)));
data=pop_editeventfield(data,'attn',fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_attn.evt', subj_id)));
data=pop_editeventfield(data,'actr',fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_actr.evt', subj_id)));
data=pop_editeventfield(data,'code',fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_code.evt', subj_id)));
data=pop_editeventfield(data,'gaze',fullfile(base_dir,'raw',num2str(subj_id),'EEG',sprintf('%d-events_gaze.evt', subj_id)));