function Vibrotactile_Detection_Process_Input(behavior, packet, src, varargin)

%
% Vibrotactile_Detection_Process_Input.m
%
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_PROCESS_INPUT processes incoming streaming data
%   blocks for the SensiTrak vibrotactile detection task and updates the 
%   system status in the handles structure accordingly.
%   
%   UPDATE LOG:
%   2024-11-11 - Drew Sloan - Function first created, adapted from
%                             "Fixed_Reinforcement_Process_Input.m".
%   2025-05-20 - Drew sloan - Added a filter class for the force signal to
%                             handle debouncing.
%

data = varargin;                                                            %Copy the variable input arguments.

if ~behavior.status.initialized                                             %If the status fields aren't yet initialized.
    behavior.status.force_buffer = Vulintus_Plot_Buffer([3,500]);           %Buffer to hold force values.
    if isnt_empty_field(behavior.session,'params','debounce_cutoff')        %If a debounce cutoff frequency was set...
        cutoff = behavior.session.params.debounce_cutoff;                   %Set the cutoff to the specified frequency...
    elseif isnt_empty_field(behavior.session,'params','debounce')           %If a debounce time was set (in milliseconds)...
        cutoff = 1000/behavior.session.params.debounce;                     %Set the debounce frequency based on the period.
    else                                                                    %Otherwise...
        cutoff = 20;                                                        %Set the cutoff frequency to 20 Hz.
    end
    behavior.status.force_filter = Vulintus_Filter('lowpass',cutoff);       %Create a filter for the force signal.
    behavior.status.force_filter.timescale = 1e-6;                          %Set the filter timescale to microseconds.
    behavior.status.nosepoke = zeros(1,2);                                  %Nosepoke statuses.
    behavior.status.lick = nan(1,2);                                        %Lick sensor statuses.
    behavior.status.feedings = [];                                          %List of feeding times.
    behavior.status.touch_flag = false;                                     %Vibratory handle is currently touched flag.
    behavior.status.initialized = true;                                     %Indicate the status fields are now initialized.    
end

switch packet                                                               %Switch between the different data types.
    
    case 'LOADCELL_VAL_GM'                                                  %Loadcell value in grams...
        val = [double(data{1}); data{3}; 0];                                %Put the force values in a matrix for the buffers.
        val(3) = behavior.status.force_filter.update(val(1), val(2));       %Run the raw signal through the filter.
        behavior.status.force_buffer.write(val);                            %Add the new value to the buffer.
        behavior.status.touch_flag = ...
            (val(3) >= behavior.session.params.force_thresh);               %Set the touch flag.        
        if isequal(behavior.run.root,'session') && ...
                behavior.session.trial(end).active                          %If we're in a session and a trial is ongoing...
            behavior.session.trial(end).signal.force.write(val);            %Add the new value to the trial buffer.
            behavior.ui.display.trial_time = 1e-6*(val(1) - ...
                behavior.session.trial(end).time.start.micros);             %Update the current trial time.
        end

    case 'POKE_BITMASK'                                                     %Nosepoke bitmask data blocks.
        nosepoke_i = src - 1;                                               %Set the nosepoke index.
        if any(nosepoke_i == 1:2)                                           %If the nosepoke index is 1 or 2...
            behavior.status.nosepoke(nosepoke_i) = data{2};                 %Update the nosepoke value in the status structure.
        end
        if behavior.run == Vulintus_Behavior_Run_Class.session              %If a session is currently running.
            % behavior.session.file.write.poke_bitmask(data(i).timestamp,3,data(i).value(1));
            % behavior.session.count.nosepoke = ...
            %     behavior.session.count.nosepoke + ...
            %     behavior.status.nosepoke;                                   %Add to the nosepoke count.
        end

    case 'CAPSENSE_VALUE'                                                   %Lick sensor capacitance data blocks.
        nosepoke_i = src - 1;                                               %Set the nosepoke index.
        if any(nosepoke_i == 1:2)                                           %If the nosepoke index is 1 or 2...
            behavior.status.lick(nosepoke_i) = data{2};                     %Update the nosepoke value in the status structure.
        end
        if behavior.run == Vulintus_Behavior_Run_Class.session              %If a session is currently running.
            % behavior.session.count.lick = ...
            %     behavior.session.count.lick + ...
            %     behavior.status.lick;                               %Add to the nosepoke count.
        end

    case 'CAPSENSE_BITMASK'                                                 %Lick sensor capacitance data blocks.
        nosepoke_i = src - 1;                                               %Set the nosepoke index.
        if any(nosepoke_i == 1:2)                                           %If the nosepoke index is 1 or 2...
            behavior.status.lick(nosepoke_i) = data{2};                     %Update the nosepoke value in the status structure.
        end
        if behavior.run == Vulintus_Behavior_Run_Class.session              %If a session is currently running.
        %     behavior.session.count.lick = ...
        %         behavior.session.count.lick + ...
        %         behavior.status.lick(1);                            %Add to the nosepoke count.
        end

    case 'DISPENSE_FIRMWARE'                                                %Firmware-triggered dispensing indicator.
        behavior.status.feedings(end+1) = data{1};                          %Add the feeding timestamp.

end

behavior.status.update_plots = true;                                %Set the update plots flag to true.