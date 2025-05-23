function Vibrotactile_Detection_Trial_Reset(behavior)

%
% Vibrotactile_Detection_Reset_behavior.session.trial(t).m
%   
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_TRIAL_RESET resets all trial variables at the 
%   start of a session or following a completed trial to prepare monitoring
%   for the next trial initiation for the SensiTrak vibrotactile detection 
%   task program.
%   
%   UPDATE LOG:
%   2024-11-13 - Drew Sloan - Function first implemented, adapted from
%                             "Vibrotactile_Detection_Task_Reset_Trial_Data.m"
%   2025-05-21 - Drew Sloan - Renamed from 
%                             "Vibrotactile_Detection_Reset_Trial" to
%                             "Vibrotactile_Detection_Trial_Reset".
%

%Create a new Vulintus_Behavior_Trial_Class instance.
behavior.session.count.trial = behavior.session.count.trial + 1;            %Increment the trial counter.
t = behavior.session.count.trial;                                           %Copy the current trial index to a simpler variable.
behavior.session.trial(t) = Vulintus_Behavior_Trial_Class(datetime('now')); %Create a new trial class instance.
behavior.session.trial(t).outcome = 'MISS';                                 %Assume the animal will score a miss.
behavior.session.trial(t).params.time_held = 0;                             %Assume the animal will hold for zero seconds.

%Set the vibration parameters.
s = behavior.session.params.stim_index;                                     %Copy the current stim index to a shorter variable name.
behavior.session.trial(t).params.vib_dur = behavior.session.params.vib_dur; %Copy the vibration pulse duration to the trials structure.
behavior.session.trial(t).params.vib_rate = ...
    behavior.session.params.stim_block(s,1);                                %Set the vibration rate, in Hertz.
behavior.session.trial(t).params.gap_length = ...
    behavior.session.params.stim_block(s,2);                                %Set the gap length, in milliseconds.
behavior.session.trial(t).params.vib_ipi = ...
    round(1000/behavior.session.trial(t).params.vib_rate);                  %Calculate the vibration inter-pulse period, in milliseconds.
behavior.session.trial(t).params.actual_vib_rate = ...
    1000/behavior.session.trial(t).params.vib_ipi;                          %Calculate the actual vibration rate, in Hertz.
behavior.session.trial(t).params.catch = ...
    behavior.session.params.stim_block(s,3);                                %Fetch the catch trial flag from the stimulus block to see if this is a catch behavior.session.trial(t).

%Set the hold time.
if t == 1 || behavior.session.trial(t-1).outcome(1) ~= 'A'                  %If this is the first trial or the last trial did not end in an abort...
    num_hits = sum(behavior.session.count.outcomes(3,:));                   %Grab the total number of hits.
    num_misses = sum(behavior.session.count.outcomes(4,:));                 %Grab the total number of misses.
    lb = behavior.session.params.hold_min_lb + ...
        num_hits*behavior.session.params.hold_incr_lb + ...
        num_misses*behavior.session.params.hold_incr_lb*behavior.session.params.miss_wt;    %Calculate the hold time lower bound.
    ub = behavior.session.params.hold_min_ub + ...
        num_hits*behavior.session.params.hold_incr_ub + ...
        num_misses*behavior.session.params.hold_incr_ub*behavior.session.params.miss_wt;    %Calculate the hold time upper bound.
    lb = clip(lb, behavior.session.params.hold_min_lb,...
        behavior.session.params.hold_max_lb);                               %Constrain the lower bound.
    ub = clip(ub, behavior.session.params.hold_min_ub,...
        behavior.session.params.hold_max_ub);                               %Constrain the upper bound.
    temp = rand*(ub - lb) + lb;                                             %Fetch a random hold time within the bounds.
    behavior.session.trial(t).params.gap_start = ...
        round(temp/(behavior.session.trial(t).params.vib_ipi/1000));        %Calculate the start index of the gap.
else                                                                        %Otherwise...
   behavior.session.trial(t).params.gap_start = ...
       behavior.session.trial(t-1).params.gap_start;                        %Set the gap start time to the same value used in the previous trial.
end
if behavior.session.trial(t).params.gap_start < 2                           %If the calculated gap start index is less than the second pulse...
    behavior.session.trial(t).params.gap_start = 2;                         %Make the second pulse the gap start pulse.
end

%Set the gap paraameters.
gap_size = ceil(behavior.session.trial(t).params.gap_length/...
    behavior.session.trial(t).params.vib_ipi);                              %Calculate the gap size, in number of pulses.
if gap_size > 0                                                             %If the gap size is greater than zero...
    gap_size = gap_size - 1;                                                %Subtract one from the gap size.
end
behavior.session.trial(t).params.gap_stop = ...
    behavior.session.trial(t).params.gap_start + gap_size;                  %Set the gap stop index.
behavior.session.trial(t).params.actual_gap_length = ...
    (gap_size + 1)*behavior.session.trial(t).params.vib_ipi;                %Calculate the actual gap length.
temp = behavior.session.params.hitwin/...
    (behavior.session.trial(t).params.vib_ipi/1000);                        %Calculate the number of pulses in the hit window.
behavior.session.trial(t).params.vib_n = ...
    behavior.session.trial(t).params.gap_start + ceil(temp);                %Set the total number of pulses to span the hit window.
behavior.session.trial(t).params.hold_time = ...
    (behavior.session.trial(t).params.gap_start - 1) * ...
    (behavior.session.trial(t).params.vib_ipi/1000);                        %Calculate the hold time to the gap.
behavior.session.trial(t).params.dur = ...
    behavior.session.trial(t).params.hold_time + ...
    behavior.session.params.hitwin;                                         %Calculate the total trial duration.

%Upload the vibration settings to the module.
behavior.session.fcn.haptic.ipi(behavior.session.trial(t).params.vib_ipi);  %Set the vibration inter-pulse interval.
behavior.session.fcn.haptic.num(behavior.session.trial(t).params.vib_n);    %Set the vibration pulsetrain duration.
switch behavior.session.trial(t).params.catch                               %Switch between the various catch trial types.
        
    case 1                                                                  %If this is a dummy LRA catch behavior.session.trial(t)...
        switch lower(behavior.session.params.task_mode)                     %Switch between the task modes ("burst" or "gap").
            case 'burst'                                                    %If this stage is uses a burst as the go signal...
                behavior.session.fcn.haptic.mode('dummy_burst_catch');      %Set the vibration task mode on the controller to 1.
            case 'gap'                                                      %If this stage is uses a gap as the go signal...
                behavior.session.fcn.haptic.mode('dummy_gap');              %Set the vibration task mode on the controller to 2.        
        end
        gap_start = behavior.session.trial(t).params.gap_start;             %Set the vibration gap start index.
        gap_stop = behavior.session.trial(t).params.gap_stop;               %Set the vibration gap stop index.  
        fprintf(1,'Dummy LRA Catch Trial\n');
        
    case 2                                                                  %If this is a silent catch behavior.session.trial(t)...
        switch lower(behavior.session.params.task_mode)                     %Switch between the task modes ("burst" or "gap").
            case 'burst'                                                    %If this stage is uses a burst as the go signal...
                behavior.session.fcn.haptic.mode('silent_burst');           %Set the vibration task mode on the controller to 1.
            case 'gap'                                                      %If this stage is uses a gap as the go signal...
                behavior.session.fcn.haptic.mode('silent_gap');             %Set the vibration task mode on the controller to 2.        
        end
        gap_start = 0;                                                      %Set the vibration gap start index.
        gap_stop = 0;                                                       %Set the vibration gap stop index.  
        
    otherwise                                                               %If this isn't a catch behavior.session.trial(t).
        if strcmpi(behavior.session.params.mask_vib_on,'on')                %If the masker vibrator is turned on...
            switch lower(behavior.session.params.task_mode)                 %Switch between the task modes ("burst" or "gap").
                case 'burst'                                                %If this stage is uses a burst as the go signal...
                    behavior.session.fcn.haptic.mode('dummy_burst');        %Set the vibration task mode on the controller to 1.
                case 'gap'                                                  %If this stage is uses a gap as the go signal...
                    behavior.session.fcn.haptic.mode('dummy_gap');          %Set the vibration task mode on the controller to 2.        
            end
        else                                                                %Otherwise, if the masker vibrator is turned off...
            switch lower(behavior.session.params.task_mode)                 %Switch between the task modes ("burst" or "gap").
                case 'burst'                                                %If this stage is uses a burst as the go signal...
                    behavior.session.fcn.haptic.mode('silent_burst');       %Set the vibration task mode on the controller to 1.
                case 'gap'                                                  %If this stage is uses a gap as the go signal...
                    behavior.session.fcn.haptic.mode('silent_gap');         %Set the vibration task mode on the controller to 2.        
            end
        end
        gap_start = behavior.session.trial(t).params.gap_start;             %Set the vibration gap start index.
        gap_stop = behavior.session.trial(t).params.gap_stop;               %Set the vibration gap stop index.  
        
end
behavior.session.fcn.haptic.gap(gap_start, gap_stop);                       %Set the vibration gap start/stop index.

%Create a trial signal buffer.
signal_size = behavior.session.params.pre_trial_sampling + ...
    behavior.session.trial(t).params.hold_time + ...
    behavior.session.params.debounce;                                       %Calculate the recording duration, in seconds.
signal_size = ceil(1000*signal_size/behavior.session.params.period);        %Calculate the recording duration, in samples.
behavior.session.trial(t).signal(1).force = ...
    Vulintus_FIFO_Buffer('single',[3, signal_size]);                        %Create a FIFO buffer to capture the trial signal.
behavior.session.display.yscale = behavior.session.params.force_thresh;     %Set the default y-scale to the hit threshold.