function Vibrotactile_Detection_Start_Trial(behavior)

%
% Vibrotactile_Detection_Start_Trial.m
% 
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_START_TRIAL initializes all of the real-time 
%   trial variables right at the start of a trial IN THE 
%   
%   UPDATE LOG:
%   2024-11-13 - Drew Sloan - Function first implemented, adapted from
%                             "Vibrotactile_Detection_Task_Start_Trial.m".
%

behavior.session.trial(end).start();                                        %Start the trial.

behavior.session.fcn.haptic.start();                                        %Turn on vibration.

i = behavior.session.params.pre_sample_index;                               %Grab the indices for the pre-trial samples.
pre_samples = behavior.status.force_buffer.values(:,i);                     %Grab the pre-trial samples.
behavior.session.trial(end).signal.write(pre_samples);                      %Write the pre-trial samples to the trial signal.
behavior.session.trial.time.start.datetime.micros = pre_samples(1,end);     %Recording the starting microsecond clock value.
