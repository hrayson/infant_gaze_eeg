import os
from preferential_gaze.coded_pref_gaze import read_coded_gaze_data

def export_coded_pref_gaze_data(data_dir, subject_ids, coder, fpss):
    outfilename=os.path.join(data_dir, '%s.sds' % coder)
    outfile=open(outfilename,'w')
    outfile.write('Timed ($target = Left Centre Right Other Offscreen);\n')
    for subject_id,fps in zip(subject_ids,fpss):
        blocks=read_coded_gaze_data(data_dir, subject_id, coder)

        current_stream=[]

        for block_idx, block in blocks.iteritems():
            for trial_idx, trial in block.trials.iteritems():

                for fixation_idx, fixation in enumerate(trial.fixations):
                    start_time_ms=fixation.start_frame/fps*1000.0
                    end_time_ms=fixation.end_frame/fps*1000.0
                    current_stream.append((start_time_ms, end_time_ms, fixation.code))

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

                if code=='Ambig/Other':
                    code='Other'

                outfile.write('%s,%d:%d.%03d-%d:%d.%03d\n' % (code, start_time_min, start_time_s, start_time_ms,
                                                              next_time_min, next_time_s, next_time_ms))

        outfile.write('/\n')
    outfile.close()


if __name__=='__main__':
    output_dir='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/6m/v2'
    subj_ids=[149,130,108]
    fpss=[29.97,29.97,29.97]
    export_coded_pref_gaze_data(output_dir, subj_ids, 'HR', fpss)
    export_coded_pref_gaze_data(output_dir, subj_ids, 'IA', fpss)

    output_dir='/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/9m/v2'
    subj_ids=[111,113,129]
    fpss=[29.97,29.97,29.97]
    export_coded_pref_gaze_data(output_dir, subj_ids, 'HR', fpss)
    export_coded_pref_gaze_data(output_dir, subj_ids, 'IA', fpss)