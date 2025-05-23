function Vibrotactile_Detection_Trial_Stop(behavior)

%
% Vibrotactile_Detection_Trial_Stop.m
% 
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_TRIAL_STOP stops and scores, i.e. determines the
%   outcome of, the current trial in the SensiTrak vibrotactile detection
%   task based on the time held by the animal.
%   
%   UPDATE LOG:
%   2024-11-13 - Drew Sloan - Function first implemented, adapted from
%                             "Vibrotactile_Detection_Task_Start_Trial.m".
%


behavior.session.fcn.haptic.stop();                                         %Stop the vibration train.
behavior.session.trial(end).stop();                                         %Stop the current trial.  

%Score the outcome and reinforce based on the response time.
signal = behavior.session.trial(end).signal.force.peek();                   %Grab the trial signals from the buffer.
i = find(signal(2,:) >= behavior.session.params.force_thresh, 1, 'last');   %Find the last unfiltered sample above the force threshold.
if ~isempty(i)                                                              %If a sample was found...
    behavior.session.trial(end).params.time_held = ...
        1e-6*(signal(1,i) - behavior.session.trial(end).time.start.micros); %Calculate the time held from the sample timestamps.
end
if behavior.session.trial(end).params.time_held >= ....
        behavior.session.trial(end).params.hold_time                        %If the rat held longer than the required hold time...
    if behavior.session.trial(end).params.time_held < ...
            (behavior.session.trial(end).params.hold_time + ...
            behavior.session.params.hitwin)                                 %If the animal released before the end of the hit window.
        if behavior.session.trial(end).params.catch == 1                    %If this was a catch trial.params...
            behavior.session.trial(end).outcome = 'FALSE ALARM';            %Label the trial as a false alarm.
        else                                                                %Otherwise, if this wasn't a catch trial.params...
            behavior.session.trial(end).outcome = 'HIT';                    %Label the trial as a hit.
            behavior.session.fcn.feed();                                    %Trigger a feeding.
            behavior.session.trial(end).time.reward = datetime;             %Save the feeding time.     
            behavior.session.count.feed = behavior.session.count.feed + 1;  %Increment the feedings count.
        end
    else                                                                    %Otherwise, if the animal didn't release before the end of the hit window...
        if behavior.session.trial(end).params.catch == 1                    %If this was a catch trial.params...
            behavior.session.trial(end).outcome = 'CORRECT REJECTION';      %Label the trial as a correct rejection.
        else                                                                %Otherwise, if this wasn't a catch trial.params...
            behavior.session.trial(end).outcome = 'MISS';                   %Label the trial as a miss.
        end
    end
else                                                                        %Otherwise, if the rat didn't hold...
    behavior.session.trial(end).outcome = 'ABORT';                          %Label the trial as an abort.
end 

