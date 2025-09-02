import os

class Block:
    def __init__(self):
        self.trials={}


class Trial:
    def __init__(self, start_frame, end_frame):
        self.fixations=[]
        self.start_frame=start_frame
        self.end_frame=end_frame


class Fixation:
    def __init__(self, code, start_frame, end_frame):
        self.code=code
        self.start_frame=start_frame
        self.end_frame=end_frame


def read_block(data_dir, subject_id, coder, block, trial_times, session=None):
    file_name=os.path.join(data_dir,'%d%s_block_%d.csv' % (subject_id, coder,block))
    if session is not None:
        file_name=os.path.join(data_dir,'%d-%d%s_block_%d.csv' % (subject_id, session, coder, block))
    block=None
    if os.path.exists(file_name):
        file=open(file_name,'r')
        block=Block()
        for line_idx, line in enumerate(file):
            if line_idx>0:
                cols=line.split(',')
                trial=int(float(cols[0]))
                direction=cols[1]
                start_frame=int(float(cols[2]))
                end_frame=int(float(cols[3]))
                if not trial in block.trials:
                    block.trials[trial]=Trial(trial_times[trial-1][0], trial_times[trial-1][1])
                block.trials[trial].fixations.append(Fixation(direction,start_frame,end_frame))
        file.close()
    return block


def read_coded_gaze_data(data_dir, subject_id, coder, session=None):
    block_trial_times=read_block_trial_times(data_dir, subject_id, coder, session=session)
    blocks={}
    for block, trial_times in block_trial_times.iteritems():
        block_data=read_block(data_dir, subject_id, coder, block, trial_times, session=session)
        if block_data is not None:
            blocks[block]=block_data
    return blocks


def read_block_trial_times(data_dir, subject_id, coder, session=None):
    block_trial_times={}
    file_name=os.path.join(data_dir,'%d%s_trial_times.csv' % (subject_id, coder))
    if session is not None:
        file_name=os.path.join(data_dir,'%d-%d%s_trial_times.csv' % (subject_id, session, coder))
    file=open(file_name,'r')
    for line_idx, line in enumerate(file):
        if line_idx>0:
            cols=line.split(',')
            block=int(float(cols[0]))
            trial=int(float(cols[1]))
            start_frame=int(float(cols[2]))
            end_frame=int(float(cols[3]))
            if not block in block_trial_times:
                block_trial_times[block]=[]
            block_trial_times[block].append([start_frame,end_frame])
    file.close()
    return block_trial_times

