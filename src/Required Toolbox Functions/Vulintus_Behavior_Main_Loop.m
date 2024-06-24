function Vulintus_Behavior_Main_Loop(fig,program,run_state)

%
%Vulintus_Behavior_Main_Loop.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_MAIN_LOOP switches between the various loops of
%   behavioral programs based around the Vulintus Common Behavior workflow
%   based on the value of the global run variable. This loop is necessary 
%   because the global run variable can only be used to modify a running 
%   loop if the function calling it has fully executed.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first implemented, adapted from
%                             STAP_2AFC_Main_Loop.m.
%   2024-04-11 - Drew Sloan - Switched from using a global run variable to
%                             a "run" field in the main figure UserData.
%   


if ~isfield(fig.UserData,'run_state')                                       %If the run states aren't yet enumerated...
    fig.UserData.run_state = Vulintus_Behavior_Enumerate_Run_Values;        %Load unique values for the recognized run states.
end

while fig.UserData.run ~= fig.UserData.run_state.root.close                 %Loop until the user closes the program.
    switch fix(fig.UserData.run)                                            %Switch between the various run root states.
        
        
        case run_state.root.idle                                            %Run state: idle mode
            if isfield(fig.UserData.program,'idle_fcn') && ...
                    ~isempty(fig.UserData.program.idle_fcn)                 %If a task-specific idle function is set...
                fig.UserData.program.idle_fcn(fig);                         %Call the idle loop.                
            else                                                            %Otherwise...
                Vulintus_Behavior_Idle(fig);                                %Call the common behavior idle loop.
            end
            
            
        case run_state.root.session                                         %Run state: behavior session.
            if isfield(fig.UserData.program,'session_fcn') && ...
                    ~isempty(fig.UserData.program.session_fcn)              %If a task-specific behavioral sesssion function is set...
                fig.UserData.program.session_fcn(fig);                      %Call the behavioral session loop.          
            else                                                            %Otherwise...
                Vulintus_Behavior_Run_Session(fig);                         %Call the common behavior session loop.
            end
            
            
        case run_state.root.calibration                                     %Run state: calibration.
            if isfield(fig.UserData.program,'calibration_fcn') && ...
                    ~isempty(fig.UserData.program.calibration_fcn)          %If there's a calibration function for this task...
                handles = fig.UserData;                                     %Grab the handles structure from the figure.          
                delete(fig);                                                %Delete the main figure.
                handles = handles.program.calibration_fcn(handles);         %Call the calibration function, passing the handles structure.
                handles = Vulintus_Behavior_Startup(handles);               %Restart the task, passing the original handles structure.
                fig = handles.mainfig;                                      %Reset the figure handle.
            else                                                            %Otherwise, if there's no calibration function for this task...
                fig.UserData.run = fig.UserData.run.run_state.root.idle;    %Return to the idle state.
            end


    end        
end

Vulintus_Behavior_Close(fig);                                               %Call the function to close the behavior program.