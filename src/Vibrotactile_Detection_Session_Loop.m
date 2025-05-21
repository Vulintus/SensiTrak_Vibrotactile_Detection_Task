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
Vibrotactile_Detection_Initialize_Session(behavior);                        %Initialize the session class.

%Create the output data file.
Vulintus_Behavior_Create_OmniTrak_File(behavior, 1);                        %Create the output date file-writing structure.
if is_fcn_field(behavior.session.fcn,'clock_sync')                          %If a clock synchronization function has been set...
    behavior.session.fcn.clock_sync();                                      %Request a clock synchronization block.
end

%Initialize the session plots on the data axes.
Vibrotactile_Detection_Create_Session_Plots(behavior);

%Initialize the columns.
behavior.ui.table.trial.Data = {};                                          %Clear the table data.
behavior.ui.table.trial.ColumnName = {'Trial', 'Time', 'Threshold', ...
    'Outcome', 'Feedings'};                                                 %Set the table column headings.
behavior.ui.table.trial.ColumnWidth = {100, 'auto', 100, 100, 100};         %Set the column widths.
behavior.ui.table.trial.RowName = [];                                       %Remove the row names.
behavior.ui.table.trial.ButtonDownFcn =  @Vulintus_Copy_to_Clipboard;       %Copy the table to the clipboard.

%Create a session timer function.
session_timer = Vulintus_Behavior_Session_Timer(behavior.ui.edit.dur,...
    behavior.session.time.start);

%Create a display timer function.
display_timer = Vulintus_Behavior_Display_Timer(0.05,...
    behavior.program.fcn.plot_system);                                      %Refresh the system plot at ~20 Hz.

%Enable data streaming.
Vulintus_Behavior_Stream_Enable(behavior, true, behavior.ui.port);          %Enable streaming.
behavior.run = Vulintus_Behavior_Run_Class.session;                         %Set the run variable to session mode.


%% MAIN LOOP ***********************************************************************************************************************
behavior.session.timer.main = tic;                                          %Create a session timer.
while isequal(behavior.run.root,'session')                                  %Loop until the user stops the session or closes the program.
    

%PREPARE THE NEXT TRIAL ************************************************************************************************************    
    Vibrotactile_Detection_Reset_Trial(behavior);                           %Reset the trial.

%WAIT FOR TRIAL INITIATION *********************************************************************************************************
    while ~behavior.status.touch_flag && ...
            behavior.run == Vulintus_Behavior_Run_Class.session             %Loop until a touch is detected...        
        behavior.ctrl.stream.read();                                        %Read and process any new streaming data.
        pause(0.005);                                                       %Pause for 5 milliseconds.
        drawnow;                                                            %Flush the event queue.
    end

%START THE TRIAL *******************************************************************************************************************   
    Vibrotactile_Detection_Start_Trial(behavior);                           %Initialize the trial variables.
    Vibrotactile_Detection_Create_Trial_Plot(behavior);                     %Create a plot showing a trial diagram.

%MONITOR THE TRIAL *****************************************************************************************************************
    while behavior.status.touch_flag && ...
            ~behavior.session.trial(end).timeout() && ...
            behavior.run == Vulintus_Behavior_Run_Class.session             %Loop until touch is released or the end of the trial...
%         set(trial.prog_line,'xdata',86400*[1,1]*(now - trial.start_time));  %Update the progress line.
        behavior.ctrl.stream.read();                                        %Read and process any new streaming data.
        pause(0.005);                                                       %Pause for 5 milliseconds.
        drawnow;                                                            %Flush the event queue.
    end
    trial.params.time_held = 86400*(now - trial.params.start_time);                       %Grab the time the rat held.

%RECORD ANY REQUIRED POST-TRIAL SAMPLES ********************************************************************************************
%     if trial.params.time_held > trial.params.hold_time                                    %If the rat didn't abort.
%         while now < (trial.params.end_time + behavior.session.params.post_trial_sampling/86400) && ...
%                 run == 2                                                    %Loop until the end of the post-trial sampling time.    
%             [session, trial] = ...
%                 Vibrotactile_Detection_Check_Signal(h, session, trial);             %Check for any new samples on the serial line.        
%         end
%     else                                                                    %Otherwise, if the rat did abort...
        behavior.session.fcn.haptic.stop();                                 %Call the function to stop the vibration train.
%     end

%RECORD TRIAL RESULTS **************************************************************************************************************
    switch behavior.run                                                     %Switch between the recognized run cases.
       
        case Vulintus_Behavior_Run_Class.session                            %If the session is still running as normal...
            Vibrotactile_Detection_Update_Session(behavior, trial);           %Calculate the trial outcome and display it.
            behavior.session.file.write{'VIBROTACTILE_DETECTION_TASK_TRIAL'}(behavior,...
                trial);                                                     %Write the trial data to the data file.  
            Vibrotactile_Detection_Plot_Psychometrics(behavior, session);                  %Show the psychometrics plots.        
            
        case Vulintus_Behavior_Run_Class.session_manual_feed_left           %If the user wants to manually feed.
            
%             feeder_index = (trial.target_feeder == 'L') + 1;                %Set the feeder index.
%             Vulintus_Behavior_Manual_Feed(session.fid,...
%                 behavior.block_codes.SWUI_MANUAL_FEED, behavior.ctrl,...
%                 feeder_index, behavior.msgbox, behavior.session.count.feed);            %Call the toolbox function to trigger and record a feeding.           
%             behavior.session.count.feed = behavior.session.count.feed + 1;                                              %Add one to the feed counts.
%             Add_Msg(behavior.msgbox,[datestr(now,13) ...
%                 ' - Manual Feeding. Feedings: ' num2str(behavior.session.count.feed) '.']);         %Show the user that the session has ended.
%             behavior.ardy.feed(2);                                               %Trigger feeding on the Arduino.
%             trial = trial - 1;                                                  %Subtract one from the trial counter.
%             set(behavior.mainfig,'userdata',1);                                  %Reset the run variable in the main figure's 'UserData' property.
            behavior.ctrl.feed.start();                                            %Trigger a feeding.
            behavior.session.count.trial = behavior.session.count.trial - 1;  %Decrement the trial counter.
            behavior.session.count.trial = ...
                behavior.session.count.trial - 1;
            behavior.run = Vulintus_Behavior_Run_Class.session;             %Set the run variable back to session mode.
            
        case Vulintus_Behavior_Run_Class.session_webcam_preview             %If the user wants to open a webcam preview...    
            Vulintus_Behavior_Launch_Webcam_Preview;                        %Call the toolbox function to launch a webcam preview.
            behavior.run = Vulintus_Behavior_Run_Class.session;             %Set the run variable back to session mode.            
            
    end         

    %WAIT FOR THE RAT TO RELEASE THE LEVER *********************************************************************************************
    trial.params.start_time = [];                                                  %Clear out the start time to prevent data overrun.
    trial.params.touch_flag = 1;                                                   %Set the touch flag to 1.
    if isfield(trial,'outcome') && ~strcmpi(trial.params.outcome,'abort')          %If the trial didn't end in an abort...
        while trial.params.touch_flag == 1 && ...
                behavior.run == Vulintus_Behavior_Run_Class.session             %Loop until touch is released or the end of the trial...     
            Vibrotactile_Detection_Check_Signal(behavior, trial);             %Check for any new samples on the serial line.
        end
    end
    temp = (behavior.session.params.debounce)/behavior.session.params.period;                                      %Calculate the number of samples in the debounce.
    if temp == 0                                                            %If there's no debounce...
        behavior.session.params.debounce_index = behavior.session.params.buffsize;                          %Set the monitored sample to the last sample in the buffer.
    else                                                                    %Otherwise, if debounce is active...
        behavior.session.params.debounce_index = (-(temp-1):1:0) + behavior.session.params.buffsize;        %Calculate the debounce samples.
    end

    if datetime('now') > behavior.session.time.end                          %If the set session duration has passed...
        behavior.run = Vulintus_Behavior_Run_Class.idle;                    %Set the run state to idle.
        if isfield(behavior.ui,'msgbox')                                    %If there's a messagebox in the GUI.
            str = sprintf('%s - Session ended after %1.0f minutes.',...
                char(datetime,'hh:mm:ss'),...
                minutes(behavior.session.params.session_dur));              %Create a message string.
            Add_Msg(behavior.ui.msgbox,str);                                %Show the message in the messagebox.
        end
    end

    drawnow;                                                                %Update the figure and execute any waiting callbacks.
    
end
   

%Stop the data stream.
behavior.ctrl.stream.enable(0);                                             %Disable streaming on the controller.
if is_fcn_field(behavior.session.fcn,'clock_sync')                          %If a clock synchronization function has been set...
    behavior.session.fcn.clock_sync();                                      %Request a clock synchronization block.
end
behavior.ctrl.device.firmware.mode.set('idle');                             %Set the firmware program mode to idle.
wait_time = toc(behavior.session.timer.main) + 0.25;                        %Wait 250 milliseconds to let all remaining data come in.
while toc(behavior.session.timer.main) < wait_time                          %Loop through the wait time.
    Vibrotactile_Detection_Check_Signal(behavior, trial);                   %Check for any new samples on the serial line.
end

%Close the session data file.
behavior.session.file.close();

%Clear any residual values from the serial line.
behavior.ctrl.otsc.clear(0.1);        

if isfield(behavior.ui,'msgbox')                                            %If there's a messagebox in the GUI.
    str = sprintf('%s - Session ended, %1.0f total feedings.',...
        char(datetime,'hh:mm:ss'), behavior.session.count.feed);             %Create a message string.
    Add_Msg(behavior.ui.msgbox,str);                                        %Show the message in the messagebox.
end

%Stop the various display timers.
stop(display_timer);                                                        %Stop the display timer.
stop(session_timer);                                                        %Stop the session timer.                                   

%Update all of the uicontrols.
Vulintus_Behavior_Update_Controls(behavior, 'idle');                        %Call the function to update all of the uicontrols.