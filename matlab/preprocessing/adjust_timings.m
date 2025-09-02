function data=adjust_timings(subj_id, age, data, delay)
% function adjust_timings(data)
% Adjust event timings based on DIN events or timing test
% INPUT:
%     data: EEG data to adjust event timings
%     delay: delay from the timing test

% Determine if contains DIN events
contains_dins=false;
% Loop through all events in the dataset
for i=1:length(data.event)
    % If the type of this event starts with D -> this is a DIN event
    if data.event(i).type(1)=='D'
        contains_dins=true;
    end
end

% If there are DIN events, adjust timings based on that - 105 has messed up DIN signals
if contains_dins && (~strcmp(age,'6m') || subj_id~=105)
    disp('Adjusting timing using DIN events');

    % Loop through each event
    for evt_idx=1:length(data.event)
        evt=data.event(evt_idx).type;

        % If this is the ima1 event - start of static period
        if strcmp(evt,'ima1')
            % Time between this event and next event (should be DIN)
            correction=(data.event(evt_idx+1).latency-data.event(evt_idx).latency);
            % Update time of ima1 event
            data.event(evt_idx).latency=data.event(evt_idx).latency+correction;

            % Adjust preceding imov event (stop if get to mov1 or ima2 or ima1 or blk1 or blk2)
            for pre_evt_idx=evt_idx-1:-1:1
                pre_evt=data.event(pre_evt_idx).type;
                if strcmp(pre_evt,'imov')
                    data.event(pre_evt_idx).latency=data.event(pre_evt_idx).latency+correction;
                    break
                elseif length(strmatch(pre_evt, {'mov1','ima2','ima1','blk1','blk2','pgst','pgen'}))>0
                    break
                end
            end

            % Adjust following ima2 event (stop if get to imov or ima1 or mov1 or blk1 or blk2)
            for post_evt_idx=evt_idx+1:length(data.event)
                post_evt=data.event(post_evt_idx).type;
                if strcmp(post_evt,'ima2')
                    data.event(post_evt_idx).latency=data.event(post_evt_idx).latency+correction;
                    break
                elseif length(strmatch(pre_evt, {'imov','mov1','ima1','blk1','blk2','pgst','pgen'}))>0
                    break
                end
            end

	    % Adjust following mov1 event (stop if get to imov or ima1 or ima2 or blk1 or blk2)
            for post_evt_idx=evt_idx+1:length(data.event)
                post_evt=data.event(post_evt_idx).type;
                if strcmp(post_evt,'mov1')
                    data.event(post_evt_idx).latency=data.event(post_evt_idx).latency+correction;
                    break
                elseif length(strmatch(pre_evt, {'imov','ima1','ima2','blk1','blk2','pgst','pgen'}))>0
                    break
                end
            end
        end
    end
% Adjust time of events based on timing test
else
    % Loop through each event
    for i=1:length(data.event)
        % Only adjust events to signal onset of visual stimuli
        if strcmp(data.event(i).type,'imov') || strcmp(data.event(i).type,'ima1') || strcmp(data.event(i).type,'ima2') || strcmp(data.event(i).type,'mov1') || strcmp(data.event(i).type,'pgst') || strcmp(data.event(i).type,'pgen')
            % Add the delay (in time steps) to the event latency
            %disp(['old latency=' num2str(data.event(i).latency)]);
            data.event(i).latency=data.event(i).latency+(delay*data.srate);
            %disp(['new latency=' num2str(data.event(i).latency)]);
        end
    end
end

% Delete DIN events
events_to_delete=[];
% Loop through each event in the file
for i=1:length(data.event)
    if data.event(i).type(1)=='D'
        events_to_delete(end+1)=i;
    end
end
data=pop_editeventvals(data,'delete',events_to_delete);
