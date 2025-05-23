function Vibrotactile_Detection_Session_Initialize(behavior)

%
% Vibrotactile_Detection_Session_Initialize.m
%   
%   copyright 2024, Vulintus, Inc.
%
%   Vibrotactile_Detection_Session_Initialize creates and populates 
%   the SensiTrak vibrotactile detection task session class.
%   
%   UPDATE LOG:
%   2024-11-13 - Drew Sloan - Function first created, adapted from
%                             "Vibrotactile_Detection_Task_Initialize_Session."
%

%Set the session timing parameters.
if isempty(behavior.session.display)                                        %If the display structure isn't initialized.
    behavior.session.display = struct('hit_ln',[],'hit_txt',[]);            %Create the structure with the hit indicator line handles.
else                                                                        %Otherwise...
    behavior.session.display.hit_ln = [];                                   %Hit indicator line handles.
    behavior.session.display.hit_txt = [];                                  %Hit text label handles.
end

%Check the sampling parameters.
if is_empty_field(behavior.session,'params','period')                       %If the sampling period isn't set in the spreadsheet.
    behavior.session.params.period = 10;                                    %Set set the sampling period to 10 milliseconds by default.
    if isnt_empty_field(behavior.program,'params','stream_settings')        %If stream settings are set in the program information.
        i = strcmpi({behavior.program.params.stream_settings.sku},'ST-VT'); %Check if the vibrotactile module stream settings are included.
        if any(i)                                                           %If vibrotactile module stream settings were found...
            temp = behavior.program.params.stream_settings(i);              %Grab the stream settings.
            if isnt_empty_field(temp,'sample_period')                       %If a sample period is set...                                                    
                behavior.session.params.period = temp.sample_period/1000;   %Convert the sampling period from microseconds to milliseconds.
            end
        end
    end
end

%Create/clear fields used to track variables for psychophysical plots.
behavior.session.params.gap_length = [];
behavior.session.params.actual_gap_length = [];
behavior.session.params.vib_rate = [];
behavior.session.params.actual_vib_rate = [];
behavior.session.params.time_held = [];

%Reset the counts.
behavior.session.count.trial = 0;                                           %Set the trial count to zero.
behavior.session.count.feed = 0;                                            %Set the feeding count to zero.

%Create a matrix to track outcomes for each vibration rate.
vib_rates = double(behavior.session.params.vib_rates);                      %Grab the possible vibration rates.  
gap_durs = double(behavior.session.params.gap_durs);                        %Grab the possible gap durations. 
behavior.session.count.outcomes = ...
    zeros(7, numel(vib_rates)*numel(gap_durs));                             %Create a matrix to hold the outcome by vibration rate and gap length.
for i = 1:numel(vib_rates)                                                  %Step through the vibration rates.
    for j = 1:numel(gap_durs)                                               %Step through the gap lengths.
        behavior.session.count.outcomes(1,j + (i-1)*numel(vib_rates)) = ...
            vib_rates(i);                                                   %Save the vibration rate.
        behavior.session.count.outcomes(2,j + (i-1)*numel(vib_rates)) = ...
            gap_durs(j);                                                    %Save the gap length.
    end
end
for f = {'trial','hit','feed','abort'}                                      %Step through outcome-counting field names...
    behavior.session.count.(f{1}) = 0;                                      %Set each field value to zero.
end
if is_empty_field(behavior.session.params,'vib_dur')                        %If the vibration duration wasn't set...
    behavior.session.params.vib_dur = 3;                                    %Set the vibration duration to 3 milliseconds.
end

% behavior.session.params.cal = ...
%     [behavior.session.params.slope, behavior.session.params.baseline];        %Grab the calibration function for the device.

%Set the debounce period.
if isnt_empty_field(behavior.session,'params','debounce')                   %If a debounce duration was set...
    temp = round(behavior.session.params.debounce/...
        behavior.session.params.period);                                    %Calculate the number of samples in the debounce.
    behavior.session.params.debounce_index = ...
        (-(temp-1):1:0) + double(behavior.status.force_buffer.size(2));     %Calculate the debounce samples.
else                                                                        %Otherwise...
    behavior.session.params.debounce_index = ...
        double(behavior.status.force_buffer.size(2));                       %Set the debounce index to the most recent sample.
end

%Set the pre-trial sampling.
if is_empty_field(behavior.session,'params','pre_trial_sampling')           %If pre-trial sampling wasn't set.
    behavior.session.params.pre_trial_sampling = 0.5;                       %Set the pre-trial sampling time to 1 seconds.
end
temp = round((1000*behavior.session.params.pre_trial_sampling)/...
    behavior.session.params.period);                                        %Calculate the number of samples in the pre-trial period.
behavior.session.params.pre_sample_index = temp:-1:1;                       %Calculate the pre-trial samples.

%Create the initial stimulus block.
behavior.session.params.stim_block = ...
    Vibrotactile_Detection_Create_Stimulus_Block(behavior.session.params);  %Create a new stimulus block.
behavior.session.params.stim_index = 1;                                     %Set the stimulus index to 1.