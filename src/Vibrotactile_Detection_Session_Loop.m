function Vibrotactile_Detection_Session_Loop(behavior)

%
% Vibrotactile_Detection_Session_Loop.m
% 
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_SESSION_LOOP is the main behavioral loop for the 
%   SensiTrak vibrotactile detection task program running through the 
%   Vulintus Common Behavior functions.
%   
%   UPDATE LOG:
%   2024-11-13 - Drew Sloan - Function first implemented, adapted from
%                             "Fixed_Reinforcement_Session_Loop.m".
%


%Update all of the uicontrols.
Vulintus_Behavior_Update_Controls(behavior, 'session');                     %Call the function to update all of the uicontrols.
Clear_Msg([],[],behavior.ui.msgbox);                                        %Clear the existing messages out of the messagebox.

%Set the session timing parameters.
Vibrotactile_Detection_Session_Initialize(behavior);                        %Initialize the session class.

%Create the output data file.
Vulintus_Behavior_Create_OmniTrak_File(behavior, 1);                        %Create the output date file-writing structure.
if is_fcn_field(behavior.session.fcn,'clock_sync')                          %If a clock synchronization function has been set...
    behavior.session.fcn.clock_sync();                                      %Request a clock synchronization block.
end

%Initialize the columns.
behavior.ui.table.trial.Data = {};                                          %Clear the table data.
str = [lower(behavior.session.params.task_mode) ' (ms)'];                   %Set the task mode string for the table.
str(1) = upper(str(1));                                                     %Make the first character upper-case.
behavior.ui.table.trial.ColumnName = {'Trial', 'Time', 'Hold (s)', ...
    'Held (s)', 'Rate (Hz)', str, 'Outcome', 'Feedings'};                   %Set the table column headings.
behavior.ui.table.trial.ColumnWidth = {40, 70, 80, 80, 80, 80, 80, 'auto'}; %Set the column widths.
behavior.ui.table.trial.RowName = [];                                       %Remove the row names.
behavior.ui.table.trial.ButtonDownFcn =  @Vulintus_Copy_to_Clipboard;       %Copy the table to the clipboard.

%Create a session timer function.
session_timer = Vulintus_Behavior_Session_Timer(behavior.ui.edit.dur,...
    behavior.session.time.start);

%Create a display timer function.
display_timer = Vulintus_Behavior_Display_Timer(0.05,...
    behavior.program.fcn.plot_system);                                      %Refresh the system plot at ~20 Hz.

%Create placeholder text on the data axes.
cla(behavior.ui.ax.data);                                                   %Clear the psychophysical plot axes.
str = 'Waiting for initiation of first trial...';                           %Create a message string.
Vulintus_Centered_Axes_Message(str, behavior.ui.ax.data);                   %Show the message on data axes.

%Enable data streaming.
Vulintus_Behavior_Stream_Enable(behavior, true, behavior.ui.port);          %Enable streaming.
behavior.run = Vulintus_Behavior_Run_Class.session;                         %Set the run variable to session mode.


%% MAIN LOOP ***********************************************************************************************************************
behavior.session.timer.main = tic;                                          %Create a session timer.
while isequal(behavior.run.root,'session')                                  %Loop until the user stops the session or closes the program.
    

%PREPARE THE NEXT TRIAL ************************************************************************************************************    
    Vibrotactile_Detection_Trial_Reset(behavior);                           %Reset the trial.

%WAIT FOR TRIAL INITIATION *********************************************************************************************************
    while ~behavior.status.touch_flag && ...
            behavior.run == Vulintus_Behavior_Run_Class.session             %Loop until a touch is detected...        
        behavior.ctrl.stream.read();                                        %Read and process any new streaming data.
        pause(0.005);                                                       %Pause for 5 milliseconds.
        drawnow;                                                            %Flush the event queue.
    end

%START THE TRIAL *******************************************************************************************************************   
    Vibrotactile_Detection_Trial_Start(behavior);                           %Initialize the trial variables and create a trial diagram.

%MONITOR THE TRIAL *****************************************************************************************************************
    while behavior.status.touch_flag && ...
            ~behavior.session.trial(end).timeout() && ...
            behavior.run == Vulintus_Behavior_Run_Class.session             %Loop until touch is released or the end of the trial...
        behavior.ctrl.stream.read();                                        %Read and process any new streaming data.
        pause(0.005);                                                       %Pause for 5 milliseconds.
        drawnow;                                                            %Flush the event queue.
    end 

%END THE TRIAL *********************************************************************************************************************
    Vibrotactile_Detection_Trial_Stop(behavior);                            %Stop the trial, determine the outcome, and trigger reinforcement.

%RECORD TRIAL RESULTS **************************************************************************************************************
    switch behavior.run                                                     %Switch between the recognized run cases.
       
        case Vulintus_Behavior_Run_Class.session                            %If the session is still running as normal...
            Vibrotactile_Detection_Session_Update(behavior);                %Calculate the trial outcome and display it.            
            Vibrotactile_Detection_Plot_Psychometrics(behavior);            %Show the psychometrics plots.        
            
        case Vulintus_Behavior_Run_Class.session_manual_feed_left           %If the user wants to manually feed.
            Vulintus_Behavior_Manual_Feed(behavior);                        %Trigger a manual feeding and record it in the data file.
            behavior.session.count.trial = ...
                behavior.session.count.trial - 1;                           %Subtract one from the trial count.
            behavior.session.trial(end) = [];                               %Delete the last trial data.
            behavior.run = Vulintus_Behavior_Run_Class.session;             %Set the run variable back to session mode.
            
        case Vulintus_Behavior_Run_Class.session_webcam_preview             %If the user wants to open a webcam preview...    
            Vulintus_Behavior_Launch_Webcam_Preview;                        %Call the toolbox function to launch a webcam preview.
            behavior.session.count.trial = ...
                behavior.session.count.trial - 1;                           %Subtract one from the trial count.
            behavior.session.trial(end) = [];                               %Delete the last trial data.
            behavior.run = Vulintus_Behavior_Run_Class.session;             %Set the run variable back to session mode.            
            
    end         

%WAIT FOR THE RAT TO RELEASE THE LEVER *********************************************************************************************
    behavior.status.touch_flag = true;                                      %Artificially set the touch flag to true.
    if ~any(behavior.session.trial(end).outcome(1) == '?A')                 %If the trial completed and the rat didn't abort.
        while behavior.status.touch_flag && ...
                behavior.run == Vulintus_Behavior_Run_Class.session         %Loop until the end of the trial...
            behavior.ctrl.stream.read();                                    %Read and process any new streaming data.
            pause(0.005);                                                   %Pause for 5 milliseconds.
            drawnow;                                                        %Flush the event queue.
        end 
    end
    behavior.status.touch_flag = false;                                     %Artificially set the touch flag to false.

%END THE SESSION IF A PRESET SESSION DURATION HAS PASSED ***************************************************************************
    if datetime('now') > behavior.session.time.end                          %If the set session duration has passed...
        behavior.run = Vulintus_Behavior_Run_Class.idle;                    %Set the run state to idle.
        if isfield(behavior.ui,'msgbox')                                    %If there's a messagebox in the GUI.
            str = sprintf('%s - Session ended after %1.0f minutes.',...
                char(datetime,'hh:mm:ss'),...
                minutes(behavior.session.params.session_dur));              %Create a message string.
            Add_Msg(behavior.ui.msgbox,str);                                %Show the message in the messagebox.
        end
        drawnow;                                                            %Flush the event queue.
    end
    
end
   
%Stop the various display timers.
stop(display_timer);                                                        %Stop the display timer.
stop(session_timer);                                                        %Stop the session timer.   

%Stop the data stream.
Vulintus_Behavior_Stream_Enable(behavior, false, behavior.ui.port);         %Disable streaming.
if is_fcn_field(behavior.session.fcn,'clock_sync')                          %If a clock synchronization function has been set...
    behavior.session.fcn.clock_sync();                                      %Request a clock synchronization block.
end
behavior.ctrl.device.firmware.mode.set('idle');                             %Set the firmware program mode to idle.

%Close the session data file.
behavior.session.file.close();

%Clear any residual values from the serial line.
behavior.ctrl.otsc.clear(0.1);        

%Show a session end message in the messagebox.
if isfield(behavior.ui,'msgbox')                                            %If there's a messagebox in the GUI.
    str = sprintf('%s - Session ended, %1.0f total feedings.',...
        char(datetime,'hh:mm:ss'), behavior.session.count.feed);            %Create a message string.
    Add_Msg(behavior.ui.msgbox,str);                                        %Show the message in the messagebox.
end
                              
%Plot the final psychometrics.
Vibrotactile_Detection_Plot_Psychometrics(behavior);                        %Show the psychometrics plots.  

%Update all of the uicontrols.
Vulintus_Behavior_Update_Controls(behavior, 'idle');                        %Call the function to update all of the uicontrols.