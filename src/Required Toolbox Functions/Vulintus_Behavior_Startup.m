function varargout = Vulintus_Behavior_Startup(varargin)

%
%Vulintus_Behavior_Startup.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_STARTUP initializes the serial connection to a
%   Vulintus controller, creates a common GUI, sets default directories,
%   and loads training stages for Vulintus behavioral programs.
%   
%   UPDATE LOG:
%   2020-02-28 - Drew Sloan - Function first created, adapted from
%                             SToP_Task_Startup.m
%


%% Initialize the handles structure.
if nargin == 0                                                              %If there are no optional input arguments...
    handles = struct;                                                       %Create a handles structure.
else                                                                        %Otherwise, the first optional input argument will be a handles structure.
    handles = varargin{1};                                                  %Grab the pre-existing handles structure.    
end
varargout = {handles};                                                      %Create a variable output argument cell array.


%% List the available behavior programs.
program = Vulintus_Behavior_Program_List;                                   %Grab the list of Vulintus behavior programs.
if isfield(handles,'task')                                                  %If a task is already defined in the handles structure...
    i = strcmpi({program.task},handles.task);                               %Find the index for the specified task.
    if ~any(i)                                                              %If no match is found.
        error('ERROR IN %s: No matching task for "%s".',...
            upper(mfilename),handles.task);                                 %Show an error.
    end
    program = program(i);                                                   %Keep only the specified program.
end
    

%% Clean up the workspace.
close all force;                                                            %Close any open figures.
fclose all;                                                                 %Close any open data files.


%% Check for required toolboxes.
if ~Vulintus_Check_MATLAB_Toolboxes('Instrument Control Toolbox')           %If the instrument control toolbox isn't installed...
    return                                                                  %Skip execution of the rest of the function.
end


%% Connect to an OmniTrak device.
[handles.ctrl, device_list] = Connect_OmniTrak_Beta;                        %Connect to a Vulintus device.
if isempty(handles.ctrl)                                                    %If no devices were found...
    return                                                                  %Exit the function.
end
handles.ctrl.otsc.clear();                                                  %Clear any residual values from the serial line.

%% Find programs that match the connected OmniTrak devices.
for i = 1:length(program)                                                   %Step through each task.
    program(i).enabled = 0;                                                 %Assume none of the required devices are connected.
    for j = 1:size(program(i).required_modules,1)                           %Step through the lists of required modules.
        checker = zeros(size(program(i).required_modules{j},1),1);          %Create a matrix to check for the presence of all modules.
        for k = 1:size(program(i).required_modules{j},1)                    %Step through the required modules.
            n = sum(strcmpi(program(i).required_modules{j}{k,1},...
                device_list));                                              %Check for the correct number of required modules.
            if n >= program(i).required_modules{j}{k,2}                     %If there's enough of the required module...
                checker(k) = 1;                                             %Mark this requirement as satisfied.
            end
        end
        if all(checker == 1)                                                %If all requirements are satisfied...
            program(i).enabled = 1;                                         %Mark the task as enabled.
        end
    end
end
program([program.enabled] == 0) = [];                                       %Kick out the tasks that don't match the configuration.
if isempty(program)                                                         %If no programs match the configuration...
    if isfield(handles,'task')                                              %If a task was specified...
        str = sprintf(['None of the connected Vulintus devices match '...
            'the configuration required for the "%s" task.'],...
            handles.task);                                                  %Create the text for an error dialog.
    else                                                                    %Otherwise, if no task was specified...
        str = ['None of the connected Vulintus devices match the '...
            'configuration required for any behavioral task.'];             %Create the test for an error dialog.
    end
    errordlg(str,'Required Vulintus Devices Not Found!');                   %Show an error dialog.
    ctrl.otsc.close();                                                      %Close the serial connection.
    return                                                                  %Exit the function.
end
if length(program) > 1                                                      %If the configuration allows for more than one program...
    icon = lower(unique({program.system_name}));                            %Grab all system names in the remaining programs.
    if length(icon) > 1                                                     %If there's more than one possible system...
        icon = 'vulintus';                                                  %Use the general Vulintus icon.
    end
    i = Vulintus_Behavior_Selection_GUI({program.task},icon,...
        'Select a Behavioral Task');                                        %Have the user select a task.
    if i == 0                                                               %If the user canceled the selection box.
        ctrl.otsc.close();                                                  %Close the serial connection.
        return                                                              %Exit the function.
    end
    program = program(i);                                                   %Pare down the program structure to just the one selected.
end
prog_fields = fieldnames(program);                                          %Grab all field names from the program structure.
handles.program = struct;                                                   %Create a field in the handles structure to hold the program information.
for i = 1:length(prog_fields)                                               %Step through each field.
    if any(strcmpi(prog_fields{i},{'task','system_name'}))                  %For the "task" and "system_name" fields...
        handles.(prog_fields{i}) = program.(prog_fields{i});                %Copy the field direct to the handles structure.
    elseif ~any(strcmpi(prog_fields{i},{'enabled'}))                        %For all other fields except "enabled" and "required_modules"...
        handles.program.(prog_fields{i}) = program.(prog_fields{i});        %Copy the field to the program subfield.
    end
end


%% Create the main GUI.
switch handles.task                                                         %Switch between the recognized tasks.
    case 'Pellet Presentation'                                              %Pellet Presentation.
        handles = Pellet_Presentation_GUI(handles);                         %Use the generalized pellet presentation task GUI.
    otherwise                                                               %All other tasks.
        handles = Vulintus_Behavior_Common_GUI(handles);                    %Use the Vulintus Common Behavioral GUI.
end
% set(handles.mainfig,'resize','on','ResizeFcn',@SToP_Task_Resize);         %Set the resize function for the vibration task main figure.
Vulintus_All_Uicontrols_Enable(handles.mainfig,'off');                      %Disable all of the uicontrols until the Arduino is connected.
if isfield(handles.ui,'msgbox')                                             %If there's a messagebox on the GUI...
    Clear_Msg([handles.ui.msgbox]);                                         %Clear all messages out of the messagebox.
    str = sprintf('%s - %s connected.',char(datetime,'hh:mm:ss'),...
        handles.ctrl(1).device.name);                                       %Create a string for the messagebox.
    Add_Msg([handles.ui.msgbox],str);                                       %Show the connected device in the messagebox.     
end


%% Connect to a secondary device, if required.
if isfield(handles.program,'secondary_modules') &&...
        ~isempty(handles.program.secondary_modules)                         %If a secondary module connection is required...
    port_list = Vulintus_Serial_Port_List;                                  %Grab all of the connected serial devices.
    i = strcmpi(port_list(:,3),'HabiTrak Thermal Activity Monitor');        %Check for connected OmniTrak Controllers.
    if sum(i) == 1 && strcmpi(port_list{i,2},'available')                   %If there's only one OmniTrak Controller connected and it's available...
        handles.otth = Connect_OmniTrak_Beta('msgbox',...
            handles.ui.msgbox,'port',port_list{i,1});                       %Connect to the OmniTrak Controller, passing the listbox handle and target port.
    else                                                                    %Otherwise, if no controllers or more than one controller was found.    
        handles.otth = Connect_OmniTrak_Beta('msgbox',...
            handles.ui.msgbox);                                             %Connect to the OmniTrak Controller, passing the listbox handle.
    end
    if isempty(handles.otth)                                                %If the serial connection failed...
        handles.ctrl.otsc.close();                                          %Close the OmniTrak Controller connection.
        close(handles.mainfig);                                             %Close the GUI.
        return                                                              %Skip execution of the rest of the function.
    end
    str = sprintf('%s - %s connected.',char(datetime,'hh:mm:ss'),...
        handles.otth.device.name);                                          %Create a string for the messagebox.
    Replace_Msg(handles.ui.msgbox,str);                                     %Show when the serial connection was successful in the messagebox.     
    handles.otth.otsc.clear();                                              %Clear any residual values from the serial line.
end


%% Load the current configuration file.
handles.computer = Vulintus_Behavior_Computer_Info;                         %Fetch info about the current computer.
handles.mainpath = Vulintus_Set_AppData_Path(handles.system_name);          %Grab the expected directory for this system's application data.
if ~isfield(handles,'initialized') || handles.initialized == 0              %If this is the first time running the startup function...
    handles.datapath = Vulintus_Behavior_Default_Datapath(handles.task);    %Set the default data directory.
    if isfield(handles.program,'default_config_fcn') && ...
            ~isempty(handles.program.default_config_fcn)                    %If there's a default configuration function for this task...
        handles = handles.program.default_config_fcn(handles);              %Load the default configuration values.    
    end
    handles = Vulintus_Behavior_Config_Load(handles);                       %Load any existing configuration file.
end
if ~exist(handles.datapath,'dir')                                           %If the specified data directory doesn't already exist...
    mkdir(handles.datapath);                                                %Create the primary local data path.
end


%% Load the training/testing stage information.
stage_path = fullfile(handles.mainpath, [handles.task ' Stages']);          %Create the folder name for the stages.
if ~isfield(handles,'stages_sync')                                          %If there's not a stages synchronization subfield...
    handles.stages = Vulintus_Behavior_Stages_Read(stage_path);             %Load the stages, passing only the configuration path.
else                                                                        %Otherwise...
    handles.stages = Vulintus_Behavior_Stages_Read(stage_path,...
        handles.stages_sync);                                               %Load the stages, passing the configuration path and the stage synchronization links.
end
if isfield(handles.program,'stage_check_fcn')                               %If a stage checking function is specified for this behavior...
    handles.stages = handles.program.stage_check_fcn(handles.stages);       %Run the stages through the check function.
end
handles.cur_stage = ones(1,length(handles.ui));                             %Set the current stage to the first stage in the list.
Vulintus_Behavior_Stage_Load(handles);                                      %Load the stage in the GUI.


%% Load the previous subject list.
handles.subjects = Vulintus_Behavior_Subject_List(handles.task,...
    handles.datapath);                                                      %Load the subject list.
handles = Vulintus_Behavior_Subject_Load(handles);                          %Load the subject in the GUI.


%% Set up the loop-controlling run field.
handles.run_state = Vulintus_Behavior_Enumerate_Run_Values;                 %Load unique values for the recognized run states.
switch handles.task                                                         %Switch between the recognized tasks.
    case 'Pellet Presentation'                                              %Pellet Presentation.
        handles.run = handles.run_state.root.session;                       %Set the run variable to the session state.
    otherwise                                                               %All other tasks.
        handles.run = handles.run_state.root.idle;                          %Set the run variable to the idle state.
end

%% Pin the handles structure to the GUI and go into the main run loop.
set(handles.mainfig,'UserData',handles);                                    %Pin the handles structure to the main figure(s).
if ~isfield(handles,'initialized') || handles.initialized == 0              %If this is the first time running the startup function...
    try                                                                     %Attempt to run the program.
        handles.initialized = 1;                                            %Set the initialized flag to 1.
        Vulintus_Behavior_Main_Loop(handles.mainfig(1),handles.program,...
            handles.run_state);                                             %Start the main loop.
    catch err                                                               %If any error occurs...
        Vulintus_Behavior_Terminal_Error(err,handles);                      %Generate error messages, logs, and close the program.
    end
else                                                                        %Otherwise, if we were just reloading the behavior...
    varargout{1} = handles;                                                 %Return the handles structure as the first variable output argument.
end