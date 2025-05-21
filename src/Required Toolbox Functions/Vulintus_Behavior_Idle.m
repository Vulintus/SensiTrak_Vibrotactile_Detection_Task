function Vulintus_Behavior_Idle(fig)

%
%Vulintus_Behavior_Idle.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_IDLE runs in the background to display streaming 
%   input signals for Vulintus Common Behavior-based programs while a
%   session is not running.
%   
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first implemented, adapted from
%                             ST_Tactile_2AFC_Idle.m.
%


%Update all of the uicontrols.
Vulintus_Behavior_Update_Controls(fig, 'idle');                             %Call the function to update all of the uicontrols.

%Start the idle loop.
fig.UserData.ctrl.otsc.clear();                                             %Clear any residual values from the serial line.
fig.UserData.ctrl.stream.enable(1);                                         %Enable streaming on the controller.
if isfield(fig.UserData,'otth')                                             %If there's an OmniTrak thermal tracker as a secondary module...
    fig.UserData.otth.stream.enable(3);                                     %Enable image streaming on the thermal tracker.
end
fig.UserData.run = fig.UserData.run_state.root.idle;                        %Set the run variable to idle mode.

while fix(fig.UserData.run) == fig.UserData.run_state.root.idle             %Loop until the user starts a session, runs the calibration, or closes the program.
    
    switch fig.UserData.run                                                 %Switch between recognized run variable values.
        
        case fig.UserData.run_state.idle_select_stage                       %If the user has selected a new stage...
            if isfield(fig.UserData,'ui') && ...
                    isfield(fig.UserData.ui,'drop_stage')                   %If the UI has a stage dropdown menu.
                temp = fig.UserData.ui.drop_stage.Value;                    %Grab the value of the stage select dropdown menu.
                i = find(strcmpi(temp,fig.UserData.ui.drop_stage.Items));   %Find the index of the selected stage.
                if i ~= fig.UserData.cur_stage                              %If the selected stage is different from the current stage.
                    fig.UserData.cur_stage = i;                             %Set the current stage to the selected stage.
                    Vulintus_Behavior_Stage_Load(fig.UserData);             %Load the selected stage.
                end
            end
%             fig.UserData.psych_plots = ...
%                 ST_Tactile_2AFC_Initialize_Psychometric_Plot(handles);      %Recreate the psychometric plots.
%             [counts, times] = ...
%                 ST_Tactile_2AFC_Load_Previous_Performance(handles);         %Call the function to load the current subject's previous performance.
%             ST_Tactile_2AFC_Update_Psychometric_Plot(...
%                 fig.UserData.psych_plots,counts,times);                          %Update the psychometric plots with the current and historical performance.
            fig.UserData.run = ...
                fig.UserData.run_state.idle_reinitialize_plots;             %Set the run variable to 1.3 to create the plot variables.
            
        case fig.UserData.run_state.idle_reinitialize_plots                      %If new plot variables must be created...
%             fig.UserData.ctrl.stream.enable(0);                                  %Disable streaming from the controller.
%             ST_Tactile_2AFC_Set_Stream_Params(handles);                     %Update the streaming properties on the controller.   
%             fig.UserData.ctrl.clear();                                           %Clear any residual values from the serial line.        
%             fig.UserData.buffsize = 3000/fig.UserData.period;                         %Calculate the number of samples in a 3-second buffer.
%             if fig.UserData.buffsize ~= numel(force)
%                 force = nan(fig.UserData.buffsize,1);                            %Create a matrix to hold the monitored signal.
%             end        
%             fig.UserData.ctrl.stream.enable(1);                                  %Re-enable periodic streaming on the controller.
            fig.UserData.run = fig.UserData.run_state.root.idle;            %Set the run variable back to idle mode.
            
        case fig.UserData.run_state.idle_manual_feed_left                   %If the user pressed the manual feed button...     
            fig.UserData.ctrl.feed.start();                                 %Trigger feeding on the controller.
            str = sprintf('%s - Manual feed.',char(datetime,'hh:mm:ss'));   %Create a string for the messagebox.
            Add_Msg(fig.UserData.ui.msgbox,str);                            %Show the message in the messagebox.    
            fig.UserData.run = fig.UserData.run_state.root.idle;            %Set the run variable back to idle mode.
            
        case fig.UserData.run_state.idle_reset_baseline                          %If the user wants to reset the baseline...
%             handles = fig.UserData.mainfig.UserData;                             %Grab the current handles structure from the main GUI.
%             N = fix(1000/fig.UserData.period);                                   %Find the number of samples in the last second of the existing signal.
%             temp = force(end-N+1:end);                                      %Convert the buffered data back to the uncalibrated raw values.
%             fprintf(1,'old_baseline = %1.2f\n',fig.UserData.baseline);           %Convert the buffered data back to the uncalibrated raw values.
%             fig.UserData.baseline = ...
%                 (mean(temp,'omitnan')/fig.UserData.slope) + fig.UserData.baseline;    %Set the baseline to the average of the last 100 signal samples.
%             fprintf(1,'new_baseline = %1.2f\n',fig.UserData.baseline);           %Convert the buffered data back to the uncalibrated raw values.
%             guidata(fig,handles);                                           %Pin the updated handles structure back to the GUI.
%             fig.UserData.ctrl.sttc_set_force_baseline(fig.UserData.baseline);         %Save the baseline as a float in the EEPROM address for the current module.
            fig.UserData.run_state.root.idle;                               %Set the run variable back to idle mode.
            
        case fig.UserData.run_state.idle_webcam_preview                     %If the user selected the "Launch Webcam" menu item...
            Vulintus_Behavior_Launch_Webcam_Preview;                        %Call the function to launch a webcam preview.
            fig.UserData.run = fig.UserData.run_state.root.idle;            %Set the run variable back to idle mode.           

        case fig.UserData.run_state.idle_select_subject                     %If the subject has been changed.
            if isfield(fig.UserData,'ui') && ...
                    isfield(fig.UserData.ui,'drop_subject')                 %If the UI has a subject dropdown menu.
                temp = fig.UserData.ui.drop_subject.Value;                  %Grab the value of the subject select dropdown menu.
                if ~strcmpi(fig.UserData.cur_subject,temp)                  %If the selected subject is different from the current subject.
                    if strcmpi(temp,'<New Subject>')                        %If the user selected to add a new subject...
                        Vulintus_Behavior_Subject_Add(fig);                 %Call the function to add the subject.
                        fig.UserData.ui.drop_subject.Value = ...
                            fig.UserData.cur_subject;                       %Reset the dropdown menu to the previously selected subject for now.
                    else                                                    %Otherwise...
                        fig.UserData.cur_subject = temp;                    %Set the current subject to the selected subject.
                        fig.UserData = ...
                            Vulintus_Behavior_Subject_Load(fig.UserData);   %Load the subject.
                    end
                end
            end            
            fig.UserData.run = fig.UserData.run_state.root.idle;            %Set the run variable back to idle mode.
            
        otherwise                                                           %For all other values 1 =< run < 2...
%             pause(0.1);
%             fig.UserData.ctrl.stream.enable(0);
%             fig.UserData.ctrl.stream.enable(1);
            [new_data, n_events] = fig.UserData.ctrl.stream.read();         %Read in any new stream output from the controller.
            if isfield(fig.UserData,'otth')                                 %If there's an OmniTrak thermal tracker as a secondary module...
                [therm_data, n_ims] = fig.UserData.otth.stream.read();      %Read in any new stream output from the thermal tracker.
                if n_ims > 0                                                %If there were any thermal image events...
                    if n_events > 0                                         %If there's nosepoke data...
                        new_data = [new_data, therm_data];                  %Add the thermal image data to the nosepoke data.
                    else                                                    %Otherwise...
                        new_data = therm_data;                              %Set the new data to the thermal image data.
                    end
                    n_events = n_events + n_ims;                            %Add to the total number of events.
%                     fig.UserData.otth.stream.enable(0);                     %Disable streaming on the thermal tracker.
                end                                         
            end
            if n_events > 0                                                 %If there was any new data in the stream.
                fig.UserData.program.process_input_fcn(fig,...
                    new_data);                                              %Call the function to process input signals.
                if is_fcn_field(fig.UserData,'program','fcn','plot_system')          %If a system diagram update function was set...
                    fig.UserData.program.fcn.plot_system(fig);              %Call the function to create or update the diagram.
                end
            end             

            
    end

    drawnow;                                                                %Update the figure and execute any waiting callbacks.

end

fig.UserData.ctrl.stream.enable(0);                                         %Disable streaming on the controller.
if isfield(fig.UserData,'otth')                                             %If there's an OmniTrak thermal tracker as a secondary module...
    fig.UserData.otth.stream.enable(0);                                     %Disable image streaming on the thermal tracker.
end
fig.UserData.ctrl.otsc.clear();                                             %Clear any residual values from the serial line.
str = sprintf('%s - Idle mode stopped.',char(datetime,'hh:mm:ss'));         %Create a string for the messagebox.
Add_Msg(fig.UserData.ui.msgbox,str);                                        %Show the message in the messagebox.    