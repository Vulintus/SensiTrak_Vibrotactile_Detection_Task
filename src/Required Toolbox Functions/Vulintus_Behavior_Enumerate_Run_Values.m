function run = Vulintus_Behavior_Enumerate_Run_Values

%
%Vulintus_Behavior_Enumerate_Run_Values.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_ENUMERATE_RUN_VALUES creates unique values for all
%   global "run" variable states used in Vulintus behavioral programs.
%   
%   UPDATE LOG:
%   05/24/2022 - Drew Sloan - Function first implemented.
%

run.root.close = 0;                                                         %Set the base value for closing the program.

run.root.idle = 1;                                                          %Set the base value for idling.
run_states = {	'select_subject',...                                        %Select subject.
                'select_stage',...                                          %Select stage.
                'reinitialize_plots',...                                    %Re-initialize plots.
                'manual_feed',...                                           %Manual feed (unidirectional).
                'manual_feed_left',...                                      %Manual feed to the left.
                'manual_feed_right',...                                     %Manual feed to the right.
                'reset_baseline',...                                        %Reset the baseline.
                'webcam_preview',...                                        %Launch a webcam preview.
                'home_pos_adjust',...                                       %Launch the home position adjustment.
                'rehome_handle',...                                         %Re-home the handle.
                };                                                         
for i = 1:numel(run_states)                                                 %Step through each idle run state...]
    run.(['idle_' run_states{i}]) = run.root.idle + i/100;                  %Create a unique value for each run state.
end 
     
run.root.session = 2;                                                       %Set the base value for running a session.
run_states = {	'pause',...                                                 %Pause a session.
                'manual_feed',...                                           %Manual feed (unidirectional).
                'manual_feed_left',...                                      %Manual feed to the left.
                'manual_feed_right',...                                     %Manual feed to the right.
                'reset_baseline',...                                        %Reset the baseline.
                'webcam_preview',...                                        %Launch a webcam preview.
                };                                                          %List the recognized run states.
for i = 1:numel(run_states)                                                 %Step through each idle run state...]
    run.(['session_' run_states{i}]) = run.root.session + i/100;            %Create a unique value for each run state.
end 
            
run.root.calibration = 3;                                                   %Set the base value for calibration operations.
run_states = {	'measure_lever',...                                         %Measure the maximum and minimum of the potentiometer signal (lever).
                'reset',...                                                 %Revert to the previous calibration.
                'update_handles',...                                        %Update the handles structure.
                'update_plots',...                                          %Update the calibration plots (isometric pull).
                'switch_rat_mouse',...                                      %Switch between rat/mouse lever range (lever).
                'save',...                                                  %Save the calibration.
                };                                                          %List the recognized run states.
for i = 1:numel(run_states)                                                 %Step through each idle run state...]
    run.(['calibration_' run_states{i}]) = run.root.calibration + i/100;    %Create a unique value for each run state.
end