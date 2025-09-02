import numpy as np
import os
import operator
from coded_eeg.coded_eeg_gaze import read_coded_gaze_data


def export_coded_gaze_data(output_dir, age, subject_ids, coder, fpss, excluded_trials, combine_conseq=False):
    outfilename=os.path.join(output_dir, age, '%s.sds' % coder)
    outfile=open(outfilename,'w')
    outfile.write('Timed ($target = Left Centre Right Offscreen);\n')

    for subject_id,fps,subj_excluded_trials in zip(subject_ids,fpss,excluded_trials):

        trials=read_coded_gaze_data(subject_id, age, coder, fps, subj_excluded_trials=subj_excluded_trials)

        current_stream=[]

        for trial in trials:
            trial_stream=[]
            trial_start_time_ms=trial.start_frame/fps*1000.0

            #trial_end_time_ms=trial.end_frame/fps*1000.0
            trial_end_time_ms=trial_start_time_ms+3000
            next_time_ms=trial_end_time_ms
            if len(trial.movements):
                next_time_ms=trial.movements[0].start_frame/fps*1000.0

            if trial_start_time_ms<next_time_ms:
                trial_stream.append((trial_start_time_ms, next_time_ms, trial.init_code.title()))

            for movement_idx, movement in enumerate(trial.movements):
                start_time_ms=movement.start_frame/fps*1000.0
                end_time_ms=trial.end_frame/fps*1000.0
                if movement_idx<len(trial.movements)-1:
                    end_time_ms=trial.movements[movement_idx+1].start_frame/fps*1000.0
                if trial_start_time_ms<=start_time_ms<=trial_end_time_ms or trial_start_time_ms<=end_time_ms<=trial_end_time_ms:
                    code='Offscreen'
                    if 'left' in movement.code:
                        code='Left'
                    elif 'right' in movement.code:
                        code='Right'
                    elif 'centre' in movement.code:
                        code='Centre'
                    trial_stream.append((start_time_ms, end_time_ms, code))
            trial_stream[-1]=(trial_stream[-1][0], trial_end_time_ms, trial_stream[-1][2])
            if combine_conseq:
                nonconseq_stream=[]
                while len(trial_stream):
                    num_to_del=1
                    (start_time_ms, final_end_time_ms, code)=trial_stream[0]

                    for m_idx,(next_start_ms, next_end_ms, next_code) in enumerate(trial_stream):
                        if m_idx>0:
                            if code==next_code:
                                num_to_del+=1
                                final_end_time_ms=next_end_ms
                            else:
                                break
                    nonconseq_stream.append((start_time_ms, final_end_time_ms, code))
                    trial_stream=trial_stream[num_to_del:]
                if len(nonconseq_stream):
                    current_stream.extend(nonconseq_stream)
            else:
                current_stream.extend(trial_stream)

        sorted_stream=sorted(current_stream, key=lambda tup: tup[0])
        for idx,(start_time_ms,next_time_ms,code) in enumerate(sorted_stream):
            if start_time_ms<next_time_ms:
                start_time_min=int(start_time_ms/(1000.0*60.0))
                start_time_ms=int(start_time_ms-start_time_min*(1000.0*60.0))
                start_time_s=int(start_time_ms/1000.0)
                start_time_ms=int(start_time_ms-start_time_s*1000.0)

                next_time_min=int(next_time_ms/(1000.0*60.0))
                next_time_ms=int(next_time_ms-next_time_min*(1000.0*60.0))
                next_time_s=int(next_time_ms/1000.0)
                next_time_ms=int(next_time_ms-next_time_s*1000.0)

                outfile.write('%s,%d:%d.%03d-%d:%d.%03d\n' % (code, start_time_min, start_time_s, start_time_ms,
                                                              next_time_min, next_time_s, next_time_ms))

        outfile.write('/\n')
    outfile.close()

if __name__=='__main__':
    export_coded_gaze_data('../../coded_eeg/', '6m', [116,123,141], 'HR',[29.97,29.97,29.97], [[],[],[]])
    export_coded_gaze_data('../../coded_eeg/', '6m', [116,123,141], 'IA',[29.97,29.97,29.97], [[],[],[]])

    export_coded_gaze_data('../../coded_eeg/', '9m', [118,131,138], 'HR',[29.97,29.97,29.97], [[],[],[]])
    export_coded_gaze_data('../../coded_eeg/', '9m', [118,131,138], 'IA',[29.97,29.97,29.97], [[],[],[]])

