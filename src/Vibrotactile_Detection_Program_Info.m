function program = Vibrotactile_Detection_Program_Info(behavior, varargin)

%
% Vibrotactile_Detection_Program_Info.m
%
%   copyright 2024, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_PROGRAM_INFO sets the system type, minimum 
%   required hardware, and function callbacks for the SensiTrak
%   vibrotactile detection task behavior program running through the 
%   Vulintus Common Behavior framework.
%   
%   UPDATE LOG:
%   2024-06-24 - Drew Sloan - Function first created, adapted from
%                             Tactile_Discrimination_Program_Info.m
%   2024-11-08 - Drew Sloan - Added passing of the behavior class for
%                             capturing in function handles/pointers.
%                            


if nargin == 1                                                              %If no inputs were passed...
    program = struct;                                                       %Create a program structure.
    i = 1;                                                                  %Set the index to 1.
else                                                                        %Otherwise...
    program = varargin{1};                                                  %Grab the program structure that was passed.
    if length(program) <= 1 || isempty(program(1).task)                     %If the program structure isn't initialized...
        i = 1;                                                              %Set the index to 1.
    else                                                                    %Otherwise...
        i = length(program) + 1;                                            %Increment the program index.
    end
end

program(i).task = 'Vibrotactile Detection';                                 %Set the task name.
program(i).abbreviation = 'STVD';                                           %Abbreviation of the task name for use in filename.
program(i).script_root = 'Vibrotactile_Detection_*';                        %Root name of all behavior-specific scripts.
program(i).system_name = 'SensiTrak';                                       %Vulintus system name.
program(i).primary_device = {'OT-CC'};                                      %Set the primary device name.
program(i).required_modules = {
    {'OT-CC', 1; 'ST-VT', 1};
    };                                                                      %Required primary modules.
program(i).max_instances = 1;                                               %Maximum number of instances supported by hardware.
program(i).ui.menus = { 'system',...
                        'stages',...
                        'preferences',...
                        'calibration',...
                        'camera'};                                          %List the menus to show on the GUI.

%Default configuration function.
program(i).fcn.default_config = ...
    @()Vibrotactile_Detection_Default_Config(behavior); 

%GUI creation function.
% program(i).fcn.create_gui = ...
% >> CURRENTLY USES THE "VULINTUS_BEHAVIOR" COMMON FRAMEWORK FUNCTION.

%Stage loading function.
program(i).fcn.load_stage = ...
    @(varargin)Vibrotactile_Detection_Load_Stage(behavior,...
    varargin{:});

% %Idle loop function.
% program(i).idle_fcn = ...        
% >> CURRENTLY USES THE "VULINTUS_BEHAVIOR" COMMON FRAMEWORK FUNCTION.

%Behavioral session function.
program(i).fcn.session = ...
    @()Vibrotactile_Detection_Session_Loop(behavior);

%System diagram update function.
program(i).fcn.plot_system = ...
    @()Vibrotactile_Detection_System_Diagram(behavior);

%Data plot update function.
program(i).fcn.plot_data = ...
    @(data)Vibrotactile_Detection_Data_Plot(behavior,data);

%Input signals processing function.
program(i).fcn.process_input = ...
    @(packet, src, varargin)Vibrotactile_Detection_Process_Input(behavior, packet, src, varargin{:});

