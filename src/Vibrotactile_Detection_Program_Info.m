function program = Vibrotactile_Detection_Program_Info(varargin)

%
%Vibrotactile_Detection_Program_Info.m - Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_PROGRAM_INFO sets the system type, minimum 
%   required hardware, and function callbacks for the SensiTrak
%   vibrotactile detection task behavior program running through the 
%   Vulintus Common Behavior framework.
%   
%   UPDATE LOG:
%   2024-06-24 - Drew Sloan - Function first created, adapted from
%                             Tactile_Discrimination_Program_Info.m
%                            


if nargin == 0                                                              %If no inputs were passed...
    program = struct;                                                       %Create a program structure.
    i = 1;                                                                  %Set the index to 1.
else                                                                        %Otherwise...
    program = varargin{1};                                                  %Grab the program structure that was passed.
    if length(program) <= 1 && isempty(program(1).task)                     %If the program structure isn't initialized...
        i = 1;                                                              %Set the index to 1.
    else                                                                    %Otherwise...
        i = length(program) + 1;                                            %Increment the program index.
    end
end

program(i).task = 'Vibrotactile Detection (Go/NoGo)';                       %Set the task name.
program(i).abbreviation = 'STVD';                                           %Abbreviation of the task name for use in filename.
program(i).script_root = 'Vibrotactile_Detection_*';                        %Root name of all behavior-specific scripts.
program(i).system_name = 'SensiTrak';                                       %Vulintus system name.
program(i).required_modules = {
    {'OT-CC', 1; 'ST-VT', 1};
    };                                                                      %Required primary modules.

%Default configuration function.
program(i).default_config_fcn = ...
    @(handles)Vibrotactile_Detection_Default_Config(handles); 

% %Idle loop function.
% program(i).idle_fcn = @(fig_handle)Vibrotactile_Detection_Idle(fig_handle);           

%Behavioral session function.
program(i).session_fcn = ...
    @(fig_handle)Vibrotactile_Detection_Session_Loop(fig_handle);

%System diagram update function.
program(i).plot_system_fcn = ...
    @(handles)Vibrotactile_Detection_System_Diagram(handles);

%Data plot update function.
program(i).plot_data_fcn = ...
    @(handles,data)Vibrotactile_Detection_Data_Plot(handles,data);

%Input signals processing function.
program(i).process_input_fcn = ...
    @(handles,data)Vibrotactile_Detection_Process_Input(handles,data);

