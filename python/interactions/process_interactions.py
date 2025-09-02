import os
import numpy as np
import matplotlib.pyplot as plt

infant_targets=['Head turn','Per Toy Right','Right Toy','Front Toy Right','Front Toy Left','Left Toy',
                'Per Toy Left','Mother face','Mother hand','Mother body','Own hand','Own foot','Own body','Camera',
                'Highchair','Other/ambig']
infant_horiz_dirs=['Back','Back Right','Far Right','Mid Right','Near Right','Centre','Near Left','Mid Left',
                   'Far Left','Back Left']
infant_vert_dirs=['Up','Middle','Down']
mother_targets=['Head turn','Rear Toy Right','Per Toy Right','Front Toy Right','Front Toy Left','Per Toy Left',
                'Rear Toy Left','Infant face','Infant hand','Infant foot','Infant body','Own hand','Own body',
                'Camera','Highchair','Other/ambig']
mother_horiz_dirs=['Back','Back Right','Far Right','Mid Right','Near Right','Centre','Near Left','Mid Left',
                   'Far Left','Back Left']
mother_vert_dirs=['Up','Middle','Down']

mother_visible_directions={
    '3m': ['Mid Right','Near Right','Centre','Near Left','Mid Left'], # periph1
    #'3m': ['Near Right','Centre','Near Left'], # periph2
    #'3m': ['Centre'], # periph3
    '6m': ['Mid Right','Near Right','Centre','Near Left','Mid Left'], # periph1
    #'6m': ['Near Right','Centre','Near Left'], # periph2
    #'6m': ['Centre'], #periph3
}
interval_threshold_seconds=3
#interval_threshold_seconds=5

infant_visible_directions=['Near Right','Centre','Near Left']

def mother_visible(age, infant_target, infant_horiz_dir):
    if infant_horiz_dir in mother_visible_directions[age]:
        return True
    return False

def infant_visible(mother_target, mother_horiz_dir):
    if mother_horiz_dir in ['Mid Right','Near Right','Centre','Near Left','Mid Left']:
        return True
    return False

def convert_infant_to_mother_target(infant_target):
    """
    Converts infant target to equivalent mother target
    """
    if infant_target=='Per Toy Right':
        return 'Front Toy Left'
    elif infant_target=='Right Toy':
        return 'Per Toy Left'
    elif infant_target=='Front Toy Right':
        return 'Rear Toy Left'
    elif infant_target=='Front Toy Left':
        return 'Rear Toy Right'
    elif infant_target=='Left Toy':
        return 'Per Toy Right'
    elif infant_target=='Per Toy Left':
        return 'Front Toy Right'
    elif infant_target=='Mother hand':
        return 'Own hand'
    elif infant_target=='Mother body':
        return 'Own body'
    elif infant_target=='Own hand':
        return 'Infant hand'
    elif infant_target=='Own foot':
        return 'Infant foot'
    elif infant_target=='Own body':
        return 'Infant body'
    elif infant_target=='Camera':
        return 'Camera'
    elif infant_target=='Highchair':
        return 'Highchair'
    elif infant_target=='Other/ambig':
        return 'Other/ambig'
    return None


def convert_mother_to_infant_target(mother_target):
    """
    Converts mother target to equivalent infant targt
    """
    if mother_target=='Front Toy Left':
        return 'Per Toy Right'
    elif mother_target=='Per Toy Left':
        return 'Right Toy'
    elif mother_target=='Rear Toy Left':
        return 'Front Toy Right'
    elif mother_target=='Rear Toy Right':
        return 'Front Toy Left'
    elif mother_target=='Per Toy Right':
        return 'Left Toy'
    elif mother_target=='Front Toy Right':
        return 'Per Toy Left'
    elif mother_target=='Own hand':
        return 'Mother hand'
    elif mother_target=='Own body':
        return 'Mother body'
    elif mother_target=='Infant hand':
        return 'Own hand'
    elif mother_target=='Infant foot':
        return 'Own foot'
    elif mother_target=='Infant body':
        return 'Own body'
    elif mother_target=='Camera':
        return 'Camera'
    elif mother_target=='Highchair':
        return 'Highchair'
    elif mother_target=='Other/ambig':
        return 'Other/ambig'
    return None


def targets_equal(infant_target, infant_horiz_dir, infant_vert_dir, mother_target, mother_horiz_dir, mother_vert_dir):
    """
    Checks if infant and mother are looking at the same target
    """
    # Not looking at same thing if or both is turning their head
    if infant_target=='Head turn' or mother_target=='Head turn':
        return False
    # If target is camera or Other/amgib - need to make sure directions are equivalent
    elif (infant_target=='Camera' and mother_target=='Camera') or\
         (infant_target=='Other/ambig' and mother_target=='Other/ambig'):
        return directions_equal(infant_horiz_dir, infant_vert_dir, mother_horiz_dir, mother_vert_dir)
    # Otherwise check that target is the same
    else:
        req_mother_target=convert_infant_to_mother_target(infant_target)
        return mother_target==req_mother_target


def convert_infant_to_mother_dir(infant_horiz_dir, infant_vert_dir):
    """
    Converts infant horiz and vert directions to equivalent mother horiz and vert directions
    """
    # If infant looking centre, down, equivalent mother direction is center, down
    if infant_vert_dir=='Down' and infant_horiz_dir=='Centre':
        return 'Centre','Down'
    # Otherwise convert horiz direction and return same vert direction
    elif infant_horiz_dir=='Back':
        return 'Centre', infant_vert_dir
    elif infant_horiz_dir=='Back Right':
        return 'Near Left', infant_vert_dir
    elif infant_horiz_dir=='Far Right':
        return 'Mid Left', infant_vert_dir
    elif infant_horiz_dir=='Mid Right':
        return 'Far Left', infant_vert_dir
    elif infant_horiz_dir=='Near Right':
        return 'Back Left', infant_vert_dir
    elif infant_horiz_dir=='Centre':
        return 'Back', infant_vert_dir
    elif infant_horiz_dir=='Near Left':
        return 'Back Right', infant_vert_dir
    elif infant_horiz_dir=='Mid Left':
        return 'Far Right', infant_vert_dir
    elif infant_horiz_dir=='Far Left':
        return 'Mid Right', infant_vert_dir
    elif infant_horiz_dir=='Back Left':
        return 'Near Right', infant_vert_dir
    return None,None


def convert_mother_to_infant_dir(mother_horiz_dir, mother_vert_dir):
    """
    Converts mother horiz and vert directions to equivalent infant horiz and vert directions
    """
    # If mother looking centre, down, equivalent infant direction is center, down
    if mother_vert_dir=='Down' and mother_horiz_dir=='Centre':
        return 'Centre','Down'
    # Otherwise convert horiz direction and return same vert direction
    elif mother_horiz_dir=='Centre':
        return 'Back', mother_vert_dir
    elif mother_horiz_dir=='Near Left':
        return 'Back Right', mother_vert_dir
    elif mother_horiz_dir=='Mid Left':
        return 'Far Right', mother_vert_dir
    elif mother_horiz_dir=='Far Left':
        return 'Mid Right', mother_vert_dir
    elif mother_horiz_dir=='Back Left':
        return 'Near Right', mother_vert_dir
    elif mother_horiz_dir=='Back':
        return 'Centre', mother_vert_dir
    elif mother_horiz_dir=='Back Right':
        return 'Near Left', mother_vert_dir
    elif mother_horiz_dir=='Far Right':
        return 'Mid Left', mother_vert_dir
    elif mother_horiz_dir=='Mid Right':
        return 'Far Left', mother_vert_dir
    elif mother_horiz_dir=='Near Right':
        return 'Back Left', mother_vert_dir
    return None,None


def directions_equal(infant_horiz_dir, infant_vert_dir, mother_horiz_dir, mother_vert_dir):
    """
    Check if infant and mother gaze directions are equivalent
    """
    if infant_horiz_dir is None and infant_vert_dir is None and mother_horiz_dir is None and mother_vert_dir is None:
        return True
    req_mother_horiz_dir, req_mother_vert_dir = convert_infant_to_mother_dir(infant_horiz_dir, infant_vert_dir)
    return mother_horiz_dir==req_mother_horiz_dir and mother_vert_dir==req_mother_vert_dir


class InteractionRun:
    def __init__(self, data_dir, subj_id, coder, age, visit_num, run_num=None):
        """
        One run from a single interaction session with a subject
        """
        self.subj_id=subj_id
        self.coder=coder
        self.age=age
        self.visit_num=visit_num
        self.run_num=run_num

        # File name includes run number if this session has multiple runs
        self.file_name=''
        if run_num is None:
            self.file_name=os.path.join(data_dir,'%d%s%d_derived.csv' % (subj_id,coder,visit_num))
        else:
            self.file_name=os.path.join(data_dir,'%d' % subj_id,'%d%s%d_%d_derived.csv' %
                                                                (subj_id,coder,visit_num,run_num))

        # Total number of frames in this run
        self.num_frames=0
        # Start and end frames
        self.start_frame=0
        self.end_frame=0

        # Level 1 matrices
        self.infant_target_mat=np.zeros((len(infant_targets),self.num_frames))
        self.infant_horiz_dir_mat=np.zeros((len(infant_targets),self.num_frames))
        self.infant_vert_dir_mat=np.zeros((len(infant_targets),self.num_frames))
        self.mother_target_mat=np.zeros((len(mother_targets),self.num_frames))
        self.mother_horiz_dir_mat=np.zeros((len(mother_targets),self.num_frames))
        self.mother_vert_dir_mat=np.zeros((len(mother_targets),self.num_frames))

        file=open(self.file_name,'r')

        # Current group categories belong to
        current_group=None

        # Read each line in the file
        for l in file:
            lines=l.split('\n')
            for line in lines:
                cols=line.replace('\r','').split(',')

                if len(cols)>1:

                    # First line - get number of frames
                    if cols[0]=='1':
                        frames=cols[2:]
                        self.start_frame=int(frames[0])
                        self.end_frame=int(frames[-1])
                        self.num_frames=len(frames)

                        # Initialize category matrices
                        self.infant_target_mat=np.zeros((len(infant_targets),self.num_frames))
                        self.infant_horiz_dir_mat=np.zeros((len(infant_targets),self.num_frames))
                        self.infant_vert_dir_mat=np.zeros((len(infant_targets),self.num_frames))
                        self.mother_target_mat=np.zeros((len(mother_targets),self.num_frames))
                        self.mother_horiz_dir_mat=np.zeros((len(mother_targets),self.num_frames))
                        self.mother_vert_dir_mat=np.zeros((len(mother_targets),self.num_frames))

                    # Set current group
                    elif cols[0]=='Infant' or cols[0]=='Mother':
                        current_group=cols[0]

                    # Read category and frames
                    elif len(cols[1])>0:
                        # Get category name
                        event_name=cols[1]

                        # Fill infant matrices
                        if current_group=='Infant':

                            # Fill infant target
                            if event_name in infant_targets:
                                evt_idx=infant_targets.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.infant_target_mat[evt_idx,col_idx-2]=1

                            # Fill infant horiz direction
                            elif event_name in infant_horiz_dirs:
                                evt_idx=infant_horiz_dirs.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.infant_horiz_dir_mat[evt_idx,col_idx-2]=1

                            # Fill infant vertical direction
                            elif event_name in infant_vert_dirs:
                                evt_idx=infant_vert_dirs.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.infant_vert_dir_mat[evt_idx,col_idx-2]=1

                        # Fill mother matrices
                        elif current_group=='Mother':

                            #  Fill mother target
                            if event_name in mother_targets:
                                evt_idx=mother_targets.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.mother_target_mat[evt_idx,col_idx-2]=1

                            # Fill mother horiz direction
                            elif event_name in mother_horiz_dirs:
                                evt_idx=mother_horiz_dirs.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.mother_horiz_dir_mat[evt_idx,col_idx-2]=1

                            # Fill mother vertical direction
                            elif event_name in mother_vert_dirs:
                                evt_idx=mother_vert_dirs.index(event_name)
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx].replace(' ','')=='x':
                                        self.mother_vert_dir_mat[evt_idx,col_idx-2]=1

        file.close()

        # Fill empty infant targets with head turns
        target_sum=np.sum(self.infant_target_mat,axis=0)
        z=np.where(target_sum==0)[0]
        if len(z)>0:
            self.infant_target_mat[0,z]=1
            self.infant_horiz_dir_mat[:,z]=0
            self.infant_vert_dir_mat[:,z]=0
        # Fill empty mother targets with head turns
        target_sum=np.sum(self.mother_target_mat,axis=0)
        z=np.where(target_sum==0)[0]
        if len(z)>0:
            self.mother_target_mat[0,z]=1
            self.mother_horiz_dir_mat[:,z]=0
            self.mother_vert_dir_mat[:,z]=0


    def get_infant_target_and_dir(self, frame_idx):
        """
        Get infant target and gaze direction in the given frame
        """
        # Get infant target
        infant_target=infant_targets[np.where(self.infant_target_mat[:,frame_idx]==1)[0][0]]

        # Get horiz direction if it is set
        infant_horiz_dir=None
        nz_idx=np.where(self.infant_horiz_dir_mat[:,frame_idx]==1)[0]
        if len(nz_idx)>0:
            infant_horiz_dir=infant_horiz_dirs[nz_idx[0]]

        # Get vertical direction if it is set
        infant_vert_dir=None
        nz_idx=np.where(self.infant_vert_dir_mat[:,frame_idx]==1)[0]
        if len(nz_idx)>0:
            infant_vert_dir=infant_vert_dirs[nz_idx[0]]

        return infant_target, infant_horiz_dir, infant_vert_dir


    def get_mother_target_and_dir(self, frame_idx):
        """
        Get mother target and gaze direction in the given frame
        """
        # Get mother target
        mother_target=mother_targets[np.where(self.mother_target_mat[:,frame_idx]==1)[0][0]]

        # Get horiz direction if it is set
        mother_horiz_dir=None
        nz_idx=np.where(self.mother_horiz_dir_mat[:,frame_idx]==1)[0]
        if len(nz_idx)>0:
            mother_horiz_dir=mother_horiz_dirs[nz_idx[0]]

        # Get vertical direction if it is set
        mother_vert_dir=None
        nz_idx=np.where(self.mother_vert_dir_mat[:,frame_idx]==1)[0]
        if len(nz_idx)>0:
            mother_vert_dir=mother_vert_dirs[nz_idx[0]]

        return mother_target, mother_horiz_dir, mother_vert_dir


    def get_next_infant_gaze_shift_time(self, frame_idx, target=None, horiz_dir=None, vert_dir=None):
        """
        Get the time that the infant stops looking at the current target
        target, horiz_dir, vert_dir - if set, get the time that the infant at this target in this direction
        """
        next_frame_idx=-1
        # Get current target
        (current_infant_target, current_infant_horiz_dir, current_infant_vert_dir)=self.get_infant_target_and_dir(frame_idx)
        current_infant_target_idx=infant_targets.index(current_infant_target)
        current_infant_horiz_dir_idx=-1
        if current_infant_horiz_dir is not None:
            current_infant_horiz_dir_idx=infant_horiz_dirs.index(current_infant_horiz_dir)
        current_infant_vert_dir_idx=-1
        if current_infant_vert_dir is not None:
            current_infant_vert_dir_idx=infant_vert_dirs.index(current_infant_vert_dir)

        # If next target and direction are not specified
        if target is None and horiz_dir is None and vert_dir is None:
            # Find when infant stops looking at this target
            target_z_idx=np.where(self.infant_target_mat[current_infant_target_idx,frame_idx:]==0)[0]

            # If target is camera or other/ambig - also need to check if direction changes - direction could change
            # without the target and it counts as a gaze shift
            if (target=='Camera' or target=='Other/ambig') and current_infant_horiz_dir is not None and current_infant_vert_dir is not None:
                # Find when infant stops looking in this horizontal direction
                horiz_dir_z_idx=np.where(self.infant_horiz_dir_mat[current_infant_horiz_dir_idx,frame_idx:]==0)[0]
                # Find when infant stops looking in this vertical direction
                vert_dir_z_idx=np.where(self.infant_vert_dir_mat[current_infant_vert_dir_idx,frame_idx:]==0)[0]
                # If the target, horiz or vertical direction changes before the end of the run
                if len(target_z_idx)>0 or len(horiz_dir_z_idx)>0 or len(vert_dir_z_idx)>0:
                    # Next frame index is first time any of these changes
                    next_frame_idx=np.min([np.min(target_z_idx),np.min(horiz_dir_z_idx),
                                           np.min(vert_dir_z_idx)])+frame_idx
            # Otherwise, if the target changes before the end of the run
            elif len(target_z_idx)>0:
                # Next frame index is the first time the target changes
                next_frame_idx=np.min(target_z_idx)+frame_idx

        # If the next target and direction are specified
        else:
            # Find when infant starts looking at this target
            if target is not None:
                req_infant_target_idx=infant_targets.index(target)
                req_target_z_idx=np.where(self.infant_target_mat[req_infant_target_idx,frame_idx:]==1)[0]

                # If target is camera or other/ambig - also need to check direction
                if (target=='Camera' or target=='Other/ambig') and horiz_dir is not None and vert_dir is not None:
                    # Find when infant starts looking in this horizontal direction
                    req_horiz_idx=infant_horiz_dirs.index(horiz_dir)
                    req_horiz_dir_z_idx=np.where(self.infant_horiz_dir_mat[req_horiz_idx,frame_idx:]==1)[0]
                    # Find when infant starts looking in this vertical direction
                    req_vert_idx=infant_vert_dirs.index(vert_dir)
                    req_vert_dir_z_idx=np.where(self.infant_horiz_dir_mat[req_vert_idx,frame_idx:]==1)[0]
                    # Find when the infant is looking at the target and in given horizontal and vertical directions
                    intersection=reduce(np.intersect1d, (req_target_z_idx,req_horiz_dir_z_idx,req_vert_dir_z_idx))
                    # If this happens before the end of the run
                    if len(intersection)>0:
                        # Next frame is the first time this happens
                        next_frame_idx=np.min(intersection)+frame_idx
                # Otherwise, if the infant looks at the target before the end of the run
                elif len(req_target_z_idx)>0:
                    # Next frame is the first time this happens
                    next_frame_idx=np.min(req_target_z_idx)+frame_idx
            else:
                if horiz_dir is not None:
                    # Find when infant starts looking in this horizontal direction
                    req_horiz_idx=infant_horiz_dirs.index(horiz_dir)
                    req_horiz_dir_z_idx=np.where(self.infant_horiz_dir_mat[req_horiz_idx,frame_idx:]==1)[0]
                    if vert_dir is not None:
                        # Find when infant starts looking in this vertical direction
                        req_vert_idx=infant_vert_dirs.index(vert_dir)
                        req_vert_dir_z_idx=np.where(self.infant_horiz_dir_mat[req_vert_idx,frame_idx:]==1)[0]
                        # Find when the infant is looking at the target and in given horizontal and vertical directions
                        intersection=reduce(np.intersect1d, (req_horiz_dir_z_idx,req_vert_dir_z_idx))
                        # If this happens before the end of the run
                        if len(intersection)>0:
                            # Next frame is the first time this happens
                            next_frame_idx=np.min(intersection)+frame_idx
                    elif len(req_horiz_dir_z_idx):
                        next_frame_idx=np.min(req_horiz_dir_z_idx)+frame_idx
        return next_frame_idx


    def get_next_mother_gaze_shift_time(self, frame_idx, target=None, horiz_dir=None, vert_dir=None):
        """
        Get the time that the mother stops looking at the current target
        target, horiz_dir, vert_dir - if set, get the time that the mother at this target in this direction
        """
        next_frame_idx=-1
        # Get current target
        (current_mother_target, current_mother_horiz_dir, current_mother_vert_dir)=self.get_mother_target_and_dir(frame_idx)
        current_mother_target_idx=mother_targets.index(current_mother_target)
        current_mother_horiz_dir_idx=-1
        if current_mother_horiz_dir is not None:
            current_mother_horiz_dir_idx=mother_horiz_dirs.index(current_mother_horiz_dir)
        current_mother_vert_dir_idx=-1
        if current_mother_vert_dir is not None:
            current_mother_vert_dir_idx=mother_vert_dirs.index(current_mother_vert_dir)

        # If next target and direction are not specified
        if target is None and horiz_dir is None and vert_dir is None:
            # Find when mother stops looking at this target
            target_z_idx=np.where(self.mother_target_mat[current_mother_target_idx,frame_idx:]==0)[0]

            # If target is camera or other/ambig - also need to check if direction changes - direction could change
            # without the target and it counts as a gaze shift
            if (target=='Camera' or target=='Other/ambig') and current_mother_horiz_dir is not None and current_mother_vert_dir is not None:
                # Find when mother stops looking in this horizontal direction
                horiz_dir_z_idx=np.where(self.mother_horiz_dir_mat[current_mother_horiz_dir_idx,frame_idx:]==0)[0]
                # Find when mother stops looking in this vertical direction
                vert_dir_z_idx=np.where(self.mother_vert_dir_mat[current_mother_vert_dir_idx,frame_idx:]==0)[0]
                # If the target, horiz or vertical direction changes before the end of the run
                if len(target_z_idx)>0 or len(horiz_dir_z_idx)>0 or len(vert_dir_z_idx)>0:
                    # Next frame index is first time any of these changes
                    next_frame_idx=np.min([np.min(target_z_idx),np.min(horiz_dir_z_idx),
                                           np.min(vert_dir_z_idx)])+frame_idx
            # Otherwise, if the target changes before the end of the run
            elif len(target_z_idx)>0:
                # Next frame index is the first time the target changes
                next_frame_idx=np.min(target_z_idx)+frame_idx

        # If the next target and direction are specified
        else:
            # Find when mother starts looking at this target
            req_mother_target_idx=mother_targets.index(target)
            req_target_z_idx=np.where(self.mother_target_mat[req_mother_target_idx,frame_idx:]==1)[0]

            # If target is camera or other/ambig - also need to check direction
            if (target=='Camera' or target=='Other/ambig') and horiz_dir is not None and vert_dir is not None:
                # Find when mother starts looking in this horizontal direction
                req_horiz_idx=mother_horiz_dirs.index(horiz_dir)
                req_horiz_dir_z_idx=np.where(self.mother_horiz_dir_mat[req_horiz_idx,frame_idx:]==1)[0]
                # Find when mother starts looking in this vertical direction
                req_vert_idx=mother_vert_dirs.index(vert_dir)
                req_vert_dir_z_idx=np.where(self.mother_horiz_dir_mat[req_vert_idx,frame_idx:]==1)[0]
                # Find when the mother is looking at the target and in given horizontal and vertical directions
                intersection=reduce(np.intersect1d, (req_target_z_idx,req_horiz_dir_z_idx,req_vert_dir_z_idx))
                # If this happens before the end of the run
                if len(intersection)>0:
                    # Next frame is the first time this happens
                    next_frame_idx=np.min(intersection)+frame_idx
            # Otherwise, if the mother looks at the target before the end of the run
            elif len(req_target_z_idx)>0:
                # Next frame is the first time this happens
                next_frame_idx=np.min(req_target_z_idx)+frame_idx
        return next_frame_idx


    def extract_level2_events(self):
        """
        Extract level 2 events - shared gaze, mutual gaze, different gaze, infant face mother other, mother face infant 
        other
        """
        # Initialize matrices
        self.shared_gaze_mat=np.zeros((1,self.num_frames))
        self.mutual_gaze_mat=np.zeros((1,self.num_frames))
        self.different_gaze_mat=np.zeros((1,self.num_frames))
        self.infant_face_mother_other_mat=np.zeros((1,self.num_frames))
        self.mother_face_infant_other_mat=np.zeros((1,self.num_frames))

        # Iterate through each frame
        for frame_idx in range(self.num_frames):
            # Get infant and mother target and direction
            (infant_target, infant_horiz_dir, infant_vert_dir)=self.get_infant_target_and_dir(frame_idx)
            (mother_target, mother_horiz_dir, mother_vert_dir)=self.get_mother_target_and_dir(frame_idx)

            # Shared gaze if looking at same target
            if targets_equal(infant_target, infant_horiz_dir, infant_vert_dir, mother_target, mother_horiz_dir, mother_vert_dir):
                self.shared_gaze_mat[0,frame_idx]=1
            # Mutual gaze if looking at each other
            elif infant_target=='Mother face' and mother_target=='Infant face':
                self.mutual_gaze_mat[0,frame_idx]=1
            # Infant face mother other if infant looking at mother face and mother not turning head
            #elif infant_target=='Mother face' and not mother_target=='Head turn':
            elif mother_visible(self.age, infant_target, infant_horiz_dir) and not mother_target=='Head turn':
                self.infant_face_mother_other_mat[0,frame_idx]=1
            # Mother face infant other if mother looking at infant face and infant not turning head
            #elif mother_target=='Infant face' and not infant_target=='Head turn':
            elif infant_visible(mother_target, mother_horiz_dir) and not infant_target=='Head turn':
                self.mother_face_infant_other_mat[0,frame_idx]=1
            # Otherwise different gaze as long as neither is turning their head
            elif not (infant_target=='Head turn' or mother_target=='Head turn'):
                self.different_gaze_mat[0,frame_idx]=1


    def fill_mother_follow_infant(self):
        #
        # Infant shifts gaze
        # Mother shifts gaze to same thing
        # Mother looking at something else (other than infant face) before infant
        # Infant doesn't look away before mother's gaze gets there

        # Initialize matrix
        mother_follow_infant_mat = np.zeros((1, self.num_frames))
        infant_face_target_idx=mother_targets.index('Infant face')

        # Start at first gaze shift
        # First time point where infant is not looking at same thing as t=0
        next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(0)

        # Go through infant gaze shifts until the end of the run
        while next_infant_gaze_shift > -1:
            # Time points before and after infant gaze shift
            next_infant_gaze_shift_start=next_infant_gaze_shift-1
            next_infant_gaze_shift_end=next_infant_gaze_shift

            # Where infant was looking after the gaze shift
            (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift_end)

            # Current mother target
            (current_mother_target, current_mother_horiz_dir, current_mother_vert_dir) = self.get_mother_target_and_dir(next_infant_gaze_shift_start)
            # Next mother gaze shift from the time the infant starts
            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_infant_gaze_shift_start)
            # Where mother looks next
            (next_mother_target, next_mother_horiz_dir, next_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)

            # Event start at time of mother's gaze shift
            mother_follow_infant_start=next_mother_gaze_shift

            # If mother gaze shift occurs within x seconds of infants
            if next_mother_gaze_shift-next_infant_gaze_shift<=interval_threshold_seconds*25:

                # If infant turning head - get target after head turn
                if post_shift_infant_target == 'Head turn':
                    next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
                    next_infant_gaze_shift_end=next_infant_gaze_shift
                    (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift_end)

                # If mother turning head - get target after head turn
                if next_mother_target == 'Head turn':
                    # Next mother gaze shift from the time the infant looks
                    next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    # Where mother looks next
                    (next_mother_target, next_mother_horiz_dir, next_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)

                # Event ends when mother is looking at target
                mother_follow_infant_end=next_mother_gaze_shift

                # Mother not already looking at same target, but shifts to look at same target
                pre_target_equal=targets_equal(post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir, current_mother_target, current_mother_horiz_dir, current_mother_vert_dir)
                post_target_equal=targets_equal(post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir, next_mother_target, next_mother_horiz_dir, next_mother_vert_dir)
                if not pre_target_equal and post_target_equal:
                    # check that infant didn't start looking at something else by the time the mother is looking (unless it's mother face)
                    infant_stopped_looking=False
                    # When infant stops looking at current target
                    next_next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift_end)
                    # If this gaze shift occurs before the mother looks at the target
                    if next_next_infant_gaze_shift<mother_follow_infant_start:
                        # Target after current target
                        (post_post_shift_infant_target, post_post_shift_infant_horiz_dir, post_post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_next_infant_gaze_shift)
                        # If turning head - get next target
                        if post_post_shift_infant_target == 'Head turn':
                            next_next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_next_infant_gaze_shift)
                            (post_post_shift_infant_target, post_post_shift_infant_horiz_dir, post_post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_next_infant_gaze_shift)
                        if post_post_shift_infant_target!='Mother face' and post_post_shift_infant_target!=post_shift_infant_target:
                            infant_stopped_looking=True

                    if not infant_stopped_looking:
                        # If mother is looking at the infants face while she's looking at object
                        if np.any(self.mother_target_mat[infant_face_target_idx,next_infant_gaze_shift_start:mother_follow_infant_end + 1]):
                            mother_follow_infant_mat[0, mother_follow_infant_start:mother_follow_infant_end + 1] = 1.0

            next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)


        # Find when mother is looking at infant
#        infant_face_idx = mother_targets.index('Infant face')
#        mother_infant_face_frames = np.where(self.mother_target_mat[infant_face_idx, :] == 1)[0]
#        # Go through times when mother is looking at the infant
#        for i in range(len(mother_infant_face_frames)):
#            frame_idx = mother_infant_face_frames[i]
#
#            # Get where mother stops looking at infant face
#            last_mother_infant_face_frame = -1
#            remaining_face_frames = np.where(self.mother_target_mat[infant_face_idx, frame_idx:] == 0)[0]
#            if len(remaining_face_frames) > 0:
#                last_mother_infant_face_frame = np.min(remaining_face_frames) + frame_idx - 1
#
#            # If the mother stops looking at the infant face before the end of the run
#            if last_mother_infant_face_frame > -1:
#                # Get where the infant is looking when the mother stops looking at its face
#                (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                    last_mother_infant_face_frame)
#
#                # If target is head turn, get target after that
#                if infant_target == 'Head turn':
#                    gaze_shift_idx = self.get_next_infant_gaze_shift_time(last_mother_infant_face_frame)
#                    # If the infant stops turning head before the end of the run
#                    if gaze_shift_idx > -1:
#                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                            gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Convert infant target and direction to mother target and direction
#                req_mother_target = convert_infant_to_mother_target(infant_target)
#                # If this is something the mother can look at
#                if req_mother_target is not None:
#                    (req_mother_horiz_dir, req_mother_vert_dir) = convert_infant_to_mother_dir(infant_horiz_dir,
#                        infant_vert_dir)
#
#                    # Get time when mother looks at this target
#                    mother_gaze_shift_idx = self.get_next_mother_gaze_shift_time(last_mother_infant_face_frame,
#                        target=req_mother_target, horiz_dir=req_mother_horiz_dir, vert_dir=req_mother_vert_dir)
#
#                    # If the mother looks at this target before the end of run
#                    if mother_gaze_shift_idx > -1:
#                        # Add up non-headturning time between mother not looking at infant face anymore and mother looking at target
#                        non_head_turn_time = np.sum(
#                            self.mother_target_mat[1:, last_mother_infant_face_frame+1:mother_gaze_shift_idx])
#                        # If not looking at anything but head turn between looking at infant and infant target
#                        if non_head_turn_time == 0 or last_mother_infant_face_frame+1==mother_gaze_shift_idx:
#                            mother_follow_infant_mat[0, last_mother_infant_face_frame:mother_gaze_shift_idx + 1] = 1.0

        return mother_follow_infant_mat


    def fill_mother_not_follow_infant(self):
        #
        # Infant shifts gaze (to something other than Mother face)
        # Mother shifts gaze to something else within 3s
        # Mother looking at something else (other than infant face) before infant
        # Infant doesn't look away before mother's gaze gets there

        # Initialize matrix
        mother_not_follow_infant_mat = np.zeros((1, self.num_frames))
        infant_face_target_idx=mother_targets.index('Infant face')

        # Start at first gaze shift
        # First time point where infant is not looking at same thing as t=0
        next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(0)

        # Go through infant gaze shifts until the end of the run
        while next_infant_gaze_shift > -1:
            next_infant_gaze_shift_start=next_infant_gaze_shift-1
            next_infant_gaze_shift_end=next_infant_gaze_shift

            # Event start at time before infant gaze shift
            mother_not_follow_infant_start=next_infant_gaze_shift_start

            # Where infant was looking after the gaze shift
            (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift_end)

            # Current mother target
            (current_mother_target, current_mother_horiz_dir, current_mother_vert_dir) = self.get_mother_target_and_dir(next_infant_gaze_shift_start)
            # Next mother gaze shift from the time the infant looks
            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_infant_gaze_shift_start)
            mother_gaze_shift_start=next_mother_gaze_shift
            # Where mother looks next
            (next_mother_target, next_mother_horiz_dir, next_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)

            # If mother gaze shift occurs within x seconds of infants
            if next_mother_gaze_shift-next_infant_gaze_shift<=interval_threshold_seconds*25:

                # If infant turning head - get target after head turn
                if post_shift_infant_target == 'Head turn':
                    next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
                    next_infant_gaze_shift_end=next_infant_gaze_shift
                    (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift_end)

                # If infant gaze shift was not to mother face
                if post_shift_infant_target!='Mother face':

                    # If mother turning head - get target after head turn
                    if next_mother_target == 'Head turn':
                        # Next mother gaze shift from the time the infant looks
                        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                        # Where mother looks next
                        (next_mother_target, next_mother_horiz_dir, next_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)

                    # Event ends when mother is looking at target
                    mother_not_follow_infant_end=next_infant_gaze_shift_end

                    # Mother didn't follow infant
                    # Mother not already looking at same target, but shifts to look at same target
                    pre_target_equal=targets_equal(post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir, current_mother_target, current_mother_horiz_dir, current_mother_vert_dir)
                    post_target_equal=targets_equal(post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir, next_mother_target, next_mother_horiz_dir, next_mother_vert_dir)
                    if not pre_target_equal and not post_target_equal:
                        # check that infant didn't start looking at something else by the time the mother is looking (unless it's mother face)
                        infant_stopped_looking=False
                        # When infant stops looking at current target
                        next_next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift_end)
                        # If this gaze shift occurs before the mother looks at the target
                        if next_next_infant_gaze_shift<mother_gaze_shift_start:
                            # Target after current target
                            (post_post_shift_infant_target, post_post_shift_infant_horiz_dir, post_post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_next_infant_gaze_shift)
                            # If turning head - get next target
                            if post_post_shift_infant_target == 'Head turn':
                                next_next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_next_infant_gaze_shift)
                                (post_post_shift_infant_target, post_post_shift_infant_horiz_dir, post_post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_next_infant_gaze_shift)
                            if post_post_shift_infant_target!='Mother face' and post_post_shift_infant_target!=post_shift_infant_target:
                                infant_stopped_looking=True

                        if not infant_stopped_looking:
                            # If mother is looking at the infants face while she's looking at object
                            if np.any(self.mother_target_mat[infant_face_target_idx,next_infant_gaze_shift_start:mother_not_follow_infant_end + 1]):
                                mother_not_follow_infant_mat[0, mother_not_follow_infant_start:mother_not_follow_infant_end + 1] = 1.0

            next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)        
            
#        # Find when mother is looking at infant
#        infant_face_idx = mother_targets.index('Infant face')
#        mother_infant_face_frames = np.where(self.mother_target_mat[infant_face_idx, :] == 1)[0]
#        # Go through times when mother is looking at the infant
#        for i in range(len(mother_infant_face_frames)):
#            frame_idx = mother_infant_face_frames[i]
#
#            # Get where mother stops looking at infant face
#            last_mother_infant_face_frame = -1
#            remaining_face_frames = np.where(self.mother_target_mat[infant_face_idx, frame_idx:] == 0)[0]
#            if len(remaining_face_frames) > 0:
#                last_mother_infant_face_frame = np.min(remaining_face_frames) + frame_idx - 1
#
#            # If the mother stops looking at the infant face before the end of the run
#            if last_mother_infant_face_frame > -1:
#                # Get where the infant is looking when the mother stops looking at its face
#                (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                    last_mother_infant_face_frame)
#
#                # If target is head turn, get target after that
#                if infant_target == 'Head turn':
#                    gaze_shift_idx = self.get_next_infant_gaze_shift_time(last_mother_infant_face_frame)
#                    # If the infant stops turning head before the end of the run
#                    if gaze_shift_idx > -1:
#                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                            gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Get where the mother is looking when she stops looking at the infant
#                mother_gaze_shift_idx=last_mother_infant_face_frame+1
#                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                    mother_gaze_shift_idx)
#
#                # If target is head turn, get target after that
#                if mother_target == 'Head turn':
#                    mother_gaze_shift_idx = self.get_next_mother_gaze_shift_time(mother_gaze_shift_idx)
#                    # If the mother stops turning head before the end of the run
#                    if mother_gaze_shift_idx > -1:
#                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                            mother_gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Convert infant target and direction to required mother target and direction
#                req_mother_target = convert_infant_to_mother_target(infant_target)
#                # If this is something the mother could look at (i.e. not her own face)
#                if req_mother_target is not None:
#                    (req_mother_horiz_dir,req_mother_vert_dir)=convert_infant_to_mother_dir(infant_horiz_dir, infant_vert_dir)
#
#                    # Mother is not following infant if targets dont match
#                    mother_not_following_infant=not mother_target==req_mother_target
#                    # or if directions don't match if target is camera or other/amib
#                    if ((mother_target=='Camera' and req_mother_target=='Camera') or (mother_target=='Other/ambig' and req_mother_target=='Other/ambig')) and mother_horiz_dir is not None and mother_vert_dir is not None and req_mother_horiz_dir is not None and req_mother_vert_dir is not None:
#                        mother_not_following_infant=not(mother_horiz_dir==req_mother_horiz_dir and mother_vert_dir==req_mother_vert_dir)
#
#                    if mother_not_following_infant:
#                        mother_not_follow_infant_mat[0,last_mother_infant_face_frame:mother_gaze_shift_idx+1]=1.0

        return mother_not_follow_infant_mat


    def fill_infant_follow_mother(self):
        #
        # Mother shifts gaze
        # Infant shifts gaze to same thing within 3s
        # Infant looking at something else (other than mother face) before mother
        # Mother doesn't look away before infant's gaze gets there

        # Initialize matrix
        infant_follow_mother_mat = np.zeros((1, self.num_frames))
        mother_face_target_idx=infant_targets.index('Mother face')

        # Start at first gaze shift
        # First time point where mother is not looking at same thing as t=0
        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(0)

        # Go through mother gaze shifts until the end of the run
        while next_mother_gaze_shift > -1:
            next_mother_gaze_shift_start=next_mother_gaze_shift-1
            next_mother_gaze_shift_end=next_mother_gaze_shift

            # Where mother was looking after the gaze shift
            (post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift_end)

            (current_infant_target, current_infant_horiz_dir, current_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift_start)
            # Next infant gaze shift from the time the mother looks
            next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_mother_gaze_shift_start)
            # Where infant looks next
            (next_infant_target, next_infant_horiz_dir, next_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift)

            # Event start at time before mother gaze shift
            infant_follow_mother_start=next_infant_gaze_shift

            # If infant gaze shift occurs within x seconds of mothers
            if next_infant_gaze_shift-next_mother_gaze_shift<=interval_threshold_seconds*25:

                # If mother turning head - get target after head turn
                if post_shift_mother_target == 'Head turn':
                    next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    next_mother_gaze_shift_end=next_mother_gaze_shift
                    (post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift_end)

                # If infant turning head - get target after head turn
                if next_infant_target == 'Head turn':
                    # Next infant gaze shift from the time the mother looks
                    next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
                    # Where infant looks next
                    (next_infant_target, next_infant_horiz_dir, next_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift)

                # Event ends when infant is looking at target
                infant_follow_mother_end=next_infant_gaze_shift

                # Infant followed mother
                pre_target_equal=targets_equal(current_infant_target, current_infant_horiz_dir, current_infant_vert_dir, post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir)
                post_target_equal=targets_equal(next_infant_target, next_infant_horiz_dir, next_infant_vert_dir, post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir)
                if not pre_target_equal and post_target_equal:
                    # check that mother didn't start looking at something else by the time the infant is looking (unless it's infant face)
                    mother_stopped_looking=False
                    # When mother stops looking at current target
                    next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift_end)
                    # If this gaze shift occurs before the infant looks at the target
                    if next_next_mother_gaze_shift<infant_follow_mother_start:
                        # Target after current target
                        (post_post_shift_mother_target, post_post_shift_mother_horiz_dir, post_post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                        # If turning head - get next target
                        if post_post_shift_mother_target == 'Head turn':
                            next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_next_mother_gaze_shift)
                            (post_post_shift_mother_target, post_post_shift_mother_horiz_dir, post_post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                        if post_post_shift_mother_target!='Infant face' and post_post_shift_mother_target!=post_shift_mother_target:
                            mother_stopped_looking=True

                    if not mother_stopped_looking:
                        # If infant is looking at the mothers face while she's looking at object
                        infant_sees_mother=False
                        for t in range(next_mother_gaze_shift_start,infant_follow_mother_end+1):
                            (t_infant_target, t_infant_horiz_dir, t_infant_vert_dir) = self.get_infant_target_and_dir(t)
                            if mother_visible(self.age, t_infant_target, t_infant_horiz_dir):
                                infant_sees_mother=True
                                break
                        if infant_sees_mother:
                            infant_follow_mother_mat[0, infant_follow_mother_start:infant_follow_mother_end + 1] = 1.0
                        #if np.any(self.infant_target_mat[mother_face_target_idx,next_mother_gaze_shift_start:infant_follow_mother_end + 1]):
                        #    infant_follow_mother_mat[0, infant_follow_mother_start:infant_follow_mother_end + 1] = 1.0

            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
            
#        # Find when infant is looking at mother
#        mother_face_idx = infant_targets.index('Mother face')
#        infant_mother_face_frames = np.where(self.infant_target_mat[mother_face_idx, :] == 1)[0]
#        # Go through times when infant is looking at the mother
#        for i in range(len(infant_mother_face_frames)):
#            frame_idx = infant_mother_face_frames[i]
#
#            # Get where infant stops looking at mother face
#            last_infant_mother_face_frame = -1
#            remaining_face_frames = np.where(self.infant_target_mat[mother_face_idx, frame_idx:] == 0)[0]
#            if len(remaining_face_frames) > 0:
#                last_infant_mother_face_frame = np.min(remaining_face_frames) + frame_idx - 1
#
#            # If the infant stops looking at the mother face before the end of the run
#            if last_infant_mother_face_frame > -1:
#                # Get where the mother is looking when the infant stops looking at its face
#                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                    last_infant_mother_face_frame)
#
#                # If target is head turn, get target after that
#                if mother_target == 'Head turn':
#                    gaze_shift_idx = self.get_next_mother_gaze_shift_time(last_infant_mother_face_frame)
#                    # If the mother stops turning head before the end of the run
#                    if gaze_shift_idx > -1:
#                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                            gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Convert mother target and direction to infant target and direction
#                req_infant_target = convert_mother_to_infant_target(mother_target)
#                # If this is something the infant can look at
#                if req_infant_target is not None:
#                    (req_infant_horiz_dir, req_infant_vert_dir) = convert_mother_to_infant_dir(mother_horiz_dir,
#                        mother_vert_dir)
#
#                    # Get time when infant looks at this target
#                    infant_gaze_shift_idx = self.get_next_infant_gaze_shift_time(last_infant_mother_face_frame,
#                        target=req_infant_target, horiz_dir=req_infant_horiz_dir, vert_dir=req_infant_vert_dir)
#
#                    # If the infant looks at this target before the end of run
#                    if infant_gaze_shift_idx > -1:
#                        # Add up non-headturning time between infant not looking at mother face anymore and infant looking at target
#                        non_head_turn_time = np.sum(
#                            self.infant_target_mat[1:, last_infant_mother_face_frame+1:infant_gaze_shift_idx])
#                        # If not looking at anything but head turn between looking at mother and mother target
#                        if non_head_turn_time ==0:
#                            infant_follow_mother_mat[0, last_infant_mother_face_frame:infant_gaze_shift_idx + 1] = 1.0
        return infant_follow_mother_mat


    def fill_infant_not_follow_mother(self):
        #
        # Mother shifts gaze (to something other than Infant face)
        # Infant shifts gaze to something else within 3s
        # Infant looking at something else (other than mother face) before mother
        # Mother doesn't look away before infant's gaze gets there

        # Initialize matrix
        infant_not_follow_mother_mat = np.zeros((1, self.num_frames))
        mother_face_target_idx=infant_targets.index('Mother face')

        # Start at first gaze shift
        # First time point where mother is not looking at same thing as t=0
        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(0)

        # Go through mother gaze shifts until the end of the run
        while next_mother_gaze_shift > -1:
            next_mother_gaze_shift_start=next_mother_gaze_shift-1
            next_mother_gaze_shift_end=next_mother_gaze_shift

            # Event start at time before mother gaze shift
            infant_not_follow_mother_start=next_mother_gaze_shift_start

            # Where mother was looking after the gaze shift
            (post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift_end)

            (current_infant_target, current_infant_horiz_dir, current_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift_start)
            # Next infant gaze shift from the time the mother looks
            next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_mother_gaze_shift_start)
            infant_gaze_shift_start=next_infant_gaze_shift
            # Where infant looks next
            (next_infant_target, next_infant_horiz_dir, next_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift)

            # If infant gaze shift occurs within x seconds of mothers
            if next_infant_gaze_shift-next_mother_gaze_shift<=interval_threshold_seconds*25:

                # If mother turning head - get target after head turn
                if post_shift_mother_target == 'Head turn':
                    next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    next_mother_gaze_shift_end=next_mother_gaze_shift
                    (post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift_end)

                # If mother gaze shift was not to infant face
                if post_shift_mother_target!='Infant face':

                    # If infant turning head - get target after head turn
                    if next_infant_target == 'Head turn':
                        # Next infant gaze shift from the time the mother looks
                        next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
                        # Where infant looks next
                        (next_infant_target, next_infant_horiz_dir, next_infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift)

                    # Event ends when infant is looking at target
                    infant_not_follow_mother_end=next_mother_gaze_shift_end

                    # Infant didn't follow mother
                    pre_target_equal=targets_equal(current_infant_target, current_infant_horiz_dir, current_infant_vert_dir, post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir)
                    post_target_equal=targets_equal(next_infant_target, next_infant_horiz_dir, next_infant_vert_dir, post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir)
                    if not pre_target_equal and not post_target_equal:
                        # check that mother didn't start looking at something else by the time the infant is looking (unless it's infant face)
                        mother_stopped_looking=False
                        # When mother stops looking at current target
                        next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift_end)
                        # If this gaze shift occurs before the infant looks at the target
                        if next_next_mother_gaze_shift<infant_gaze_shift_start:
                            # Target after current target
                            (post_post_shift_mother_target, post_post_shift_mother_horiz_dir, post_post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                            # If turning head - get next target
                            if post_post_shift_mother_target == 'Head turn':
                                next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_next_mother_gaze_shift)
                                (post_post_shift_mother_target, post_post_shift_mother_horiz_dir, post_post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                            if post_post_shift_mother_target!='Infant face' and post_post_shift_mother_target!=post_shift_mother_target:
                                mother_stopped_looking=True

                        if not mother_stopped_looking:
                            # If infant is looking at the mothers face while she's looking at object
                            infant_sees_mother=False
                            for t in range(next_mother_gaze_shift_start,infant_not_follow_mother_end+1):
                                (t_infant_target, t_infant_horiz_dir, t_infant_vert_dir) = self.get_infant_target_and_dir(t)
                                if mother_visible(self.age, t_infant_target, t_infant_horiz_dir):
                                    infant_sees_mother=True
                                    break
                            if infant_sees_mother:
                                infant_not_follow_mother_mat[0, infant_not_follow_mother_start:infant_not_follow_mother_end + 1] = 1.0
                            #if np.any(self.infant_target_mat[mother_face_target_idx,next_mother_gaze_shift_start:infant_not_follow_mother_end + 1]):
                            #    infant_not_follow_mother_mat[0, infant_not_follow_mother_start:infant_not_follow_mother_end + 1] = 1.0

            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)

#        # Find when infant is looking at mother
#        mother_face_idx = infant_targets.index('Mother face')
#        infant_mother_face_frames = np.where(self.infant_target_mat[mother_face_idx, :] == 1)[0]
#        # Go through times when infant is looking at the mother
#        for i in range(len(infant_mother_face_frames)):
#            frame_idx = infant_mother_face_frames[i]
#
#            # Get where infant stops looking at mother face
#            last_infant_mother_face_frame = -1
#            remaining_face_frames = np.where(self.infant_target_mat[mother_face_idx, frame_idx:] == 0)[0]
#            if len(remaining_face_frames) > 0:
#                last_infant_mother_face_frame = np.min(remaining_face_frames) + frame_idx - 1
#
#            # If the infant stops looking at the mother face before the end of the run
#            if last_infant_mother_face_frame > -1:
#                # Get where the mother is looking when the infant stops looking at its face
#                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                    last_infant_mother_face_frame)
#
#                # If target is head turn, get target after that
#                if mother_target == 'Head turn':
#                    gaze_shift_idx = self.get_next_mother_gaze_shift_time(last_infant_mother_face_frame)
#                    # If the mother stops turning head before the end of the run
#                    if gaze_shift_idx > -1:
#                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                            gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Get where the infant is looking when she stops looking at the mother
#                infant_gaze_shift_idx=last_infant_mother_face_frame+1
#                (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                    infant_gaze_shift_idx)
#
#                # If target is head turn, get target after that
#                if infant_target == 'Head turn':
#                    infant_gaze_shift_idx = self.get_next_infant_gaze_shift_time(infant_gaze_shift_idx)
#                    # If the infant stops turning head before the end of the run
#                    if infant_gaze_shift_idx > -1:
#                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(
#                            infant_gaze_shift_idx)
#                    # Otherwise keep looking
#                    else:
#                        continue
#
#                # Convert mother target and direction to required infant target and direction
#                req_infant_target = convert_mother_to_infant_target(mother_target)
#                # If this is something the infant could look at (i.e. not its own face)
#                if not req_infant_target is None:
#                    (req_infant_horiz_dir,req_infant_vert_dir)=convert_mother_to_infant_dir(mother_horiz_dir, mother_vert_dir)
#
#                    # Infant is not following mother if targets dont match
#                    infant_not_following_mother=not infant_target==req_infant_target
#                    # or if directions don't match if target is camera or other/amib
#                    if ((infant_target=='Camera' and req_infant_target=='Camera') or\
#                        (infant_target=='Other/ambig' and req_infant_target=='Other/ambig')) and infant_horiz_dir is not None and infant_vert_dir is not None and req_infant_horiz_dir is not None and req_infant_vert_dir is not None:
#                        infant_not_following_mother=not(infant_horiz_dir==req_infant_horiz_dir and infant_vert_dir==req_infant_vert_dir)
#
#                    if infant_not_following_mother:
#                        infant_not_follow_mother_mat[0,last_infant_mother_face_frame:infant_gaze_shift_idx+1]=1.0

        return infant_not_follow_mother_mat


    def fill_mother_sees_infant_gaze_shift(self):
        # Mother observes infant gaze shift
        # Initialize matrix
        mother_sees_infant_gaze_shift = np.zeros((1, self.num_frames))

        # Start at first gaze shift
        next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(0)

        # Go through infant gaze shifts until the end of the run
        while next_infant_gaze_shift > -1:
            # Gaze shift can't be first frame
            if next_infant_gaze_shift > 0:
                (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(next_infant_gaze_shift)
                # If head turn - mother needs to be looking at some point during turn
                if infant_target=='Head turn':
                    next_next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
                    mother_sees=False
                    for frame_idx in range(next_infant_gaze_shift,next_next_infant_gaze_shift):
                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(frame_idx)
                        if mother_target=='Infant face':
                        #if mother_horiz_dir in infant_visible_directions:
                            mother_sees=True
                            break
                    if mother_sees:
                        mother_sees_infant_gaze_shift[0, next_infant_gaze_shift:next_next_infant_gaze_shift] = 1.0
                else:
                    # Check if the mother is looking at the infant
                    (pre_shift_mother_target, pre_shift_mother_horiz_dir, pre_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_infant_gaze_shift - 1)
                    (post_shift_mother_target, post_shift_mother_horiz_dir, post_shift_mother_vert_dir) = self.get_mother_target_and_dir(next_infant_gaze_shift)
                    if pre_shift_mother_target == 'Infant face' and post_shift_mother_target == 'Infant face':
                    #if pre_shift_mother_horiz_dir in infant_visible_directions and post_shift_mother_horiz_dir in infant_visible_directions:
                        mother_sees_infant_gaze_shift[0, next_infant_gaze_shift] = 1.0

            # Get the next gaze shift
            next_infant_gaze_shift = self.get_next_infant_gaze_shift_time(next_infant_gaze_shift)
        return mother_sees_infant_gaze_shift


    def fill_infant_sees_mother_gaze_shift(self):
        # Infant observes mother gaze shift
        # Initialize matrix
        infant_sees_mother_gaze_shift = np.zeros((1, self.num_frames))
        # Start at first gaze shift
        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(0)
        # Go through mother gaze shifts until the end of the run
        while next_mother_gaze_shift > -1:
            # Gaze shift can't be first frame
            if next_mother_gaze_shift > 0:
                # If not just the end of a head turn
                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)
                if mother_target == 'Head turn':
                    next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    infant_sees=False
                    for frame_idx in range(next_mother_gaze_shift,next_next_mother_gaze_shift):
                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(frame_idx)
                        #if infant_target=='Mother face':
                        if mother_visible(self.age, infant_target, infant_horiz_dir):
                        #if infant_horiz_dir in mother_visible_directions[self.age]:
                            infant_sees=True
                            break
                    if infant_sees:
                        infant_sees_mother_gaze_shift[0, next_mother_gaze_shift:next_next_mother_gaze_shift] = 1.0
                else:
                    # Check if the infant is looking at the mother
                    (pre_shift_infant_target, pre_shift_infant_horiz_dir,pre_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift - 1)
                    (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift)
                    #if pre_shift_infant_target == 'Mother face' and post_shift_infant_target == 'Mother face':
                    if mother_visible(self.age, pre_shift_infant_target, pre_shift_infant_horiz_dir) and mother_visible(self.age, post_shift_infant_target, post_shift_infant_horiz_dir):
                    #if pre_shift_infant_horiz_dir in mother_visible_directions[self.age] and post_shift_infant_horiz_dir in mother_visible_directions[self.age]:
                        infant_sees_mother_gaze_shift[0, next_mother_gaze_shift] = 1.0

            # Get the next gaze shift
            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
        return infant_sees_mother_gaze_shift


    def fill_infant_sees_mother_object_to_infant_gaze_shift(self):
        # Infant observes mother gaze shift
        # Initialize matrix
        infant_sees_mother_gaze_shift = np.zeros((1, self.num_frames))
        # Start at first gaze shift
        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(0)
        # Go through mother gaze shifts until the end of the run
        while next_mother_gaze_shift > -1:
            # Gaze shift can't be first frame
            if next_mother_gaze_shift > 0:
                # If not just the end of a head turn
                (last_mother_target, last_mother_horiz_dir, last_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift-1)
                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)
                if mother_target == 'Head turn':
                    next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                    if last_mother_target!='Infant face' and mother_target=='Infant face':
                        infant_sees=False
                        for frame_idx in range(next_mother_gaze_shift,next_next_mother_gaze_shift):
                            (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(frame_idx)
                            #if infant_target=='Mother face':
                            if mother_visible(self.age, infant_target, infant_horiz_dir):
                            #if infant_horiz_dir in mother_visible_directions[self.age]:
                                infant_sees=True
                                break
                        if infant_sees:
                            infant_sees_mother_gaze_shift[0, next_mother_gaze_shift:next_next_mother_gaze_shift] = 1.0
                else:
                    if last_mother_target!='Infant face' and mother_target=='Infant face':
                        # Check if the infant is looking at the mother
                        (pre_shift_infant_target, pre_shift_infant_horiz_dir,pre_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift - 1)
                        (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift)
                        #if pre_shift_infant_target == 'Mother face' and post_shift_infant_target == 'Mother face':
                        if mother_visible(self.age, pre_shift_infant_target, pre_shift_infant_horiz_dir) and mother_visible(self.age, post_shift_infant_target, post_shift_infant_horiz_dir):
                        #if pre_shift_infant_horiz_dir in mother_visible_directions[self.age] and post_shift_infant_horiz_dir in mother_visible_directions[self.age]:
                            infant_sees_mother_gaze_shift[0, next_mother_gaze_shift] = 1.0

            # Get the next gaze shift
            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
        return infant_sees_mother_gaze_shift


    def fill_infant_sees_mother_infant_to_object_gaze_shift(self):
        # Infant observes mother gaze shift
        # Initialize matrix
        infant_sees_mother_gaze_shift = np.zeros((1, self.num_frames))
        # Start at first gaze shift
        next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(0)
        # Go through mother gaze shifts until the end of the run
        while next_mother_gaze_shift > -1:
            # Gaze shift can't be first frame
            if next_mother_gaze_shift > 0:
                # If not just the end of a head turn
                (last_mother_target, last_mother_horiz_dir, last_mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift-1)
                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_mother_gaze_shift)
                if mother_target == 'Head turn':
                    next_next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
                    (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_next_mother_gaze_shift)
                    if last_mother_target=='Infant face' and mother_target!='Infant face':
                        infant_sees=False
                        for frame_idx in range(next_mother_gaze_shift,next_next_mother_gaze_shift):
                            (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(frame_idx)
                            #if infant_target=='Mother face':
                            if mother_visible(self.age, infant_target, infant_horiz_dir):
                            #if infant_horiz_dir in mother_visible_directions[self.age]:
                                infant_sees=True
                                break
                        if infant_sees:
                            infant_sees_mother_gaze_shift[0, next_mother_gaze_shift:next_next_mother_gaze_shift] = 1.0
                else:
                    if last_mother_target=='Infant face' and mother_target!='Infant face':
                        # Check if the infant is looking at the mother
                        (pre_shift_infant_target, pre_shift_infant_horiz_dir,pre_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift - 1)
                        (post_shift_infant_target, post_shift_infant_horiz_dir, post_shift_infant_vert_dir) = self.get_infant_target_and_dir(next_mother_gaze_shift)
                        #if pre_shift_infant_target == 'Mother face' and post_shift_infant_target == 'Mother face':
                        if mother_visible(self.age, pre_shift_infant_target, pre_shift_infant_horiz_dir) and mother_visible(self.age, post_shift_infant_target, post_shift_infant_horiz_dir):
                        #if pre_shift_infant_horiz_dir in mother_visible_directions[self.age] and post_shift_infant_horiz_dir in mother_visible_directions[self.age]:
                            infant_sees_mother_gaze_shift[0, next_mother_gaze_shift] = 1.0

            # Get the next gaze shift
            next_mother_gaze_shift = self.get_next_mother_gaze_shift_time(next_mother_gaze_shift)
        return infant_sees_mother_gaze_shift


    def extract_level3_events(self):

        """
        Extract Level 3 events - mother follow infant, infant follow mother, mother observes infant gaze shift, infant 
        observes mother gaze shift, mother not follow infant, infant not follow mother
        """

        self.mother_follow_infant_mat = self.fill_mother_follow_infant()

        self.infant_follow_mother_mat = self.fill_infant_follow_mother()

        self.mother_not_follow_infant_mat = self.fill_mother_not_follow_infant()

        self.infant_not_follow_mother_mat = self.fill_infant_not_follow_mother()

        self.mother_sees_infant_gaze_shift = self.fill_mother_sees_infant_gaze_shift()

        self.infant_sees_mother_gaze_shift = self.fill_infant_sees_mother_gaze_shift()

        self.infant_sees_mother_object_to_infant_gaze_shift = self.fill_infant_sees_mother_object_to_infant_gaze_shift()

        self.infant_sees_mother_infant_to_object_gaze_shift = self.fill_infant_sees_mother_infant_to_object_gaze_shift()



    def fill_infant_sees_mother_follow(self):
        infant_sees_mother_follow_mat = np.zeros((1, self.num_frames))
        mother_follows_infant_onsets=np.where(np.diff(self.mother_follow_infant_mat[0, :])==1)[0]+1
        mother_follows_infant_offsets=np.where(np.diff(self.mother_follow_infant_mat[0, :])==-1)[0]
        if len(mother_follows_infant_onsets)==len(mother_follows_infant_offsets):

            for onset_idx, mother_follows_infant_onset in enumerate(mother_follows_infant_onsets):
                mother_follows_infant_offset=mother_follows_infant_offsets[onset_idx]

                infant_time_at_mother = self.get_next_infant_gaze_shift_time(mother_follows_infant_onset+1, target='Mother face')
#                times_at_mother=[]
#                for dir in mother_visible_directions[self.age]:
#                   times_at_mother.append(self.get_next_infant_gaze_shift_time(mother_follows_infant_onset+1,horiz_dir=dir))
#                infant_time_at_mother=np.min(times_at_mother)
#                infant_time_off_mother=self.get_next_infant_gaze_shift_time(infant_time_at_mother)
                # If the infant looks back at the mother before the end of the run
                if infant_time_at_mother > -1:
                    next_mother_gaze_shift=self.get_next_mother_gaze_shift_time(mother_follows_infant_offset)
                    if infant_time_at_mother<next_mother_gaze_shift:

                        infant_sees_mother_follow_mat[0, infant_time_at_mother] = 1.0
        else:
            print('error')

#        # Find where mother follows infant
#        mother_follows_infant_frames = np.where(self.mother_follow_infant_mat[0, :] == 1)[0]
#        # Go through times when mother follows the infant
#        for i in range(len(mother_follows_infant_frames)):
#            frame_idx = mother_follows_infant_frames[i]
#
#            # Get the last frame of mother follows infant
#            last_mother_follow_infant_frame = -1
#            remaining_follow_frames = np.where(self.mother_follow_infant_mat[0, frame_idx:] == 0)[0]
#            if len(remaining_follow_frames) > 0:
#                last_mother_follow_infant_frame = np.min(remaining_follow_frames) + frame_idx - 1
#
#            if last_mother_follow_infant_frame > -1:
#                # At last frame of mother follows infant - mother is looking at target
#                (req_mother_target, req_mother_horiz_dir, req_mother_vert_dir) = self.get_mother_target_and_dir(
#                    last_mother_follow_infant_frame)
#
#                # Find where infant looks at mother's face - starting from the start of the mother follow infant period
#                #infant_time_at_mother = self.get_next_infant_gaze_shift_time(frame_idx, target='Mother face')
#                times_at_mother=[]
#                for dir in mother_visible_directions[self.age]:
#                    times_at_mother.append(self.get_next_infant_gaze_shift_time(frame_idx,horiz_dir=dir))
#                infant_time_at_mother=np.min(times_at_mother)
#
#                # If the infant looks back at the mother before the end of the run
#                if infant_time_at_mother > -1:
#                    # Add up non-head turning time between infant looking at target and infant looking back at mother's face
#                    non_head_turn_time = np.sum(self.infant_target_mat[1:, frame_idx+1:infant_time_at_mother])
#                    # If not looking at anything between looking at target and looking at mom
#                    if non_head_turn_time == 0 or frame_idx+1==infant_time_at_mother:
#                        # Get mother target and direction when infant looks back at her
#                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                            infant_time_at_mother)
#                        # If the mother is turning her head, get the next mother target
#                        if mother_target == 'Head turn':
#                            # Get the next time the mother stops head turning
#                            next_mother_gaze_shift_idx = self.get_next_mother_gaze_shift_time(infant_time_at_mother)
#                            # If the mother stops head turning before the end of the run
#                            if next_mother_gaze_shift_idx > -1:
#                                # Get the next mother target and direction
#                                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                                    next_mother_gaze_shift_idx)
#                            else:
#                                continue
#
#                        # If the target and required mother target are camera or other/ambig, check the direction
#                        if (mother_target == 'Camera' and req_mother_target == 'Camera') or (mother_target == 'Other/ambig' and req_mother_target == 'Other/ambig') and mother_horiz_dir is not None and req_mother_horiz_dir is not None and mother_vert_dir is not None and req_mother_vert_dir is not None:
#                            mother_looking_at_same_target = req_mother_horiz_dir == mother_horiz_dir and req_mother_vert_dir == mother_vert_dir
#
#                        # Otherwise check that the mother target matches the required target
#                        else:
#                            mother_looking_at_same_target = req_mother_target == mother_target
#
#                        # If the mother is still looking at the objet that the infant did when the infant looks back at her
#                        if mother_looking_at_same_target:
#                            infant_sees_mother_follow_mat[0, last_mother_follow_infant_frame:infant_time_at_mother + 1] = 1.0
        return infant_sees_mother_follow_mat


    def fill_infant_sees_mother_not_follow(self):
        infant_sees_mother_not_follow_mat = np.zeros((1, self.num_frames))
        mother_not_follows_infant_onsets=np.where(np.diff(self.mother_not_follow_infant_mat[0, :])==1)[0]+1
        mother_not_follows_infant_offsets=np.where(np.diff(self.mother_not_follow_infant_mat[0, :])==-1)[0]
        if len(mother_not_follows_infant_onsets)==len(mother_not_follows_infant_offsets):

            for onset_idx, mother_not_follows_infant_onset in enumerate(mother_not_follows_infant_onsets):
                mother_not_follows_infant_offset=mother_not_follows_infant_offsets[onset_idx]

                infant_time_at_mother = self.get_next_infant_gaze_shift_time(mother_not_follows_infant_onset+1, target='Mother face')
#                times_at_mother=[]
#                for dir in mother_visible_directions[self.age]:
#                    times_at_mother.append(self.get_next_infant_gaze_shift_time(mother_not_follows_infant_onset+1,horiz_dir=dir))
#                infant_time_at_mother=np.min(times_at_mother)
#                infant_time_off_mother=self.get_next_infant_gaze_shift_time(infant_time_at_mother)
                # If the infant looks back at the mother before the end of the run
                if infant_time_at_mother > -1:
                    next_mother_gaze_shift=self.get_next_mother_gaze_shift_time(mother_not_follows_infant_offset)
                    if infant_time_at_mother<next_mother_gaze_shift:
                        infant_sees_mother_not_follow_mat[0, infant_time_at_mother] = 1.0
        else:
            print('error')

#        infant_sees_mother_not_follow_mat = np.zeros((1, self.num_frames))
#        # Find where mother does not follow infant
#        mother_not_follows_infant_frames = np.where(self.mother_not_follow_infant_mat[0, :] == 1)[0]
#        # Go through times when mother does not follow the infant
#        for i in range(len(mother_not_follows_infant_frames)):
#            frame_idx = mother_not_follows_infant_frames[i]
#
#            # Get the last frame of mother does not follow infant
#            last_mother_not_follow_infant_frame = -1
#            remaining_not_follow_frames = np.where(self.mother_not_follow_infant_mat[0, frame_idx:] == 0)[0]
#            if len(remaining_not_follow_frames) > 0:
#                last_mother_not_follow_infant_frame = np.min(remaining_not_follow_frames) + frame_idx - 1
#
#            if last_mother_not_follow_infant_frame > -1:
#                # At last frame of mother not follows infant - mother is looking at different target
#                (req_mother_target, req_mother_horiz_dir, req_mother_vert_dir) = self.get_mother_target_and_dir(
#                    last_mother_not_follow_infant_frame)
#
#                # Find where infant looks at mother's face - starting from the start of the mother follow infant period
#                #infant_time_at_mother = self.get_next_infant_gaze_shift_time(frame_idx, target='Mother face')
#                times_at_mother=[]
#                for dir in mother_visible_directions[self.age]:
#                    times_at_mother.append(self.get_next_infant_gaze_shift_time(frame_idx,horiz_dir=dir))
#                infant_time_at_mother=np.min(times_at_mother)
#
#                # If the infant looks back at the mother before the end of the run
#                if infant_time_at_mother > -1:
#                    # Add up non-head turning time between infant looking at target and infant looking back at mother's face
#                    non_head_turn_time = np.sum(self.infant_target_mat[1:, frame_idx+1:infant_time_at_mother])
#                    # If not looking at anything between looking at target and looking at mom
#                    if non_head_turn_time == 0 or frame_idx+1==infant_time_at_mother:
#                        # Get mother target and direction when infant looks back at her
#                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                            infant_time_at_mother)
#                        # If the mother is turning her head, get the next mother target
#                        if mother_target == 'Head turn':
#                            # Get the next time the mother stops head turning
#                            next_mother_gaze_shift_idx = self.get_next_mother_gaze_shift_time(infant_time_at_mother)
#                            # If the mother stops head turning before the end of the run
#                            if next_mother_gaze_shift_idx > -1:
#                                # Get the next mother target and direction
#                                (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(
#                                    next_mother_gaze_shift_idx)
#                            else:
#                                continue
#
#                        mother_looking_at_same_target = req_mother_target == mother_target
#                        # If the target and required mother target are camera or other/ambig, check the direction
#                        if (mother_target == 'Camera' and req_mother_target == 'Camera') or (mother_target == 'Other/ambig' and req_mother_target == 'Other/ambig') and mother_horiz_dir is not None and req_mother_horiz_dir is not None and mother_vert_dir is not None and req_mother_vert_dir is not None:
#                            mother_looking_at_same_target = req_mother_horiz_dir == mother_horiz_dir and req_mother_vert_dir == mother_vert_dir
#
#                        # If the mother is still looking at the objet that the infant did when the infant looks back at her
#                        if mother_looking_at_same_target:
#                            infant_sees_mother_not_follow_mat[0, last_mother_not_follow_infant_frame:infant_time_at_mother + 1] = 1.0
        return infant_sees_mother_not_follow_mat


    def fill_infant_sees_mother_gaze_infant(self):
        """
        Find when infant is looking at some target (not mother) and turns to look at mother and mother is looking at
        infant
        """
        infant_sees_mother_gaze_infant_mat = np.zeros((1, self.num_frames))

        # Index of current gaze shift
        next_gaze_shift_idx=0
        # Iterate over all gaze shifts
        while next_gaze_shift_idx>-1:
            # Start at second frame at least
            if next_gaze_shift_idx>0:
                # Get current infant target
                (infant_target,infant_horiz_dir,infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx)
                # Get last infant target
                (last_infant_target,last_infant_horiz_dir,last_infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx-1)
                # If the infant is turning her head, get the next infant target
                if infant_target == 'Head turn':
                    # Get the next time the infant stops head turning
                    next_gaze_shift_idx = self.get_next_infant_gaze_shift_time(next_gaze_shift_idx)
                    # If the infant stops head turning before the end of the run
                    if next_gaze_shift_idx > -1:
                        # Get the next infant target and direction
                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(next_gaze_shift_idx)
                    else:
                        continue

                # If last target is not mother face (head turns are skipped) and current target is mother face
                #if not last_infant_target=='Mother face' and infant_target=='Mother face':
                if not mother_visible(self.age, last_infant_target, last_infant_horiz_dir) and mother_visible(self.age, infant_target, infant_horiz_dir):
                #if not last_infant_horiz_dir in mother_visible_directions[self.age] and infant_horiz_dir in mother_visible_directions[self.age]:
                #if not last_infant_target=='Mother face' and infant_horiz_dir in mother_visible_directions[self.age]:
                    (mother_target, mother_horiz_dir, mother_vert_dir)=self.get_mother_target_and_dir(next_gaze_shift_idx)
                    if mother_target=='Infant face':
                        infant_sees_mother_gaze_infant_mat[0,next_gaze_shift_idx-1:next_gaze_shift_idx]=1.0


            # Get the next infant gaze shift
            next_gaze_shift_idx = self.get_next_infant_gaze_shift_time(next_gaze_shift_idx)
        return infant_sees_mother_gaze_infant_mat


    def extract_level4_events(self):
        """
        Extract level 4 events - infant sees mother follow, infant sees mother did not follow
        """
        self.infant_sees_mother_follow_mat = self.fill_infant_sees_mother_follow()

        self.infant_sees_mother_not_follow_mat = self.fill_infant_sees_mother_not_follow()

        self.infant_sees_mother_gaze_infant_mat = self.fill_infant_sees_mother_gaze_infant()


    def get_num_infant_gaze_shifts(self, type):
        """
        Get number of infant gaze shifts - type can be All, Head turn, or Saccade
        """
        num_gaze_shifts=0
        # Index of current gaze shift
        next_gaze_shift_idx=0
        # Iterate over all gaze shifts
        while next_gaze_shift_idx>-1:
            # Start at second frame at least
            if next_gaze_shift_idx>0:
                # Get current infant target
                (infant_target,infant_horiz_dir,infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx)
                # Get last infant target
                (last_infant_target,last_infant_horiz_dir,last_infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx-1)
                # If the last target was not head turn - dont want the end of head turns regardless of type
                if not last_infant_target=='Head turn':
                    # If looking for all gaze shifts or head turns and this is a head turn
                    if type=='All' or (type=='Head turn' and infant_target=='Head turn'):
                        num_gaze_shifts+=1
                    # If looking for saccades and this is not a head turn
                    elif type=='Saccade' and not infant_target=='Head turn':
                        num_gaze_shifts+=1
                # Get next gaze shift
            next_gaze_shift_idx=self.get_next_infant_gaze_shift_time(next_gaze_shift_idx)
        return num_gaze_shifts

    def get_num_mother_gaze_shifts(self, type):
        """
        Get number of mother gaze shifts - type can be All, Head turn, or Saccade
        """
        num_gaze_shifts=0
        # Index of current gaze shift
        next_gaze_shift_idx=0
        # Iterate over all gaze shifts
        while next_gaze_shift_idx>-1:
            # Start at second frame at least
            if next_gaze_shift_idx>0:
                # Get current mother target
                (mother_target,mother_horiz_dir,mother_vert_dir)=self.get_mother_target_and_dir(next_gaze_shift_idx)
                # Get last mother target
                (last_mother_target,last_mother_horiz_dir,last_mother_vert_dir)=self.get_mother_target_and_dir(next_gaze_shift_idx-1)
                # If the last target was not head turn - dont want the end of head turns regardless of type
                if not last_mother_target=='Head turn':
                    # If looking for all gaze shifts or head turns and this is a head turn
                    if type=='All' or (type=='Head turn' and mother_target=='Head turn'):
                        num_gaze_shifts+=1
                    # If looking for saccades and this is not a head turn
                    elif type=='Saccade' and not mother_target=='Head turn':
                        num_gaze_shifts+=1
                        # Get next gaze shift
            next_gaze_shift_idx=self.get_next_mother_gaze_shift_time(next_gaze_shift_idx)
        return num_gaze_shifts


    def get_num_infant_face_mother_other(self):
        diff=self.infant_face_mother_other_mat[0,1:]-self.infant_face_mother_other_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_mother_face_infant_other(self):
        diff=self.mother_face_infant_other_mat[0,1:]-self.mother_face_infant_other_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_infant_follow_mother(self):
        diff=self.infant_follow_mother_mat[0,1:]-self.infant_follow_mother_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_mother_follow_infant(self):
        diff=self.mother_follow_infant_mat[0,1:]-self.mother_follow_infant_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_infant_not_follow_mother(self):
        diff=self.infant_not_follow_mother_mat[0,1:]-self.infant_not_follow_mother_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_mother_not_follow_infant(self):
        diff=self.mother_not_follow_infant_mat[0,1:]-self.mother_not_follow_infant_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_infant_sees_mother_follow(self):
        diff=self.infant_sees_mother_follow_mat[0,1:]-self.infant_sees_mother_follow_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_infant_sees_mother_not_follow(self):
        diff=self.infant_sees_mother_not_follow_mat[0,1:]-self.infant_sees_mother_not_follow_mat[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_infant_target_to_target_shifts(self, from_target, to_target):
        num_gaze_shifts=0
        # Index of current gaze shift
        next_gaze_shift_idx=0
        # Iterate over all gaze shifts
        while next_gaze_shift_idx>-1:
            # Start at second frame at least
            if next_gaze_shift_idx>0:
                # Get current infant target
                (infant_target,infant_horiz_dir,infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx)
                # Get last infant target
                (last_infant_target,last_infant_horiz_dir,last_infant_vert_dir)=self.get_infant_target_and_dir(next_gaze_shift_idx-1)
                # If the infant is turning her head, get the next infant target
                if infant_target == 'Head turn':
                    # Get the next time the infant stops head turning
                    next_gaze_shift_idx = self.get_next_infant_gaze_shift_time(next_gaze_shift_idx)
                    # If the infant stops head turning before the end of the run
                    if next_gaze_shift_idx > -1:
                        # Get the next infant target and direction
                        (infant_target, infant_horiz_dir, infant_vert_dir) = self.get_infant_target_and_dir(next_gaze_shift_idx)
                    else:
                        continue

                # If last target is not mother face (head turns are skipped) and current target is mother face
                if from_target=='object' and to_target=='mother':
                    if not last_infant_target=='Mother face' and infant_target=='Mother face':
                        num_gaze_shifts+=1
                elif from_target=='object' and to_target=='object':
                    if not last_infant_target=='Mother face' and not infant_target=='Mother face':
                        num_gaze_shifts+=1
                elif from_target=='mother' and to_target=='object':
                    if last_infant_target=='Mother face' and not infant_target=='Mother face':
                        num_gaze_shifts+=1

            # Get the next infant gaze shift
            next_gaze_shift_idx = self.get_next_infant_gaze_shift_time(next_gaze_shift_idx)
        return num_gaze_shifts


    def get_num_mother_target_to_target_shifts(self, from_target, to_target):
        num_gaze_shifts=0
        # Index of current gaze shift
        next_gaze_shift_idx=0
        # Iterate over all gaze shifts
        while next_gaze_shift_idx>-1:
            # Start at second frame at least
            if next_gaze_shift_idx>0:
                # Get current mother target
                (mother_target,mother_horiz_dir,mother_vert_dir)=self.get_mother_target_and_dir(next_gaze_shift_idx)
                # Get last mother target
                (last_mother_target,last_mother_horiz_dir,last_mother_vert_dir)=self.get_mother_target_and_dir(next_gaze_shift_idx-1)
                # If the mother is turning her head, get the next mother target
                if mother_target == 'Head turn':
                    # Get the next time the mother stops head turning
                    next_gaze_shift_idx = self.get_next_mother_gaze_shift_time(next_gaze_shift_idx)
                    # If the mother stops head turning before the end of the run
                    if next_gaze_shift_idx > -1:
                        # Get the next mother target and direction
                        (mother_target, mother_horiz_dir, mother_vert_dir) = self.get_mother_target_and_dir(next_gaze_shift_idx)
                    else:
                        continue

                # If last target is not infant face (head turns are skipped) and current target is infant face
                if from_target=='object' and to_target=='infant':
                    if not last_mother_target=='Infant face' and mother_target=='Infant face':
                        num_gaze_shifts+=1
                elif from_target=='object' and to_target=='object':
                    if not last_mother_target=='Infant face' and not mother_target=='Infant face':
                        num_gaze_shifts+=1
                elif from_target=='infant' and to_target=='object':
                    if last_mother_target=='Infant face' and not mother_target=='Infant face':
                        num_gaze_shifts+=1

            # Get the next mother gaze shift
            next_gaze_shift_idx = self.get_next_mother_gaze_shift_time(next_gaze_shift_idx)
        return num_gaze_shifts


    def get_num_infant_target_gaze_shifts(self, infant_target, direction):
        target_idx=infant_targets.index(infant_target)
        diff=self.infant_target_mat[target_idx,1:]-self.infant_target_mat[target_idx,0:-1]
        if direction=='to':
            return len(np.where(diff>0)[0])
        else:
            return len(np.where(diff<0)[0])


    def get_num_mother_target_gaze_shifts(self, mother_target, direction):
        target_idx=mother_targets.index(mother_target)
        diff=self.mother_target_mat[target_idx,1:]-self.mother_target_mat[target_idx,0:-1]
        if direction=='to':
            return len(np.where(diff>0)[0])
        else:
            return len(np.where(diff<0)[0])


    def get_num_infant_gaze_shifts_mother_observed(self):
        diff=self.mother_sees_infant_gaze_shift[0,1:]-self.mother_sees_infant_gaze_shift[0,0:-1]
        return len(np.where(diff>0)[0])


    def get_num_mother_gaze_shifts_infant_observed(self):
        diff=self.infant_sees_mother_gaze_shift[0,1:]-self.infant_sees_mother_gaze_shift[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_mother_object_to_infant_gaze_shifts_infant_observed(self):
        diff=self.infant_sees_mother_object_to_infant_gaze_shift[0,1:]-self.infant_sees_mother_object_to_infant_gaze_shift[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_mother_infant_to_object_gaze_shifts_infant_observed(self):
        diff=self.infant_sees_mother_infant_to_object_gaze_shift[0,1:]-self.infant_sees_mother_infant_to_object_gaze_shift[0,0:-1]
        return len(np.where(diff>0)[0])

    def get_num_shared_gaze(self, after=None):
        num_shared_gaze=0
        diff=self.shared_gaze_mat[0,1:]-self.shared_gaze_mat[0,0:-1]
        if self.shared_gaze_mat[0,0]>0:
            new_diff=[1]
            new_diff.extend(diff)
            diff=np.array(new_diff)
        shared_gaze_idx=np.where(diff>0)[0]
        if after is None:
            num_shared_gaze=len(shared_gaze_idx)
        else:
            for idx in range(len(shared_gaze_idx)):
                if after=='mother_follow_infant'and self.mother_follow_infant_mat[0,shared_gaze_idx[idx]-1]>0:
                    num_shared_gaze+=1
                elif after=='infant_follow_mother' and  self.infant_follow_mother_mat[0,shared_gaze_idx[idx]-1]>0:
                    num_shared_gaze+=1
        return num_shared_gaze


    def get_num_dyadic_shifts(self):
        num_shifts=0
        diff=self.shared_gaze_mat[0,1:]-self.shared_gaze_mat[0,0:-1]
        num_shifts+=len(np.where(diff>0)[0])
        diff=self.mutual_gaze_mat[0,1:]-self.mutual_gaze_mat[0,0:-1]
        num_shifts+=len(np.where(diff>0)[0])
        diff=self.different_gaze_mat[0,1:]-self.different_gaze_mat[0,0:-1]
        num_shifts+=len(np.where(diff>0)[0])
        diff=self.infant_face_mother_other_mat[0,1:]-self.infant_face_mother_other_mat[0,0:-1]
        num_shifts+=len(np.where(diff>0)[0])
        diff=self.mother_face_infant_other_mat[0,1:]-self.mother_face_infant_other_mat[0,0:-1]
        num_shifts+=len(np.where(diff>0)[0])
        return num_shifts


    def get_num_infant_sees_mother_gaze_infant(self):
        diff=self.infant_sees_mother_gaze_infant_mat[0,1:]-self.infant_sees_mother_gaze_infant_mat[0,0:-1]
        return len(np.where(diff>0)[0])


    def export_csv(self, file_name):
        file=open(file_name, 'w')
        file.write(',%s\n' % ','.join([str(x) for x in range(self.start_frame,self.end_frame+1)]))
        file.write('Infant\n')
        for target_idx, target in enumerate(infant_targets):
            file.write('%s,%s\n' % (target, ','.join([conv_x(x) for x in self.infant_target_mat[target_idx,:]])))
        for dir_idx, dir in enumerate(infant_horiz_dirs):
            file.write('%s,%s\n' % (dir, ','.join([conv_x(x) for x in self.infant_horiz_dir_mat[dir_idx,:]])))
        for dir_idx, dir in enumerate(infant_vert_dirs):
            file.write('%s,%s\n' % (dir, ','.join([conv_x(x) for x in self.infant_vert_dir_mat[dir_idx,:]])))
        file.write('\nMother\n')
        for target_idx, target in enumerate(mother_targets):
            file.write('%s,%s\n' % (target, ','.join([conv_x(x) for x in self.mother_target_mat[target_idx,:]])))
        for dir_idx, dir in enumerate(mother_horiz_dirs):
            file.write('%s,%s\n' % (dir, ','.join([conv_x(x) for x in self.mother_horiz_dir_mat[dir_idx,:]])))
        for dir_idx, dir in enumerate(mother_vert_dirs):
            file.write('%s,%s\n' % (dir, ','.join([conv_x(x) for x in self.mother_vert_dir_mat[dir_idx,:]])))
        file.write('\nLevel2\n')
        file.write('SharedGaze,%s\n' % ','.join([conv_x(x) for x in self.shared_gaze_mat[0,:]]))
        file.write('MutualGaze,%s\n' % ','.join([conv_x(x) for x in self.mutual_gaze_mat[0,:]]))
        file.write('DifferentGaze,%s\n' % ','.join([conv_x(x) for x in self.different_gaze_mat[0,:]]))
        file.write('InfantFaceMotherOtherGaze,%s\n' % ','.join([conv_x(x) for x in self.infant_face_mother_other_mat[0,:]]))
        file.write('MotherFaceInfantOtherGaze,%s\n' % ','.join([conv_x(x) for x in self.mother_face_infant_other_mat[0,:]]))
        file.write('\nLevel3\n')
        file.write('MotherFollowInfant,%s\n' % ','.join([conv_x(x) for x in self.mother_follow_infant_mat[0,:]]))
        file.write('InfantFollowMother,%s\n' % ','.join([conv_x(x) for x in self.infant_follow_mother_mat[0,:]]))
        file.write('MotherNotFollowInfant,%s\n' % ','.join([conv_x(x) for x in self.mother_not_follow_infant_mat[0,:]]))
        file.write('InfantNotFollowMother,%s\n' % ','.join([conv_x(x) for x in self.infant_not_follow_mother_mat[0,:]]))
        file.write('MotherSeesInfantGazeShift,%s\n' % ','.join([conv_x(x) for x in self.mother_sees_infant_gaze_shift[0,:]]))
        file.write('InfantSeesMotherGazeShift,%s\n' % ','.join([conv_x(x) for x in self.infant_sees_mother_gaze_shift[0,:]]))
        file.write('\nLevel4\n')
        file.write('InfantSeesMotherFollow,%s\n' % ','.join([conv_x(x) for x in self.infant_sees_mother_follow_mat[0,:]]))
        file.write('InfantSeesMotherNotFollow,%s\n' % ','.join([conv_x(x) for x in self.infant_sees_mother_not_follow_mat[0,:]]))
        file.close()

def conv_x(x):
    if x>0:
        return 'x'
    return ''

class InteractionSession:
    def __init__(self, data_dir, subj_id, coder, age, visit_num, runs):
        self.subj_id=subj_id
        self.coder=coder
        self.age=age
        self.visit_num=visit_num
        self.runs=runs

        self.interaction_runs=[]
        if not len(self.runs):
            self.interaction_runs.append(InteractionRun(data_dir,subj_id,coder,age,visit_num))
        else:
            for run in self.runs:
                self.interaction_runs.append(InteractionRun(data_dir,subj_id,coder,age,visit_num,run_num=run))

    def extract_measures(self):
        total_frames=0
        infant_target_time_count=np.zeros((len(infant_targets),1))
        infant_horiz_dir_time_count=np.zeros((len(infant_horiz_dirs),1))
        infant_vert_dir_time_count=np.zeros((len(infant_vert_dirs),1))

        mother_target_time_count=np.zeros((len(mother_targets),1))
        mother_horiz_dir_time_count=np.zeros((len(mother_horiz_dirs),1))
        mother_vert_dir_time_count=np.zeros((len(mother_vert_dirs),1))

        shared_gaze_time_count=0
        mutual_gaze_time_count=0
        different_gaze_time_count=0
        infant_face_mother_other_time_count=0
        mother_face_infant_other_time_count=0
        num_infant_face_mother_other=0
        num_mother_face_infant_other=0

        num_infant_gaze_shifts=0
        num_infant_saccades=0
        num_infant_head_turns=0

        num_mother_gaze_shifts=0
        num_mother_saccades=0
        num_mother_head_turns=0

        num_infant_follow_mother=0
        num_mother_follow_infant=0
        num_infant_not_follow_mother=0
        num_mother_not_follow_infant=0

        num_infant_sees_mother_follow=0
        num_infant_sees_mother_not_follow=0
        num_infant_sees_mother_gaze_infant=0

        num_infant_object_to_mother_gaze_shifts=0
        num_infant_object_to_object_gaze_shifts=0
        num_infant_mother_to_object_gaze_shifts=0

        num_mother_object_to_infant_gaze_shifts=0
        num_mother_object_to_object_gaze_shifts=0
        num_mother_infant_to_object_gaze_shifts=0

        infant_gaze_shifts_to_target_count=np.zeros((1,len(infant_targets)-1))
        infant_gaze_shifts_from_target_count=np.zeros((1,len(infant_targets)-1))
        mother_gaze_shifts_to_target_count=np.zeros((1,len(mother_targets)-1))
        mother_gaze_shifts_from_target_count=np.zeros((1,len(mother_targets)-1))

        num_mother_gaze_shifts_infant_observed=0
        num_infant_gaze_shifts_mother_observed=0
        num_mother_object_to_infant_gaze_shifts_infant_observed=0
        num_mother_infant_to_object_gaze_shifts_infant_observed=0

        num_shared_gaze=0
        num_shared_gaze_after_mother_follow_infant=0
        num_shared_gaze_after_infant_follow_mother=0

        num_dyadic_shifts=0


        for run in self.interaction_runs:
            run.extract_level2_events()
            run.extract_level3_events()
            run.extract_level4_events()

            total_frames+=run.num_frames

            infant_target_time_count=infant_target_time_count+np.sum(run.infant_target_mat,axis=1)
            infant_horiz_dir_time_count=infant_horiz_dir_time_count+np.sum(run.infant_horiz_dir_mat,axis=1)
            infant_vert_dir_time_count=infant_vert_dir_time_count+np.sum(run.infant_vert_dir_mat,axis=1)

            mother_target_time_count=mother_target_time_count+np.sum(run.mother_target_mat,axis=1)
            mother_horiz_dir_time_count=mother_horiz_dir_time_count+np.sum(run.mother_horiz_dir_mat,axis=1)
            mother_vert_dir_time_count=mother_vert_dir_time_count+np.sum(run.mother_vert_dir_mat,axis=1)

            shared_gaze_time_count+=np.sum(run.shared_gaze_mat)
            mutual_gaze_time_count+=np.sum(run.mutual_gaze_mat)
            different_gaze_time_count+=np.sum(run.different_gaze_mat)
            infant_face_mother_other_time_count+=np.sum(run.infant_face_mother_other_mat)
            mother_face_infant_other_time_count+=np.sum(run.mother_face_infant_other_mat)
            num_infant_face_mother_other+=run.get_num_infant_face_mother_other()
            num_mother_face_infant_other+=run.get_num_mother_face_infant_other()

            num_infant_gaze_shifts+=run.get_num_infant_gaze_shifts('All')
            num_infant_saccades+=run.get_num_infant_gaze_shifts('Saccade')
            num_infant_head_turns+=run.get_num_infant_gaze_shifts('Head turn')

            num_mother_gaze_shifts+=run.get_num_mother_gaze_shifts('All')
            num_mother_saccades+=run.get_num_mother_gaze_shifts('Saccade')
            num_mother_head_turns+=run.get_num_mother_gaze_shifts('Head turn')

            num_infant_follow_mother+=run.get_num_infant_follow_mother()
            num_mother_follow_infant+=run.get_num_mother_follow_infant()
            num_infant_not_follow_mother+=run.get_num_infant_not_follow_mother()
            num_mother_not_follow_infant+=run.get_num_mother_not_follow_infant()

            num_infant_sees_mother_follow+=run.get_num_infant_sees_mother_follow()
            num_infant_sees_mother_not_follow+=run.get_num_infant_sees_mother_not_follow()
            num_infant_sees_mother_gaze_infant+=run.get_num_infant_sees_mother_gaze_infant()

            num_infant_object_to_mother_gaze_shifts+=run.get_num_infant_target_to_target_shifts('object','mother')
            num_infant_object_to_object_gaze_shifts+=run.get_num_infant_target_to_target_shifts('object','object')
            num_infant_mother_to_object_gaze_shifts+=run.get_num_infant_target_to_target_shifts('mother','object')

            num_mother_object_to_infant_gaze_shifts+=run.get_num_mother_target_to_target_shifts('object','infant')
            num_mother_object_to_object_gaze_shifts+=run.get_num_mother_target_to_target_shifts('object','object')
            num_mother_infant_to_object_gaze_shifts+=run.get_num_mother_target_to_target_shifts('infant','object')

            for idx in range(1,len(infant_targets)):
                target=infant_targets[idx]
                infant_gaze_shifts_to_target_count[0,idx-1]=infant_gaze_shifts_to_target_count[0,idx-1]+run.get_num_infant_target_gaze_shifts(target,'to')
                infant_gaze_shifts_from_target_count[0,idx-1]=infant_gaze_shifts_from_target_count[0,idx-1]+run.get_num_infant_target_gaze_shifts(target,'from')

            for idx in range(1,len(mother_targets)):
                target=mother_targets[idx]
                mother_gaze_shifts_to_target_count[0,idx-1]=mother_gaze_shifts_to_target_count[0,idx-1]+run.get_num_mother_target_gaze_shifts(target,'to')
                mother_gaze_shifts_from_target_count[0,idx-1]=mother_gaze_shifts_from_target_count[0,idx-1]+run.get_num_mother_target_gaze_shifts(target,'from')

            num_infant_gaze_shifts_mother_observed+=run.get_num_infant_gaze_shifts_mother_observed()
            num_mother_gaze_shifts_infant_observed+=run.get_num_mother_gaze_shifts_infant_observed()
            num_mother_object_to_infant_gaze_shifts_infant_observed+=run.get_num_mother_object_to_infant_gaze_shifts_infant_observed()
            num_mother_infant_to_object_gaze_shifts_infant_observed+=run.get_num_mother_infant_to_object_gaze_shifts_infant_observed()

            num_shared_gaze+=run.get_num_shared_gaze()
            num_shared_gaze_after_mother_follow_infant+=run.get_num_shared_gaze(after='mother_follow_infant')
            num_shared_gaze_after_infant_follow_mother+=run.get_num_shared_gaze(after='infant_follow_mother')

            num_dyadic_shifts+=run.get_num_dyadic_shifts()

        self.total_min=(total_frames/25.00)/60.0

        self.measures={
            'infant_perc_time_target': infant_target_time_count/float(total_frames),
            'infant_perc_time_horiz_dir': infant_horiz_dir_time_count/float(total_frames),
            'infant_perc_time_vert_dir':infant_vert_dir_time_count/float(total_frames),
            'mother_perc_time_target':mother_target_time_count/float(total_frames),
            'mother_perc_time_horiz_dir':mother_horiz_dir_time_count/float(total_frames),
            'mother_perc_time_vert_dir':mother_vert_dir_time_count/float(total_frames),

            'shared_gaze_perc_time':float(shared_gaze_time_count)/float(total_frames),
            'mutual_gaze_perc_time':float(mutual_gaze_time_count)/float(total_frames),
            'different_gaze_perc_time':float(different_gaze_time_count)/float(total_frames),
            'infant_face_mother_other_perc_time':float(infant_face_mother_other_time_count)/float(total_frames),
            'mother_face_infant_other_perc_time':float(mother_face_infant_other_time_count)/float(total_frames),

            'num_infant_gaze_shifts_per_min':float(num_infant_gaze_shifts)/self.total_min,
            'num_infant_saccades_per_min':float(num_infant_saccades)/self.total_min,
            'num_infant_head_turns_per_min':float(num_infant_head_turns)/self.total_min,

            'num_mother_gaze_shifts_per_min':float(num_mother_gaze_shifts)/self.total_min,
            'num_mother_saccades_per_min':float(num_mother_saccades)/self.total_min,
            'num_mother_head_turns_per_min':float(num_mother_head_turns)/self.total_min,

            'num_infant_gaze_shifts_mother_observed_per_min':float(num_infant_gaze_shifts_mother_observed)/self.total_min,
            'num_infant_gaze_shifts_mother_observed_per_gaze_shift':0,
            'num_mother_gaze_shifts_infant_observed_per_min':float(num_mother_gaze_shifts_infant_observed)/self.total_min,
            'num_mother_gaze_shifts_infant_observed_per_gaze_shift':0,
            'num_mother_object_to_infant_gaze_shifts_infant_observed_per_min':float(num_mother_object_to_infant_gaze_shifts_infant_observed)/self.total_min,
            'num_mother_infant_to_object_gaze_shifts_infant_observed_per_min':float(num_mother_object_to_infant_gaze_shifts_infant_observed)/self.total_min,
            'num_mother_object_to_infant_gaze_shifts_infant_observed_per_mother_object_to_infant_gaze_shift':0,
            'num_mother_infant_to_object_gaze_shifts_infant_observed_per_mother_infant_to_object_gaze_shift':0,

            'infant_follow_mother_per_min':float(num_infant_follow_mother)/self.total_min,
            'mother_follow_infant_per_min':float(num_mother_follow_infant)/self.total_min,
            'infant_follow_mother_per_gaze_shift':0,
            'mother_follow_infant_per_gaze_shift':0,
            'infant_follow_mother_per_gaze_shift_observed':0,
            'mother_follow_infant_per_gaze_shift_observed':0,
            'infant_follow_mother_per_infant_face_mother_other':0,
            'mother_follow_infant_per_mother_face_infant_other':0,

            'infant_not_follow_mother_per_min':float(num_infant_not_follow_mother)/self.total_min,
            'mother_not_follow_infant_per_min':float(num_mother_not_follow_infant)/self.total_min,
            'infant_not_follow_mother_per_gaze_shift':0,
            'mother_not_follow_infant_per_gaze_shift':0,
            'infant_not_follow_mother_per_gaze_shift_observed':0,
            'mother_not_follow_infant_per_gaze_shift_observed':0,

            'infant_sees_mother_follow_per_min':float(num_infant_sees_mother_follow)/self.total_min,
            'infant_sees_mother_follow_per_mother_follow':0,
            'infant_sees_mother_not_follow_per_min':float(num_infant_sees_mother_not_follow)/self.total_min,
            'infant_sees_mother_not_follow_per_mother_not_follow':0,
            'infant_sees_mother_gaze_infant_per_min':float(num_infant_sees_mother_gaze_infant)/self.total_min,
            'infant_sees_mother_gaze_infant_per_infant_gaze_object_to_mother':0,

            'num_infant_object_to_mother_gaze_shifts_per_min':float(num_infant_object_to_mother_gaze_shifts)/self.total_min,
            'num_infant_object_to_object_gaze_shifts_per_min':float(num_infant_object_to_object_gaze_shifts)/self.total_min,
            'num_infant_mother_to_object_gaze_shifts_per_min':float(num_infant_mother_to_object_gaze_shifts)/self.total_min,
            'num_infant_object_to_mother_gaze_shifts_per_gaze_shift':0,
            'num_infant_object_to_object_gaze_shifts_per_gaze_shift':0,
            'num_infant_mother_to_object_gaze_shifts_per_gaze_shift':0,

            'num_mother_object_to_infant_gaze_shifts_per_min':float(num_mother_object_to_infant_gaze_shifts)/self.total_min,
            'num_mother_object_to_object_gaze_shifts_per_min':float(num_mother_object_to_object_gaze_shifts)/self.total_min,
            'num_mother_infant_to_object_gaze_shifts_per_min':float(num_mother_infant_to_object_gaze_shifts)/self.total_min,
            'num_mother_object_to_infant_gaze_shifts_per_gaze_shift':0,
            'num_mother_object_to_object_gaze_shifts_per_gaze_shift':0,
            'num_mother_infant_to_object_gaze_shifts_per_gaze_shift':0,

            'infant_gaze_shifts_to_target_per_min':infant_gaze_shifts_to_target_count/self.total_min,
            'infant_gaze_shifts_from_target_per_min':infant_gaze_shifts_from_target_count/self.total_min,
            'mother_gaze_shifts_to_target_per_min':mother_gaze_shifts_to_target_count/self.total_min,
            'mother_gaze_shifts_from_target_per_min':mother_gaze_shifts_from_target_count/self.total_min,

            'perc_shared_gaze_after_mother_follow_infant':0,
            'perc_shared_gaze_after_infant_follow_mother':0,

            'num_dyadic_shifts_per_min':float(num_dyadic_shifts)/self.total_min,
            }
        if num_mother_gaze_shifts>0:
            if num_mother_gaze_shifts-num_mother_follow_infant>0:
                self.measures['infant_follow_mother_per_gaze_shift']=float(num_infant_follow_mother)/float(num_mother_gaze_shifts-num_mother_follow_infant)
                self.measures['infant_not_follow_mother_per_gaze_shift']=float(num_infant_not_follow_mother)/float(num_mother_gaze_shifts-num_mother_follow_infant)
            else:
                self.measures['infant_follow_mother_per_gaze_shift']=float('NaN')
                self.measures['infant_not_follow_mother_per_gaze_shift']=float('NaN')
            self.measures['num_mother_object_to_infant_gaze_shifts_per_gaze_shift']=float(num_mother_object_to_infant_gaze_shifts)/float(num_mother_gaze_shifts)
            self.measures['num_mother_object_to_object_gaze_shifts_per_gaze_shift']=float(num_mother_object_to_object_gaze_shifts)/float(num_mother_gaze_shifts)
            self.measures['num_mother_infant_to_object_gaze_shifts_per_gaze_shift']=float(num_mother_infant_to_object_gaze_shifts)/float(num_mother_gaze_shifts)
            self.measures['num_mother_gaze_shifts_infant_observed_per_gaze_shift']=float(num_mother_gaze_shifts_infant_observed)/float(num_mother_gaze_shifts)
        else:
            self.measures['infant_follow_mother_per_gaze_shift']=float('NaN')
            self.measures['infant_not_follow_mother_per_gaze_shift']=float('NaN')
            self.measures['num_mother_object_to_infant_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_mother_object_to_object_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_mother_infant_to_object_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_mother_gaze_shifts_infant_observed_per_gaze_shift']=float('NaN')
        if num_mother_object_to_infant_gaze_shifts>0:
            self.measures['num_mother_object_to_infant_gaze_shifts_infant_observed_per_mother_object_to_infant_gaze_shift']=float(num_mother_object_to_infant_gaze_shifts_infant_observed)/float(num_mother_object_to_infant_gaze_shifts)
        else:
            self.measures['num_mother_object_to_infant_gaze_shifts_infant_observed_per_mother_object_to_infant_gaze_shift']=float('NaN')
        if num_mother_infant_to_object_gaze_shifts>0:
            self.measures['num_mother_infant_to_object_gaze_shifts_infant_observed_per_mother_infant_to_object_gaze_shift']=float(num_mother_infant_to_object_gaze_shifts_infant_observed)/float(num_mother_infant_to_object_gaze_shifts)
        else:
            self.measures['num_mother_infant_to_object_gaze_shifts_infant_observed_per_mother_infant_to_object_gaze_shift']=float('NaN')
        if num_infant_gaze_shifts>0:
            if num_infant_gaze_shifts-num_infant_follow_mother>0:
                self.measures['mother_follow_infant_per_gaze_shift']=float(num_mother_follow_infant)/float(num_infant_gaze_shifts-num_infant_follow_mother)
                self.measures['mother_not_follow_infant_per_gaze_shift']=float(num_mother_not_follow_infant)/float(num_infant_gaze_shifts-num_infant_follow_mother)
            else:
                self.measures['mother_follow_infant_per_gaze_shift']=float('NaN')
                self.measures['mother_not_follow_infant_per_gaze_shift']=float('NaN')
            self.measures['num_infant_object_to_mother_gaze_shifts_per_gaze_shift']=float(num_infant_object_to_mother_gaze_shifts)/float(num_infant_gaze_shifts)
            self.measures['num_infant_object_to_object_gaze_shifts_per_gaze_shift']=float(num_infant_object_to_object_gaze_shifts)/float(num_infant_gaze_shifts)
            self.measures['num_infant_mother_to_object_gaze_shifts_per_gaze_shift']=float(num_infant_mother_to_object_gaze_shifts)/float(num_infant_gaze_shifts)
            self.measures['num_infant_gaze_shifts_mother_observed_per_gaze_shift']=float(num_infant_gaze_shifts_mother_observed)/float(num_infant_gaze_shifts)
        else:
            self.measures['mother_follow_infant_per_gaze_shift']=float('NaN')
            self.measures['mother_not_follow_infant_per_gaze_shift']=float('NaN')
            self.measures['num_infant_object_to_mother_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_infant_object_to_object_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_infant_mother_to_object_gaze_shifts_per_gaze_shift']=float('NaN')
            self.measures['num_infant_gaze_shifts_mother_observed_per_gaze_shift']=float('NaN')
        if num_mother_gaze_shifts_infant_observed>0:
            self.measures['infant_follow_mother_per_gaze_shift_observed']=float(num_infant_follow_mother)/float(num_mother_gaze_shifts_infant_observed)
            self.measures['infant_not_follow_mother_per_gaze_shift_observed']=float(num_infant_not_follow_mother)/float(num_mother_gaze_shifts_infant_observed)
        else:
            self.measures['infant_follow_mother_per_gaze_shift_observed']=float('NaN')
            self.measures['infant_not_follow_mother_per_gaze_shift_observed']=float('NaN')
        if num_infant_face_mother_other>0:
            self.measures['infant_follow_mother_per_infant_face_mother_other']=float(num_infant_follow_mother)/float(num_infant_face_mother_other)
        else:
            self.measures['infant_follow_mother_per_infant_face_mother_other']=float('NaN')
        if num_mother_face_infant_other>0:
            self.measures['mother_follow_infant_per_mother_face_infant_other']=float(num_mother_follow_infant)/float(num_mother_face_infant_other)
        else:
            self.measures['mother_follow_infant_per_mother_face_infant_other']=float('NaN')
        if num_infant_gaze_shifts_mother_observed>0:
            self.measures['mother_follow_infant_per_gaze_shift_observed']=float(num_mother_follow_infant)/float(num_infant_gaze_shifts_mother_observed)
            self.measures['mother_not_follow_infant_per_gaze_shift_observed']=float(num_mother_not_follow_infant)/float(num_infant_gaze_shifts_mother_observed)
        else:
            self.measures['mother_follow_infant_per_gaze_shift_observed']=float('NaN')
            self.measures['mother_not_follow_infant_per_gaze_shift_observed']=float('NaN')
        if num_mother_follow_infant>0:
            self.measures['infant_sees_mother_follow_per_mother_follow']=float(num_infant_sees_mother_follow)/float(num_mother_follow_infant)
        else:
            self.measures['infant_sees_mother_follow_per_mother_follow']=float('NaN')
        if num_mother_not_follow_infant>0:
            self.measures['infant_sees_mother_not_follow_per_mother_not_follow']=float(num_infant_sees_mother_not_follow)/float(num_mother_not_follow_infant)
        else:
            self.measures['infant_sees_mother_not_follow_per_mother_not_follow']=float('NaN')
        if num_infant_object_to_mother_gaze_shifts>0:
            self.measures['infant_sees_mother_gaze_infant_per_infant_gaze_object_to_mother']=float(num_infant_sees_mother_gaze_infant)/float(num_infant_object_to_mother_gaze_shifts)
        else:
            self.measures['infant_sees_mother_gaze_infant_per_infant_gaze_object_to_mother']=float('NaN')
        if num_shared_gaze>0:
            self.measures['perc_shared_gaze_after_mother_follow_infant']=float(num_shared_gaze_after_mother_follow_infant)/float(num_shared_gaze)
            self.measures['perc_shared_gaze_after_infant_follow_mother']=float(num_shared_gaze_after_infant_follow_mother)/float(num_shared_gaze)
        else:
            self.measures['perc_shared_gaze_after_mother_follow_infant']=float('NaN')
            self.measures['perc_shared_gaze_after_infant_follow_mother']=float('NaN')

def export_derived_csv(data_dir, subjects, age, coder, visit_num, output_dir):
    for subject_id, runs in subjects.iteritems():
        session=InteractionSession(data_dir, subject_id, coder, age, visit_num, runs)
        session.extract_measures()
        for run_num,run in enumerate(session.interaction_runs):
            file_name=''
            if len(session.interaction_runs)==1:
                file_name=os.path.join(output_dir,'%d%s%d_derived.csv' % (subject_id,coder,visit_num))
            else:
                file_name=os.path.join(output_dir,'%d%s%d_%d_derived.csv' % (subject_id,coder,visit_num,run_num))
            out_file=open(file_name,'w')
            out_file.write('1,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',%d' % frame)
            out_file.write('\n')
            out_file.write('Infant,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',')
            out_file.write('\n')
            for target_idx,target in enumerate(infant_targets):
                out_file.write(',%s' % target)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.infant_target_mat[target_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')
            for dir_idx,horiz_dir in enumerate(infant_horiz_dirs):
                out_file.write(',%s' % horiz_dir)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.infant_horiz_dir_mat[dir_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')
            for dir_idx,vert_dir in enumerate(infant_vert_dirs):
                out_file.write(',%s' % vert_dir)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.infant_vert_dir_mat[dir_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')
            out_file.write(',')
            for idx in range(run.num_frames):
                out_file.write(',')
            out_file.write('\n')
            out_file.write('Mother,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',')
            out_file.write('\n')
            for target_idx,target in enumerate(mother_targets):
                out_file.write(',%s' % target)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.mother_target_mat[target_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')
            for dir_idx,horiz_dir in enumerate(mother_horiz_dirs):
                out_file.write(',%s' % horiz_dir)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.mother_horiz_dir_mat[dir_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')
            for dir_idx,vert_dir in enumerate(mother_vert_dirs):
                out_file.write(',%s' % vert_dir)
                for idx in range(run.num_frames):
                    out_file.write(',')
                    if run.mother_vert_dir_mat[dir_idx,idx]>0:
                        out_file.write('x')
                out_file.write('\n')

            out_file.write(',')
            for idx in range(run.num_frames):
                out_file.write(',')
            out_file.write('\n')
            out_file.write('Level 2,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',')
            out_file.write('\n')
            out_file.write(',Shared gaze')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.shared_gaze_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Mutual gaze')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.mutual_gaze_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Different gaze')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.different_gaze_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant face mother other')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_face_mother_other_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Mother face infant other')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.mother_face_infant_other_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')

            out_file.write(',')
            for idx in range(run.num_frames):
                out_file.write(',')
            out_file.write('\n')
            out_file.write('Level 3,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',')
            out_file.write('\n')
            out_file.write(',Mother follow infant')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.mother_follow_infant_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant follow mother')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_follow_mother_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Mother not follow infant')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.mother_not_follow_infant_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant not follow mother')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_not_follow_mother_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Mother sees infant gaze shift')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.mother_sees_infant_gaze_shift[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant sees mother gaze shift')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_sees_mother_gaze_shift[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')

            out_file.write(',')
            for idx in range(run.num_frames):
                out_file.write(',')
            out_file.write('\n')
            out_file.write('Level 4,')
            for frame in range(run.start_frame, run.end_frame):
                out_file.write(',')
            out_file.write('\n')
            out_file.write(',Infant sees mother follow')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_sees_mother_follow_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant sees mother not follow')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_sees_mother_not_follow_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')
            out_file.write(',Infant sees mother gaze infant')
            for idx in range(run.num_frames):
                out_file.write(',')
                if run.infant_sees_mother_gaze_infant_mat[0,idx]>0:
                    out_file.write('x')
            out_file.write('\n')

            out_file.close()


def export_wide_csv(data_dir, subjects, age, coder, visit_num, output_filename):
    out_file=open(output_filename,'w')
    out_file.write('Subject,Age')
    for target in infant_targets:
        out_file.write(',InfantPercTime%s' % target.title().replace(' ','').replace('/',''))
    for dir in infant_horiz_dirs:
        out_file.write(',InfantPercTime%s' % dir.title().replace(' ',''))
    for dir in infant_vert_dirs:
        out_file.write(',InfantPercTime%s' % dir.title().replace(' ',''))
    for target in mother_targets:
        out_file.write(',MotherPercTime%s' % target.title().replace(' ','').replace('/',''))
    for dir in mother_horiz_dirs:
        out_file.write(',MotherPercTime%s' % dir.title().replace(' ',''))
    for dir in mother_vert_dirs:
        out_file.write(',MotherPercTime%s' % dir.title().replace(' ',''))
    out_file.write(',')
    out_file.write(','.join(['SharedGazePercTime',
                             'MutualGazePercTime',
                             'DifferentGazePercTime',
                             'InfantFaceMotherOtherPercTime',
                             'MotherFaceInfantOtherPercTime',
                             'InfantGazeShiftsPerMin',
                             'InfantSaccadesPerMin',
                             'InfantHeadTurnsPerMin',
                             'MotherGazeShiftsPerMin',
                             'MotherSaccadesPerMin',
                             'MotherHeadTurnsPerMin',
                             'InfantGazeShiftsMotherObservedPerMin',
                             'InfantGazeShiftsMotherObservedPerGazeShift',
                             'MotherGazeShiftsInfantObservedPerMin',
                             'MotherGazeShiftsInfantObservedPerGazeShift',
                             'MotherObjectToInfantGazeShiftsInfantObservedPerMin',
                             'MotherInfantToObjectGazeShiftsInfantObservedPerMin',
                             'MotherObjectToInfantGazeShiftsInfantObservedPerMotherObjectToInfantGazeShift',
                             'MotherInfantToObjectGazeShiftsInfantObservedPerMotherInfantToObjectGazeShift',
                             'InfantFollowMotherPerMin',
                             'MotherFollowInfantPerMin',
                             'InfantFollowMotherPerGazeShift',
                             'MotherFollowInfantPerGazeShift',
                             'InfantFollowMotherPerGazeShiftObserved',
                             'MotherFollowInfantPerGazeShiftObserved',
                             'InfantFollowMotherPerInfantFaceMotherOther',
                             'MotherFollowInfantPerMotherFaceInfantOther',
                             'InfantNotFollowMotherPerMin',
                             'MotherNotFollowInfantPerMin',
                             'InfantNotFollowMotherPerGazeShift',
                             'MotherNotFollowInfantPerGazeShift',
                             'InfantNotFollowMotherPerGazeShiftObserved',
                             'MotherNotFollowInfantPerGazeShiftObserved',
                             'InfantSeesMotherFollowPerMin',
                             'InfantSeesMotherFollowPerMotherFollow',
                             'InfantSeesMotherNotFollowPerMin',
                             'InfantSeesMotherNotFollowPerMotherNotFollow',
                             'InfantSeesMotherGazeInfantPerMin',
                             'InfantSeesMotherGazeInfantPerInfantGazeObjectToMother',
                             'NumInfantObjectToMotherGazeShiftsPerMin',
                             'NumInfantObjectToObjectGazeShiftsPerMin',
                             'NumInfantMotherToObjectGazeShiftsPerMin',
                             'NumInfantObjectToMotherGazeShiftsPerGazeShift',
                             'NumInfantObjectToObjectGazeShiftsPerGazeShift',
                             'NumInfantMotherToObjectGazeShiftsPerGazeShift',
                             'NumMotherObjectToInfantGazeShiftsPerMin',
                             'NumMotherObjectToObjectGazeShiftsPerMin',
                             'NumMotherInfantToObjectGazeShiftsPerMin',
                             'NumMotherObjectToInfantGazeShiftsPerGazeShift',
                             'NumMotherObjectToObjectGazeShiftsPerGazeShift',
                             'NumMotherInfantToObjectGazeShiftsPerGazeShift']))
    for idx in range(1,len(infant_targets)):
        target=infant_targets[idx]
        out_file.write(',InfantGazeShiftsTo%sPerMin' % target.title().replace(' ','').replace('/',''))
    for idx in range(1,len(infant_targets)):
        target=infant_targets[idx]
        out_file.write(',InfantGazeShiftsFrom%sPerMin' % target.title().replace(' ','').replace('/',''))
    for idx in range(1,len(mother_targets)):
        target=mother_targets[idx]
        out_file.write(',MotherGazeShiftsTo%sPerMin' % target.title().replace(' ','').replace('/',''))
    for idx in range(1,len(mother_targets)):
        target=mother_targets[idx]
        out_file.write(',MotherGazeShiftsFrom%sPerMin' % target.title().replace(' ','').replace('/',''))
    out_file.write(',')
    out_file.write(','.join(['PercSharedGazeAfterMotherFollowInfant','PercSharedGazeAfterInfantFollowMother',
                             'NumDyadicShiftsPerMin']))
    out_file.write('\n')

    for subject_id, runs in subjects.iteritems():
        session=InteractionSession(data_dir, subject_id, coder, age, visit_num, runs)
        session.extract_measures()
        out_file.write('%d,%s' % (subject_id,age))
        for idx in range(len(infant_targets)):
            out_file.write(',%.4f' % session.measures['infant_perc_time_target'][0,idx])
        for idx in range(len(infant_horiz_dirs)):
            out_file.write(',%.4f' % session.measures['infant_perc_time_horiz_dir'][0,idx])
        for idx in range(len(infant_vert_dirs)):
            out_file.write(',%.4f' % session.measures['infant_perc_time_vert_dir'][0,idx])
        for idx in range(len(mother_targets)):
            out_file.write(',%.4f' % session.measures['mother_perc_time_target'][0,idx])
        for idx in range(len(mother_horiz_dirs)):
            out_file.write(',%.4f' % session.measures['mother_perc_time_horiz_dir'][0,idx])
        for idx in range(len(mother_vert_dirs)):
            out_file.write(',%.4f' % session.measures['mother_perc_time_vert_dir'][0,idx])
        out_file.write(',')
        out_file.write(','.join(['%.4f' % session.measures[x] for x in ['shared_gaze_perc_time',
                                                                        'mutual_gaze_perc_time',
                                                                        'different_gaze_perc_time',
                                                                        'infant_face_mother_other_perc_time',
                                                                        'mother_face_infant_other_perc_time',
                                                                        'num_infant_gaze_shifts_per_min',
                                                                        'num_infant_saccades_per_min',
                                                                        'num_infant_head_turns_per_min',
                                                                        'num_mother_gaze_shifts_per_min',
                                                                        'num_mother_saccades_per_min',
                                                                        'num_mother_head_turns_per_min',
                                                                        'num_infant_gaze_shifts_mother_observed_per_min',
                                                                        'num_infant_gaze_shifts_mother_observed_per_gaze_shift',
                                                                        'num_mother_gaze_shifts_infant_observed_per_min',
                                                                        'num_mother_gaze_shifts_infant_observed_per_gaze_shift',
                                                                        'num_mother_object_to_infant_gaze_shifts_infant_observed_per_min',
                                                                        'num_mother_infant_to_object_gaze_shifts_infant_observed_per_min',
                                                                        'num_mother_object_to_infant_gaze_shifts_infant_observed_per_mother_object_to_infant_gaze_shift',
                                                                        'num_mother_infant_to_object_gaze_shifts_infant_observed_per_mother_infant_to_object_gaze_shift',
                                                                        'infant_follow_mother_per_min',
                                                                        'mother_follow_infant_per_min',
                                                                        'infant_follow_mother_per_gaze_shift',
                                                                        'mother_follow_infant_per_gaze_shift',
                                                                        'infant_follow_mother_per_gaze_shift_observed',
                                                                        'mother_follow_infant_per_gaze_shift_observed',
                                                                        'infant_follow_mother_per_infant_face_mother_other',
                                                                        'mother_follow_infant_per_mother_face_infant_other',
                                                                        'infant_not_follow_mother_per_min',
                                                                        'mother_not_follow_infant_per_min',
                                                                        'infant_not_follow_mother_per_gaze_shift',
                                                                        'mother_not_follow_infant_per_gaze_shift',
                                                                        'infant_not_follow_mother_per_gaze_shift_observed',
                                                                        'mother_not_follow_infant_per_gaze_shift_observed',
                                                                        'infant_sees_mother_follow_per_min',
                                                                        'infant_sees_mother_follow_per_mother_follow',
                                                                        'infant_sees_mother_not_follow_per_min',
                                                                        'infant_sees_mother_not_follow_per_mother_not_follow',
                                                                        'infant_sees_mother_gaze_infant_per_min',
                                                                        'infant_sees_mother_gaze_infant_per_infant_gaze_object_to_mother',
                                                                        'num_infant_object_to_mother_gaze_shifts_per_min',
                                                                        'num_infant_object_to_object_gaze_shifts_per_min',
                                                                        'num_infant_mother_to_object_gaze_shifts_per_min',
                                                                        'num_infant_object_to_mother_gaze_shifts_per_gaze_shift',
                                                                        'num_infant_object_to_object_gaze_shifts_per_gaze_shift',
                                                                        'num_infant_mother_to_object_gaze_shifts_per_gaze_shift',
                                                                        'num_mother_object_to_infant_gaze_shifts_per_min',
                                                                        'num_mother_object_to_object_gaze_shifts_per_min',
                                                                        'num_mother_infant_to_object_gaze_shifts_per_min',
                                                                        'num_mother_object_to_infant_gaze_shifts_per_gaze_shift',
                                                                        'num_mother_object_to_object_gaze_shifts_per_gaze_shift',
                                                                        'num_mother_infant_to_object_gaze_shifts_per_gaze_shift']]))

        for idx in range(1,len(infant_targets)):
            out_file.write(',%.4f' % session.measures['infant_gaze_shifts_to_target_per_min'][0,idx-1])
        for idx in range(1,len(infant_targets)):
            out_file.write(',%.4f' % session.measures['infant_gaze_shifts_from_target_per_min'][0,idx-1])
        for idx in range(1,len(mother_targets)):
            out_file.write(',%.4f' % session.measures['mother_gaze_shifts_to_target_per_min'][0,idx-1])
        for idx in range(1,len(mother_targets)):
            out_file.write(',%.4f' % session.measures['mother_gaze_shifts_from_target_per_min'][0,idx-1])
        out_file.write(',')
        out_file.write(','.join(['%.4f' % session.measures[x] for x in ['perc_shared_gaze_after_mother_follow_infant',
                                                                        'perc_shared_gaze_after_infant_follow_mother',
                                                                        'num_dyadic_shifts_per_min']]))
        out_file.write('\n')

    out_file.close()


def get_mat(run, event):
    if event=='Infant Face Mother Other':
        return run.infant_face_mother_other_mat
    elif event=='Infant Follow Mother':
        return run.infant_follow_mother_mat
    elif event=='Infant Not Follow Mother':
        return run.infant_not_follow_mother_mat
    elif event=='Infant Sees Mother Follow':
        return run.infant_sees_mother_follow_mat
    elif event=='Infant Sees Mother Gaze Infant':
        return run.infant_sees_mother_gaze_infant_mat
    elif event=='Infant Sees Mother Not Follow':
        return run.infant_sees_mother_not_follow_mat
    elif event=='Infant Sees Mother Gaze Shift':
        return run.infant_sees_mother_gaze_shift
    elif event=='Mother Face Infant Other':
        return run.mother_face_infant_other_mat
    elif event=='Mother Follow Infant':
        return run.mother_follow_infant_mat
    elif event=='Mother Not Follow Infant':
        return run.mother_not_follow_infant_mat
    elif event=='Mother Sees Infant Gaze shift':
        return run.mother_sees_infant_gaze_shift
    elif event=='Mutual Gaze':
        return run.mutual_gaze_mat
    elif event=='Shared Gaze':
        return run.shared_gaze_mat
    elif event=='Different Gaze':
        return run.different_gaze_mat
    return None


def event_triggered_ave(data_dir, subjects, age, coder, visit_num, epoch_width):
    subj_sessions={}
    for subject_id, runs in subjects.iteritems():
        session=InteractionSession(data_dir, subject_id, coder, age, visit_num, runs)
        session.extract_measures()
        subj_sessions[subject_id]=session
    events=['Infant Face Mother Other','Infant Follow Mother','Infant Not Follow Mother','Infant Sees Mother Follow',
            'Infant Sees Mother Gaze Infant','Infant Sees Mother Not Follow','Infant Sees Mother Gaze Shift',
            'Mother Face Infant Other','Mother Follow Infant','Mother Not Follow Infant','Mother Sees Infant Gaze shift',
            'Mutual Gaze','Shared Gaze','Different Gaze']
    epoch_width_s=epoch_width/25
    bins=np.linspace(-epoch_width_s/2,epoch_width_s/2,51)
    bin_width=np.diff(bins)[0]
    plot_bins=bins[:-1]+bin_width/2
    fig,axs=plt.subplots(len(events),len(events))
    for idx1,trigger_event in enumerate(events):
        for idx2, target_event in enumerate(events):
            subj_hists=np.zeros((len(subjects),len(bins)-1))
            for s_idx, (subject_id, session) in enumerate(subj_sessions.iteritems()):
                target_times=[]
                for run in session.interaction_runs:
                    trigger_mat=get_mat(run, trigger_event)
                    target_mat=get_mat(run, target_event)
                    trigger_diff_mat=np.diff(trigger_mat[0,:])
                    target_diff_mat=np.diff(target_mat[0,:])
                    start_idxs=np.where(trigger_diff_mat==1)[0]
                    for start_idx in start_idxs:
                        stop_idxs=np.where(trigger_diff_mat[start_idx:]==-1)[0]
                        if len(stop_idxs):
                            stop_idx=start_idx+stop_idxs[0]
                            pre_aligned_times=np.where(target_mat[0,np.max([0, start_idx-epoch_width/2]):start_idx]==1)[0]
                            target_times.extend(pre_aligned_times-epoch_width/2)
                            post_aligned_times=np.where(target_mat[0,stop_idx:np.min([target_mat.shape[1],stop_idx+epoch_width/2])]==1)[0]
                            target_times.extend(post_aligned_times)
                [n,b]=np.histogram(np.array(target_times)/25.0,bins=bins)
                subj_hists[s_idx,:]=n
            axs[idx2,idx1].bar(plot_bins,np.mean(subj_hists,axis=0),width=bin_width)
            axs[idx2,idx1].plot([0,0],axs[idx2,idx1].get_ylim(),'k--')
            if idx2==len(events)-1:
                axs[idx2,idx1].set_xlabel(trigger_event, fontsize=7,rotation=45)
                axs[idx2,idx1].xaxis.set_label_coords(0, -0.1)
            else:
                axs[idx2,idx1].set_xticklabels([])
            if idx1==0:
                axs[idx2,idx1].set_ylabel(target_event, fontsize=7,rotation=45)
            axs[idx2,idx1].set_xlim(-epoch_width_s/2, epoch_width_s/2)
            #axs[idx2,idx1].set_ylim(0,np.max([100,np.max(np.mean(subj_hists,axis=0))]))
            #axs[idx2,idx1].set_yticklabels([])


def event_triggered_ave_comparison(data_dir_3m, subjects_3m, coder_3m, data_dir_6m, subjects_6m, coder_6m, epoch_width):
    subj_sessions_3m={}
    for subject_id, runs in subjects_3m.iteritems():
        session=InteractionSession(data_dir_3m, subject_id, coder_3m, '3m', 1, runs)
        session.extract_measures()
        subj_sessions_3m[subject_id]=session
    subj_sessions_6m={}
    for subject_id, runs in subjects_6m.iteritems():
        session=InteractionSession(data_dir_6m, subject_id, coder_6m, '6m', 2, runs)
        session.extract_measures()
        subj_sessions_6m[subject_id]=session

    events=['Infant Face Mother Other','Infant Follow Mother','Infant Not Follow Mother','Infant Sees Mother Follow',
            'Infant Sees Mother Gaze Infant','Infant Sees Mother Not Follow','Infant Sees Mother Gaze Shift',
            'Mother Face Infant Other','Mother Follow Infant','Mother Not Follow Infant','Mother Sees Infant Gaze shift',
            'Mutual Gaze','Shared Gaze','Different Gaze']
    epoch_width_s=epoch_width/25
    bins=np.linspace(-epoch_width_s/2,epoch_width_s/2,51)
    bin_width=np.diff(bins)[0]
    plot_bins=bins[:-1]+bin_width/2
    fig,axs=plt.subplots(len(events),len(events))
    for idx1,trigger_event in enumerate(events):
        for idx2, target_event in enumerate(events):
            subj_hists_3m=np.zeros((len(subjects_3m),len(bins)-1))
            for s_idx, (subject_id, session) in enumerate(subj_sessions_3m.iteritems()):
                target_times=[]
                for run in session.interaction_runs:
                    trigger_mat=get_mat(run, trigger_event)
                    target_mat=get_mat(run, target_event)
                    trigger_diff_mat=np.diff(trigger_mat[0,:])
                    target_diff_mat=np.diff(target_mat[0,:])
                    start_idxs=np.where(trigger_diff_mat==1)[0]
                    for start_idx in start_idxs:
                        stop_idxs=np.where(trigger_diff_mat[start_idx:]==-1)[0]
                        if len(stop_idxs):
                            stop_idx=start_idx+stop_idxs[0]
                            pre_aligned_times=np.where(target_mat[0,np.max([0, start_idx-epoch_width/2]):start_idx]==1)[0]
                            target_times.extend(pre_aligned_times-epoch_width/2)
                            post_aligned_times=np.where(target_mat[0,stop_idx:np.min([target_mat.shape[1],stop_idx+epoch_width/2])]==1)[0]
                            target_times.extend(post_aligned_times)
                [n,b]=np.histogram(np.array(target_times)/25.0,bins=bins)
                subj_hists_3m[s_idx,:]=n
            subj_hists_6m=np.zeros((len(subjects_6m),len(bins)-1))
            for s_idx, (subject_id, session) in enumerate(subj_sessions_6m.iteritems()):
                target_times=[]
                for run in session.interaction_runs:
                    trigger_mat=get_mat(run, trigger_event)
                    target_mat=get_mat(run, target_event)
                    trigger_diff_mat=np.diff(trigger_mat[0,:])
                    target_diff_mat=np.diff(target_mat[0,:])
                    start_idxs=np.where(trigger_diff_mat==1)[0]
                    for start_idx in start_idxs:
                        stop_idxs=np.where(trigger_diff_mat[start_idx:]==-1)[0]
                        if len(stop_idxs):
                            stop_idx=start_idx+stop_idxs[0]
                            pre_aligned_times=np.where(target_mat[0,np.max([0, start_idx-epoch_width/2]):start_idx]==1)[0]
                            target_times.extend(pre_aligned_times-epoch_width/2)
                            post_aligned_times=np.where(target_mat[0,stop_idx:np.min([target_mat.shape[1],stop_idx+epoch_width/2])]==1)[0]
                            target_times.extend(post_aligned_times)
                [n,b]=np.histogram(np.array(target_times)/25.0,bins=bins)
                subj_hists_6m[s_idx,:]=n
            axs[idx2,idx1].bar(plot_bins,np.mean(subj_hists_3m,axis=0),width=bin_width, color='b', alpha=0.25)
            axs[idx2,idx1].bar(plot_bins,np.mean(subj_hists_6m,axis=0),width=bin_width, color='r', alpha=0.25)
            axs[idx2,idx1].plot([0,0],axs[idx2,idx1].get_ylim(),'k--')
            if idx2==len(events)-1:
                axs[idx2,idx1].set_xlabel(trigger_event, fontsize=7,rotation=45)
                axs[idx2,idx1].xaxis.set_label_coords(0, -0.1)
            else:
                axs[idx2,idx1].set_xticklabels([])
            if idx1==0:
                axs[idx2,idx1].set_ylabel(target_event, fontsize=7,rotation=45)
            axs[idx2,idx1].set_xlim(-epoch_width_s/2, epoch_width_s/2)
            #axs[idx2,idx1].set_ylim(0,np.max([100,np.max(np.mean(subj_hists,axis=0))]))
            #axs[idx2,idx1].set_yticklabels([])

def export_csv(data_dir, subjects, age, coder, visit_num, output_filename):
    infant_targets=['Head turn','Per Toy Right','Right Toy','Front Toy Right','Front Toy Left','Left Toy',
                    'Per Toy Left','Mother face','Mother hand','Mother body','Own hand','Own foot','Own body','Camera',
                    'Highchair','Other/ambig']
    infant_horiz_dirs=['Back','Back Right','Far Right','Mid Right','Near Right','Centre','Near Left','Mid Left',
                       'Far Left','Back Left']
    infant_vert_dirs=['Up','Middle','Down']
    mother_targets=['Head turn','Rear Toy Right','Per Toy Right','Front Toy Right','Front Toy Left','Per Toy Left',
                    'Rear Toy Left','Infant face','Infant hand','Infant foot','Infant body','Own hand','Own body',
                    'Camera','Highchair','Other/ambig']
    mother_horiz_dirs=['Back','Back Right','Far Right','Mid Right','Near Right','Centre','Near Left','Mid Left',
                       'Far Left','Back Left']
    mother_vert_dirs=['Up','Middle','Down']

    out_file=open(output_filename,'w')
    out_file.write('Subject,Age')
    for target in infant_targets:
        out_file.write(',InfantPerc%s' % target.title().replace(' ','').replace('/',''))
    for dir in infant_horiz_dirs:
        out_file.write(',InfantPerc%s' % dir.title().replace(' ',''))
    for dir in infant_vert_dirs:
        out_file.write(',InfantPerc%s' % dir.title().replace(' ',''))
    out_file.write(',InfantGazeShiftsPerMin')
    # 0 is head turn
    for target in infant_targets[1:]:
        out_file.write(',InfantFixations%sPerMin' % target.title().replace(' ','').replace('/',''))

    for target in mother_targets:
        out_file.write(',MotherPerc%s' % target.title().replace(' ','').replace('/',''))
    for dir in mother_horiz_dirs:
        out_file.write(',MotherPerc%s' % dir.title().replace(' ',''))
    for dir in mother_vert_dirs:
        out_file.write(',MotherPerc%s' % dir.title().replace(' ',''))
    out_file.write(',MotherGazeShiftsPerMin')
    # 0 is head turn
    for target in mother_targets[1:]:
        out_file.write(',MotherFixations%sPerMin' % target.title().replace(' ','').replace('/',''))

    out_file.write(',SharedGaze,MutualGaze,InfantFaceMotherOther,MotherFaceInfantOther,DifferentGaze,InfantFollowMotherPerMin,NormInfantFollowMotherPerMin,MotherFollowInfantPerMin,NormMotherFollowInfantPerMin,InfantSeesFollowedPerMin,NormInfantSeesFollowedPerMin\n')


    for subj_id, sessions in subjects.iteritems():
        files_to_read=[]
        if not len(sessions):
            files_to_read.append(os.path.join(data_dir,'%d%s%d_derived.csv' % (subj_id,coder,visit_num)))
        else:
            for session in sessions:
                files_to_read.append(os.path.join(data_dir,'%d' % subj_id,'%d%s%d_%d_derived.csv' % (subj_id,coder,visit_num,session)))

        # Total number of frames across all sessions
        num_frames=0

        # Number of frames for each category
        group_frame_counts={
            'Infant':{},
            'Mother':{},
            'Level 2':{},
            'Level 3':{},
            'Level 4':{}
        }

        # Read each file
        for filename in files_to_read:
            file=open(filename,'r')

            # Current group categories belong to
            current_group=None

            for l in file:
                lines=l.split('\n')
                for line in lines:
                    cols=line.replace('\r','').split(',')

                    if len(cols)>1:

                        # First line - get number of frames
                        if cols[0]=='1':
                            frames=cols[2:]
                            num_frames+=len(frames)

                        # Set current group
                        elif cols[0]=='Infant' or cols[0]=='Mother':
                            current_group=cols[0]
                        elif cols[1]=='Level 2' or cols[1]=='Level 3' or cols[1]=='Level 4':
                            current_group=cols[1]

                        # Read category and frames
                        elif len(cols[1])>0:
                            # Get category name and init frame count to 0
                            event_name=cols[1]
                            if not event_name in group_frame_counts[current_group]:
                                group_frame_counts[current_group][event_name]=0

                            # Update frame count
                            for idx in range(2,len(cols)):
                                if cols[idx]=='x':
                                    group_frame_counts[current_group][event_name]+=1
            file.close()

        # Category matrices
        infant_target_mat=np.zeros((len(infant_targets),num_frames))
        mother_target_mat=np.zeros((len(mother_targets),num_frames))
        infant_follow_mother_mat=np.zeros((1,num_frames))
        mother_follow_infant_mat=np.zeros((1,num_frames))
        infant_sees_followed_mat=np.zeros((1,num_frames))

        # Read each file
        for filename in files_to_read:
            file=open(filename,'r')

            # Current group categories belong to
            current_group=None

            for l in file:
                lines=l.split('\n')
                for line in lines:
                    cols=line.split(',')

                    if len(cols)>1:

                        # Set current group
                        if cols[0]=='Infant' or cols[0]=='Mother':
                            current_group=cols[0]

                        # Read category and frames
                        elif len(cols[1])>0:
                            # Get category frame
                            event_name=cols[1]

                            # Get category index for infant and mother target
                            evt_idx=-1
                            if current_group=='Infant' and event_name in infant_targets:
                                evt_idx=infant_targets.index(event_name)
                            elif current_group=='Mother' and event_name in mother_targets:
                                evt_idx=mother_targets.index(event_name)

                            # Set matrix for infant and mother target
                            if evt_idx>-1:
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx]=='x':
                                        if current_group=='Infant':
                                            infant_target_mat[evt_idx,col_idx-2]=1
                                        elif current_group=='Mother':
                                            mother_target_mat[evt_idx,col_idx-2]=1

                            # Set matrix for level 3 events
                            elif event_name=='Infant follow mother':
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx]=='x':
                                        infant_follow_mother_mat[0,col_idx-2]=1
                            elif event_name=='Mother follow infant':
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx]=='x':
                                        mother_follow_infant_mat[0,col_idx-2]=1
                            elif event_name=='Infant Sees Followed':
                                for col_idx in range(2,len(cols)):
                                    if cols[col_idx]=='x':
                                        infant_sees_followed_mat[0,col_idx-2]=1
            file.close()

        # List of gaze targets for computing fixations/min
        infant_gaze_target=[]
        mother_gaze_target=[]

        # Count
        infant_follow_mother_freq=0.0
        mother_follow_infant_freq=0.0
        infant_sees_followed_freq=0.0

        # Loop through all frames
        for i in range(num_frames):
            # Find infant gaze target
            nz=np.where(infant_target_mat[:,i]>0)[0]
            if len(nz):
                infant_target_idx=nz[0]
                # 0 is head turn, check that this is a new gaze target
                if infant_target_idx>0 and (len(infant_gaze_target)==0 or not infant_target_idx==infant_gaze_target[-1]):
                    infant_gaze_target.append(infant_target_idx)

            # Find mother gaze target
            nz=np.where(mother_target_mat[:,i]>0)[0]
            if len(nz):
                mother_target_idx=nz[0]
                # 0 is head turn, check that this is a new gaze target
                if mother_target_idx>0 and (len(mother_gaze_target)==0 or not mother_target_idx==mother_gaze_target[-1]):
                    mother_gaze_target.append(mother_target_idx)

            # Count level 3 events - unique instances
            if infant_follow_mother_mat[0,i]>0 and (i==0 or infant_follow_mother_mat[0,i-1]==0):
                infant_follow_mother_freq+=1.0
            if mother_follow_infant_mat[0,i]>0 and (i==0 or mother_follow_infant_mat[0,i-1]==0):
                mother_follow_infant_freq+=1.0
            if infant_sees_followed_mat[0,i]>0 and (i==0 or infant_sees_followed_mat[0,i-1]==0):
                infant_sees_followed_freq+=1.0

        total_min=(num_frames/25.0)/60.0
        # Gaze shifts per min
        infant_gaze_shifts_per_min=float(len(infant_gaze_target))/total_min
        mother_gaze_shifts_per_min=float(len(mother_gaze_target))/total_min

        # Level 3 events per min
        infant_follow_mother_per_min=float(infant_follow_mother_freq)/total_min
        mother_follow_infant_per_min=float(mother_follow_infant_freq)/total_min
        infant_sees_followed_per_min=float(infant_sees_followed_freq)/total_min

        # Convert gaze target lists to arrays
        infant_gaze_target=np.array(infant_gaze_target)
        mother_gaze_target=np.array(mother_gaze_target)

        # Compute fixations per minute for each target
        infant_fixations_per_min=[]
        mother_fixations_per_min=[]
        # 0 is head turn
        for i in range(1,len(infant_targets)):
            # Find number of fixations to this target / 3 min
            infant_fixations_per_min.append(float(len(np.where(infant_gaze_target==i)[0]))/total_min)
            # 0 is head turn
        for i in range(1,len(mother_targets)):
            # Find number of fixations to this target / 3 min
            mother_fixations_per_min.append(float(len(np.where(mother_gaze_target==i)[0]))/total_min)

        # Normalize infant follow mother / min by infant fixations per min on mother face
        # -1 because 0 is head turn
        norm_infant_follow_mother_per_min=infant_follow_mother_per_min/infant_fixations_per_min[infant_targets.index('Mother face')-1]
        # Normalize mother follow infant / min by mother fixations per min on infant face
        # -1 because 0 is head turn
        norm_mother_follow_infant_per_min=mother_follow_infant_per_min/mother_fixations_per_min[mother_targets.index('Infant face')-1]

        # Normalize infant sees mother follow / min by mother follow infant / min
        norm_infant_sees_followed_per_min=infant_sees_followed_per_min/mother_follow_infant_per_min

        # Convert group category frame counts to percentages
        group_event_perc={}
        for group in group_frame_counts:
            group_event_perc[group]={}
            for evt in group_frame_counts[group]:
                group_event_perc[group][evt]=float(group_frame_counts[group][evt])/float(num_frames)

        out_file.write('%d,%s' % (subj_id,age))
        for target in infant_targets:
            out_file.write(',%.4f' % group_event_perc['Infant'][target])
        for dir in infant_horiz_dirs:
            out_file.write(',%.4f' % group_event_perc['Infant'][dir])
        for dir in infant_vert_dirs:
            out_file.write(',%.4f' % group_event_perc['Infant'][dir])
        out_file.write(',%.4f' % infant_gaze_shifts_per_min)
        for fpm in infant_fixations_per_min:
            out_file.write(',%.4f' % fpm)

        for target in mother_targets:
            out_file.write(',%.4f' % group_event_perc['Mother'][target])
        for dir in mother_horiz_dirs:
            out_file.write(',%.4f' % group_event_perc['Mother'][dir])
        for dir in mother_vert_dirs:
            out_file.write(',%.4f' % group_event_perc['Mother'][dir])
        out_file.write(',%.4f' % mother_gaze_shifts_per_min)
        for fpm in mother_fixations_per_min:
            out_file.write(',%.4f' % fpm)

        out_file.write(',%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n' %
                       (group_event_perc['Level 2']['Shared gaze'],
                        group_event_perc['Level 2']['Mutual gaze'],
                        group_event_perc['Level 2']['Infant face mother other'],
                        group_event_perc['Level 2']['Mother face infant other'],
                        group_event_perc['Level 2']['Different gaze'],
                        infant_follow_mother_per_min,
                        norm_infant_follow_mother_per_min,
                        mother_follow_infant_per_min,
                        norm_mother_follow_infant_per_min,
                        infant_sees_followed_per_min,
                        norm_infant_sees_followed_per_min))
    out_file.close()

if __name__=='__main__':
    subjects_3m={
        103: [1,2,3],
        105: [],
        106: [],
        108: [],
        109: [],
        110: [],
        111: [],
        112: [1,2,3],
        113: [],
        114: [],
        115: [],
        117: [],
        118: [],
        119: [],
        120: [],
        121: [1,2,3],
        122: [],
        123: [1,2],
        127: [],
        126: [],
        128: [],
        129: [],
        130: [],
        131: [],
        133: [],
        135: [],
        138: [],
        139: [],
        140: [1,2],
        141: [],
        142: [],
        143: [],
        144: [],
        146: [],
        147: [1,2],
        148: [1,2],
        149: []
    }
    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
        subjects_3m,'3m','HR',1,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/3.5months_derived_events.csv')
#    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
#        subjects_3m,'3m','HR',1,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/3.5months_derived_events_5s.csv')
#    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
#        subjects_3m,'3m','HR',1,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/3.5months_derived_events_periph3.csv')
#    event_triggered_ave('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
#        subjects_3m,'3m','HR',1,25*6)

#    export_derived_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
#         subjects_3m,'3m','HR',1, '/data2/Dropbox/joint_attention/infant_gaze_eeg-interactions/output/processed_behaviour/3m')

    subjects_6m={
        102: [],
        103: [],
        105: [],
        106: [],
        108: [],
        109: [],
        110: [1,2],
        111: [],
        112: [1,2],
        113: [],
        114: [],
        115: [],
        116: [],
        117: [],
        118: [1,2],
        119: [],
        120: [1,2],
        121: [],
        122: [],
        123: [],
        126: [],
        127: [],
        128: [],
        129: [],
        130: [],
        131: [],
        133: [],
        135: [],
        138: [],
        139: [],
        140: [],
        141: [],
        143: [],
        144: [],
        146: [],
        147: [],
        148: [],
        149: []
    }
    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived',
        subjects_6m,'6m','HR',2,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/6.5months_derived_events.csv')
#    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived',
#        subjects_6m,'6m','HR',2,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/6.5months_derived_events_periph3.csv')
#    export_wide_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived',
#        subjects_6m,'6m','HR',2,'/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/6.5months_derived_events_5s.csv')

#    event_triggered_ave('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived',
#        subjects_6m,'6m','HR',2,25*6)
#    export_derived_csv('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived',
#        subjects_6m,'6m','HR',2, '/data2/Dropbox/joint_attention/infant_gaze_eeg-interactions/output/processed_behaviour/6m')

#    event_triggered_ave_comparison('/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_3m_interaction_coding/3.5months_derived', subjects_3m, 'HR',
#        '/data2/Dropbox/joint_attention/infant_gaze_eeg/Interaction coding/Final_6m_interaction_coding/6.5months_derived', subjects_6m, 'HR',
#        25*6)

#    plt.show()

    #    run=InteractionRun('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Coding/Interaction coding/Final_3m_interaction_coding/3.5months_derived',
    #        106,'HR',1)
    #
    #    run.extract_level2_events()
    #    run.extract_level3_events()
    #    run.extract_level4_events()
    #    run.export_csv('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/Coding/Interaction coding/Final_3m_interaction_coding/3.5months_derived/106_test.csv')