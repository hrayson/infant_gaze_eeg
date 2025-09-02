import os

class Trial:
    def __init__(self, start_frame, init_code, direction=None, congruence=None, shuffled=None):
        self.start_frame=start_frame
        self.init_code=init_code
        self.direction=direction
        self.congruence=congruence
        self.shuffled=shuffled
        self.movements=[]

    def num_movements(self, start=None, end=None):
        num_movements=0
        for movement in self.movements:
            if (start is None or start <= movement.start_frame) and (end is None or movement.start_frame < end):
                num_movements+=1
        return num_movements

    def num_head_turns(self, start=None, end=None):
        num_head_turns=0
        for movement in self.movements:
            #EEG analysised from -.5 to 1.5s around mov1
            if (start is None or start <= movement.start_frame) and (end is None or movement.start_frame < end) and movement.type=='head turn':
                num_head_turns+=1
        return num_head_turns

    def time_onscreen(self, fps, start=None, end=None):
        frames_onscreen=0.0
        last_dir=self.init_code
        last_frame=self.end_frame-3*fps
        for movement in self.movements:
            if (start is None or start <= movement.start_frame) and (end is None or movement.start_frame < end):
                if not last_dir=='offscreen':
                    frames_onscreen+=(movement.start_frame-last_frame)
                last_frame=movement.end_frame
            last_dir=movement.dir
        if not last_dir=='offscreen':
            frames_onscreen+=(self.end_frame-last_frame)
        time_onscreen=frames_onscreen/fps
        return time_onscreen

    def follow_first(self, start=None):
        for pattern_idx,target in enumerate(self.pattern):
            if start is None or start <= self.pattern_time[pattern_idx]:
                if target=='face':
                    continue
                elif self.congruence and target=='target':
                    return True
                elif not self.congruence and target=='antitarget':
                    return True
                else:
                    return False
        return False


    def antifollow_first(self, start=None):
        for pattern_idx,target in enumerate(self.pattern):
            if start is None or start <= self.pattern_time[pattern_idx]:
                if target=='face':
                    continue
                elif self.congruence and target=='antitarget':
                    return True
                elif not self.congruence and target=='target':
                    return True
                else:
                    return False
        return False

    def face_first(self, start=None):
        for pattern_idx,target in enumerate(self.pattern):
            if start is None or start <= self.pattern_time[pattern_idx]:
                if target=='face':
                    return True
                else:
                    return False
        return False

    def num_follows(self, start=None, end=None):
        num_follows=0.0
        for pattern_idx,target in enumerate(self.pattern):
            if (start is None or start <= self.pattern_time[pattern_idx]) and (end is None or self.pattern_time[pattern_idx] < end):
                if self.congruence and target=='target':
                    num_follows+=1.0
                elif not self.congruence and target=='antitarget':
                    num_follows+=1.0
        return num_follows

    def num_anti_follows(self, start=None, end=None):
        num_anti_follows=0.0
        for pattern_idx,target in enumerate(self.pattern):
            if (start is None or start <= self.pattern_time[pattern_idx]) and (end is None or self.pattern_time[pattern_idx] < end):
                if self.congruence and target=='antitarget':
                    num_anti_follows+=1.0
                elif not self.congruence and target=='target':
                    num_anti_follows+=1.0
        return num_anti_follows

    def num_face(self, start=None, end=None):
        n=0.0
        for pattern_idx,target in enumerate(self.pattern):
            if (start is None or start <= self.pattern_time[pattern_idx]) and (end is None or self.pattern_time[pattern_idx] < end):
                if target=='face':
                    n+=1.0
        return n

    def process(self):
        self.gaze_highlighted=self.init_code==self.direction
        self.gaze_face=False
        self.gaze_highlighted_back=False
        self.gaze_unhighlighted_back=False
        self.pattern=[]
        self.pattern_time=[]
        if self.init_code==self.direction:
            self.pattern=['target']
        elif self.init_code=='centre':
            self.pattern=['face']
        elif self.init_code=='offscreen':
            self.pattern=['offcreen']
        else:
            self.pattern=['antitarget']
        self.pattern_time.append(self.start_frame)

        for movement_idx, movement in enumerate(self.movements):
            movement_pat='antitarget'
            if movement.dir==self.direction:
                movement_pat='target'
            elif movement.dir=='centre':
                movement_pat='face'
            elif movement.dir=='offscreen':
                movement_pat='offscreen'
            if len(self.pattern)==0 or not movement_pat==self.pattern[-1]:
                self.pattern.append(movement_pat)
                self.pattern_time.append(movement.start_frame)
            if not self.gaze_highlighted and movement.dir==self.direction:
                self.gaze_highlighted=True
            if self.gaze_highlighted and movement.dir=='centre':
                self.gaze_face=True
            if self.gaze_face and not movement.dir=='centre':
                if movement.dir==self.direction:
                    self.gaze_highlighted_back=True
                if not(movement.dir==self.direction) and not(movement.dir=='offscreen'):
                    self.gaze_unhighlighted_back=True
        self.pattern_str=','.join(self.pattern)

class Movement:
    def __init__(self, start_frame, end_frame, code):
        self.start_frame=start_frame
        self.end_frame=end_frame
        self.code=code
        self.dir='offscreen'
        if 'left' in self.code:
            self.dir='left'
        elif 'right' in self.code:
            self.dir='right'
        elif 'centre' in self.code:
            self.dir='centre'
        self.type=''
        if 'Saccade' in self.code:
            self.type='saccade'
        elif 'Head turn' in self.code:
            self.type='head turn'


def read_coded_gaze_session(init_dir_file, movement_file, fps, trial_times, subj_excluded_trials=None):
    trials = []
    for line_idx, line in enumerate(init_dir_file):
        line = line.replace('\n', '')
        if line_idx > 0 and (subj_excluded_trials is None or (line_idx-1) not in subj_excluded_trials):
            cols=line.replace('\r\n','').split(',')
            trial=Trial(int(float(cols[1])), cols[2])
            if len(cols) > 3:
                gaze = None
                congruence = None
                shuf = None
                if cols[3] == 'l':
                    gaze = 'left'
                elif cols[3] == 'r':
                    gaze = 'right'
                if cols[4] == 'cong':
                    congruence = 'congruent'
                elif cols[4] == 'inco':
                    congruence = 'incongruent'
                if cols[5]=='0':
                    shuf=False
                elif cols[5]=='1':
                    shuf=True

                trial=Trial(int(cols[1]), cols[2], direction=gaze, congruence=congruence,
                    shuffled=shuf)
            trials.append(trial)
    for trial_idx, trial in enumerate(trials):
        trial.end_frame=trial_times[trial_idx][1]

    init_dir_file.close()
    for line_idx, line in enumerate(movement_file):
        if line_idx > 0:
            cols = line.split(',')
            if len(cols[0]):
                movement = cols[1]
                start_frame = int(float(cols[2]))
                end_frame = int(float(cols[3]))
                for trial_idx,trial in enumerate(trials):
                    if trial.start_frame <= start_frame <= trial.end_frame:
                        trial.movements.append(Movement(start_frame, end_frame, movement))
    movement_file.close()

    for trial in trials:
        trial.process()
    return trials

def read_coded_gaze_data(subject_id, age, coder, fps, subj_excluded_trials=None, session=None):
    trials=[]
    trial_times=read_trial_times(subject_id, age, session=session)
    if session is None:
        init_dir_file = open(os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), '%d%s%s-initialdirectioncoding.csv' %
                                                                                   (subject_id, coder, age)))
        movement_file = open(os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), '%d%s%s-movementcoding.csv' %
                                                                                   (subject_id, coder, age)))
        trials.extend(read_coded_gaze_session(init_dir_file, movement_file, fps, trial_times, subj_excluded_trials=subj_excluded_trials))
    else:
        init_dir_file = open(os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), '%d%s%s-initialdirectioncoding-%d.csv' %
                                                                                                      (subject_id, coder, age, session)))
        movement_file = open(os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), '%d%s%s-movementcoding-%d.csv' %
                                                                                                      (subject_id, coder, age, session)))
        trials.extend(read_coded_gaze_session(init_dir_file, movement_file, fps, trial_times, subj_excluded_trials=subj_excluded_trials))

    return trials

def read_trial_times(subject_id, age, session=None):
    trial_times=[]
    file_name=os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), 'trial_times.csv')
    if session is not None:
        file_name=os.path.join('/data/infant_gaze_eeg/%s/raw/%d/EEG/' % (age, subject_id), 'trial_times-%d.csv' % session)
    file=open(file_name,'r')
    for line_idx, line in enumerate(file):
        if line_idx>0:
            cols=line.split(',')
            trial_times.append((int(cols[1]),int(cols[2])))
    file.close()
    return trial_times