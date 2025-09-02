function data=add_event_durations(data)

% Adjust event durations - otherwise will complain when we try to set the duration of no attention events
event_durations=[];
% Loop through each event in the file
for i=1:length(data.event)
    % Add a duration of 1 time step to the list of event durations
    event_durations=[event_durations 0.001*data.srate*data.srate];       
end
data=pop_editeventfield(data,'duration',event_durations);
