function program = Vulintus_Behavior_Program_List

%
%Vulintus_Behavior_Program_List.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_PROGRAM_LIST lists the available Vulintus behavioral 
%   task programs paired with relevant task-specific parameters for each
%   task.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created.
%


program = struct('task',[],'required_modules',[],'enabled',0);              %Create a structure to hold program requirements.


%% Fixed Reinforcement.
program = Fixed_Reinforcement_Program_Info(program);


%% Pellet Presentation.
program = Pellet_Presentation_Program_Info(program);


%% Arm Proprioception (2AFC).
program = Arm_Proprioception_Program_Info(program);


%% Tactile Discrimination (2AFC).
program = Tactile_Discrimination_Program_Info(program);


%% Vibrotactile Detection (Go/NoGo).
program = Vibrotactile_Detection_Program_Info(program);


%% Stop Task.
program = Stop_Task_Program_Info(program);


[~, i] = sort({program.task});                                              %Sort the programs alphabetically by name.
program = program(i);                                                       %Reorganize the program list alphabetically.