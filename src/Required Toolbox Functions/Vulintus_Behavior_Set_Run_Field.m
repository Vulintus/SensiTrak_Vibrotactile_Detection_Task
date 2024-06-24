function Vulintus_Behavior_Set_Run_Field(~,~,run_val)

%
%Vulintus_Set_Global_Run.m - Vulintus, Inc.
%
%   VULINTUS_SET_GLOBAL_RUN declares a global variable "run" and then sets
%   the value of that variable. The global "run" variable is used thoughout
%   Vulintus behavior programs to control monitoring loops and transistions
%   between program functions.
%   
%   UPDATE LOG:
%   2021-11-30 - Drew Sloan - Function first create to fix issues with code
%                             directly evaluated from uibutton 
%                             ButtonPushedFcn callbacks.
%   2024-04-11 - Drew Sloan - Switched from using a global run variable to
%                             a "run" field in the main figure UserData.
%                             Renamed function from
%                             "Vulintus_Set_Global_Run" to
%                             "Vulintus_Behavior_Set_Run_Field".
%

fig = gcbf;                                                                 %Grab the parent figure handle.
fig.UserData.run = run_val;                                                 %Set the run variable to the specified value.
fprintf(1,'fig.UserData.run = %1.3f\n',run_val);                            %Print the value of the global run variable to the command line.