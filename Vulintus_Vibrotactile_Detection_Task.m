function Vulintus_Vibrotactile_Detection_Task

%Collated: 2024-06-24, 05:15:11

Vibrotactile_Detection_Startup;                                             %Call the startup function.


%% ***********************************************************************
function Vibrotactile_Detection_Startup(varargin)

%
%Vibrotactile_Detection_Startup.m - Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_STARTUP starts the SensiTrak vibrotactile
%   detection task program. It loads in default parameters, creates the 
%   GUI, and creates the connection to the OmniTrak controller on a 
%   SensiTrak system.
%   
%   UPDATE LOG:
%   2024-06-24 - Drew Sloan - Function first created.
%                            


%% Use the Vulintus Common Behavior startup function.
if nargin                                                                   %If there were any input arguments.
    handles = varargin{1};                                                  %Assume the handles structure is the first input.
else                                                                        %Otherwise...
    handles = struct('task','Vibrotactile Detection');                      %Create a handles structure.
end
Vulintus_Behavior_Startup(handles);                                         %Call the common behavior startup functions.


%% ***********************************************************************
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
    if length(program) <= 1 || isempty(program(1).task)                     %If the program structure isn't initialized...
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
program(i).fcn.default_config = ...
    @(handles)Vibrotactile_Detection_Default_Config(handles); 

% %Idle loop function.
% program(i).fcn.idle = @(fig_handle)Vibrotactile_Detection_Idle(fig_handle);           

%Behavioral session function.
program(i).fcn.session = ...
    @(fig_handle)Vibrotactile_Detection_Session_Loop(fig_handle);

%System diagram update function.
program(i).fcn.plot_system = ...
    @(handles)Vibrotactile_Detection_System_Diagram(handles);

%Data plot update function.
program(i).fcn.plot_data = ...
    @(handles,data)Vibrotactile_Detection_Data_Plot(handles,data);

%Input signals processing function.
program(i).process_input_fcn = ...
    @(handles,data)Vibrotactile_Detection_Process_Input(handles,data);


%% ***********************************************************************
function Vulintus_All_Uicontrols_Enable(fig,on_off)

%
%Vulintus_All_Uicontrols_Enable.m - Vulintus, Inc.
%
%   VULINTUS_ALL_UICONTROLS_ENABLE is a Vulintus toolbox function which 
%   enables or disables all of the user interface objects on the figure 
%   specified by the handle "fig". The input variable "on_off" must be set
%   to either "on" or "off"
%   
%   UPDATE LOG:
%   11/30/2021 - Drew Sloan - Function converted to a Vulintus behavior 
%       toolbox function, adapted from
%       Vibrotactile_Detection_Task_Enable_All_Uicontrols.m.
%


if ~all(ishandle(fig))                                                      %If the "fig" input variable isn't an object handle...
    error(['ERROR IN VULINTUS_ALL_UICONTROLS_ENABLE: first input '...
        'argument must be a graphics object handle!']);                     %Throw an error.
elseif ~any(strcmpi(on_off,{'on','off'}))                                   %If the "on_off" input variable isn't set to either "on" or "off"...
    error(['ERROR IN VULINTUS_ALL_UICONTROLS_ENABLE: second input '...
        'argument must be either "on" or "off" (case insensitive)!']);      %Throw an error.
end

for i = 1:length(fig)                                                       %Step through all of the figures.
    objs = findobj(fig);                                                    %Grab all fo the graphics objects on the figure.
    i = strcmpi(get(objs,'type'),'uitable') | ...
        strcmpi(get(objs,'type'),'uibutton') | ...
        strcmpi(get(objs,'type'),'uidropdown') | ...
        strcmpi(get(objs,'type'),'uieditfield') | ...
        strcmpi(get(objs,'type'),'uimenu') | ...
        strcmpi(get(objs,'type'),'uicontrol');                              %Find any text area, table, button, drop-down, or edit box components.
    set(objs(i),'enable',on_off);                                           %Enable all text area components.
end


%% ***********************************************************************
function Vulintus_Behavior_Close(fig)

%
%Vulintus_Behavior_Close.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CLOSE executes after the main behavioral loop
%   terminates, usually because the user closes the figure window.
%   
%   UPDATE LOG:
%   2021-11-30 - Drew Sloan - Function converted to a Vulintus behavior
%                             toolbox function, adapted from 
%                             Tactile_Discrimination_Task_Close.m.
%   2024-05-07 - Drew Sloan - Updated to include stream disable, clear, and
%                             close calls for the new version of 
%                             Connect_OmniTrak.
%

handles = fig.UserData;                                                     %Grab the handles structure from the main GUI.

for f = {'ardy','moto','ctrl','otth'}                                       %Step through each commonly-used controller handle name.
    if isfield(handles,f{1})                                                %If the handles structure has a matching field...    
        if isfield(handles.(f{1}),'stream_enable')                          %If there's a stream enable function...
            handles.(f{1}).stream_enable(0);                                %Call the function to double-check that streaming is disabled.
        end
        if isfield(handles.(f{1}),'stream') && ...
                isfield(handles.(f{1}).stream,'enable')                     %If there's an stream subfield with an enable function...
            handles.(f{1}).stream.enable(0);                                %Call the function to double-check that streaming is disabled.
        end
        if isfield(handles.(f{1}),'clear')                                  %If there's a clear serial line function...
            handles.(f{1}).clear();                                         %Call the function to clear any leftover stream output.
        end
        if isfield(handles,'otsc') && isfield(handles.otsc,'clear')         %If there's an OTSC subfield with a clear serial line function...
            handles.(f{1}).otsc.clear();                                    %Call the function to clear any leftover stream output.
        end
        if isfield(handles.(f{1}),'close')                                  %If there's a close serial object function...
            handles.(f{1}).close();                                         %Call the function to close and delete the serial line object.
        end
        if isfield(handles,'otsc') && isfield(handles.otsc,'close')         %If there's an OTSC subfield with a close serial object function...
            handles.(f{1}).otsc.close();                                    %Call the function to close and delete the serial line object.
        end
    end
end

if isfield(handles,'mainfig')                                               %If the handles structure has a "mainfig" field...
    delete(handles.mainfig);                                                %Delete the main figure(s).
else                                                                        %Otherwise...
    delete(fig);                                                            %Delete the passed figure.
end

fprintf(1,'"Vulintus_Behavior_Close" Completed\n');                                                             


%% ***********************************************************************
function handles = Vulintus_Behavior_Common_GUI(varargin)

%
%Vulintus_Behavior_Common_GUI.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_COMMON_GUI creates a common graphical user interface
%   (GUI) used by most Vulintus behavioral task programs.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created, adapted from
%                             Stop_Task_Make_GUI.m
%


%% Load any passed task information.
options = struct;                                                           %Create an empty options structure.
if nargin >= 1                                                              %If at least one input argument was passed...
    handles = varargin{1};                                                  %The pre-existing handles structure will be the first argument..
else                                                                        %Otherwise (mostly for debugging)...
    handles = struct;                                                       %Create an empty handles structure.
    close all force;                                                        %Close any open figures.
    fclose all;                                                             %Close any open data files.
end
if nargin >= 2                                                              %If at least two input arguments were passed...
    options = varargin{2};                                                  %An options structure will be the second argument.
end
if isfield(handles,'task')                                                  %If there   's a task name field in the handles structure...
    if isfield(handles,'system_name')                                       %If there's a system name in the handles structure...
        fig_name = sprintf('%s: %s',handles.system_name,handles.task);      %Create a figure title.
    else                                                                    %Otherwise, if there's no system name...
        fig_name = handles.task;                                            %Use the task name.
    end
else                                                                        %Otherwise...
    fig_name = 'Vulintus Behavior';                                         %Use a generic figure title for the time being.
end
if isfield(handles,'ctrl') && isfield(handles.ctrl,'port')                  %If there's a control field and a device subfield...
    fig_name = sprintf('%s (%s',fig_name,handles.ctrl.port);                %Add the COM port to the figure name.
    if isfield(handles.ctrl,'device') && ...
            isfield(handles.ctrl.device,'userset_alias') && ...
            ~isempty(handles.ctrl.device.userset_alias)                     %If there's an user-set alias for the device...
        fig_name = sprintf('%s, %s)',fig_name,...
            handles.ctrl.device.userset_alias);                             %Add the alias to the figure name.
    else                                                                    %Otherwise...
        fig_name = sprintf('%s)',fig_name);                                 %Close the parentheses on the figure name.
    end
end


%% Set the common properties of subsequent uicontrols.
fontsize = 16;                                                              %Set the fontsize for all uicontrols.
ui_h = 0.75;                                                                %Set the height of all editboxes and listboxes, in centimeters.
sp = 0.1;                                                                   %Set the spacing between uicontrols, in centimeters.
label_color = [0.7 0.7 0.9];                                                %Set the color for all labels.


%% Create the main figure.
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the system screen size.
w = 20;                                                                     %Set the initial GUI width, in centimeters.
h = 14;                                                                     %Set the initial GUI height, in centimeters.
fig = uifigure('units','centimeter',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h],...
    'resize','off',...
    'name',fig_name);                                                       %Create the main figure.
if isfield(handles,'system_name')                                           %If there's a system name in the handles structure...
    switch lower(handles.system_name)                                       %Switch between the recognized system names.
        case 'habitrak'                                                     %HabiTrak.
            [img, alpha_map] = Vulintus_Load_HabiTrak_V1_Icon_48px;         %Use the HabiTrak icon.
        case 'mototrak'                                                     %MotoTrak.
            [img, alpha_map] = Vulintus_Load_MotoTrak_V2_Icon_48px;         %Use the MotoTrak V2 icon.
        case 'omnihome'                                                     %OmniHome.
            [img, alpha_map] = Vulintus_Load_OmniHome_V1_Icon_48px;         %Use the OmniHome icon.
        case 'omnitrak'                                                     %OmniTrak.
            [img, alpha_map] = Vulintus_Load_OmniTrak_V1_Icon_48px;         %Use the OmniTrak icon.    
        case 'sensitrak'                                                    %SensiTrak.
            [img, alpha_map] = Vulintus_Load_SensiTrak_V1_Icon_48px;        %Use the SensiTrak icon.
        otherwise                                                           %For all other options.
            [img, alpha_map] = ...
                Vulintus_Load_Vulintus_Logo_Circle_Social_48px;             %Use the Vulintus Social Logo.
    end
else                                                                        %Otherwise...
    [img, alpha_map] = Vulintus_Load_Vulintus_Logo_Circle_Social_48px;      %Use the Vulintus Social Logo icon.
end
img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);                    %Match the icon board to the figure.
fig.Icon = img;                                                             %Set the figure icon.
fig.Units = 'pixels';                                                       %Change the figure units to pixels.
pos = fig.Position;                                                         %Grab the figure position, in pixes.
scale = pos(3)/w;                                                           %Calculate the centimeters to pixels conversion factor.


%% Reset any handles already existing in the structure.
handles.ui = struct('menu',[],'label',[]);                                  %Reset the "ui" structure


%% Create a system menu at the top of the figure.
handles.ui.menu.system.h = uimenu(fig,'label','System');                    %Create a system menu at the top of the figure.
str = 'COM Port:';                                                          %Create a submenu option string.
if isfield(handles,'ctrl') && isfield(handles.ctrl,'port')                  %If there's a control field and a device subfield...
    str = sprintf('%s %s',str,handles.ctrl.port);                           %Add the port to the string.
end
handles.ui.menu.system.com_port = uimenu(handles.ui.menu.system.h,...
    'label',str,...
    'enable','on',...
    'separator','off');                                                     %Create a submenu option to show the COM port.
str = 'Controller:';                                                        %Create a submenu option string.
if isfield(handles,'ctrl') && isfield(handles.ctrl,'device') && ...
        isfield(handles.ctrl.device,'name')                                 %If there's a device name in the handles structure...
    str = sprintf('%s %s',str,handles.ctrl.device.name);                    %Add the device name to the string.
end
handles.ui.menu.system.controller = uimenu(handles.ui.menu.system.h,...
    'label',str,...
    'enable','on',...
    'separator','off');                                                     %Create a submenu option to show the controller type.
str = 'Vulintus SN:';                                                       %Create a submenu option string.
if isfield(handles,'ctrl') && isfield(handles.ctrl,'device') && ...
        isfield(handles.ctrl.device,'vulintus_alias')                       %If there's a Vulintus alias in the handles structure...
    str = sprintf('%s %s',str,handles.ctrl.device.vulintus_alias);          %Add the Vulintus alias to the string.
end
handles.ui.menu.system.vulintus_alias = uimenu(handles.ui.menu.system.h,...
    'label',str,...
    'enable','on',...
    'separator','off');                                                     %Create a submenu option to show the Vulintus alias.


%% Create a stages menu at the top of the figure.
handles.ui.menu.stages.h = uimenu(fig,'label','Stages');                    %Create a stages menu at the top of the LED_Detection_Task figure.
handles.ui.menu.stages.view_spreadsheet = ...
    uimenu(handles.ui.menu.stages.h,...
    'label','View Spreadsheet in Browser...',...
    'enable','off',...
    'separator','on');                                                      %Create a submenu option for opening the stages spreadsheet.
handles.ui.menu.stages.set_spreadsheet = ...
    uimenu(handles.ui.menu.stages.h,...
    'label','Set Spreadsheet URL...',...
    'enable','off');                                                        %Create a submenu option for setting the stages spreadsheet URL.
handles.ui.menu.stages.reload_spreadsheet = ...
    uimenu(handles.ui.menu.stages.h,...
    'label','Reload Spreadsheet',...
    'enable','off');                                                        %Create a submenu option for reloading the stages spreadsheet.


%% Create a preferences menu at the top of the figure.
handles.ui.menu.pref.h = uimenu(fig,'label','Preferences');                 %Create a preferences menu at the top of the LED_Detection_Task figure.
handles.ui.menu.pref.open_datapath = uimenu(handles.ui.menu.pref.h,...
    'label','Open Data Directory',...
    'enable','off');                                                        %Create a submenu option for opening the target data directory.
handles.ui.menu.pref.set_datapath = uimenu(handles.ui.menu.pref.h,...
    'label','Set Data Directory',...
    'enable','off');                                                        %Create a submenu option for setting the target data directory.
handles.ui.menu.pref.err_report = uimenu(handles.ui.menu.pref.h,...
    'label','Automatic Error Reporting',...
    'enable','off',...
    'separator','on');                                                      %Create a submenu option for tuning Automatic Error Reporting on/off.
handles.ui.menu.pref.err_report_on = ...
    uimenu(handles.ui.menu.pref.err_report,...
    'label','On',...
    'enable','off',...
    'checked','on');                                                        %Create a sub-submenu option for tuning Automatic Error Reporting on.
handles.ui.menu.pref.err_report_off = ...
    uimenu(handles.ui.menu.pref.err_report,...
    'label','Off',...
    'enable','off',...
    'checked','off');                                                       %Create a sub-submenu option for tuning Automatic Error Reporting on.
handles.ui.menu.pref.error_reports = uimenu(handles.ui.menu.pref.h,...
    'label','View Error Reports',...
    'enable','off');                                                        %Create a submenu option for opening the error reports directory.
handles.ui.menu.pref.config_dir = uimenu(handles.ui.menu.pref.h,...
    'label','Configuration Files...',...
    'enable','off',...
    'separator','on');                                                      %Create a submenu option for opening the configuration files directory.
        

%% Create a panel housing all of the session information uicontrols.
ph = 2*(ui_h + sp) + 2*sp;                                                  %Set the panel height.
pw = w - 3*sp;                                                              %Set the panel width.
py = h - ph - sp;                                                           %Set the panel bottom edge.
p = uipanel(fig,'units','pixels',...
    'position',scale*[2*sp, py, pw, ph],...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'backgroundcolor',get(fig,'color'));                                    %Create the panel to hold the session information uicontrols.

pos = [sp, 2*sp, 2.35, ui_h];                                               %Set the label position.
handles.ui.label.system = uilabel(p,'text','SYSTEM: ',...
    'position',scale*pos);                                                  %Make a static text label for the booth.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left-hand edge for the booth drop-down.
pos(3) = 5.5;                                                               %Set the width of the booth drop-down.
if isfield(handles.ctrl,'device') &&...   
        isfield(handles.ctrl.device,'userset_alias') && ...
        ~isempty(handles.ctrl.device.userset_alias)                         %If there's an user-set alias for the device...
    str = handles.ctrl.device.userset_alias;                                %Grab the alias to show in the system editbox.
elseif isfield(handles.ctrl,'port') && ~isempty(handles.ctrl.port)          %Otherwise, if there's a COM port for this device...
    str = handles.ctrl.port;                                                %Grab the COM port to show in the system editbox.
else                                                                        %Otherwise...
    str = '-';                                                              %Just show a dash.
end
handles.ui.edit_port = uieditfield(p,'editable','off',...
    'value',str,...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','left',...
    'backgroundcolor','w',...
    'enable','off');                                                        %Create an editbox for displaying the COM Port.

pos = [sp, 3*sp + ui_h, 2.35, ui_h];                                        %Set the label position.
handles.ui.label.subject = uilabel(p,'text','SUBJECT: ',...
    'position',scale*pos);                                                  %Make a static text label for the subject.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left-hand edge for the subject drop-down.
pos(3) = 3.5;                                                               %Set the width of the subject drop-down.
handles.ui.drop_subject = uidropdown(p,'editable','off',...
    'items',{'<Add New Subject>','<Edit Subject List>','[Bench Test]'},...
    'position',scale*pos,...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'backgroundcolor','w',...
    'enable','off');                                                        %Create an drop-down for selecting the subject name.

pos = handles.ui.drop_subject.Position/scale;                               %Grab the position of the subject drop-down.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left-hand edge for the subject drop-down.
pos(3) = 1.9;                                                               %Set the width of the label.
handles.ui.label.stage = uilabel(p,'text','STAGE: ',...
    'position',scale*pos);                                                  %Make a static text label for the stage
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left edge of the task mode editbox.
pos(3) = pw - sp - pos(1);                                                  %Set the width of the task mode editbox.
handles.ui.drop_stage = uidropdown(p,'editable','off',...
    'items',{'-'},...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'backgroundcolor','w',...
    'enable','off');                                                        %Create an drop-down for selecting the stage.

pos = handles.ui.edit_port.Position/scale;                                  %Grab the position of the system/port editbox.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left-hand edge for the session duration timer.
pos(3) = 2.25;                                                              %Set the width of the label.
handles.ui.label.session = uilabel(p,'text','SESSION: ',...
    'position',scale*pos);                                                  %Make a static text label for the stage
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left edge of the task mode editbox.
pos(3) = 2.0;                                                               %Set the width of the task mode editbox.
handles.ui.edit_dur = uieditfield(p,'editable','off',...
    'value','0:00:00',...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','center',...
    'backgroundcolor','w',...
    'enable','off');                                                        %Create an editbox for displaying the sampling time.

pos(1) = pos(1) + pos(3) + sp;                                              %Set the left edge of a label.
pos(3) = 3.3;                                                               %Set the width of a label.
handles.ui.label.hits = uilabel(p,'text','HITS / TRIALS: ',...
    'position',scale*pos);                                                  %Make a static text label for each uicontrol.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left edge of the task mode editbox.
pos(3) = pw - sp - pos(1);                                                  %Set the width of the task mode editbox.
handles.ui.edit_rewards = uieditfield(p,'editable','off',...
    'value','0 / 0',...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','center',...
    'backgroundcolor','w',...
    'enable','off');                                                        %Create an editbox for displaying the sampling time.

labels = [  handles.ui.label.system,...
            handles.ui.label.subject,...
            handles.ui.label.stage,...
            handles.ui.label.session,...
            handles.ui.label.hits];                                         %Grab all of the label handles.
set(labels,'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','right',...
    'verticalalignment','center',...
    'backgroundcolor',label_color);                                         %Set the properties for all the labels.

    
%% Create axes for displaying a system diagram.
ax_h = 6;                                                                   %Set the total axes height, in centimeters.
py = py - ax_h - 2*sp;                                                      %Set the axes bottom edge.
pos = [2*sp, py, ax_h, ax_h];                                               %Set the position for the force axes.
handles.ui.ax_system = axes('parent',fig,...
    'units','centimeters',...
    'position',pos,...
    'xtick',[],...
    'ytick',[],...
    'box','on');                                                            %Create axes to show the force signal.
disableDefaultInteractivity(handles.ui.ax_system);                          %Disable the axes interactivity.
handles.ui.ax_system.Toolbar.Visible = 'off';                               %Hide the axes toolbar.


%% Create axes for displaying real-time data.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left edge of the psychophysical axes.
pos(2) = py;                                                                %Set the bottom edge of the axes.
pos(3) = w - pos(1) - 2*sp;                                                 %Set the width of the axes.
pos(4) = ax_h;                                                              %Set the height of the axes.
handles.ui.ax_data = axes('parent',fig,...
    'units','centimeters',...
    'position',pos,...
    'xtick',[],...
    'ytick',[],...
    'box','on');                                                            %Create axes to show the real-time data.
disableDefaultInteractivity(handles.ui.ax_data);                            %Disable the axes interactivity.
handles.ui.ax_data.Toolbar.Visible = 'off';                                 %Hide the axes toolbar.


%% Create pushbuttons for starting, stopping, pausing, and manually triggering feedings.
ui_w = 4;                                                                   %Set the button width, in centimeters.
ui_h = (py - 5*sp)/3;                                                       %Recalculate the uicontrol height.
if isfield(options,'feed_left_right') && options.feed_left_right == 1       %If there are two feeders...
    pos = [sp, 2*sp, (ui_w - sp)/2, ui_h];                                  %Set the button position.
    str = {'FEED','LEFT'};                                                  %Set the button text.
else                                                                        %Otherwise, if there's just one feeder...
    pos = [sp, 2*sp, ui_w, ui_h];                                           %Set the button position.
    str = 'FEED';                                                           %Set the button text.
end
handles.ui.btn_feed = uibutton(fig,'text',str,...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'fontcolor','k',...
    'enable','off');                                                        %Create a button for (left) manual feeds.
if isfield(options,'feed_left_right') && options.feed_left_right == 1       %If there are two feeders...
    pos(1) = pos(1) + (ui_w - sp)/2 + sp;                                   %Update the position left edge.
    str = {'FEED','RIGHT'};                                                 %Set the button text.
    handles.ui.btn_feed(2) = uibutton(fig,'text',str,...
        'position',scale*pos,...
        'fontname','Arial',...
        'fontweight','bold',...
        'fontsize',fontsize,...
        'fontcolor','k',...
        'enable','off');                                                    %Create a button for manual feeds.
end
pos(1) = sp;                                                                %Update the position left edge.
pos(3) = ui_w;                                                              %Set the start and pause buttons to maximum width.
pos(2) = pos(2) + pos(4) + sp;                                              %Adjust the position bottom edge.    
handles.ui.btn_pause = uibutton(fig,'text','PAUSE',...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'fontcolor',[0 0 0.5],...
    'enable','off');                                                        %Create a pause button.
pos(2) = pos(2) + pos(4) + sp;                                              %Adjust the position bottom edge.    
handles.ui.btn_start = uibutton(fig,'text','START',...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'fontcolor',[0 0.5 0],...
    'enable','off');                                                        %Create a pause button.


%% Create a table to show users trial data.
pos(1) = pos(1) + pos(3) + sp;                                              %Set the left-hand edge of the trial table.
pos(2) = 2*sp;                                                              %Set the bottom edge of the trial table.
pos(3) = w - pos(1) - 2*sp;                                                 %Set the width of the trial table.
pos(4) = py - 2*sp - 1.75;                                                  %Set the height of the trial table.
handles.ui.tbl_trial = uitable(fig,'position',scale*pos,...
    'fontname','Arial',...
    'fontsize',0.75*fontsize,...
    'enable','off');                                                        %Create a table to hold trial info.
columns =   {   'Trial',...
                'Time',...
                'Outcome'};                                                 %List the column labels.
handles.ui.tbl_trial.ColumnName = columns;                                  %Label the columns of the table.
col_w = {1, 1, 1};                                                          %Create a matrix to hold column widths.
N = sum(vertcat(col_w{:}));                                                 %Find the total of all the column widths.
for i = 1:numel(columns)                                                    %Step through each column label.
    col_w{i} = scale*pos(3)*col_w{i}/N;                                     %Scale each column width to the character size.
end
col_w{end} = 'auto';                                                        %Set the last column to auto-scale.
handles.ui.tbl_trial.ColumnWidth = col_w;                                   %Set the column widths.            
handles.ui.table_style = [];                                                %Create a field to hold table styles.
handles.ui.table_style.outcomes = 'HMFCANLP';                               %Create a subfield to hold table style labels.
handles.ui.table_style.h(1) = uistyle('BackgroundColor',[0.5 1 0.6]);       %Create a light green cell color for hits.
handles.ui.table_style.h(2) = uistyle('BackgroundColor',[1 0.6 0.5]);       %Create a light red cell color for misses.
handles.ui.table_style.h(3) = uistyle('BackgroundColor',[1 0.5 0.6]);       %Create a light red cell color for false alarms.
handles.ui.table_style.h(4) = uistyle('BackgroundColor',[0.6 1 0.5]);       %Create a light green cell color for correct rejections.
handles.ui.table_style.h(5) = uistyle('BackgroundColor',[0.8 0.8 0.8]);     %Create a light gray cell color for aborts.
handles.ui.table_style.h(6) = uistyle('BackgroundColor',[0.95 1 0.5]);      %Create a light yellow cell color for non-responses.
handles.ui.table_style.h(7) = uistyle('BackgroundColor',[1 0.95 0.5]);      %Create a light yellow cell color for loiters.
handles.ui.table_style.h(8) = uistyle('BackgroundColor',[0.95 0.95 0.5]);   %Create a light yellow cell color for pre-empts.
s = uistyle('HorizontalAlignment','center');                                %Create a centered horicontal alignment style.
addStyle(handles.ui.tbl_trial,s);                                           %Add the centered style to the table.


%% Create a text area to show users status messages.
pos(2) = pos(2) + pos(4) + sp;                                              %Set the bottom edge of the messagebox.
pos(4) = py - pos(2) - sp;                                                  %Set the height of the the messagebox.
handles.ui.msgbox = uitextarea(fig,...
    'value','Initializing...',...
    'position',scale*pos,...
    'fontname','Arial',...
    'fontweight','bold',...
    'fontsize',0.8*fontsize,...
    'editable','off');                                                      %Create a messagebox.

%% Update the handles structure.
handles.ui = orderfields(handles.ui);                                       %Order the UI fields alphabetically.
handles.mainfig = fig;                                                      %Save the figure handle in the handles structure.
fig.UserData = handles;                                                     %Save the handles structure to the figure's UserData property.


% %% Set the units for all children of the main figure to "normalized".
% objs = get(fig,'children');                                     %Grab the handles for all children of the main figure.
% checker = ones(1,numel(objs));                                              %Create a checker variable to control the following loop.
% while any(checker == 1)                                                     %Loop until no new children are found.
%     for i = 1:numel(objs)                                                   %Step through each object.
%         if isempty(get(objs(i),'children'))                                 %If the object doesn't have any children.
%             checker(i) = 0;                                                 %Set the checker variable entry for this object to 0.
%         end
%     end
%     if any(checker == 1)                                                    %If any objects were found to have children...        
%         temp = get(objs(checker == 1),'children');                          %Grab the handles of the newly-identified children.
%         checker(:) = 0;                                                     %Skip all already-registed objects on the next loop.
%         temp = vertcat(temp{:});                                            %Vertically concatenate all of the object handles.
%         j = strcmpi(get(temp,'type'),'uimenu');                             %Check if any of the children are uimenu objects.
%         temp(j) = [];                                                       %Kick out all uimenu objects.        
%         if ~isempty(temp)                                                   %If there's any new objects...
%             for i = 1:numel(temp)                                           %Step through each new object.
%                 objs(end+1) = temp(i);                                      %Add each new child to the object list.
%                 checker(end+1) = 1;                                         %Add a new entry to the checker matrix.
%             end
%         end
%     end
% end
% type = get(objs,'type');                                                    %Grab the type of each object.
% objs(strcmpi(type,'uimenu')) = [];                                          %Kick out all uimenu items.
% set(objs,'units','normalized');                                             %Set all units to normalized.


%% ***********************************************************************
function sys = Vulintus_Behavior_Computer_Info(varargin)

%
%Vulintus_Behavior_Computer_Info.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_COMPUTER_INFO returns the type, name, and other
%   specifications about the computer currently running the calling
%   software.
%   
%   UPDATE LOG:
%   2023-12-20 - Drew Sloan - Function first created.
%


debug = 0;                                                                  %Assume by default that we don't want to return debugging information.
for i = 1:length(varargin)                                                  %Step through the input arguments.
    debug = debug | strcmpi(varargin{i},'debug');                           %Set the debug mode to 1 if any argument is "debug".
end

[~, temp] = system('hostname');                                             %Grab the local computer name.
temp(temp < 33) = [];                                                       %Kick out any spaces and carriage returns from the computer name.
sys = struct('host',temp);                                                  %Local computer name.
sys.name = getenv('COMPUTERNAME');                                          %User-set computer name.

if debug                                                                    %If we're debugging...
    sys.specs.os = feature('GetOS');                                        %Operating system name.
    sys.specs.win_sys = feature('GetWinSys');                               %Windows build version.
    sys.specs.cpu = feature('GetCPU');                                      %CPU name.
    sys.specs.num_cores = feature('NumCores');                              %Number of cores.
    temp = ver('matlab');                                                   %Fetch the MATLAB version.
    sys.matlab.ver = temp.Version;                                          %MATLAB version.
    sys.matlab.release = matlabRelease.Release;                             %MATLAB release.
    sys.matlab.update = matlabRelease.Update;                               %MATLAB update number.
    [~,temp] = memory;                                                      %Fetch the memory size.
    sys.memory.physical = temp.PhysicalMemory.Total;                        %Total physical memory.
    sys.memory.system = temp.SystemMemory.Available;                        %Total system memory.
end


%% ***********************************************************************
function handles = Vulintus_Behavior_Config_Load(handles)

%
%Vulintus_Behavior_Config_Load.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CONFIG_LOAD loads the values of customizable 
%   behavioral parameters into the fields of a configuration structure
%   ("handles").
%   
%   UPDATE LOG:
%   2021-10-05 - Drew Sloan - Function first created, adapted from
%                             LED_Detection_Task_Load_Config.m.
%   2024-02-28 - Drew Sloan - Renamed from "Vulintus_Behavior_Load_Config"
%                             to "Vulintus_Behavior_Config_Load".
%


%List the fielst to write to the configuration file if none are found.
default_fields = {
    {'datapath'};
    {'stages','google_spreadsheet_url'};
    {'stages','google_spreadsheet_edit_url'};
    };  

config_root = lower(handles.task);                                          %Grab the task name.
if any(config_root == '(')                                                  %If there's a parenthesis in the task name.
    config_root(find(config_root == '(',1,'first'):end) = [];               %Kick out everything from the parenthesis onward.
end
config_root = strtrim(config_root);                                         %Trim the remaining string.
config_root(config_root == ' ') = '_';                                      %Replace all spaces with underscores.
search_str = sprintf('*%s.config',config_root);                             %Create the search string for the configuration files.
search_str = fullfile(handles.mainpath,search_str);                         %Add the AppData path to the search string.
files = dir(search_str);                                                    %Find all matching configuration files in the main program path.

if isempty(files)                                                           %If no configuration files were found...
    filename = sprintf('%s_%s.config',lower(handles.computer.name),...
        config_root);                                                       %Create a configuration filename.
    filename = fullfile(handles.mainpath,filename);                         %Add the main path to the filename.
    Vulintus_Behavior_Config_Write(filename, handles, default_fields);      %Create a default configuration file.
    return                                                                  %Exit the function.
end

if isscalar(files)                                                          %If there's one configuration file in the main program path...
    handles.config_file = fullfile(handles.mainpath, files(1).name);        %Set the configuration file path to the single file.
else                                                                        %Otherwise, if there's multiple configuration files...
    files = {files.name};                                                   %Create a cell array of configuration file names.
    i = listdlg('PromptString',...
        'Which configuration file would you like to use?',...
        'name','Multiple Configuration Files',...
        'SelectionMode','single',...
        'listsize',[300 200],...
        'initialvalue',1,...
        'uh',25,...
        'ListString',files);                                                %Have the user pick a configuration file to use from a list dialog.
    if isempty(i)                                                           %If the user clicked "cancel" or closed the dialog...
        return                                                              %Skip execution of the rest of the function.
    end
    handles.config_file = fullfile(handles.mainpath,files{i});              %Set the configuration file path to the single file.
end 

config = Vulintus_JSON_File_Read(handles.config_file);                      %Read in the configuration file.

handles = Vulintus_Merge_Structures(handles, config);                       %Merge the configuration fields into the handles structure


%% ***********************************************************************
function Vulintus_Behavior_Config_Write(filename, handles, config_fields)

%
%Vulintus_Behavior_Config_Write.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CONFIG_WRITE create a *.config file linking the specificed 
%   customizable behavioral parameters ("fields") stored in a configuration
%   structure ("handles") to currently-set values.
%   
%   UPDATE LOG:
%   2021-10-05 - Drew Sloan - Function first created, adapted from
%                             LED_Detection_Task_Write_Config.m.
%   2024-02-28 - Drew Sloan - Renamed from "Vulintus_Behavior_Write_Config"
%                             to "Vulintus_Behavior_Config_Write".
%


if ~isempty(config_fields)                                                  %If the fields input isn't empty...
    config = struct;                                                        %Create a temporary structure.    
    for f = 1:length(config_fields)                                         %Step through each set of fields/subfields to include.
        config = Vulintus_Copy_Subfield(config, handles, config_fields{f}); %Copy each field/subfield to the temporary structure.
    end
    Vulintus_JSON_File_Write(config, filename);                             %Write the configuration to a JSON file.
end


%% ***********************************************************************
function ofbc_write = Vulintus_Behavior_Create_OmniTrak_File(fig)

%
%Vulintus_Behavior_Create_OmniTrak_File.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CREATE_OMNITRAK_FILE creates an Vulintus *.OmniTrak 
%   format file to receive Vulintus behavioral program session data and 
%   starts the file with a standardized header.
%   
%   UPDATE LOG:
%   2024-04-22 - Drew Sloan - Function first created, adapted from
%                             ST_Tactile_2AFC_Write_File_Header.m.
%

data_path = fullfile(fig.UserData.datapath,...
    upper(fig.UserData.cur_subject));                                       %Create the subfolder name for this subject.
if ~exist(data_path,'dir')                                                  %If the subject subfolder doesn't already exist...
    mkdir(data_path);                                                       %Create the subject subfolder.
end
date_string = char(datetime,'yyyyMMdd''T''hhmmss');                         %Create a timestamp string.
s = fig.UserData.cur_stage;                                                 %Grab the stage index.
stage = fig.UserData.stages(s).name;                                        %Grab the stage name.
stage(stage == ' ') = [];                                                   %Kick out all spaces.
short_filename = sprintf(   '%s_%s_%s_%s.OmniTrak',...
                            upper(fig.UserData.cur_subject),...
                            date_string,...
                            fig.UserData.program.abbreviation,...
                            stage);                                         %Create the new filename.
full_filename = fullfile(data_path,short_filename);                         %Add the path to the filename.

ofbc_write = OmniTrak_File_Writer(full_filename);                           %Create the OFBC file-writer structure.

if isfield(fig.UserData,'ui') && isfield(fig.UserData.ui,'msgbox')          %If there's a messagebox in the GUI.
    str = sprintf('%s - Writing session data to file:',...
        char(datetime,'hh:mm:ss'));                                         %Create a message string.
    Add_Msg(fig.UserData.ui.msgbox,str);                                    %Show the message in the messagebox.
    Add_Msg(fig.UserData.ui.msgbox,['          ' fullfile(data_path,' ')]); %Show the user the session data path.
    Add_Msg(fig.UserData.ui.msgbox,['          ' short_filename]);          %Show the user the session data file name.
end



%System name.
if isfield(fig.UserData,'system_name') && ...
        ~isempty(fig.UserData.system_name)                                  %If a system name is specified in the handles structure.
    ofbc_write.system_name(fig.UserData.system_name);                       %Write the Vulintus system name to the file.
end

%Computer name.
if isfield(fig.UserData,'computer') && ...
        isfield(fig.UserData.computer,'name') && ...
        ~isempty(fig.UserData.computer.name)                                %If a computer name is specified in the handles structure.
    ofbc_write.computer_name(fig.UserData.computer.name);                   %Write the computer name to the file.
end

%User-set alias (a.k.a. user system name).
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'userset_alias') && ...
        ~isempty(fig.UserData.ctrl.device.userset_alias)                    %If an user-set alias is specified in the handles structure.
    ofbc_write.userset_alias(fig.UserData.ctrl.device.userset_alias);       %Write the system user-set alias to the file.
end

%COM Port.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'port') && ...
        ~isempty(fig.UserData.ctrl.port)                                    %If a COM port is specified in the handles structure.
    ofbc_write.com_port(fig.UserData.ctrl.port);                            %Write the COM port to the file.
end

%Time zone offset.
ofbc_write.time_zone_offset();                                              %Write the time zone offset block.

%Firmware filename.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_filename') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_filename)            %If a firmware filename-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_filename();                 %Grab the firmware filename.
    if ~isempty(str)                                                        %If a firmware filename was returned.
        ofbc_write.ctrl_fw_filename(str);                                   %Write the controller firmware filename to the file.
    end
end

%Firmware date.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_date') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_date)                %If a firmware date-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_date();                     %Grab the firmware compilation date.
    if ~isempty(str)                                                        %If a firmware date was returned.
        ofbc_write.ctrl_fw_date(str);                                       %Write the controller firmware compilation date to the file.
    end
end

%Firmware time.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_time') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_time)                %If a firmware time-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_time();                     %Grab the firmware compilation time.
    if ~isempty(str)                                                        %If a firmware date was returned.
        ofbc_write.ctrl_fw_time(str);                                       %Write the controller firmware compilation time to the file.
    end
end

%Subject.
if isfield(fig.UserData,'cur_subject') && ...
        ~isempty(fig.UserData.cur_subject)                                  %If a subject name is specified in the handles structure.
    ofbc_write.subject_name(fig.UserData.cur_subject);                      %Write the subject name to the file.
end

%Experiment name.
if isfield(fig.UserData,'task') && ~isempty(fig.UserData.task)              %If a experiment/task name is specified in the handles structure.
    ofbc_write.exp_name(fig.UserData.task);                                 %Write the experiment/task name to the file.
end

%Stage name and description.
if isfield(fig.UserData,'cur_stage') && ~isempty(fig.UserData.cur_stage)    %If a stage index is specified in the handles structure.
    s = fig.UserData.cur_stage;                                             %Grab the stage index.    
    ofbc_write.stage_name(fig.UserData.stages(s).name);                     %Write the stage name to the file.
    ofbc_write.stage_description(fig.UserData.stages(s).description);       %Write the stage description to the file.
end


%% ***********************************************************************
function datapath = Vulintus_Behavior_Default_Datapath(task_name)

%
%Vulintus_Behavior_Default_Datapath.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_DEFAULT_DATAPATH sets the default directory for data
%   files written by Vulintus behavioral programs. This directory
%   assignment can be overridden by a data directory set in each task's
%   configuration file.
%   
%   UPDATE LOG:
%   2024-03-08 - Drew Sloan - Function first created, branched from
%                             Vulintus_Behavior_Startup.m.
%

task_name = strtrim(task_name);                                             %Trim off any leading or trailing spaces from the task name.

switch computer('arch')                                                     %Switch between the different computer architectures.

    case 'win64'                                                            %Windows 64-bit.
        [sys_root,~,~] = fileparts(getenv('SYSTEMROOT'));                   %Grab the system root directory.
        datapath = fullfile(sys_root, 'Vulintus Data', task_name);          %Set the default data directory on the main drive.

    case 'glnxa64'                                                          %Linux 64-bit.
        error(['ERROR IN %s: This function needs to be updated to work '...
            'with Linux.'],upper(mfilename));                               %Throw an error to say we need to complete the function.

    case 'maci64'                                                           %Mac 64-bit.
        error(['ERROR IN %s: This function needs to be updated to work '...
            'with Mac OS.'],upper(mfilename));                              %Throw an error to say we need to complete the function.

    otherwise                                                               %If the architecture doesn't match any of these...
        error('ERROR IN %s: Unrecognized computer architecture!',...
            upper(mfilename));                                              %Throw an error.

end


%% ***********************************************************************
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


%% ***********************************************************************
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


%% ***********************************************************************
function Vulintus_Behavior_Launch_Webcam_Preview

set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
pos = get(0,'screensize');                                                  %Grab the default position of the new figure.
w = 15;                                                                     %Set the preview width, in centimeters.
h = 9*w/16;                                                                 %Set the preview height, in centimeters.
pos = [pos(3)/2 - w/2, pos(4)/2 - h/2, w, h];                               %Set the figure position.
sp = 0.25;                                                                  %Set the space in between webcam buttons.

fig = figure('units','centimeters',...
    'position',pos,...
    'MenuBar','none',...
    'numbertitle','off',...
    'resize','on',...
    'name','Webcam Preview');                                               %Make a new figure.

cams = webcamlist;                                                          %Fetch all of the available webcams.
if numel(cams) == 1                                                         %If there's only one camera available...
    Open_Webcam_Preview(fig,[],cams{1});                                    %Open up the webcam preview immediately.
    return                                                                  %Skip execution of the rest of the function.
end

ui_h = (h - (numel(cams) + 1)*sp)/numel(cams);                              %Calculate the height of each button.
fontsize = 4*ui_h;                                                          %Set the button fontsize.

for i = 1:numel(cams)                                                       %Step through each available camera.
    pos = [sp, h - i*(ui_h + sp), w - 2*sp, ui_h];                          %Set the position for each uicontrol
    uicontrol('style','pushbutton',...
        'string',cams{i},...
        'fontsize',fontsize,...
        'units','centimeters',...
        'position',pos,...
        'callback',{@Open_Webcam_Prevew,cams{i}},...
        'parent',fig);       
end


function Open_Webcam_Prevew(hObject,~,camstring)
type = get(hObject,'type');                                                 %Grab the calling object type.
if strcmpi(type,'figure')                                                   %If the object handle is for a figure...
    obj = hObject;                                                          %Keep that object handles.
else                                                                        %Otherwise...
    obj = get(hObject,'parent');                                            %Grab the parent handle for the object.
end
temp = get(obj,'children');                                                 %Grab handles for all children of the figure.
delete(temp);                                                               %Delete all children.
ax = axes('units','normalized',...
    'position',[0,0,1,1],...
    'visible','off',...
    'parent',obj);                                                          %Create axes on the figure.
cam = webcam(camstring);                                                    %Create a webcam object.
img = snapshot(cam);                                                        %Grab a snapshot from the camera.
img_size = size(img);                                                       %Grab the image size.
pos = get(obj,'position');                                                  %Grab the figure position.
pos(4) = pos(3)*(img_size(1)/img_size(2));                                  %Re-adjust the height of the figure.
set(obj,'position',pos);                                                    %Update the figure position.
im = image(img,'parent',ax);                                                %Show the image in the axes.
preview(cam,im);                                                            %Show a preview of the webcam in the image.
set(obj,'ResizeFcn',{@Webcam_Figure_Resize,img_size(1)/img_size(2)});       %Set the resize figure callback.
set(obj,'CloseRequestFcn',{@Webcam_Figure_Close,cam});                      %Set the close figure callback.


function Webcam_Figure_Resize(hObject,~,ratio)
pos = get(hObject,'position');                                              %Grab the figure position.
pos(4) = pos(3)*ratio;                                                      %Re-adjust the height of the figure.
set(hObject,'position',pos);                                                %Update the figure position.


function Webcam_Figure_Close(hObject,~,cam)
delete(cam);                                                                %Delete the camera object.
delete(hObject);                                                            %Delete the figure.


%% ***********************************************************************
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
                    ~isempty(fig.UserData.program.fcn.idle)                 %If a task-specific idle function is set...
                fig.UserData.program.fcn.idle(fig);                         %Call the idle loop.                
            else                                                            %Otherwise...
                Vulintus_Behavior_Idle(fig);                                %Call the common behavior idle loop.
            end
            
            
        case run_state.root.session                                         %Run state: behavior session.
            if isfield(fig.UserData.program,'session_fcn') && ...
                    ~isempty(fig.UserData.program.fcn.session)              %If a task-specific behavioral sesssion function is set...
                fig.UserData.program.fcn.session(fig);                      %Call the behavioral session loop.          
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


%% ***********************************************************************
function icon = Vulintus_Behavior_Match_Icon(icon, alpha_map, fig_handle)

%
%Vulintus_Behavior_Match_Icon.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_MATCH_ICON replaces transparent pixels in a uifigure
%   icon with the menubar color behind the icon.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created.
%

tb = uitoolbar(fig_handle);                                                 %Temporarily create a toolbar on the figure.
if ~isprop(tb,'BackgroundColor')                                            %If this version of MATLAB doesn't have the toolbar BackgroundColor property.
    return                                                                  %Skip the rest of the function.
end
back_color = tb.BackgroundColor;                                            %Grab the background color.
delete(tb);                                                                 %Delete the temporary toolbar.
alpha_map = double(1-alpha_map/255);                                        %Convert the alpha map to a 0-1 transparency.
for i = 1:size(icon,1)                                                      %Step through each row of the icon.
    for j = 1:size(icon,2)                                                  %Step through each column of the icon.
        if alpha_map(i,j) > 0                                               %If the pixel has any transparency...
            for k = 1:3                                                     %Step through the RGB elements.
                if alpha_map(i,j) == 1                                      %If the pixel is totally transparent...
                    icon(i,j,k) = uint8(255*back_color(k));                 %Set the pixel color to the background color directly.
                else                                                        %Otherwise...
                    icon(i,j,k) = icon(i,j,k) + ...
                        uint8(255*alpha_map(i,j)*back_color(k));        %   Add in the appropriate amount of background color.
                end
            end
        end
    end
end


%% ***********************************************************************
function Vulintus_Behavior_Open_Error_Reports(~,~,mainpath)

%
%Vibration_Task_Open_Error_Reports.m - Vulintus, Inc.
%
%   Vibration_Task_Open_Error_Reports is called whenever the user selects
%   "View Error Reports" from the vibration task GUI Preferences menu and
%   opens the local AppData folder containing all archived error reports.
%
%   UPDATE LOG:
%   11/29/2019 - Drew Sloan - Converted to a Vulintus behavior toolbox
%       function, adapted from Vibration_Task_Open_Error_Reports.m.
%

err_path = fullfile(mainpath, 'Error Reports');                             %Create the expected directory name for the error reports.
if ~exist(err_path,'dir')                                                   %If the error report directory doesn't exist...
    mkdir(err_path);                                                        %Create the error report directory.
end
system(['explorer ' err_path]);                                             %Open the error report directory in Windows Explorer.


%% ***********************************************************************
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


%% ***********************************************************************
function varargout = Vulintus_Behavior_Save_Error_Report(err_path, task_type, msg, varargin)

%
%Vulintus_Behavior_Save_Error_Report.m - Vulintus, Inc.
%
%   This function saves an error report ("msg") to a text file in the
%   specified directory ("err_path"), typically an \AppData\ folder, tagged
%   with the task type ("task_type").
%   
%   UPDATE LOG:
%   2021-10-06 - Drew Sloan - First function implementation, adapted from
%                             LED_Detection_Task_Save_Error_Report.m.
%

if nargin > 3 && isstruct(varargin{1})                                      %If the user passed a handles structure...
    handles = varargin{1};                                                  %Pull the handles structure out of the variable input arguments.
end

clc;                                                                        %Clear the command line.
fprintf(1,'Generating LED detection task error report...\n\n');             %Print a line to show an error report is being generated.
if isa(msg,'MException')                                                    %If the message to send is an error exception...
    txt = getReport(msg,'extended');                                        %Get an extended report about the error.
    a = strfind(txt,'<a');                                                  %Find all hyperlink starts in the text.
    for i = length(a):-1:1                                                  %Step backwards through all hyperlink commands.
        j = find(txt(a(i):end) == '>',1,'first') + a(i) - 1;                %Find the end of the hyperlink start.
        txt(a(i):j) = [];                                                   %Kick out all hyperlink calls.
    end
    a = strfind(txt,'a>') + 1;                                              %Find all hyperlink ends in the text.
    for i = length(a):-1:1                                                  %Step backwards through all hyperlink commands.
        j = find(txt(1:a(i)) == '<',1,'last');                              %Find the end of the hyperlink end.
        txt(j:a(i)) = [];                                                   %Kick out all hyperlink calls.
    end
else                                                                        %Otherwise, if the message to send isn't an error exception...
    if iscell(msg)                                                          %If the message text is a cell array of strings.
        txt = sprintf('%s\n',msg{:});                                       %Convert the cell array to a continuous string.
    elseif ischar(msg)                                                      %Otherwise, if the message text is already a string...
        txt = msg;                                                          %Send the message text as-is.
    else                                                                    %Otherwise, for all other messages...
        return                                                              %Skip execution of the rest of the function.
    end    
end

if ~exist(err_path,'dir')                                                   %If the error report directory doesn't exist...
    mkdir(err_path);                                                        %Create the error report directory.
end
[~,source] = system('hostname');                                            %Use the computer hostname as the source.
source(source < 33) = [];                                                   %Kick out any special characters.
task = lower(task_type);                                                    %Convert the task type to all lower-case.
task(task < 32) = [];                                                       %Kick out any special characters.
task(task == ' ') = '_';                                                    %Replace all spaces with underscores.
filename = sprintf('%s_error_report_%s.txt',task, datestr(now,30));         %Create a filename for the error report.
filename = fullfile(err_path, filename);                                    %Add the error path to the filename.
fid = fopen(filename,'wt');                                                 %Open the file for writing as text.
task = upper(task_type);                                                    %Convert the task type to all upper-case.
task(task < 32) = [];                                                       %Kick out any special characters.
fprintf(fid,'%s ERROR REPORT\n',task);                                      %Print a title for the error report.
fprintf(fid,'SOURCE: %s\n',source);                                         %Print the error source.
fprintf(fid,'TIMESTAMP: %s\n',datestr(now,21));                             %Print a timestamp.
fprintf(fid,'%s\n',txt);                                                    %Print the error stack to the file.
fprintf(1,'%s\n',txt);                                                      %Print the error stack to the command line as well.
fprintf(fid,'\n');                                                          %Print a carraige return to the file.

if exist('handles','var')                                                   %If a handles structure was passed to the function.
    fields = fieldnames(handles);                                           %Grab all of the field names from the handles structure.
    for i = 1:length(fields)                                                %Step through each field.
        fprintf(fid,'handles.%s = ',fields{i});                             %Print the field name.
        switch class(handles.(fields{i}))                                   %Switch between the possible field classes.
            case 'cell'                                                     %If the field is a cell array.
                fprintf(fid,'{');                                           %Print a left bracket.
                for k = 1:size(handles.(fields{i}),2)                       %Step through each column of the cell array.
                    for j = 1:size(handles.(fields{i}),1)                   %Step through each row of the cell array.                
                        switch class(handles.(fields{i}){j,k})              %Switch between the possible cell classes.
                            case 'char'                                     %If the cell is a character array...
                                fprintf(fid,'''%s''',...
                                    handles.(fields{i}){j,k});              %Print the characters to the text file.
                            case {'single','double'}                        %If the cell is numeric...
                                fprintf(fid,'%1.4f',...
                                    handles.(fields{i}){j,k});              %Print the values to the text file.
                            otherwise                                       %For all other classes...
                                fprintf(fid,'%s\n',...
                                    class(handles.(fields{i}){j,k}));       %Print the cell class.
                        end
                        if j ~= size(handles.(fields{i}),2)                 %If this isn't the last entry in the row...
                            fprintf(fid,' ');                               %Print a space to the text file.
                        end
                    end
                    if k == size(handles.(fields{i}),2)                     %If this was the last row in the array...
                        fprintf(fid,'}\n');                                 %Print a left bracket and a carriage return.
                    else                                                    %Otherwise...
                        fprintf(fid,'\n\t');                                %Print a carrage return and a tab.
                    end
                end            
            case 'char'                                                     %If the field is a character array.
                fprintf(fid,'''%s''\n',handles.(fields{i}));                %Print the characters to the text file.
            case {'single','double'}                                        %Otherwise, if the field is numeric...
                fprintf(fid,'[');                                           %Print a left bracket.
                for k = 1:size(handles.(fields{i}),2)                       %Step through each column of the cell array.
                    for j = 1:size(handles.(fields{i}),1)                   %Step through each row of the cell array.                
                        fprintf(fid,'%1.4f',handles.(fields{i})(j,k));      %Print the values to the text file.
                        if j ~= size(handles.(fields{i}),2)                 %If this isn't the last entry in the row...
                            fprintf(fid,' ');                               %Print a space to the text file.
                        end
                    end
                    if k == size(handles.(fields{i}),2)                     %If this was the last row in the array...
                        fprintf(fid,']\n');                                 %Print a left bracket and a carriage return.
                    else                                                    %Otherwise...
                        fprintf(fid,'\n\t');                                %Print a carrage return and a tab.
                    end
                end            
            otherwise                                                       %For all other data types...
                fprintf(fid,'%s\n',class(handles.(fields{i})));             %Print the field class.
        end
    end
end

fclose(fid);                                                                %Close the error report file.
if nargout > 0                                                              %If the user requested the text of the error report file...
    fid = fopen(filename,'rt');                                             %Open the error report file for reading as text.
    varargout{1} = fread(fid,'*char')';                                      %Read in the data as characters.
    fclose(fid);                                                            %Close the error report file again.
end


%% ***********************************************************************
function choice = Vulintus_Behavior_Selection_GUI(options, varargin)

%
%Vulintus_Behavior_Selection_GUI.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SELECTION_GUI creates a GUI selection box with the 
%   choices specified in the cell array (options), and returns the index of
%   the selected choice.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created, adapted from
%                             SensiTrak_Launcher.m.
%

fig_title = [];                                                             %Don't put a title on the figure by default.
icon = 'vulintus';                                                          %Set the default figure icon to the Vulintus icon.
available_icons = {'habitrak','mototrak','omnihome','omnitrak',...
    'sensitrak','vulintus'};                                                %List the available Vulintus icons.
for i = 1:length(varargin)                                                  %Step through the optional input arguments...
    if any(strcmpi(varargin{i},available_icons))                            %If an icon was specified...
        icon = lower(varargin{i});                                          %Set the figure icon.
    else                                                                    %Otherwise...
        fig_title = varargin{i};                                            %Assume the input is the figure title.
    end
end


%Set the scaling parameters according to the screen size and number of options.
n_choices = length(options);                                                %Grab the number of specified choices.
set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
screen_size = get(0,'ScreenSize');                                          %Grab the screensize.
ui_h = 0.8*screen_size(4)/length(options);                                  %Calculate a button height.
ui_h = min(ui_h, 2.0);                                                      %Enforce a maximum button height.
fontsize = 10*ui_h;                                                         %Set the fontsize to 10x the button height.
max_char = 0;                                                               %Create a variable to hold the maximum number of characters.
for i = 1:n_choices                                                         %Step through each option.
    max_char = max(max_char, length(options{i}));                           %Check for a new maximum character length;
end
ui_w = 0.15*max_char*ui_h;                                                  %Scale the button width to the maximum character length.
ui_w = max(ui_w, 3.0);                                                      %Enforce a minimum button width.
sp = 0.25;                                                                  %Set the spacing between buttons.
fig_w = ui_w + 2*sp;                                                        %Set the figure width.
fig_h = n_choices*(ui_h + sp) + sp;                                         %Set the figure height.

%Create the selection GUI.
fig_pos = [ screen_size(3)/2-fig_w/2,...
            screen_size(4)/2-fig_h/2,...
            fig_w,...
            fig_h];                                                         %Center the figure in the screen.
fig = uifigure('units','centimeters',...
    'Position',fig_pos,...
    'resize','off',...
    'MenuBar','none',...
    'name',fig_title,...
    'numbertitle','off');                                                   %Set the properties of the figure.
switch icon                                                                 %Switch between the recognized icons.
    case 'habitrak'                                                         %HabiTrak.
        [icon_img, alpha_map] = Vulintus_Load_HabiTrak_V1_Icon_48px;        %Use the HabiTrak icon.
    case 'mototrak'                                                         %MotoTrak.
        [icon_img, alpha_map] = Vulintus_Load_MotoTrak_V2_Icon_48px;        %Use the MotoTrak V2 icon.
    case 'omnihome'                                                         %OmniHome.
        [icon_img, alpha_map] = Vulintus_Load_OmniHome_V1_Icon_48px;        %Use the OmniHome icon.
    case 'omnitrak'                                                         %OmniTrak.
        [icon_img, alpha_map] = Vulintus_Load_OmniTrak_V1_Icon_48px;        %Use the OmniTrak icon.    
    case 'sensitrak'                                                        %SensiTrak.
        [icon_img, alpha_map] = Vulintus_Load_SensiTrak_V1_Icon_48px;       %Use the SensiTrak icon.
    otherwise                                                               %For all other options.
        [icon_img, alpha_map] = ...
            Vulintus_Load_Vulintus_Logo_Circle_Social_48px;                 %Use the Vulintus Social Logo.
end
icon_img = Vulintus_Behavior_Match_Icon(icon_img, alpha_map, fig);          %Match the icon board to the figure.
fig.Icon = icon_img;                                                        %Set the figure icon.
fig.Units = 'pixels';                                                       %Change the figure units to pixels.
fig_pos = fig.Position;                                                     %Grab the figure position, in pixels.
scale = fig_pos(3)/fig_w;                                                   %Calculate the centimeters to pixels conversion factor.
fig.UserData = 0;                                                           %Assume no selection will be made.
for i = 1:length(options)                                                   %Step through each specified option.
    y = (length(options) - i)*(ui_h+sp) + sp;                               %Set the bottom edge.
    btn = uibutton(fig);                                                    %Create a button on the figure.
    btn.Position = scale*[sp y ui_w ui_h];                                  %Set the button position.
    btn.Text = options{i};                                                  %Set the button text.
    btn.FontName = 'Arial';                                                 %Set the font.
    btn.FontSize = fontsize;                                                %Set the fontsize.
    btn.FontWeight = 'bold';                                                %Set the fontweight.
    btn.ButtonPushedFcn = ...
        {@Vulintus_Behavior_Selection_GUI_Btn_Press,fig,i};                 %Set the button push callback.
end
drawnow;                                                                    %Immediately update the figure.
uiwait(fig);                                                                %Wait for the user to push a button on the pop-up figure.
if ishandle(fig)                                                            %If the user didn't close the figure without choosing an option...
    choice = fig.UserData;                                                  %Grab the selected option index.
    close(fig);                                                             %Close the figure.   
else                                                                        %Otherwise, if the user closed the figure without choosing an option...
   choice = 0;                                                              %Return a zero.
end
          

function Vulintus_Behavior_Selection_GUI_Btn_Press(~,~,fig,i)
fig.UserData = i;                                                           %Set the figure UserData property to the specified value.
uiresume(fig);                                                              %Resume execution.


%% ***********************************************************************
function Vulintus_Behavior_Send_Error_Report(target,task_type,msg)

%
%Vulintus_Behavior_Send_Error_Report.m - Vulintus, Inc.
%
%   This function sends an error report ("msg") by email to the specified 
%   recipient ("target") through the Vulintus dummy error-reporting 
%   account.
%   
%   UPDATE LOG:
%   10/06/2021 - Drew Sloan - First function implementation, adapted from
%       LED_Detection_Task_Send_Error_Report.m.
%

if isa(msg,'MException')                                                    %If the message to send is an error exception...
    txt = getReport(msg,'extended');                                        %Get an extended report about the error.
    a = strfind(txt,'<a');                                                  %Find all hyperlink starts in the text.
    for i = length(a):-1:1                                                  %Step backwards through all hyperlink commands.
        j = find(txt(a(i):end) == '>',1,'first') + a(i) - 1;                %Find the end of the hyperlink start.
        txt(a(i):j) = [];                                                   %Kick out all hyperlink calls.
    end
    a = strfind(txt,'a>') + 1;                                              %Find all hyperlink ends in the text.
    for i = length(a):-1:1                                                  %Step backwards through all hyperlink commands.
        j = find(txt(1:a(i)) == '<',1,'last');                              %Find the end of the hyperlink end.
        txt(j:a(i)) = [];                                                   %Kick out all hyperlink calls.
    end
else                                                                        %Otherwise, if the message to send isn't an error exception...
    if iscell(msg)                                                          %If the message text is a cell array of strings.
        txt = sprintf('%s\n',msg{:});                                       %Convert the cell array to a continuous string.
    elseif ischar(msg)                                                      %Otherwise, if the message text is already a string...
        txt = msg;                                                          %Send the message text as-is.
    else                                                                    %Otherwise, for all other messages...
        return                                                              %Skip execution of the rest of the function.
    end    
end
[~,source] = system('hostname');                                            %Use the computer hostname as the source.
subject = sprintf('%s Error Report From: %s',task_type,source);             %Create a subject line.
subject(subject < 32) = [];                                                 %Kick out all special characters from the subject line.
if isdeployed                                                               %If this is deployed code...
    [~, result] = system('path');                                           %Grab the current environmental path variable.
    path = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));          %Find the directory pertaining to the current compiled program.
    program = [path '\subfuns\vulintus_send_error_report.exe'];             %Add the full path to the error-reporting program name.    
    cmd = sprintf('"%s" "%s" "%s" "%s"',program,target,subject,txt);        %Create a command-line call for the error-reporting program.
    task = lower(task_type);                                                %Conver the task type to lower case.
    fprintf(1,'Reporting %s error to %s\n',task,target);                    %Show that the error reporting program is being run on the command line.
    [~, cmdout] = system(cmd);                                              %Call the error reporting program.
    fprintf(1,'\t%s\n',cmdout);                                             %Return any reply to the command line.
else                                                                        %Otherwise, if the code isn't deployed...
    Vulintus_Send_Error_Report(target,subject,txt);                         %Use the common subfunction to send the error report.
end


%% ***********************************************************************
function Vulintus_Behavior_Set_Datapath(hObject,~)

%
%Vulintus_Behavior_Set_Datapath.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SET_DATAPATH is a Vulintus behavioral task toolbox
%   function that allows the user to update the default path for session 
%   records and updates the configuration file to
%   reflect the new path.
%   
%   UPDATE LOG:
%   11/29/2021 - Drew Sloan - Function first created, copied from
%       LED_Detection_Task_Set_Datapath.m.
%

handles = guidata(hObject);                                                 %Load the handles structure from the GUI.

fprintf(1,'Need to finish coding: %s\n',mfilename); 


%% ***********************************************************************
function Vulintus_Behavior_Set_Error_Reporting(hObject,~)

%
%Vulintus_Behavior_Set_Error_Reporting.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SET_ERROR_REPORTING is a Vulintus behavior program
%   toolbox function that is called whenever the user selects "On" or "Off"
%   for the Automatic Error Reporting feature under the GUI Preferences 
%   menu. Use of this function requires program parameters to be tied to
%   the calling figure with the "guidata" function, and requires that the
%   figure contain uimenu controls with the following names:
%
%       handles.menu.pref.err_report_on
%       handles.menu.pref.err_report_off
%   
%   UPDATE LOG:
%   11/29/2019 - Drew Sloan - First function implementation, adapted from
%       Vibrotactile_Detection_Task_Set_Error_Reporting.m.
%

handles = guidata(gcbf);                                                    %Grab the handles structure from the main figure.
str = get(hObject,'label');                                                 %Grab the string property from the selected menu option.
if strcmpi(str,'on')                                                        %If the user selected to turn error reporting on...
    handles.enable_error_reporting = 1;                                     %Enable error-reporting.
    set(handles.menu.pref.err_report_on,'checked','on');                    %Check the "On" option.
    set(handles.menu.pref.err_report_off,'checked','off');                  %Uncheck the "Off" option.
else                                                                        %Otherwise, if the user selected to turn error reporting off...
    handles.enable_error_reporting = 0;                                     %Disable error-reporting.
    set(handles.menu.pref.err_report_on,'checked','off');                   %Uncheck the "On" option.
    set(handles.menu.pref.err_report_off,'checked','on');                   %Check the "Off" option.
end
guidata(gcbf,handles);                                                      %Pin the handles structure back to the main figure.


%% ***********************************************************************
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


%% ***********************************************************************
function Vulintus_Behavior_Stage_Load(handles,varargin)

%
%Vulintus_Behavior_Stage_Load.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_STAGE_LOAD loads the training/testing parameters from
%   a selected behavior stage and updates the GUI to display those
%   parameters.
%   
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created, adapted from
%                             ST_Tactile_2AFC_Load_Stage.m
%

if nargin > 1                                                               %If the user specified a GUI instance.
    instances = varargin{1};                                                %Grab the specified instances.
else                                                                        %Otherwise...
    instances = 1:length(handles.ui);                                       %Load the stage for all instances.
end

for gui_i = instances                                                       %Step through all specified GUI instances.

    %Show the current stage in the message box.
    if isfield(handles,'ui') && isfield(handles.ui(gui_i),'msgbox')         %If there's a messagebox in the GUI.
        str = sprintf('%s - The current stage is "%s".',...
            char(datetime,'hh:mm:ss'),...
            handles.stages(handles.cur_stage(gui_i)).list_str);             %Create a message string.
        Add_Msg(handles.ui(gui_i).msgbox,str);                              %Show the message in the messagebox.
    end
    
    if isfield(handles,'ui') && isfield(handles.ui(gui_i),'drop_stage')     %If there's a stage drop-down menu in the GUI.
        handles.ui(gui_i).drop_stage.Items = {handles.stages.list_str};     %Update the stages list in the drop-down menu.
        handles.ui(gui_i).drop_stage.Value = ...
            handles.stages(handles.cur_stage(gui_i)).list_str;              %Set the stage dropdown menu value to the current stage.
    end
    
    if is_fcn_field(handles.program,'fcn','load_stage')                            %If a stage loading function is specified for this behavior...
        handles.program.fcn.load_stage(handles, gui_i);                     %Run the stages through the check function.
    end

end


%% ***********************************************************************
function stages = Vulintus_Behavior_Stages_Read(stage_path, varargin)

%
%Vulintus_Behavior_Read_Stages.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_READ_STAGES loads stage information from the stages
%   subfolder in the configuration folder. If a Google spreadsheet link is
%   passed, it will download that stage information and update all stage
%   files listed in spreadsheet.
%   
%   UPDATE LOG:
%   2024-02-29 - Drew Sloan - Function first created, adapted from
%                             Stop_Task_Read_Stages.m
%

if nargin > 1                                                               %If stage synchronization information was passed.
    stages_sync = varargin{1};                                              %A stage synchronization structure should be the first input.
else                                                                        %Otherwise...
    stages_sync = struct;                                                   %Create a stage synchronization structure.
end
     
if ~exist(stage_path,'dir')                                                 %If the stage path doesn't exist yet...
    mkdir(stage_path);                                                      %Create it.
end

if isfield(stages_sync,'google_spreadsheet_url')                            %If a Google spreadsheet URL was defined...
    try                                                                     %Try to read in the stage information from the web.
        data = Read_Google_Spreadsheet(stages_sync.google_spreadsheet_url); %Read in the stage information from the Google Docs URL.
        field_row = 0;                                                      %Assume no field row is found.
        for i = 2:size(data,1)                                              %Step through each row of the data.
            if ischar(data{i,1}) && data{i,1}(1) == '.'                     %If the cell entry is preceded by a period...
                field_row = i;                                              %Use this row as the field name row.
                break                                                       %Skip the remaining rows.
            end
        end
        if field_row ~= 0                                                   %If a field name row was found...
            stage_fields = data(field_row,:);                               %Grab all of the field names.
            for i = 1:length(stage_fields)                                  %Step through the stage fields.
                stage_fields{i} = lower(stage_fields{i});                   %Make the field all lower-case.
                stage_fields{i}(stage_fields{i} == '_') = ' ';              %Replace all underscores with spaces.
                bad_chars = (stage_fields{i} < 32) | ...
                            (stage_fields{i} > 32 & stage_fields{i} < 48) | ...
                            (stage_fields{i} > 57 & stage_fields{i} < 97) | ...
                            (stage_fields{i} > 122);                        %Find all non-field-friendly characters.
                stage_fields{i}(bad_chars) = [];                            %Kick out all non-field-friendly characters.
                stage_fields{i} = strtrim(stage_fields{i});                 %Trim off any leading or trailing spaces.
                stage_fields{i}(stage_fields{i} == ' ') = '_';              %Replace all spaces with underscores.
            end
            if any(strcmpi(stage_fields,'name'))                            %If there's a "name" column...
                for i = (field_row+1):size(data,1)                          %Step through each row of the data.
                    temp = struct;                                          %Reset a structure to hold the stage info.
                    for j = 1:length(stage_fields)                          %Step through each column.
                        if ~isempty(stage_fields{j})                        %If there's a field name for this column...
                            if ~isempty(data{i,j})                          %If there's data in this cell...
                                temp.(stage_fields{j}) = strtrim(data{i,j});%Copy the cell value into the temporary structure.
                            end
                        end
                    end
                    if isfield(temp,'name') && ~isempty(temp.name)          %If a name was set for this stage...
                        filename = [upper(temp.name) '.STAGE'];             %Create the filename.
                        filename(filename == ' ') = '_';                    %Replace all spaces with underscores.
                        filename = fullfile(stage_path,filename);           %Add the stage path to the filename.
                        Vulintus_JSON_File_Write(temp, filename);           %Write the configuration to a JSON file.
                    end
                end
            else                                                            %Otherwise, if no "name" colume was found.
                warning(['%s -> No "name" column was found in the '...
                    'specified stages spreadsheet:\n\t%s'],...
                upper(mfilename),stages_sync.google_spreadsheet_url);       %Show a warning.
            end
        else                                                                %Otherwise, if no field name row was found.
            warning(['%s -> No field names row was found in the '...
                'specified stages spreadsheet:\n\t%s'],...
                upper(mfilename),stages_sync.google_spreadsheet_url);       %Show a warning.
        end
    catch err                                                               %If there's an error...
        warning(['%s -> Could not read the specified stages '...
            'spreadsheet.\n\t%s:%s'], upper(mfilename), err.identifier,...
            err.message);                                                   %Show a warning.
    end
end

stages = struct;                                                            %Create a stages structure.
stage_files = dir(fullfile(stage_path,'*.STAGE'));                          %Find all stage files in the stage folder.
for i = 1:length(stage_files)                                               %Step through each stage file.
    stages(i).filename = fullfile(stage_path, stage_files(i).name);         %Add the path to the filename.
    temp = Vulintus_JSON_File_Read(stages(i).filename);                     %Read in the stage file.
    temp_fields = fieldnames(temp);                                         %Grab all of the fieldnames from the temporary structure.
    for f = 1:length(temp_fields)                                           %Step through each field.
        stages(i).(temp_fields{f}) = temp.(temp_fields{f});                 %Copy each field to the stages structure.
    end
end

for i = 1:length(stages)                                                    %Step through the stages.
    if all(isfield(stages,{'name','description'}))                           %If the stage structure has both number and description fields.
        stages(i).list_str = [stages(i).name ': ' stages(i).description];   %Create a list selection string with the stage name and descriptions.
    else                                                                    %Otherwise...
        stages(i).list_str = stages(i).name;                                %Create a list selection string with just the stage name.
    end
end


%% ***********************************************************************
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
%                             Stop_Task_Startup.m
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
% set(handles.mainfig,'resize','on','ResizeFcn',@Stop_Task_Resize);         %Set the resize function for the vibration task main figure.
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
    if isfield(handles.program,'fcn.default_config') && ...
            ~isempty(handles.program.fcn.default_config)                    %If there's a default configuration function for this task...
        handles = handles.program.fcn.default_config(handles);              %Load the default configuration values.    
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
    handles.stages = handles.program.fcn.stage_check(handles.stages);       %Run the stages through the check function.
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


%% ***********************************************************************
function Vulintus_Behavior_Subject_Add(main_fig)      

%
%Vulintus_Behavior_Subject_Add.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SUBJECT_ADD creates a figure with an editbox for
%   users to enter a new subject name, which is then added to the central 
%   and task-specific subject lists.
%   
%   UPDATE LOG:
%   2024-05-15 - Drew Sloan - Function first created.
%


dpc = get(0,'ScreenPixelsPerInch')/2.54;                                    %Grab the dots-per-centimeter of the screen.
set(0,'units','pixels');                                                    %Set the screensize units to pixels.
scrn = get(0,'ScreenSize');                                                 %Grab the screensize.
ui_h = 1.2*dpc;                                                             %Set the height for all labels, editboxes, and buttons, in pixels.
ui_w = 10.0*dpc;                                                            %Set the width for all labels, editboxes, and buttons, in pixels.
ui_sp = 0.1*dpc;                                                            %Set the spacing between UI components.
fig_h = 5*ui_sp + 2*ui_h;                                                   %Set the figure height, in pixels.
fig_w = 2*ui_sp + ui_w;                                                     %Set the figure width, in pixels.
ui_fontsize = 18;                                                           %Set the fontsize for all uicontrols.

fig = uifigure;                                                             %Create a UI figure.
fig.Units = 'pixels';                                                       %Set the units to pixels.
fig.Position = [scrn(3)/2-fig_w/2, scrn(4)/2-fig_h/2,fig_w,fig_h];          %St the figure position
fig.Resize = 'off';                                                         %Turn off figure resizing.
fig.Name = 'Add a New Subject Name';                                        %Set the figure name.
[img, alpha_map] = Vulintus_Load_Vulintus_Logo_Circle_Social_48px;          %Use the Vulintus Social Logo for an icon.
img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);                    %Match the icon board to the figure.
fig.Icon = img;                                                             %Set the figure icon.

%"Add Subject" button.
pos = [ui_sp, ui_sp, ui_w, ui_h];                                           %Set the button position.
add_btn = uibutton(fig);                                                    %Put a new UI button on the figure.
add_btn.Text = 'Add Subject';                                               %Set the button text.
add_btn.Position = pos;                                                     %Set the button position.
add_btn.FontName = 'Arial';                                                 %Set the font name.
add_btn.FontWeight = 'bold';                                                %Set the fontweight to bold.
add_btn.FontSize = ui_fontsize;                                             %Set the fontsize.
add_btn.Enable = 'off';                                                     %Disable the button for now.

%Subject editbox.
pos(1) = pos(1) + ui_sp;                                                    %Indent the editbox slightly.
pos(2) = pos(2) + 2*ui_sp + ui_h;                                           %Set the bottom edge of the editbox.
pos(3) = pos(3) - 2*ui_sp;                                                  %Make the editbox slightly less wide than the button.
subject_edit = uieditfield(fig);                                            %Put a new UI editbox on the figure.
subject_edit.Position = pos;                                                %Set the editbox position.
subject_edit.FontName = 'Arial';                                            %Set the font name.
subject_edit.FontWeight = 'bold';                                           %Set the fontweight to bold.
subject_edit.FontSize = ui_fontsize;                                        %Set the fontsize.

%Set the callbacks.
fig.CloseRequestFcn = ...
    {@Vulintus_Behavior_Subject_Add_Close,main_fig,subject_edit,1};         %Set the figure close request function.
add_btn.ButtonPushedFcn = ...
    {@Vulintus_Behavior_Subject_Add_Close,main_fig,subject_edit,0};         %Set the button push callback.
subject_edit.ValueChangingFcn = {@Vulintus_Behavior_Subject_Add_Enable,...
    add_btn};                                                               %Set the editbox value changing function.
subject_edit.ValueChangedFcn = {@Vulintus_Behavior_Subject_Add_Format,...
    add_btn};                                                               %Set the editbox value change callback.


function Vulintus_Behavior_Subject_Add_Close(hObject,~,fig,edit_h,cancel_add)
if ~cancel_add                                                              %If the figure was closed by pressing "Add Subject"...
    subject_name = edit_h.Value;                                            %Grab the subject name.
    all_subjects = {fig.UserData.subject_list{1:end-2}, subject_name};      %Add the new subject name to the list of subjects.
    keepers = ones(size(all_subjects));                                     %Create a matrix to mark subject names for exclusions.
    for i = 2:length(all_subjects)                                          %Step through all of the subjects.
        if any(strcmpi(all_subjects{i},all_subjects(1:i-1)))                %If the name matches any previous names, ignoring case...
            keepers(i) = 0;                                                 %Mark the name for exclusion.
        end
    end
    all_subjects(keepers == 0) = [];                                        %Kick out all duplicates.
    all_subjects = sort(all_subjects);                                      %Sort the subjects alphabetically.
    config_path = Vulintus_Set_AppData_Path('Common Configuration');        %Grab the directory for common Vulintus task application data.
    appdata_subject_list_file = fullfile(config_path,'Subject_List.json');  %Create the expected subject list filename in the appdata path.
    appdata_placeholder = ...
        fullfile(config_path,'subject_list_placeholder.temp');              %Set the filename for the temporary placeholder file.
    Vulintus_Placeholder_Check(appdata_placeholder, 1.0);                   %Wait for any ongoing operation to finish.
    Vulintus_Placeholder_Set(appdata_placeholder);                          %Create a new placeholder in the AppData path.   
    if exist(appdata_subject_list_file,'file')                              %If a subject lists exists in the appdata path...
        appdata_subjects = ...
            Vulintus_JSON_File_Read(appdata_subject_list_file);             %Load the subject list from the appdata path.
        i = strcmpi({appdata_subjects.name},subject_name);                  %Check for matches to the subject name.
        if ~any(i)                                                          %If no matches were found...
            i = length(appdata_subjects) + 1;                               %Increment the subject index.
        end
        appdata_subjects(i).name = subject_name;                            %Add the subject name.
        if isfield(appdata_subjects,'tasks') && ...
                ~isempty(appdata_subjects(i).tasks)                         %If this subject is already doing tasks.
            if iscell(appdata_subjects(i).tasks)                            %If the field is a cell array.
                appdata_subjects(i).tasks{end+1} = fig.UserData.task;       %Add the task to the cell array.
            else
                appdata_subjects(i).tasks = ...
                    {appdata_subjects(i).tasks, fig.UserData.task};         %Convert the task list to a cell array.
            end
            appdata_subjects(i).tasks = unique(appdata_subjects(i).tasks);  %Kick out any non-unique duplicates.
        else
            appdata_subjects(i).tasks = fig.UserData.task;                  %Add the task name.
        end        
        appdata_subjects(i).status = 'active';                              %Add the current status.
    else                                                                    %Otherwise...
        appdata_subjects = struct('name',subject_name,...
            'tasks',fig.UserData.task,...
            'status','active');                                             %Create a new subjects structure.
    end
    Vulintus_JSON_File_Write(appdata_subjects,appdata_subject_list_file);   %Update the AppData subjects list.
    if exist(appdata_placeholder,'file')                                    %If an AppData placeholder file exists...
        delete(appdata_placeholder);                                        %Delete the AppData placeholder file.
    end
    fig.UserData.subject_list = ...
        [all_subjects, fig.UserData.subject_list(end-1:end)];               %Add the new subject name to the list.
    fig.UserData.ui.drop_subject.Items = fig.UserData.subject_list;         %Update the selections in the subject dropdown.
    fig.UserData.ui.drop_subject.Value = subject_name;                      %Set the value of the subject dropdown to the new subject name.
    fig.UserData.run = fig.UserData.run_state.idle_select_subject;          %Set the run variable to the select subject value.
end
if ~strcmpi(hObject.Type,'figure')                                          %If the passing object isn't a figure...
    hObject = hObject.Parent;                                               %Grab the parent handle.
end
delete(hObject);                                                            %Close the figure.   


function Vulintus_Behavior_Subject_Add_Enable(hObject,~,btn_h)
if ~isempty(hObject.Value)                                                  %If the value isn't empty...
    btn_h.Enable = 'on';                                                    %Enabled the "Add Subject" button.
else                                                                        %Otherwise...
    btn_h.Enable = 'off';                                                   %Disable the "Add Subject" button.
end


function Vulintus_Behavior_Subject_Add_Format(hObject,~,btn_h)
subject_edit = hObject;                                                     %Grab the editbox handle.
temp = subject_edit.Value;                                                  %Grab the entered name.
temp = strtrim(temp);                                                       %Trim off any leading or trailing spaces.
temp(temp == ' ') = '_';                                                    %Replace any spaces with underscores.
subject_edit.Value = temp;                                                  %Update the name in the editbox.
if ~isempty(subject_edit.Value)                                             %If the value isn't empty...
    btn_h.Enable = 'on';                                                    %Enabled the "Add Subject" button.
else                                                                        %Otherwise...
    btn_h.Enable = 'off';                                                   %Disable the "Add Subject" button.
end


%% ***********************************************************************
function subjects = Vulintus_Behavior_Subject_List(task_name, datapath)

%Vulintus_Behavior_Subject_List.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SUBJECT_LIST reads in the central behavioral subject
%   list stored as a JSON-formatted file in the Vulintus Common 
%   Configuration AppData folder.
%
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created, branched from
%                             Vulintus_Load_Previous_Subjects.m.
%

config_path = Vulintus_Set_AppData_Path('Common Configuration');            %Grab the directory for common Vulintus task application data.

shortfile = [task_name '_Subject_List.json'];                               %Create the short filename.
shortfile(shortfile == ' ') = '_';                                          %Replace any spaces in the filename with underscores.

task_subject_list_file = fullfile(datapath,shortfile);                      %Create the expected subject list filename in the data path.
task_placeholder = fullfile(datapath,'subject_list_placeholder.temp');      %Set the filename for the temporary placeholder file.
Vulintus_Placeholder_Check(task_placeholder, 1.0);                          %Wait for any ongoing operation to finish.

appdata_subject_list_file = fullfile(config_path,'Subject_List.json');      %Create the expected subject list filename in the appdata path.
appdata_placeholder = ...
    fullfile(config_path,'subject_list_placeholder.temp');                  %Set the filename for the temporary placeholder file.
Vulintus_Placeholder_Check(appdata_placeholder, 1.0);                       %Wait for any ongoing operation to finish.
Vulintus_Placeholder_Set(appdata_placeholder);                              %Create a new placeholder in the AppData path.

if exist(task_subject_list_file,'file')                                     %If a subject lists exists in the task data path...    
    task_subjects = Vulintus_JSON_File_Read(task_subject_list_file);        %Load the subject list from the task data path.
else                                                                        %Otherwise...
    task_subjects = struct;                                                 %Create a structure to hold subject data from the data path.
end

if exist(appdata_subject_list_file,'file')                                  %If a subject lists exists in the appdata path...
    appdata_subjects = Vulintus_JSON_File_Read(appdata_subject_list_file);  %Load the subject list from the appdata path.
else                                                                        %Otherwise...
    appdata_subjects = struct;                                              %Create an empty structure.
end

if ~isempty(task_subjects) && isfield(task_subjects,'name')                 %If there are subjects in the task subject list.
    if isempty(appdata_subjects) || ~isfield(appdata_subjects,'name')       %If there's no subjects in the appdata subject list..
        appdata_subjects = task_subjects;                                   %Copy the tasks subject to the appdata subject list.
    else                                                                    %Otherwise, if both lists have subjects.
        for i = 1:length(task_subjects)                                     %Step through each subject in the task subject list.            
            s = strcmpi({appdata_subjects.name},task_subjects(i).name);     %Check if this subject is already in the appdata subject list.
            if any(s)                                                       %If a match was found...
                copy_fields = fieldnames(task_subjects(i));                 %Grab the field names in the task subject list.
                for f = 1:length(copy_fields)                               %Step through the field names.
                    appdata_subjects(s).(copy_fields{f}) = ...
                        task_subjects(i).(copy_fields{f});                  %Copy each field over, overwriting any existing value.
                end
            else                                                            %Otherwise...
                appdata_subjects(end+1) = task_subjects(i);                 %#ok<AGROW> %Copy the subject over entirely...
            end
        end
    end
end

if ~isempty(appdata_subjects) && isfield(appdata_subjects,'name')           %If there's any subjects to record...
    Vulintus_JSON_File_Write(appdata_subjects,appdata_subject_list_file);   %Update the AppData subjects list.
end

subjects = appdata_subjects;                                                %Return the subjects from the AppData subjects list.

if exist(appdata_placeholder,'file')                                        %If an AppData placeholder file exists...
    delete(appdata_placeholder);                                            %Delete the AppData placeholder file.
end
if exist(task_placeholder,'file')                                           %If a task subject list placeholder file exists...
    delete(task_placeholder);                                               %Delete the task subject list placeholder file.
end


%% ***********************************************************************
function handles = Vulintus_Behavior_Subject_Load(handles,varargin)

%
%Vulintus_Behavior_Load_Subject.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_LOAD_SUBJECT loads the training/testing parameters from
%   a selected behavior stage and updates the GUI to display those
%   parameters.
%   
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created.
%

if nargin > 1                                                               %If the user specified a GUI instance.
    instances = varargin{1};                                                %Grab the specified instances.
else                                                                        %Otherwise...
    instances = 1:length(handles.ui);                                       %Load the stage for all instances.
end

if ~isfield(handles,'subject_list')                                         %If there's no subject list yet...
    if isfield(handles,'subjects') && ...   
            isfield(handles.subjects,'name') && ...
            ~isempty(handles.subjects(1).name)                              %If there's any subjects in the list...
        handles.subject_list = ...
            {handles.subjects.name,'<New Subject>','[Bench Test]'};         %List the subjects along with a "new subject" and "bench test" option.           
    else                                                                    %Otherwise...
        handles.subject_list = {'<New Subject>','[Bench Test]'};            %List only the "new subject" and "bench test" option.         
    end
end

for gui_i = instances                                                       %Step through all specified GUI instances.
    
    if ~isfield(handles,'cur_subject') || isempty(handles.cur_subject)     %If the current subject isn't set yet...
        handles.cur_subject = cell(1,length(handles.ui));                   %Create a cell array to hold the subject.
        
    end

    if isempty(handles.cur_subject{gui_i})                                  %If no subject is chosen for this instance...
        if length(handles.subject_list) == 2                                %If there's only two subjects in the list...
            handles.cur_subject{gui_i} = handles.subject_list{end};         %Set the current subject to the last in the list ("[Bench Test]").
        else                                                                %Otherwise...
            handles.cur_subject{gui_i} = handles.subject_list{1};           %Set the current subject to the first in the list.
        end
    end
    
    if isfield(handles,'ui') && isfield(handles.ui(gui_i),'msgbox')         %If there's a messagebox in the GUI.
        str = sprintf('%s - The current subject is "%s".',...
            char(datetime,'hh:mm:ss'),handles.cur_subject{gui_i});          %Create a message string.
        Add_Msg(handles.ui(gui_i).msgbox,str);                              %Show the message in the messagebox.
    end
    
    if isfield(handles,'ui') && isfield(handles.ui(gui_i),'drop_subject')   %If there's a subject drop-down menu in the GUI.
        handles.ui(gui_i).drop_subject.Items = handles.subject_list;        %Update the subjects list in the drop-down menu.
        handles.ui(gui_i).drop_subject.Value = handles.cur_subject{gui_i};  %Set the subjects dropdown menu value to the current subject.
    end
    
    if isfield(handles.program,'load_subject_fcn')                          %If a subject loading function is specified for this behavior...
        handles.program.load_subject_fcn(handles, gui_i);                   %Load the subject information.
    end

end


%% ***********************************************************************
function Vulintus_Behavior_Terminal_Error(err,handles)

%
%Vulintus_Behavior_Terminal_Error.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_TERMINAL_ERROR goes through all the housekeeping of
%   shutting down a Vulintus behavior program following a terminal error.
%   It generates an error report based on the "err" error message details
%   passed to it, displays error messages, and closes the program and main
%   GUI.
%   
%   UPDATE LOG:
%   2022-03-09 - Drew Sloan - Function first implemented, forked from
%                             ST_Proprioception_2AFC_Startup.m.
%   2024-03-25 - Drew Sloan - Changed "task_title" field to "task".
%

Vulintus_Show_Error_Report(handles.task,err);                               %Pop up a window showing the error.
if isfield(handles,'mainfig') && ~isempty(handles.mainfig)                  %If the original figure was closed (i.e. during calibration)...
    handles = handles.mainfig.UserData;                                     %Grab the most recent handles structure from the main GUI.     
end        
err_path = [handles.mainpath 'Error Reports\'];                             %Create the expected directory name for the error reports.
txt = Vulintus_Behavior_Save_Error_Report(err_path,handles.task,...
    err,handles);                                                           %Save a copy of the error in the AppData folder.      
% if handles.enable_error_reporting ~= 0                                      %If remote error reporting is enabled...
%     Vulintus_Behavior_Send_Error_Report(handles,...
%         handles.err_rcpt,txt);                                              %Send an error report to the specified recipient.     
% end
Vulintus_Behavior_Close(handles.mainfig);                                   %Call the function to close the vibration task program.
% errordlg(sprintf(['An fatal error occurred in the vibration '...
%     'task program. An message containing the error information '...
%     'has been sent to "%s", and a Vulintus engineer will '...
%     'contact you shortly.'], handles.err_rcpt),...
%     sprintf('Fatal Error in %s',handles.task_title));                       %Display an error dialog.


%% ***********************************************************************
function Vulintus_Behavior_Update_Controls(fig, mode)

%
%Vulintus_Behavior_Update_Controls.m - Vulintus, Inc.
%
%   2AFC_UPDATE_CONTROLS_DURING_IDLE enables or disables all of the 
%   uicontrol and uimenu objects on a Vulintus Common Behavior-based GUI
%   depending on the current program mode ('idle' or 'session') passed to
%   the function.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first implemented, adapted from
%                             STAP_2AFC_Update_Controls_During_Idle.m.
%   2024-04-11 - Drew Sloan - Switched from using a global run variable to
%                             a "run" field in the main figure UserData.
%

%Update the figure callbacks.
handles = fig.UserData;                                                     %Grab the handles structure from the main GUI.
handles.mainfig.CloseRequestFcn = ...
    {@Vulintus_Behavior_Set_Run_Field,handles.run_state.root.close};        %Set the callback for when the user tries to close the GUI.

if ~isfield(handles, 'ui')                                                  %If there's no "ui" field...
    warning(['%s -> No user interface objects were found in the '...
        'handles structure.'],upper(mfilename));                            %Show a warning.
    return                                                                  %Skip execution of the rest of the function.
end

%Update the menu callbacks.
if isfield(handles.ui,'menu')

    %Update the "Stages" uimenu.
    if isfield(handles.ui.menu,'stages') && ...
            isfield(handles,'stages_sync') && ...
            isfield(handles.stages_sync,'google_spreadsheet_edit_url')        
        handles.ui.menu.stages.view_spreadsheet.MenuSelectedFcn = ...
            {@Vulintus_Open_Google_Spreadsheet,...
            handles.stages_sync.google_spreadsheet_edit_url};               %Set the callback for the "Open Spreadsheet" submenu option.
    end

    %Update the "Preferences" uimenu.
    if isfield(handles.ui.menu,'pref')                                      %If there's a preferences menu...
        if isfield(handles.ui.menu.pref,'open_datapath')                    %Preferences >> Open Data Directory
            handles.ui.menu.pref.open_datapath.MenuSelectedFcn = ...
                {@Vulintus_Open_Directory,handles.datapath};                %Set the callback for the "Open Data Directory" submenu option.
        end
        if isfield(handles.ui.menu.pref,'set_datapath')                     %Preferences >> Set Data Directory
            handles.ui.menu.pref.set_datapath.MenuSelectedFcn = ...
                @Vulintus_Behavior_Set_Datapath;                            %Set the callback for the "Set Data Directory" submenu option.
        end
        if isfield(handles.ui.menu.pref,'err_report_on')                    %Preferences >> Error Report
            set([handles.ui.menu.pref.err_report_on,...
                handles.ui.menu.pref.err_report_off],...
                'MenuSelectedFcn',@Vulintus_Behavior_Set_Error_Reporting);  %Set the callback for turning off/on automatic error reporting.
        end
        if isfield(handles.ui.menu.pref,'error_reports')                    %Preferences >> View Error Reports
            handles.ui.menu.pref.error_reports.MenuSelectedFcn = ...
                {@Vulintus_Behavior_Open_Error_Reports,handles.mainpath};   %Set the callback for opening the error reports directory.
        end
        if isfield(handles.ui.menu.pref,'config_dir')                       %Preferences >> Configuration Files...
            handles.ui.menu.pref.config_dir.MenuSelectedFcn = ...
                {@Vulintus_Open_Directory,handles.mainpath};                %Set the callback for opening the configuration directory.
        end
    end

    %Update the "Camera" uimenu.
    if isfield(handles.ui.menu,'camera')
        if isfield(handles.ui.menu.pref,'view_webcam')                      %Camera >> View Webcam
            handles.ui.menu.camera.view_webcam.MenuSelectedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.idle_webcam_preview};                     %Set the callback for the "View Webcam" option.
        end
    end

end
    
%Update the dropdown callbacks.
if isfield(handles.ui,'drop_subject')                                       %If the GUI has a subjects drop-down menu...
    handles.ui.drop_subject.ValueChangedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.idle_select_subject};                             %Set the callback for the subject drop-down menu.
end
if isfield(handles.ui,'drop_stage')                                         %If the GUI has a stages drop-down menu...
    handles.ui.drop_stage.ValueChangedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.idle_select_stage};                               %Set the callback for the stage selection drop-down menu.
end

%Update the pause button.
if isfield(handles.ui,'btn_pause')                                          %If the GUI has a pause button...
    handles.ui.btn_pause.ButtonPushedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.session_pause};                                   %Set the callback for the pause button.
end

switch mode                                                                 %Switch between the different behavior program modes.

    case 'idle'                                                             %Idle mode.
        
        %Update the Start/Stop button.
        if isfield(handles.ui,'btn_start')                                  %If there's a start button.
            handles.ui.btn_start.Text = 'START';                            %Set the text on the Start/Stop button.
            handles.ui.btn_start.FontColor = [0 0.5 0];                     %Set the font color Start/Stop buttonto dark green.
            handles.ui.btn_start.ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.root.session};                            %Set the callback for the Start/Stop button.
        end

        %Enable all uicontrol objects.
        Vulintus_All_Uicontrols_Enable(handles.mainfig,'on');               %Enable all of the uicontrols.

        %Disable the pause button.
        if isfield(handles.ui,'btn_pause')                                  %If the GUI has a pause button...
            handles.ui.btn_pause.Enable = 'off';                            %Disable the pause button.
        end
        
        %Disable the trial table if unused.
        if isfield(handles.ui,'tbl_trial')                                  %If the GUI has a trial table...
            data = handles.ui.tbl_trial.Data;                               %Grab the data from the trial table.
            if isempty(data)                                                %If there's no data yet...
                handles.ui.tbl_trial.Enable = 'off';                        %Disable the trial table.
            end
        end

        %Update the manual feed buttons.
        if isfield(handles.ui,'btn_feed')                                   %If the GUI has a manual feed button.
            handles.ui.btn_feed(1).ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.idle_manual_feed_left};                   %Set the callback for the Manual Feed button (left, default).
            if length(handles.ui.btn_feed) > 1                              %If there's a second feed button...
                handles.ui.btn_right_feed.ButtonPushedFcn = ...
                    {@Vulintus_Behavior_Set_Run_Field,...
                    handles.run_state.idle_manual_feed_right};              %Set the callback for the Manual Feed button (right).
            end
        end

    case 'session'                                                          %Session mode.

        %Disable all uicontrol objects.
        Vulintus_All_Uicontrols_Enable(handles.mainfig,'off');              %Disable all of the uicontrols.

        if isfield(handles.ui,'menu')                                       %If this GUI has a menubar...

            %Update the "Camera" uimenu.
            if isfield(handles.ui.menu,'camera') && ...
                    isfield(handles.ui.menu.pref,'view_webcam') 
                handles.ui.menu.camera.h.Enable = 'on';                     %Enable the camera menu.
                handles.ui.menu.camera.view_webcam.Enable = 'on';           %Enable the "View Webcam" option.
            end
    
%             %Update the "Calibration" uimenu.
%             handles.ui.menu.cal.h.Enable = 'on';                             %Enable the calibration menu.
%             handles.ui.menu.cal.reset_baseline.MenuSelectedFcn = ...
%                 {@Vulintus_Behavior_Set_Run_Field,...
%                     handles.run_state.session_reset_baseline};              %Set the callback for the "Reset Baseline" option.
%             handles.ui.menu.cal.reset_baseline.Enable = 'on';               %Enable the "Reset Baseline" option.
%             handles.ui.menu.cal.rehome_handle.Enable = 'on';                %Enable the "Re-Home Handle" option.
%             handles.ui.menu.cal.adjust_midline.Enable = 'off';              %Disable the "Adjust Handle Home Position" option.

            %Update the "Stages" uimenu.
            if isfield(handles.ui.menu,'stages') && ...
                    isfield(handles.ui.menu.stages,'view_spreadsheet')      %If the menu has a "View Spreadsheet" option...
                handles.ui.menu.stages.h.Enable = 'on';                     %Enable the camera menu.
                handles.ui.menu.stages.view_spreadsheet.Enable = 'on';      %Enable the "View Spreadsheet" option.
            end
    
            %Update the "Preferences" uimenu.
            if isfield(handles.ui.menu,'pref')                              %If there's a preferences menu...
                handles.ui.menu.pref.h.Enable = 'on';                       %Enable the preferences menu.
                if isfield(handles.ui.menu.pref,'open_datapath')            %Preferences >> Open Data Directory        
                    handles.ui.menu.pref.open_datapath.Enable = 'on';       %Enable the "Open Datapath" option.
                end
                if isfield(handles.ui.menu.pref,'error_reports')            %Preferences >> View Error Reports
                    handles.ui.menu.pref.error_reports.Enable = 'on';       %Enable the "View Error Reports" option.
                end
                if isfield(handles.ui.menu.pref,'config_dir')               %Preferences >> Configuration Files...
                    handles.ui.menu.pref.config_dir.Enable = 'on';          %Enable the "Configuration Files..." option.
                end
            end

        end

        %Enable the trial table.
        if isfield(handles.ui,'tbl_trial')                                  %If the GUI has a trial table...              
            handles.ui.tbl_trial.Enable = 'on';                             %Enable the trial table.
            handles.ui.tbl_trial.Data = {};                                 %Clear any existing data from the trial table.
        end

        %Enable the manual feed buttons.
        if isfield(handles.ui,'btn_feed')                                   %If the GUI has a manual feed button.            
            handles.ui.btn_feed(1).ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.session_manual_feed_left};                %Set the callback for the Manual Feed button (left, default).
            if length(handles.ui.btn_feed) > 1                              %If there's a second feed button...
                handles.ui.btn_right_feed.ButtonPushedFcn = ...
                    {@Vulintus_Behavior_Set_Run_Field,...
                    handles.run_state.session_manual_feed_right};           %Set the callback for the Manual Feed button (right).
            end
            set(handles.ui.btn_feed,'Enable','on');                         %Enable all manual feed buttons.
        end
        
        %Enable the pause button.
        if isfield(handles.ui,'btn_pause')                                  %If the GUI has a pause button...
            handles.ui.btn_pause.Enable = 'on';                             %Enable the pause button.
        end
        
        %Change the Start/Stop button to stop mode.
        if isfield(handles.ui,'btn_start')                                  %If there's a start button.
            handles.ui.btn_start.Text = 'STOP';                             %Update the string on the Start/Stop button.
            handles.ui.btn_start.FontColor = [0.5 0 0];                     %Update the string on the Start/Stop button.
            handles.ui.btn_start.ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.root.idle};                               %Set the Start/Stop button callback.
            handles.ui.btn_start.Enable = 'on';                             %Enable the Start/Stop button.
        end
        
end

fig.UserData = handles;                                                     %Re-pin the handles structure to the main figure.    

drawnow;                                                                    %Immediately update the figure.


%% ***********************************************************************
function Vulintus_Open_Directory(~,~,datapath)

%
%Vulintus_Open_Directory.m - Vulintus, Inc.
%
%   VULINTUS_OPEN_DIRECTORY will open the directory specified by "datapath" 
%   in a separate Windows Explorer window.
%
%   UPDATE LOG:
%   11/29/2021 - Drew Sloan - Function converted to a Vulintus toolbox
%       function, adapted from LED_Detection_Task_Open_Data_Directory.m.
%

system(['explorer ' datapath]);                                             %Open the specified directory in Windows Explorer.


%% ***********************************************************************
function Vulintus_Open_Google_Spreadsheet(~,~,url)

%
%Vulintus_Open_Google_Spreadsheet.m - Vulintus, Inc.
%
%   VULINTUS_OPEN_GOOGLE_SPREADSHEET opens the Google Doc specified by
%   "url" in the user's default browser.
%   
%   UPDATE LOG:
%   11/29/2021 - Drew Sloan - Function converted to a Vulintus toolbox
%       function, adapted from
%       Vibrotactile_Detection_Task_Open_Google_Spreadsheet.m
%

if strncmpi(url,'https://docs.google.com/spreadsheet/pub',39)               %If the URL is in the old-style format...
    i = strfind(url,'key=') + 4;                                            %Find the start of the spreadsheet key.
    key = url(i:i+43);                                                      %Grab the 44-character spreadsheet key.
else                                                                        %Otherwise...
    i = strfind(url,'/d/') + 3;                                             %Find the start of the spreadsheet key.
    key = url(i:i+43);                                                      %Grab the 44-character spreadsheet key.
end
str = sprintf('https://docs.google.com/spreadsheets/d/%s/',key);            %Create the Google spreadsheet general URL from the spreadsheet key.
web(str,'-browser');                                                        %Open the Google spreadsheet in the default system browser.


%% ***********************************************************************
function Vulintus_Send_Error_Report(recipient,subject,msg)

%
%Vulintus_Send_Error_Report.m - Vulintus, Inc.
%
%   Vulintus_Send_Error_Report sends an error report ("msg") by email to 
%   the specified recipient ("target") through the Vulintus dummy 
%   error-reporting account.
%
%   The funtion must be compiled for deployment. Compile using the
%   following command in the command line:
%   
%       mcc -e -v Vulintus_Send_Error_Report.m
%   
%   UPDATE LOG:
%   02/21/2017 - Drew Sloan - Added enabling of a STARTTLS command.
%   2023-08-22 - Drew Sloan - Removed hard coded password and username.
%

try                                                                         %Attempt to send an email with the error information.
    setpref('Internet','E_mail','error.report@vulintus.com');               %Set the default email sender to "error.report@vulintus.com".
    setpref('Internet','SMTP_Server','smtp.gmail.com');                     %Set the SMTP server to Gmail.
    props = java.lang.System.getProperties;                                 %Grab the javascript email properties.
    props.setProperty('mail.smtp.auth','true');                             %Set the email properties to enable gmail logins.
    props.setProperty('mail.smtp.starttls.enable','true');                  %Enable the STARTTLS command.
    props.setProperty('mail.smtp.socketFactory.class', ...
                      'javax.getprfenet.ssl.SSLSocketFactory');             %Create an SSL socket.                  
    props.setProperty('mail.smtp.socketFactory.port','465');                %Set the email socket to a secure port.
    sendmail(recipient,subject,msg);                                        %Email the new and old calibration values to the specified users.
catch err                                                                   %Otherwise...
    warning('%s - %s',err.identifier,err.message);                          %Show the error message as a warning.                                                                  
end


%% ***********************************************************************
function path = Vulintus_Set_AppData_Path(program)

%
%Vulintus_Set_AppData_Path.m - Vulintus, Inc.
%
%   This function finds and/or creates the local application data folder
%   for Vulintus functions specified by "program".
%   
%   UPDATE LOG:
%   08/05/2016 - Drew Sloan - Function created to replace within-function
%       calls in multiple programs.
%

local = winqueryreg('HKEY_CURRENT_USER',...
        ['Software\Microsoft\Windows\CurrentVersion\' ...
        'Explorer\Shell Folders'],'Local AppData');                         %Grab the local application data directory.    
path = fullfile(local,'Vulintus','\');                                      %Create the expected directory name for Vulintus data.
if ~exist(path,'dir')                                                       %If the directory doesn't already exist...
    [status, msg, ~] = mkdir(path);                                         %Create the directory.
    if status ~= 1                                                          %If the directory couldn't be created...
        errordlg(sprintf(['Unable to create application data'...
            ' directory\n\n%s\n\nDetails:\n\n%s'],path,msg),...
            'Vulintus Directory Error');                                    %Show an error.
    end
end
path = fullfile(path,program,'\');                                          %Create the expected directory name for MotoTrak data.
if ~exist(path,'dir')                                                       %If the directory doesn't already exist...
    [status, msg, ~] = mkdir(path);                                         %Create the directory.
    if status ~= 1                                                          %If the directory couldn't be created...
        errordlg(sprintf(['Unable to create application data'...
            ' directory\n\n%s\n\nDetails:\n\n%s'],path,msg),...
            [program ' Directory Error']);                                  %Show an error.
    end
end

if strcmpi(program,'mototrak')                                              %If the specified function is MotoTrak.
    oldpath = fullfile(local,'MotoTrak','\');                               %Create the expected name of the previous version appdata directory.
    if exist(oldpath,'dir')                                                 %If the previous version directory exists...
        files = dir(oldpath);                                               %Grab the list of items contained within the previous directory.
        for f = 1:length(files)                                             %Step through each item.
            if ~files(f).isdir                                             	%If the item isn't a directory...
                copyfile([oldpath, files(f).name],path,'f');                %Copy the file to the new directory.
            end
        end
        [status, msg] = rmdir(oldpath,'s');                                 %Delete the previous version appdata directory.
        if status ~= 1                                                      %If the directory couldn't be deleted...
            warning(['Unable to delete application data'...
                ' directory\n\n%s\n\nDetails:\n\n%s'],oldpath,msg);         %Show an warning.
        end
    end
end


%% ***********************************************************************
function Vulintus_Show_Error_Report(program, err)

%
%Vulintus_Show_Error_Report.m - Vulintus, Inc.
%
%   Vulintus_Show_Error_Report creates a pop-up summary of an error report,
%   which is useful when programs are compiled and running without a
%   command line display. The functon blocks execution until the summary is
%   closed.
%   
%   UPDATE LOG:
%   11/19/2019 - Drew Sloan - Function first created, adapted from
%       Vulintus_Send_Error_Report.m.
%

fig = figure('menubar','none',...
    'name',upper([program ' Error Summary']),...
    'numbertitle','off');
ax = axes('units','normalized',...
    'position',[0 0 1 1],...
    'color','w',...
    'xlim',[0,1],...
    'ylim',[0,1],...
    'parent',fig);
t = text(0.05,1,err.identifier,...
    'fontsize',10,...
    'horizontalalignment','left',...
    'verticalalignment','top',...
    'interpreter','none',...
    'parent',ax);
y = get(t,'extent');
t = text(0.05,y(2) - 0.01,['     ' err.message],...
    'fontsize',10,...
    'horizontalalignment','left',...
    'verticalalignment','top',...
    'interpreter','none',...
    'parent',ax);
for i = 1:length(err.stack)
    y = get(t,'extent');
    t = text(0.05,y(2) - 0.01,err.stack(i).name,...
        'fontsize',10,...
        'horizontalalignment','left',...
        'verticalalignment','top',...
        'interpreter','none',...
        'parent',ax);
    y = get(t,'extent');
    t = text(0.05,y(2) - 0.01,['     LINE: ' num2str(err.stack(i).line)],...
        'fontsize',10,...
        'horizontalalignment','left',...
        'verticalalignment','top',...
        'interpreter','none',...
        'parent',ax);
end
set(ax,'xtick',[],'ytick',[]);
uiwait(fig);


%% ***********************************************************************
function block_codes = Load_OmniTrak_File_Block_Codes(varargin)

%LOAD_OMNITRAK_FILE_BLOCK_CODES.m
%
%	Vulintus, Inc.
%
%	OmniTrak file format block code libary.
%
%	https://github.com/Vulintus/OmniTrak_File_Format
%
%	This file was programmatically generated: 2024-04-24, 03:26:50 (UTC).
%

if nargin > 0
	ver = varargin{1};
else
	ver = 1;
end

block_codes = [];

switch ver

	case 1

		block_codes.CUR_DEF_VERSION = 1;

		block_codes.OMNITRAK_FILE_VERIFY = 43981;                           %First unsigned 16-bit integer written to every *.OmniTrak file to identify the file type, has a hex value of 0xABCD.

		block_codes.FILE_VERSION = 1;                                       %The version of the file format used.
		block_codes.MS_FILE_START = 2;                                      %Value of the SoC millisecond clock at file creation.
		block_codes.MS_FILE_STOP = 3;                                       %Value of the SoC millisecond clock when the file is closed.
		block_codes.SUBJECT_DEPRECATED = 4;                                 %A single subject's name.

		block_codes.CLOCK_FILE_START = 6;                                   %Computer clock serial date number at file creation (local time).
		block_codes.CLOCK_FILE_STOP = 7;                                    %Computer clock serial date number when the file is closed (local time).

		block_codes.DEVICE_FILE_INDEX = 10;                                 %The device's current file index.

		block_codes.NTP_SYNC = 20;                                          %A fetched NTP time (seconds since January 1, 1900) at the specified SoC millisecond clock time.
		block_codes.NTP_SYNC_FAIL = 21;                                     %Indicates the an NTP synchonization attempt failed.
		block_codes.MS_US_CLOCK_SYNC = 22;                                  %The current SoC microsecond clock time at the specified SoC millisecond clock time.
		block_codes.MS_TIMER_ROLLOVER = 23;                                 %Indicates that the millisecond timer rolled over since the last loop.
		block_codes.US_TIMER_ROLLOVER = 24;                                 %Indicates that the microsecond timer rolled over since the last loop.
		block_codes.TIME_ZONE_OFFSET = 25;                                  %Computer clock time zone offset from UTC.
		block_codes.TIME_ZONE_OFFSET_HHMM = 26;                             %Computer clock time zone offset from UTC as two integers, one for hours, and the other for minutes

		block_codes.RTC_STRING_DEPRECATED = 30;                             %Current date/time string from the real-time clock.
		block_codes.RTC_STRING = 31;                                        %Current date/time string from the real-time clock.
		block_codes.RTC_VALUES = 32;                                        %Current date/time values from the real-time clock.

		block_codes.ORIGINAL_FILENAME = 40;                                 %The original filename for the data file.
		block_codes.RENAMED_FILE = 41;                                      %A timestamped event to indicate when a file has been renamed by one of Vulintus' automatic data organizing programs.
		block_codes.DOWNLOAD_TIME = 42;                                     %A timestamp indicating when the data file was downloaded from the OmniTrak device to a computer.
		block_codes.DOWNLOAD_SYSTEM = 43;                                   %The computer system name and the COM port used to download the data file form the OmniTrak device.

		block_codes.INCOMPLETE_BLOCK = 50;                                  %Indicates that the file will end in an incomplete block.

		block_codes.USER_TIME = 60;                                         %Date/time values from a user-set timestamp.

		block_codes.SYSTEM_TYPE = 100;                                      %Vulintus system ID code (1 = MotoTrak, 2 = OmniTrak, 3 = HabiTrak, 4 = OmniHome, 5 = SensiTrak, 6 = Prototype).
		block_codes.SYSTEM_NAME = 101;                                      %Vulintus system name.
		block_codes.SYSTEM_HW_VER = 102;                                    %Vulintus system hardware version.
		block_codes.SYSTEM_FW_VER = 103;                                    %System firmware version, written as characters.
		block_codes.SYSTEM_SN = 104;                                        %System serial number, written as characters.
		block_codes.SYSTEM_MFR = 105;                                       %Manufacturer name for non-Vulintus systems.
		block_codes.COMPUTER_NAME = 106;                                    %Windows PC computer name.
		block_codes.COM_PORT = 107;                                         %The COM port of a computer-connected system.
		block_codes.DEVICE_ALIAS = 108;                                     %Human-readable Adjective + Noun alias/name for the device, assigned by Vulintus during manufacturing

		block_codes.PRIMARY_MODULE = 110;                                   %Primary module name, for systems with interchangeable modules.
		block_codes.PRIMARY_INPUT = 111;                                    %Primary input name, for modules with multiple input signals.
		block_codes.SAMD_CHIP_ID = 112;                                     %The SAMD manufacturer's unique chip identifier.

		block_codes.ESP8266_MAC_ADDR = 120;                                 %The MAC address of the device's ESP8266 module.
		block_codes.ESP8266_IP4_ADDR = 121;                                 %The local IPv4 address of the device's ESP8266 module.
		block_codes.ESP8266_CHIP_ID = 122;                                  %The ESP8266 manufacturer's unique chip identifier
		block_codes.ESP8266_FLASH_ID = 123;                                 %The ESP8266 flash chip's unique chip identifier

		block_codes.USER_SYSTEM_NAME = 130;                                 %The user's name for the system, i.e. booth number.

		block_codes.DEVICE_RESET_COUNT = 140;                               %The current reboot count saved in EEPROM or flash memory.
		block_codes.CTRL_FW_FILENAME = 141;                                 %Controller firmware filename, copied from the macro, written as characters.
		block_codes.CTRL_FW_DATE = 142;                                     %Controller firmware upload date, copied from the macro, written as characters.
		block_codes.CTRL_FW_TIME = 143;                                     %Controller firmware upload time, copied from the macro, written as characters.
		block_codes.MODULE_FW_FILENAME = 144;                               %OTMP Module firmware filename, copied from the macro, written as characters.
		block_codes.MODULE_FW_DATE = 145;                                   %OTMP Module firmware upload date, copied from the macro, written as characters.
		block_codes.MODULE_FW_TIME = 146;                                   %OTMP Module firmware upload time, copied from the macro, written as characters.

		block_codes.WINC1500_MAC_ADDR = 150;                                %The MAC address of the device's ATWINC1500 module.
		block_codes.WINC1500_IP4_ADDR = 151;                                %The local IPv4 address of the device's ATWINC1500 module.

		block_codes.BATTERY_SOC = 170;                                      %Current battery state-of charge, in percent, measured the BQ27441
		block_codes.BATTERY_VOLTS = 171;                                    %Current battery voltage, in millivolts, measured by the BQ27441
		block_codes.BATTERY_CURRENT = 172;                                  %Average current draw from the battery, in milli-amps, measured by the BQ27441
		block_codes.BATTERY_FULL = 173;                                     %Full capacity of the battery, in milli-amp hours, measured by the BQ27441
		block_codes.BATTERY_REMAIN = 174;                                   %Remaining capacity of the battery, in milli-amp hours, measured by the BQ27441
		block_codes.BATTERY_POWER = 175;                                    %Average power draw, in milliWatts, measured by the BQ27441
		block_codes.BATTERY_SOH = 176;                                      %Battery state-of-health, in percent, measured by the BQ27441
		block_codes.BATTERY_STATUS = 177;                                   %Combined battery state-of-charge, voltage, current, capacity, power, and state-of-health, measured by the BQ27441

		block_codes.FEED_SERVO_MAX_RPM = 190;                               %Actual rotation rate, in RPM, of the feeder servo (OmniHome) when set to 180 speed.
		block_codes.FEED_SERVO_SPEED = 191;                                 %Current speed setting (0-180) for the feeder servo (OmniHome).

		block_codes.SUBJECT_NAME = 200;                                     %A single subject's name.
		block_codes.GROUP_NAME = 201;                                       %The subject's or subjects' experimental group name.

		block_codes.EXP_NAME = 300;                                         %The user's name for the current experiment.
		block_codes.TASK_TYPE = 301;                                        %The user's name for task type, which can be a variant of the overall experiment type.

		block_codes.STAGE_NAME = 400;                                       %The stage name for a behavioral session.
		block_codes.STAGE_DESCRIPTION = 401;                                %The stage description for a behavioral session.

		block_codes.AMG8833_ENABLED = 1000;                                 %Indicates that an AMG8833 thermopile array sensor is present in the system.
		block_codes.BMP280_ENABLED = 1001;                                  %Indicates that an BMP280 temperature/pressure sensor is present in the system.
		block_codes.BME280_ENABLED = 1002;                                  %Indicates that an BME280 temperature/pressure/humidty sensor is present in the system.
		block_codes.BME680_ENABLED = 1003;                                  %Indicates that an BME680 temperature/pressure/humidy/VOC sensor is present in the system.
		block_codes.CCS811_ENABLED = 1004;                                  %Indicates that an CCS811 VOC/eC02 sensor is present in the system.
		block_codes.SGP30_ENABLED = 1005;                                   %Indicates that an SGP30 VOC/eC02 sensor is present in the system.
		block_codes.VL53L0X_ENABLED = 1006;                                 %Indicates that an VL53L0X time-of-flight distance sensor is present in the system.
		block_codes.ALSPT19_ENABLED = 1007;                                 %Indicates that an ALS-PT19 ambient light sensor is present in the system.
		block_codes.MLX90640_ENABLED = 1008;                                %Indicates that an MLX90640 thermopile array sensor is present in the system.
		block_codes.ZMOD4410_ENABLED = 1009;                                %Indicates that an ZMOD4410 VOC/eC02 sensor is present in the system.

		block_codes.AMG8833_THERM_CONV = 1100;                              %The conversion factor, in degrees Celsius, for converting 16-bit integer AMG8833 pixel readings to temperature.
		block_codes.AMG8833_THERM_FL = 1101;                                %The current AMG8833 thermistor reading as a converted float32 value, in Celsius.
		block_codes.AMG8833_THERM_INT = 1102;                               %The current AMG8833 thermistor reading as a raw, signed 16-bit integer.

		block_codes.AMG8833_PIXELS_CONV = 1110;                             %The conversion factor, in degrees Celsius, for converting 16-bit integer AMG8833 pixel readings to temperature.
		block_codes.AMG8833_PIXELS_FL = 1111;                               %The current AMG8833 pixel readings as converted float32 values, in Celsius.
		block_codes.AMG8833_PIXELS_INT = 1112;                              %The current AMG8833 pixel readings as a raw, signed 16-bit integers.
		block_codes.HTPA32X32_PIXELS_FP62 = 1113;                           %The current HTPA32x32 pixel readings as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius. This allows temperatures from 0 to 63.75 C.
		block_codes.HTPA32X32_PIXELS_INT_K = 1114;                          %The current HTPA32x32 pixel readings represented as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
		block_codes.HTPA32X32_AMBIENT_TEMP = 1115;                          %The current ambient temperature measured by the HTPA32x32, represented as a 32-bit float, in units of Celcius.
		block_codes.HTPA32X32_PIXELS_INT12_C = 1116;                        %The current HTPA32x32 pixel readings represented as 12-bit signed integers (2 pixels for every 3 bytes) in units of deciCelsius (dC, or Celsius * 10), with values under-range set to the minimum  (2048 dC) and values over-range set to the maximum (2047 dC).

		block_codes.BH1749_RGB = 1120;                                      %The current red, green, blue, IR, and green2 sensor readings from the BH1749 sensor
		block_codes.DEBUG_SANITY_CHECK = 1121;                              %A special block acting as a sanity check, only used in cases of debugging

		block_codes.BME280_TEMP_FL = 1200;                                  %The current BME280 temperature reading as a converted float32 value, in Celsius.
		block_codes.BMP280_TEMP_FL = 1201;                                  %The current BMP280 temperature reading as a converted float32 value, in Celsius.
		block_codes.BME680_TEMP_FL = 1202;                                  %The current BME680 temperature reading as a converted float32 value, in Celsius.

		block_codes.BME280_PRES_FL = 1210;                                  %The current BME280 pressure reading as a converted float32 value, in Pascals (Pa).
		block_codes.BMP280_PRES_FL = 1211;                                  %The current BMP280 pressure reading as a converted float32 value, in Pascals (Pa).
		block_codes.BME680_PRES_FL = 1212;                                  %The current BME680 pressure reading as a converted float32 value, in Pascals (Pa).

		block_codes.BME280_HUM_FL = 1220;                                   %The current BM280 humidity reading as a converted float32 value, in percent (%).
		block_codes.BME680_HUM_FL = 1221;                                   %The current BME680 humidity reading as a converted float32 value, in percent (%).

		block_codes.BME680_GAS_FL = 1230;                                   %The current BME680 gas resistance reading as a converted float32 value, in units of kOhms

		block_codes.VL53L0X_DIST = 1300;                                    %The current VL53L0X distance reading as a 16-bit integer, in millimeters (-1 indicates out-of-range).
		block_codes.VL53L0X_FAIL = 1301;                                    %Indicates the VL53L0X sensor experienced a range failure.

		block_codes.SGP30_SN = 1400;                                        %The serial number of the SGP30.

		block_codes.SGP30_EC02 = 1410;                                      %The current SGp30 eCO2 reading distance reading as a 16-bit integer, in parts per million (ppm).

		block_codes.SGP30_TVOC = 1420;                                      %The current SGp30 TVOC reading distance reading as a 16-bit integer, in parts per million (ppm).

		block_codes.MLX90640_DEVICE_ID = 1500;                              %The MLX90640 unique device ID saved in the device's EEPROM.
		block_codes.MLX90640_EEPROM_DUMP = 1501;                            %Raw download of the entire MLX90640 EEPROM, as unsigned 16-bit integers.
		block_codes.MLX90640_ADC_RES = 1502;                                %ADC resolution setting on the MLX90640 (16-, 17-, 18-, or 19-bit).
		block_codes.MLX90640_REFRESH_RATE = 1503;                           %Current refresh rate on the MLX90640 (0.25, 0.5, 1, 2, 4, 8, 16, or 32 Hz).
		block_codes.MLX90640_I2C_CLOCKRATE = 1504;                          %Current I2C clock freqency used with the MLX90640 (100, 400, or 1000 kHz).

		block_codes.MLX90640_PIXELS_TO = 1510;                              %The current MLX90640 pixel readings as converted float32 values, in Celsius.
		block_codes.MLX90640_PIXELS_IM = 1511;                              %The current MLX90640 pixel readings as converted, but uncalibrationed, float32 values.
		block_codes.MLX90640_PIXELS_INT = 1512;                             %The current MLX90640 pixel readings as a raw, unsigned 16-bit integers.

		block_codes.MLX90640_I2C_TIME = 1520;                               %The I2C transfer time of the frame data from the MLX90640 to the microcontroller, in milliseconds.
		block_codes.MLX90640_CALC_TIME = 1521;                              %The calculation time for the uncalibrated or calibrated image captured by the MLX90640.
		block_codes.MLX90640_IM_WRITE_TIME = 1522;                          %The SD card write time for the MLX90640 float32 image data.
		block_codes.MLX90640_INT_WRITE_TIME = 1523;                         %The SD card write time for the MLX90640 raw uint16 data.

		block_codes.ALSPT19_LIGHT = 1600;                                   %The current analog value of the ALS-PT19 ambient light sensor, as an unsigned integer ADC value.

		block_codes.ZMOD4410_MOX_BOUND = 1700;                              %The current lower and upper bounds for the ZMOD4410 ADC reading used in calculations.
		block_codes.ZMOD4410_CONFIG_PARAMS = 1701;                          %Current configuration values for the ZMOD4410.
		block_codes.ZMOD4410_ERROR = 1702;                                  %Timestamped ZMOD4410 error event.
		block_codes.ZMOD4410_READING_FL = 1703;                             %Timestamped ZMOD4410 reading calibrated and converted to float32.
		block_codes.ZMOD4410_READING_INT = 1704;                            %Timestamped ZMOD4410 reading saved as the raw uint16 ADC value.

		block_codes.ZMOD4410_ECO2 = 1710;                                   %Timestamped ZMOD4410 eCO2 reading.
		block_codes.ZMOD4410_IAQ = 1711;                                    %Timestamped ZMOD4410 indoor air quality reading.
		block_codes.ZMOD4410_TVOC = 1712;                                   %Timestamped ZMOD4410 total volatile organic compound reading.
		block_codes.ZMOD4410_R_CDA = 1713;                                  %Timestamped ZMOD4410 total volatile organic compound reading.

		block_codes.LSM303_ACC_SETTINGS = 1800;                             %Current accelerometer reading settings on any enabled LSM303.
		block_codes.LSM303_MAG_SETTINGS = 1801;                             %Current magnetometer reading settings on any enabled LSM303.
		block_codes.LSM303_ACC_FL = 1802;                                   %Current readings from the LSM303 accelerometer, as float values in m/s^2.
		block_codes.LSM303_MAG_FL = 1803;                                   %Current readings from the LSM303 magnetometer, as float values in uT.
		block_codes.LSM303_TEMP_FL = 1804;                                  %Current readings from the LSM303 temperature sensor, as float value in degrees Celcius

		block_codes.SPECTRO_WAVELEN = 1900;                                 %Spectrometer wavelengths, in nanometers.
		block_codes.SPECTRO_TRACE = 1901;                                   %Spectrometer measurement trace.

		block_codes.PELLET_DISPENSE = 2000;                                 %Timestamped event for feeding/pellet dispensing.
		block_codes.PELLET_FAILURE = 2001;                                  %Timestamped event for feeding/pellet dispensing in which no pellet was detected.

		block_codes.HARD_PAUSE_START = 2010;                                %Timestamped event marker for the start of a session pause, with no events recorded during the pause.
		block_codes.HARD_PAUSE_START = 2011;                                %Timestamped event marker for the stop of a session pause, with no events recorded during the pause.
		block_codes.SOFT_PAUSE_START = 2012;                                %Timestamped event marker for the start of a session pause, with non-operant events recorded during the pause.
		block_codes.SOFT_PAUSE_START = 2013;                                %Timestamped event marker for the stop of a session pause, with non-operant events recorded during the pause.

		block_codes.POSITION_START_X = 2020;                                %Starting position of an autopositioner in just the x-direction, with distance in millimeters.
		block_codes.POSITION_MOVE_X = 2021;                                 %Timestamped movement of an autopositioner in just the x-direction, with distance in millimeters.
		block_codes.POSITION_START_XY = 2022;                               %Starting position of an autopositioner in just the x- and y-directions, with distance in millimeters.
		block_codes.POSITION_MOVE_XY = 2023;                                %Timestamped movement of an autopositioner in just the x- and y-directions, with distance in millimeters.
		block_codes.POSITION_START_XYZ = 2024;                              %Starting position of an autopositioner in the x-, y-, and z- directions, with distance in millimeters.
		block_codes.POSITION_MOVE_XYZ = 2025;                               %Timestamped movement of an autopositioner in the x-, y-, and z- directions, with distance in millimeters.

		block_codes.STREAM_INPUT_NAME = 2100;                               %Stream input name for the specified input index.

		block_codes.CALIBRATION_BASELINE = 2200;                            %Starting calibration baseline coefficient, for the specified module index.
		block_codes.CALIBRATION_SLOPE = 2201;                               %Starting calibration slope coefficient, for the specified module index.
		block_codes.CALIBRATION_BASELINE_ADJUST = 2202;                     %Timestamped in-session calibration baseline coefficient adjustment, for the specified module index.
		block_codes.CALIBRATION_SLOPE_ADJUST = 2203;                        %Timestamped in-session calibration slope coefficient adjustment, for the specified module index.

		block_codes.HIT_THRESH_TYPE = 2300;                                 %Type of hit threshold (i.e. peak force), for the specified input.

		block_codes.SECONDARY_THRESH_NAME = 2310;                           %A name/description of secondary thresholds used in the behavior.

		block_codes.INIT_THRESH_TYPE = 2320;                                %Type of initation threshold (i.e. force or touch), for the specified input.

		block_codes.REMOTE_MANUAL_FEED = 2400;                              %A timestamped manual feed event, triggered remotely.
		block_codes.HWUI_MANUAL_FEED = 2401;                                %A timestamped manual feed event, triggered from the hardware user interface.
		block_codes.FW_RANDOM_FEED = 2402;                                  %A timestamped manual feed event, triggered randomly by the firmware.
		block_codes.SWUI_MANUAL_FEED_DEPRECATED = 2403;                     %A timestamped manual feed event, triggered from a computer software user interface.
		block_codes.FW_OPERANT_FEED = 2404;                                 %A timestamped operant-rewarded feed event, trigged by the OmniHome firmware, with the possibility of multiple feedings.
		block_codes.SWUI_MANUAL_FEED = 2405;                                %A timestamped manual feed event, triggered from a computer software user interface.
		block_codes.SW_RANDOM_FEED = 2406;                                  %A timestamped manual feed event, triggered randomly by computer software.
		block_codes.SW_OPERANT_FEED = 2407;                                 %A timestamped operant-rewarded feed event, trigged by the PC-based behavioral software, with the possibility of multiple feedings.

		block_codes.MOTOTRAK_V3P0_OUTCOME = 2500;                           %MotoTrak version 3.0 trial outcome data.
		block_codes.MOTOTRAK_V3P0_SIGNAL = 2501;                            %MotoTrak version 3.0 trial stream signal.

		block_codes.OUTPUT_TRIGGER_NAME = 2600;                             %Name/description of the output trigger type for the given index.

		block_codes.VIBRATION_TASK_TRIAL_OUTCOME = 2700;                    %Vibration task trial outcome data.

		block_codes.LED_DETECTION_TASK_TRIAL_OUTCOME = 2710;                %LED detection task trial outcome data.
		block_codes.LIGHT_SRC_MODEL = 2711;                                 %Light source model name.
		block_codes.LIGHT_SRC_TYPE = 2712;                                  %Light source type (i.e. LED, LASER, etc).

		block_codes.STTC_2AFC_TRIAL_OUTCOME = 2720;                         %SensiTrak tactile discrimination task trial outcome data.
		block_codes.STTC_NUM_PADS = 2721;                                   %Number of pads on the SensiTrak Tactile Carousel module.
		block_codes.MODULE_MICROSTEP = 2722;                                %Microstep setting on the specified OTMP module.
		block_codes.MODULE_STEPS_PER_ROT = 2723;                            %Steps per rotation on the specified OTMP module.

		block_codes.MODULE_PITCH_CIRC = 2730;                               %Pitch circumference, in millimeters, of the driving gear on the specified OTMP module.
		block_codes.MODULE_CENTER_OFFSET = 2731;                            %Center offset, in millimeters, for the specified OTMP module.

		block_codes.STAP_2AFC_TRIAL_OUTCOME = 2740;                         %SensiTrak proprioception discrimination task trial outcome data.

		block_codes.FR_TASK_TRIAL = 2800;                                   %Fixed reinforcement task trial data.

end


%% ***********************************************************************
function OmniTrakFileWrite_Close(fid, ofbc_clock_file_stop)

%
%OmniTrakFileWrite_Close.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_CLOSE adds a time-stamped file-closing block to the
%   specified *.OmniTrak file and then closes the file.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,ofbc_clock_file_stop,'uint16');                                  %-CLOCK_FILE_STOP- block code.
fwrite(fid,now,'float64');                                                  %Serial date number written as a 64-bit floating point.


%% ***********************************************************************
function OmniTrakFileWrite_WriteBlock_V1_FR_TASK_TRIAL(fid, block_code, trial, session, licks)

%
%OmniTrakFileWrite_WriteBlock_V1_FR_TASK_TRIAL.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_FR_TASK_TRIAL writes data from
%   individual trials of the Fixed Reinforcement task.
%
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

data_block_version = 1;                                                     %Set the FR_TASK_TRIAL block version.

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
fwrite(fid,data_block_version,'uint16');                                    %Write the FR_TASK_TRIAL block version.

fwrite(fid, session.trial_num, 'uint16');                                   %Trial number.
fwrite(fid, trial.timestamp, 'float64');                                    %Trial start timestamp (serial date number).
fwrite(fid, trial.outcome(1), 'uchar');                                     %Trial outcome.
fwrite(fid, trial.target_poke, 'uint8');                                    %Target nosepoke.
fwrite(fid, session.thresh, 'uint8');                                       %Required number of pokes.
fwrite(fid, max(trial.plot_signal(:,2)), 'uint16');                         %Poke count.
fwrite(fid, trial.hit_time, 'float32');                                     %Hit time (0 for misses).
fwrite(fid, session.reward_dur, 'float32');                                 %Reward window duration (lick availability), in seconds.
fwrite(fid, length(licks), 'uint16');                                       %Number of licks after the hit.
for i = 1:length(licks)                                                     %Step through each lick.
    fwrite(fid, licks(i), 'float32');                                       %Write each lick time.
end
fwrite(fid, session.feedings, 'uint16');                                    %Total Feed count.


%% ***********************************************************************
function OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, block_code, str)

%
%OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_LONG_CHARACTER_BLOCK adds the
%   specified character block to an *.OmniTrak data file, with a maximum
%   character count of 65,535.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
fwrite(fid,length(str),'uint16');                                           %Number of characters in the specified string.
fwrite(fid,str,'uchar');                                                    %Characters of the string.


%% ***********************************************************************
function OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, block_code, str)

%
%OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_SHORT_CHARACTER_BLOCK adds the
%   specified character block to an *.OmniTrak data file, with a maximum
%   character count of 255.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
fwrite(fid,length(str),'uint8');                                            %Number of characters in the specified string.
fwrite(fid,str,'uchar');                                                    %Characters of the string.


%% ***********************************************************************
function OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET(fid, block_code)

%
%OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_TIME_ZONE_OFFSET adds the time zone
%   offset, in units of days, between the local computer's time zone and
%   UTC time.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
dt = datenum(datetime('now','TimeZone','local')) - ...
    datenum(datetime('now','TimeZone','UTC'));                              %Calculate the different between the computer time and UTC time.
fwrite(fid,dt,'float64');                                                   %Write the time zone offset as a serial date number.


%% ***********************************************************************
function file_writer = OmniTrak_File_Writer(filename)

%
%OmniTrak_File_Writer.m - Vulintus, Inc., 2024.
%
%   OMNITRAK_FILE_WRITER opens a new *.OmniTrak format file with the
%   specified filename and passes back a function structure for writing new
%   blocks into the file.
%
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%


[fid,errmsg] = fopen(filename,'w');                                         %Open the data file as a binary file for writing.
if fid == -1                                                                %If the file could not be created...
    errordlg(sprintf(['Could not create the *.OmniTrak data file '...
        'at:\n\n%s\n\nError:\n\n%s'],filename,...
        errmsg),'OmniTrak File Write Error');                               %Show an error dialog box.
end

ofbc = Load_OmniTrak_File_Block_Codes(1);                                   %Load the OmniTrak file format block code libary.

%File format verification and version.
fwrite(fid,ofbc.OMNITRAK_FILE_VERIFY,'uint16');                             %The first block of the file should equal 0xABCD to indicate a Vulintus *.OmniTrak file.
fwrite(fid,ofbc.FILE_VERSION,'uint16');                                     %The second block of the file should be the file version indicator.
fwrite(fid,ofbc.CUR_DEF_VERSION,'uint16');                                  %Write the current file version.

%File creation start time.
fwrite(fid,ofbc.CLOCK_FILE_START,'uint16');                                 %Write the file start serial date number block code.
fwrite(fid,now,'float64');                                                  %Write the current serial date number.

file_writer = struct('fid',fid,'filename',filename);                        %Initialize an OFBC file-writing structure.
file_writer.close = @()OmniTrakFileWrite_Close(fid, ofbc.CLOCK_FILE_STOP);  %Add the file-closing function.


% CUR_DEF_VERSION: 1
% OMNITRAK_FILE_VERIFY: 43981
% FILE_VERSION: 1
% MS_FILE_START: 2
% MS_FILE_STOP: 3
% SUBJECT_DEPRECATED: 4
% CLOCK_FILE_START: 6
% CLOCK_FILE_STOP: 7
% DEVICE_FILE_INDEX: 10
% NTP_SYNC: 20
% NTP_SYNC_FAIL: 21
% MS_US_CLOCK_SYNC: 22
% MS_TIMER_ROLLOVER: 23
% US_TIMER_ROLLOVER: 24

% Block code: TIME_ZONE_OFFSET = 25.
file_writer.time_zone_offset = @()OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET(fid, ofbc.TIME_ZONE_OFFSET);

% TIME_ZONE_OFFSET_HHMM: 26
% RTC_STRING_DEPRECATED: 30
% RTC_STRING: 31
% RTC_VALUES: 32
% ORIGINAL_FILENAME: 40
% RENAMED_FILE: 41
% DOWNLOAD_TIME: 42
% DOWNLOAD_SYSTEM: 43
% INCOMPLETE_BLOCK: 50
% USER_TIME: 60
% SYSTEM_TYPE: 100

% Block code: SYSTEM_NAME = 101.
file_writer.system_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.SYSTEM_NAME, str);

% SYSTEM_HW_VER: 102
% SYSTEM_FW_VER: 103
% SYSTEM_SN: 104
% SYSTEM_MFR: 105

% Block code: COMPUTER_NAME = 106.
file_writer.computer_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.COMPUTER_NAME, str);

% Block code: COM_PORT = 107.
file_writer.com_port = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.COM_PORT, str);

% DEVICE_ALIAS: 108
% PRIMARY_MODULE: 110
% PRIMARY_INPUT: 111
% SAMD_CHIP_ID: 112
% WIFI_MAC_ADDR: 120
% WIFI_IP4_ADDR: 121
% ESP8266_CHIP_ID: 122
% ESP8266_FLASH_ID: 123

% Block code: USER_SYSTEM_NAME = 130.
file_writer.userset_alias = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.USER_SYSTEM_NAME, str);

% DEVICE_RESET_COUNT: 140

% Block code: CTRL_FW_FILENAME = 141.
file_writer.ctrl_fw_filename = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_FILENAME, str);

% Block code: CTRL_FW_DATE = 142.
file_writer.ctrl_fw_date = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_DATE, str);

% Block code: CTRL_FW_TIME = 143.
file_writer.ctrl_fw_time = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_TIME, str);

% MODULE_FW_FILENAME: 144
% MODULE_FW_DATE: 145
% MODULE_FW_TIME: 146
% WINC1500_MAC_ADDR: 150
% WINC1500_IP4_ADDR: 151
% BATTERY_SOC: 170
% BATTERY_VOLTS: 171
% BATTERY_CURRENT: 172
% BATTERY_FULL: 173
% BATTERY_REMAIN: 174
% BATTERY_POWER: 175
% BATTERY_SOH: 176
% BATTERY_STATUS: 177
% FEED_SERVO_MAX_RPM: 190
% FEED_SERVO_SPEED: 191

% Block code: SUBJECT_NAME = 200.
file_writer.subject_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.SUBJECT_NAME, str);

% GROUP_NAME: 201

% Block code: EXP_NAME = 300.
file_writer.exp_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.EXP_NAME, str);

% TASK_TYPE: 301

% Block code: STAGE_NAME = 400.
file_writer.stage_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.STAGE_NAME, str);


% Block code: STAGE_DESCRIPTION = 401.
file_writer.stage_description = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.STAGE_DESCRIPTION, str);

% AMG8833_ENABLED: 1000
% BMP280_ENABLED: 1001
% BME280_ENABLED: 1002
% BME680_ENABLED: 1003
% CCS811_ENABLED: 1004
% SGP30_ENABLED: 1005
% VL53L0X_ENABLED: 1006
% ALSPT19_ENABLED: 1007
% MLX90640_ENABLED: 1008
% ZMOD4410_ENABLED: 1009
% AMG8833_THERM_CONV: 1100
% AMG8833_THERM_FL: 1101
% AMG8833_THERM_INT: 1102
% AMG8833_PIXELS_CONV: 1110
% AMG8833_PIXELS_FL: 1111
% AMG8833_PIXELS_INT: 1112
% HTPA32X32_PIXELS_FP62: 1113
% HTPA32X32_PIXELS_INT_K: 1114
% HTPA32X32_AMBIENT_TEMP: 1115
% HTPA32X32_PIXELS_INT12_C: 1116
% BH1749_RGB: 1120
% DEBUG_SANITY_CHECK: 1121
% BME280_TEMP_FL: 1200
% BMP280_TEMP_FL: 1201
% BME680_TEMP_FL: 1202
% BME280_PRES_FL: 1210
% BMP280_PRES_FL: 1211
% BME680_PRES_FL: 1212
% BME280_HUM_FL: 1220
% BME680_HUM_FL: 1221
% BME680_GAS_FL: 1230
% VL53L0X_DIST: 1300
% VL53L0X_FAIL: 1301
% SGP30_SN: 1400
% SGP30_EC02: 1410
% SGP30_TVOC: 1420
% MLX90640_DEVICE_ID: 1500
% MLX90640_EEPROM_DUMP: 1501
% MLX90640_ADC_RES: 1502
% MLX90640_REFRESH_RATE: 1503
% MLX90640_I2C_CLOCKRATE: 1504
% MLX90640_PIXELS_TO: 1510
% MLX90640_PIXELS_IM: 1511
% MLX90640_PIXELS_INT: 1512
% MLX90640_I2C_TIME: 1520
% MLX90640_CALC_TIME: 1521
% MLX90640_IM_WRITE_TIME: 1522
% MLX90640_INT_WRITE_TIME: 1523
% ALSPT19_LIGHT: 1600
% ZMOD4410_MOX_BOUND: 1700
% ZMOD4410_CONFIG_PARAMS: 1701
% ZMOD4410_ERROR: 1702
% ZMOD4410_READING_FL: 1703
% ZMOD4410_READING_INT: 1704
% ZMOD4410_ECO2: 1710
% ZMOD4410_IAQ: 1711
% ZMOD4410_TVOC: 1712
% ZMOD4410_R_CDA: 1713
% LSM303_ACC_SETTINGS: 1800
% LSM303_MAG_SETTINGS: 1801
% LSM303_ACC_FL: 1802
% LSM303_MAG_FL: 1803
% LSM303_TEMP_FL: 1804
% SPECTRO_WAVELEN: 1900
% SPECTRO_TRACE: 1901
% PELLET_DISPENSE: 2000
% PELLET_FAILURE: 2001
% HARD_PAUSE_START: 2011
% SOFT_PAUSE_START: 2013
% POSITION_START_X: 2020
% POSITION_MOVE_X: 2021
% POSITION_START_XY: 2022
% POSITION_MOVE_XY: 2023
% POSITION_START_XYZ: 2024
% POSITION_MOVE_XYZ: 2025
% STREAM_INPUT_NAME: 2100
% CALIBRATION_BASELINE: 2200
% CALIBRATION_SLOPE: 2201
% CALIBRATION_BASELINE_ADJUST: 2202
% CALIBRATION_SLOPE_ADJUST: 2203
% HIT_THRESH_TYPE: 2300
% SECONDARY_THRESH_NAME: 2310
% INIT_THRESH_TYPE: 2320
% REMOTE_MANUAL_FEED: 2400
% HWUI_MANUAL_FEED: 2401
% FW_RANDOM_FEED: 2402
% SWUI_MANUAL_FEED_DEPRECATED: 2403
% FW_OPERANT_FEED: 2404
% SWUI_MANUAL_FEED: 2405
% SW_RANDOM_FEED: 2406
% SW_OPERANT_FEED: 2407
% MOTOTRAK_V3P0_OUTCOME: 2500
% MOTOTRAK_V3P0_SIGNAL: 2501
% OUTPUT_TRIGGER_NAME: 2600
% VIBRATION_TASK_TRIAL_OUTCOME: 2700
% LED_DETECTION_TASK_TRIAL_OUTCOME: 2710
% LIGHT_SRC_MODEL: 2711
% LIGHT_SRC_TYPE: 2712
% STTC_2AFC_TRIAL_OUTCOME: 2720
% STTC_NUM_PADS: 2721
% MODULE_MICROSTEP: 2722
% MODULE_STEPS_PER_ROT: 2723
% MODULE_PITCH_CIRC: 2730
% MODULE_CENTER_OFFSET: 2731
% STAP_2AFC_TRIAL_OUTCOME: 2740

% Block code: FR_TASK_TRIAL = 2800.
file_writer.fr_task_trial = @(trial,session,licks)OmniTrakFileWrite_WriteBlock_V1_FR_TASK_TRIAL(fid, ofbc.FR_TASK_TRIAL, trial, session, licks);




%% ***********************************************************************
function serial_codes = Vulintus_Load_OTSC_Codes

%	Vulintus_Load_OTSC_Codes.m
%
%	Vulintus, Inc.
%
%	OmniTrak Serial Communication (OTSC) library.
%
%	Library documentation:
%	https://github.com/Vulintus/OmniTrak_Serial_Communication
%
%	This function was programmatically generated: 2024-06-11, 03:37:20 (UTC)
%

serial_codes = [];

serial_codes.CLEAR = 0;                            %Reset communication with the device.
serial_codes.REQ_COMM_VERIFY = 1;                  %Request verification that the connected device is using the OTSC serial code library.
serial_codes.REQ_DEVICE_ID = 2;                    %Request the device type ID number.
serial_codes.DEVICE_ID = 3;                        %Set/report the device type ID number.
serial_codes.REQ_USERSET_ALIAS = 4;                %Request the user-set name for the device.
serial_codes.USERSET_ALIAS = 5;                    %Set/report the user-set name for the device.
serial_codes.REQ_VULINTUS_ALIAS = 6;               %Request the Vulintus alias (adjective/noun serial number) for the device.
serial_codes.VULINTUS_ALIAS = 7;                   %Set/report the Vulintus alias (adjective/noun serial number) for the device.

serial_codes.REQ_MAC_ADDR = 10;                    %Request the device MAC address.
serial_codes.MAC_ADDR = 11;                        %Report the device MAC address.
serial_codes.REQ_MCU_SERIALNUM = 12;               %Request the device microcontroller serial number.
serial_codes.MCU_SERIALNUM = 13;                   %Report the device microcontroller serial number.

serial_codes.FW_FILENAME = 21;                     %Report the firmware filename.
serial_codes.REQ_FW_FILENAME = 22;                 %Request the firmware filename.
serial_codes.FW_DATE = 23;                         %Report the firmware upload date.
serial_codes.REQ_FW_DATE = 24;                     %Request the firmware upload date.
serial_codes.FW_TIME = 25;                         %Report the firmware upload time.
serial_codes.REQ_FW_TIME = 26;                     %Request the firmware upload time.

serial_codes.REQ_LIB_VER = 31;                     %Request the OTSC serial code library version.
serial_codes.LIB_VER = 32;                         %Report the OTSC serial code library version.
serial_codes.UNKNOWN_BLOCK_ERROR = 33;             %Indicate an unknown block code error.
serial_codes.ERROR_INDICATOR = 34;                 %Indicate an error and send the associated error code.

serial_codes.REQ_CUR_FEEDER = 50;                  %Request the current dispenser index.
serial_codes.CUR_FEEDER = 51;                      %Set/report the current dispenser index.
serial_codes.REQ_FEED_TRIG_DUR = 52;               %Request the current dispenser triggger duration, in milliseconds.
serial_codes.FEED_TRIG_DUR = 53;                   %Set/report the current dispenser triggger duration, in milliseconds.
serial_codes.TRIGGER_FEEDER = 54;                  %Trigger feeding on the currently-selected dispenser.
serial_codes.STOP_FEED = 55;                       %Immediately shut off any active feeding trigger.
serial_codes.DISPENSE_FIRMWARE = 56;               %Report that a feeding was automatically triggered in the device firmware.

serial_codes.MODULE_REHOME = 59;                   %Initiate the homing routine on the module.
serial_codes.HOMING_COMPLETE = 60;                 %Indicate that a module's homing routine is complete.
serial_codes.MOVEMENT_START = 61;                  %Indicate that a commanded movement has started.
serial_codes.MOVEMENT_COMPLETE = 62;               %Indicate that a commanded movement is complete.
serial_codes.MODULE_RETRACT = 63;                  %Retract the module movement to it's starting or base position.
serial_codes.REQ_TARGET_POS_MM = 64;               %Request the current target position of a module movement, in millimeters.
serial_codes.TARGET_POS_MM = 65;                   %Set/report the target position of a module movement, in millimeters.
serial_codes.REQ_CUR_POS_MM = 66;                  %Request the current  position of the module movement, in millimeters.
serial_codes.CUR_POS_MM = 67;                      %Set/report the current position of the module movement, in millimeters.
serial_codes.REQ_MIN_POS_MM = 68;                  %Request the current minimum position of a module movement, in millimeters.
serial_codes.MIN_POS_MM = 69;                      %Set/report the current minimum position of a module movement, in millimeters.
serial_codes.REQ_MAX_POS_MM = 70;                  %Request the current maximum position of a module movement, in millimeters.
serial_codes.MAX_POS_MM = 71;                      %Set/report the current maximum position of a module movement, in millimeters.
serial_codes.REQ_MIN_SPEED_MM_S = 72;              %Request the current minimum speed (i.e. motor start speed), in millimeters/second.
serial_codes.MIN_SPEED_MM_S = 73;                  %Set/report the current minimum speed (i.e. motor start speed), in millimeters/second.
serial_codes.REQ_MAX_SPEED_MM_S = 74;              %Request the current maximum speed, in millimeters/second.
serial_codes.MAX_SPEED_MM_S = 75;                  %Set/report the current maximum speed, in millimeters/second.
serial_codes.REQ_ACCEL_MM_S2 = 76;                 %Request the current movement acceleration, in millimeters/second^2.
serial_codes.ACCEL_MM_S2 = 77;                     %Set/report the current movement acceleration, in millimeters/second^2.
serial_codes.REQ_MOTOR_CURRENT = 78;               %Request the current motor current setting, in milliamps.
serial_codes.MOTOR_CURRENT = 79;                   %Set/report the current motor current setting, in milliamps.
serial_codes.REQ_MAX_MOTOR_CURRENT = 80;           %Request the maximum possible motor current, in milliamps.
serial_codes.MAX_MOTOR_CURRENT = 81;               %Set/report the maximum possible motor current, in milliamps.

serial_codes.STREAM_PERIOD = 101;                  %Set/report the current streaming period, in milliseconds.
serial_codes.REQ_STREAM_PERIOD = 102;              %Request the current streaming period, in milliseconds.
serial_codes.STREAM_ENABLE = 103;                  %Enable/disable streaming from the device.

serial_codes.AP_DIST_X = 110;                      %Set/report the autopositioner x position, in millimeters.
serial_codes.REQ_AP_DIST_X = 111;                  %Request the current autopositioner x position, in millimeters.
serial_codes.AP_ERROR = 112;                       %Indicate an autopositioning error.

serial_codes.READ_FROM_NVM = 120;                  %Read bytes from non-volatile memory.
serial_codes.WRITE_TO_NVM = 121;                   %Write bytes to non-volatile memory.
serial_codes.REQ_NVM_SIZE = 122;                   %Request the non-volatile memory size.
serial_codes.NVM_SIZE = 123;                       %Report the non-volatile memory size.

serial_codes.PLAY_TONE = 256;                      %Play the specified tone.
serial_codes.STOP_TONE = 257;                      %Stop any currently playing tone.
serial_codes.REQ_NUM_TONES = 258;                  %Request the number of queueable tones.
serial_codes.NUM_TONES = 259;                      %Report the number of queueable tones.
serial_codes.TONE_INDEX = 260;                     %Set/report the current tone index.
serial_codes.REQ_TONE_INDEX = 261;                 %Request the current tone index.
serial_codes.TONE_FREQ = 262;                      %Set/report the frequency of the current tone, in Hertz.
serial_codes.REQ_TONE_FREQ = 263;                  %Request the frequency of the current tone, in Hertz.
serial_codes.TONE_DUR = 264;                       %Set/report the duration of the current tone, in milliseconds.
serial_codes.REQ_TONE_DUR = 265;                   %Return the duration of the current tone in milliseconds.
serial_codes.TONE_VOLUME = 266;                    %Set/report the volume of the current tone, normalized from 0 to 1.
serial_codes.REQ_TONE_VOLUME = 267;                %Request the volume of the current tone, normalized from 0 to 1.

serial_codes.INDICATOR_LEDS_ON = 352;              %Set/report whether the indicator LEDs are turned on (0 = off, 1 = on).

serial_codes.CUE_LIGHT_ON = 384;                   %Turn on the specified cue light.
serial_codes.CUE_LIGHT_OFF = 385;                  %Turn off any currently-showing cue light.
serial_codes.NUM_CUE_LIGHTS = 386;                 %Report the number of queueable cue lights.
serial_codes.REQ_NUM_CUE_LIGHTS = 387;             %Request the number of queueable cue lights.
serial_codes.CUE_LIGHT_INDEX = 388;                %Set/report the current cue light index.
serial_codes.REQ_CUE_LIGHT_INDEX = 389;            %Request the current cue light index.
serial_codes.CUE_LIGHT_RGBW = 390;                 %Set/report the RGBW values for the current cue light (0-255).
serial_codes.REQ_CUE_LIGHT_RGBW = 391;             %Request the RGBW values for the current cue light (0-255).
serial_codes.CUE_LIGHT_DUR = 392;                  %Set/report the current cue light duration, in milliseconds.
serial_codes.REQ_CUE_LIGHT_DUR = 393;              %Request the current cue light duration, in milliseconds.
serial_codes.CUE_LIGHT_MASK = 394;                 %Set/report the cue light enable bitmask.
serial_codes.REQ_CUE_LIGHT_MASK = 395;             %Request the cue light enable bitmask.
serial_codes.CUE_LIGHT_QUEUE_SIZE = 396;           %Set/report the number of queueable cue light stimuli.
serial_codes.REQ_CUE_LIGHT_QUEUE_SIZE = 397;       %Request the number of queueable cue light stimuli.
serial_codes.CUE_LIGHT_QUEUE_INDEX = 398;          %Set/report the current cue light queue index.
serial_codes.REQ_CUE_LIGHT_QUEUE_INDEX = 399;      %Request the current cue light queue index.

serial_codes.CAGE_LIGHT_ON = 416;                  %Turn on the overhead cage light.
serial_codes.CAGE_LIGHT_OFF = 417;                 %Turn off the overhead cage light.
serial_codes.CAGE_LIGHT_RGBW = 418;                %Set/report the RGBW values for the overhead cage light (0-255).
serial_codes.REQ_CAGE_LIGHT_RGBW = 419;            %Request the RGBW values for the overhead cage light (0-255).
serial_codes.CAGE_LIGHT_DUR = 420;                 %Set/report the overhead cage light duration, in milliseconds.
serial_codes.REQ_CAGE_LIGHT_DUR = 421;             %Request the overhead cage light duration, in milliseconds.

serial_codes.POKE_BITMASK = 512;                   %Set/report the current nosepoke status bitmask.
serial_codes.REQ_POKE_BITMASK = 513;               %Request the current nosepoke status bitmask.
serial_codes.POKE_ADC = 514;                       %Report the current nosepoke analog reading.
serial_codes.REQ_POKE_ADC = 515;                   %Request the current nosepoke analog reading.
serial_codes.POKE_MINMAX = 516;                    %Set/report the minimum and maximum ADC values of the nosepoke infrared sensor history, in ADC ticks.
serial_codes.REQ_POKE_MINMAX = 517;                %Request the minimum and maximum ADC values of the nosepoke infrared sensor history, in ADC ticks.
serial_codes.POKE_THRESH_FL = 518;                 %Set/report the current nosepoke threshold setting, normalized from 0 to 1.
serial_codes.REQ_POKE_THRESH_FL = 519;             %Request the current nosepoke threshold setting, normalized from 0 to 1.
serial_codes.POKE_THRESH_ADC = 520;                %Set/report the current nosepoke threshold setting, in ADC ticks.
serial_codes.REQ_POKE_THRESH_ADC = 521;            %Request the current nosepoke auto-threshold setting, in ADC ticks.
serial_codes.POKE_THRESH_AUTO = 522;               %Set/report the current nosepoke auto-thresholding setting (0 = fixed, 1 = autoset).
serial_codes.REQ_POKE_THRESH_AUTO = 523;           %Request the current nosepoke auto-thresholding setting (0 = fixed, 1 = autoset).
serial_codes.POKE_RESET = 524;                     %Reset the nosepoke infrared sensor history.
serial_codes.POKE_INDEX = 525;                     %Set/report the current nosepoke index for multi-nosepoke modules.
serial_codes.REQ_POKE_INDEX = 526;                 %Request the current nosepoke index for multi-nosepoke modules.

serial_codes.LICK_BITMASK = 544;                   %Set/report the current lick sensor status bitmask.
serial_codes.REQ_LICK_BITMASK = 545;               %Request the current lick sensor status bitmask.
serial_codes.LICK_CAP = 546;                       %Report the current lick sensor capacitance reading.
serial_codes.REQ_LICK_CAP = 547;                   %Request the current lick sensor capacitance reading.
serial_codes.LICK_MINMAX = 548;                    %Set/report the minimum and maximum capacitance values of the lick sensor capacitance history.
serial_codes.REQ_LICK_MINMAX = 549;                %Request the minimum and maximum capacitance values of the lick sensor capacitance history.
serial_codes.LICK_THRESH_FL = 550;                 %Set/report the current lick sensor threshold setting, normalized from 0 to 1.
serial_codes.REQ_LICK_THRESH_FL = 551;             %Request the current lick sensor threshold setting, normalized from 0 to 1.
serial_codes.LICK_THRESH_CAP = 552;                %Set/report the current lick sensor threshold setting.
serial_codes.REQ_LICK_THRESH_CAP = 553;            %Request the current lick sensor auto-threshold setting.
serial_codes.LICK_THRESH_AUTO = 554;               %Set/report the current lick sensor auto-thresholding setting (0 = fixed, 1 = autoset <default>).
serial_codes.REQ_LICK_THRESH_AUTO = 555;           %Request the current lick sensor auto-thresholding setting (0 = fixed, 1 = autoset <default>).
serial_codes.LICK_RESET = 556;                     %Reset the lick sensor infrared capacitance history.
serial_codes.LICK_INDEX = 557;                     %Set/report the current lick sensor index for multi-lick sensor modules.
serial_codes.REQ_LICK_INDEX = 558;                 %Request the current lick sensor index for multi-lick sensor modules.
serial_codes.LICK_RESET_TIMEOUT = 559;             %Set/report the current lick sensor reset timeout duration, in milliseconds (0 = no time-out reset).
serial_codes.REQ_LICK_RESET_TIMEOUT = 560;         %Request the current lick sensor reset timeout duration, in milliseconds (0 = no time-out reset).

serial_codes.TOUCH_BITMASK = 640;                  %Set/report the current capacitive touch status bitmask.
serial_codes.REQ_TOUCH_BITMASK = 641;              %Request the current capacitive touch status bitmask.

serial_codes.REQ_THERM_PIXELS_INT_K = 768;         %Request a thermal pixel image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
serial_codes.THERM_PIXELS_INT_K = 769;             %Report a thermal image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
serial_codes.REQ_THERM_PIXELS_FP62 = 770;          %Request a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius.
serial_codes.THERM_PIXELS_FP62 = 771;              %Report a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius. This allows temperatures from 0 to 63.75 C.

serial_codes.REQ_THERM_XY_PIX = 784;               %Request the current thermal hotspot x-y position, in units of pixels.
serial_codes.THERM_XY_PIX = 785;                   %Report the current thermal hotspot x-y position, in units of pixels.

serial_codes.REQ_AMBIENT_TEMP = 800;               %Request the current ambient temperature as a 32-bit float, in units of Celsius.
serial_codes.AMBIENT_TEMP = 801;                   %Report the current ambient temperature as a 32-bit float, in units of Celsius.

serial_codes.REQ_TOF_DIST = 896;                   %Request the current time-of-flight distance reading, in units of millimeters (float32).
serial_codes.TOF_DIST = 897;                       %Report the current time-of-flight distance reading, in units of millimeters (float32).

serial_codes.VIB_DUR = 16384;                      %Set/report the current vibration pulse duration, in microseconds.
serial_codes.REQ_VIB_DUR = 16385;                  %Request the current vibration pulse duration, in microseconds.
serial_codes.VIB_IPI = 16386;                      %Set/report the current vibration train onset-to-onset inter-pulse interval, in microseconds.
serial_codes.REQ_VIB_IPI = 16387;                  %Request the current vibration train onset-to-onset inter-pulse interval, in microseconds.
serial_codes.VIB_N_PULSE = 16388;                  %Set/report the current vibration train duration, in number of pulses.
serial_codes.REQ_VIB_N_PULSE = 16389;              %Request the current vibration train duration, in number of pulses.
serial_codes.VIB_GAP_START = 16390;                %Set/report the current vibration train skipped pulses starting index.
serial_codes.REQ_VIB_GAP_START = 16391;            %Request the current vibration train skipped pulses starting index.
serial_codes.VIB_GAP_STOP = 16392;                 %Set/report the current vibration train skipped pulses stop index.
serial_codes.REQ_VIB_GAP_STOP = 16393;             %Request the current vibration train skipped pulses stop index.
serial_codes.START_VIB = 16394;                    %Immediately start the vibration pulse train.
serial_codes.STOP_VIB = 16395;                     %Immediately stop the vibration pulse train.
serial_codes.VIB_MASK_ENABLE = 16396;              %Enable/disable vibration tone masking (0 = disabled, 1 = enabled).
serial_codes.VIB_TONE_FREQ = 16397;                %Set/report the currently selected vibration masking tone's frequency, in Hz.
serial_codes.REQ_VIB_TONE_FREQ = 16398;            %Request the currently selected vibration masking tone's frequency, in Hz.
serial_codes.VIB_TONE_DUR = 16399;                 %Set/report the currently selected vibration masking tone's duration, in milliseconds.
serial_codes.REQ_VIB_TONE_DUR = 16400;             %Request the currently selected vibration masking tone's duration, in milliseconds.
serial_codes.VIB_TASK_MODE = 16401;                %Set/report the current vibration task mode (1 = BURST, 2 = GAP).
serial_codes.REQ_VIB_TASK_MODE = 16402;            %Request the current vibration task mode (1 = BURST, 2 = GAP).
serial_codes.VIB_INDEX = 16403;                    %Set/report the current vibration motor/actuator index.
serial_codes.REQ_VIB_INDEX = 16404;                %Request the current vibration motor/actuator index.

serial_codes.STAP_REQ_FORCE_VAL = 16650;           %Request the current primary force/loadcell value. DEPRECATED: Switch to REQ_PRIMARY FORCE_VAL (0xAA0A).
serial_codes.STAP_FORCE_VAL = 16651;               %Report the current force/loadcell value. DEPRECATED: Switch to PRIMARY FORCE_VAL (0xAA0B).
serial_codes.STAP_REQ_FORCE_BASELINE = 16652;      %Request the current force calibration baseline, in ADC ticks.
serial_codes.STAP_FORCE_BASELINE = 16653;          %Set/report the current force calibration baseline, in ADC ticks.
serial_codes.STAP_REQ_FORCE_SLOPE = 16654;         %Request the current force calibration slope, in grams per ADC tick.
serial_codes.STAP_FORCE_SLOPE = 16655;             %Set/report the current force calibration slope, in grams per ADC tick.
serial_codes.STAP_REQ_DIGPOT_BASELINE = 16656;     %Request the current force baseline-adjusting digital potentiometer setting.
serial_codes.STAP_DIGPOT_BASELINE = 16657;         %Set/report the current force baseline-adjusting digital potentiometer setting.

serial_codes.STAP_STEPS_PER_ROT = 16665;           %Set/report the number of steps per full revolution for the stepper motor.
serial_codes.STAP_REQ_STEPS_PER_ROT = 16666;       %Return the current number of steps per full revolution for the stepper motor.

serial_codes.STAP_MICROSTEP = 16670;               %Set/report the microstepping multiplier.
serial_codes.STAP_REQ_MICROSTEP = 16671;           %Request the current microstepping multiplier.
serial_codes.CUR_POS = 16672;                      %Set/report the target/current handle position, in micrometers.
serial_codes.REQ_CUR_POS = 16673;                  %Request the current handle position, in micrometers.
serial_codes.MIN_SPEED = 16674;                    %Set/report the minimum movement speed, in micrometers/second.
serial_codes.REQ_MIN_SPEED = 16675;                %Request the minimum movement speed, in micrometers/second.
serial_codes.MAX_SPEED = 16676;                    %Set/report the maximum movement speed, in micrometers/second.
serial_codes.REQ_MAX_SPEED = 16677;                %Request the maximum movement speed, in micrometers/second.
serial_codes.RAMP_N = 16678;                       %Set/report the cosine ramp length, in steps.
serial_codes.REQ_RAMP_N = 16679;                   %Request the cosine ramp length, in steps.
serial_codes.PITCH_CIRC = 16680;                   %Set/report the driving gear pitch circumference, in micrometers.
serial_codes.REQ_PITCH_CIRC = 16681;               %Request the driving gear pitch circumference, in micrometers.
serial_codes.CENTER_OFFSET = 16682;                %Set/report the center-to-slot detector offset, in micrometers.
serial_codes.REQ_CENTER_OFFSET = 16683;            %Request the center-to-slot detector offset, in micrometers.

serial_codes.TRIAL_SPEED = 16688;                  %Set/report the trial movement speed, in micrometers/second.
serial_codes.REQ_TRIAL_SPEED = 16689;              %Request the trial movement speed, in micrometers/second.
serial_codes.RECENTER = 16690;                     %Rapidly re-center the handle to the home position state.
serial_codes.RECENTER_COMPLETE = 16691;            %Indicate that the handle is recentered.

serial_codes.SINGLE_EXCURSION = 16705;             %Select excursion type:  direct single motion (L/R)
serial_codes.INCREASING_EXCURSION = 16706;         %Select excursion type:  deviation increase from midline
serial_codes.DRIFTING_EXCURSION = 16707;           %Select excursion type:  R/L motion with a net direction
serial_codes.SELECT_TEST_DEV_DEG = 16708;          %Set deviation degrees:  used in mode 65, 66 and 67
serial_codes.SELECT_BASE_DEV_DEG = 16709;          %Set the baseline rocking: used in mode 66 and 67
serial_codes.SELECT_SYMMETRY = 16710;              %Sets oscillation around midline or from mindline
serial_codes.SELECT_ACCEL = 16711;
serial_codes.SET_EXCURSION_TYPE = 16712;           %Set the excursion type (49 = simple movement, 50 = wandering wobble)
serial_codes.GET_EXCURSION_TYPE = 16713;           %Get the current excurion type.

serial_codes.CUR_DEBUG_MODE = 25924;               %Report the current debug mode ("Debug_ON_" or "Debug_OFF");

serial_codes.TOGGLE_DEBUG_MODE = 25956;            %Toggle OTSC debugging mode (type "db" in a serial monitor).

serial_codes.REQ_PRIMARY_FORCE_VAL = 43530;        %Request the current primary force/loadcell value.
serial_codes.PRIMARY_FORCE_VAL = 43531;            %Report the current force/loadcell value.
serial_codes.REQ_FORCE_BASELINE = 43532;           %Request the current force calibration baseline, in ADC ticks.
serial_codes.FORCE_BASELINE = 43533;               %Set/report the current force calibration baseline, in ADC ticks.
serial_codes.REQ_FORCE_SLOPE = 43534;              %Request the current force calibration slope, in grams per ADC tick.
serial_codes.FORCE_SLOPE = 43535;                  %Set/report the current force calibration slope, in grams per ADC tick.
serial_codes.REQ_DIGPOT_BASELINE = 43536;          %Request the current force baseline-adjusting digital potentiometer setting.
serial_codes.DIGPOT_BASELINE = 43537;              %Set/report the current force baseline-adjusting digital potentiometer setting.

serial_codes.STEPS_PER_ROT = 43545;                %Set/report the number of steps per full revolution for the stepper motor.
serial_codes.REQ_STEPS_PER_ROT = 43546;            %Return the current number of steps per full revolution for the stepper motor.

serial_codes.MICROSTEP = 43550;                    %Set/report the microstepping multiplier.
serial_codes.REQ_MICROSTEP = 43551;                %Request the current microstepping multiplier.

serial_codes.NUM_PADS = 43560;                     %Set/report the number of texture positions on the carousel disc.
serial_codes.REQ_NUM_PADS = 43561;                 %Request the number of texture positions on the carousel disc.

serial_codes.CUR_PAD_I = 43570;                    %Set/report the current texture position index.
serial_codes.REQ_CUR_PAD_I = 43571;                %Return the current texture position index.
serial_codes.PAD_LABEL = 43572;                    %Set/report the current position label.
serial_codes.REQ_PAD_LABEL = 43573;                %Return the current position label.
serial_codes.ROTATE_CW = 43574;                    %Rotate one position clockwise (viewed from above).
serial_codes.ROTATE_CCW = 43575;                   %Rotate one position counter-clockwise (viewed from above).

serial_codes.VOLTAGE_IN = 43776;                   %Report the current input voltage to the device.
serial_codes.REQ_VOLTAGE_IN = 43777;               %Request the current input voltage to the device.
serial_codes.CURRENT_IN = 43778;                   %Report the current input current to the device, in milliamps.
serial_codes.REQ_CURRENT_IN = 43779;               %Request the current input current to the device, in milliamps.

serial_codes.COMM_VERIFY = 43981;                  %Verify use of the OTSC serial code library, responding to a REQ_COMM_VERIFY block.

serial_codes.PASSTHRU_DOWN = 48350;                %Route the immediately following block downstream to the specified port or VPB device.
serial_codes.PASSTHRU_UP = 48351;                  %Route the immediately following block upstream, typically to the controller or computer.
serial_codes.PASSTHRU_HOLD = 48352;                %Route all following blocks to the specified port or VPB device until the serial line is inactive for a set duration.
serial_codes.PASSTHRU_HOLD_DUR = 48353;            %Set/report the timeout duration for a passthrough hold, in milliseconds.
serial_codes.REQ_PASSTHRU_HOLD_DUR = 48354;        %Request the timeout duration for a passthrough hold, in milliseconds.

serial_codes.REQ_OTMP_IOUT = 48368;                %Request the OmniTrak Module Port (OTMP) output current for the specified port, in milliamps.
serial_codes.OTMP_IOUT = 48369;                    %Report the OmniTrak Module Port (OTMP) output current for the specified port, in milliamps.
serial_codes.REQ_OTMP_ACTIVE_PORTS = 48370;        %Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
serial_codes.OTMP_ACTIVE_PORTS = 48371;            %Report a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
serial_codes.REQ_OTMP_HIGH_VOLT = 48372;           %Request the current high voltage supply setting for the specified OmniTrak Module Port (0 = off <default>, 1 = high voltage enabled).
serial_codes.OTMP_HIGH_VOLT = 48373;               %Set/report the current high voltage supply setting for the specified OmniTrak Module Port (0 = off <default>, 1 = high voltage enabled).
serial_codes.REQ_OTMP_OVERCURRENT = 48374;         %Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.
serial_codes.OTMP_OTMP_OVERCURRENT = 48375;        %Report a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.

serial_codes.BROADCAST_OTMP = 48586;               %Route the immediately following block to all available OmniTrak Module Ports (RJ45 jacks).


%% ***********************************************************************
function device = Vulintus_Load_OTSC_Device_IDs

%	Vulintus_Load_OTSC_Device_IDs.m
%
%	Vulintus, Inc.
%
%	OmniTrak Serial Communication (OTSC) library.
%
%	OTSC device IDs.
%
%	Library documentation:
%	https://github.com/Vulintus/OmniTrak_Serial_Communication
%
%	This function was programmatically generated: 2024-06-11, 03:37:21 (UTC)
%

device = struct([]);

device(1).sku = 'HT-TH';
device(1).name = 'HabiTrak Thermal Activity Tracker';
device(1).id = 5;

device(2).sku = 'MT-AP';
device(2).name = 'MotoTrak Autopositioner';
device(2).id = 21;

device(3).sku = 'MT-HL';
device(3).name = 'MotoTrak Haptic Lever Module';
device(3).id = 6;

device(4).sku = 'MT-HS';
device(4).name = 'MotoTrak Haptic Supination Module';
device(4).id = 3;

device(5).sku = 'MT-IP';
device(5).name = 'MotoTrak Isometric Pull Module (MT-IP)';
device(5).id = 17;

device(6).sku = 'MT-LP';
device(6).name = 'MotoTrak Lever Press Module';
device(6).id = 4;

device(7).sku = 'MT-PC';
device(7).name = 'MotoTrak Pellet Carousel Module';
device(7).id = 11;

device(8).sku = 'MT-PP';
device(8).name = 'MotoTrak Pellet Pedestal Module';
device(8).id = 20;

device(9).sku = 'MT-PS';
device(9).name = 'MotoTrak Passive Supination Module';
device(9).id = 2;

device(10).sku = 'MT-SQ';
device(10).name = 'MotoTrak Squeeze Module';
device(10).id = 13;

device(11).sku = 'MT-WR';
device(11).name = 'MotoTrak Water Reach Module';
device(11).id = 10;

device(12).sku = 'OT-3P';
device(12).name = 'OmniTrak Three-Nosepoke Module';
device(12).id = 19;

device(13).sku = 'OT-CC';
device(13).name = 'OmniTrak Common Controller';
device(13).id = 1;

device(14).sku = 'OT-LR';
device(14).name = 'OmniTrak Liquid Receiver Module';
device(14).id = 9;

device(15).sku = 'OT-NP';
device(15).name = 'OmniTrak Nosepoke Module';
device(15).id = 7;

device(16).sku = 'OT-OA';
device(16).name = 'OmniTrak Overhead Auditory Module';
device(16).id = 16;

device(17).sku = 'OT-PD';
device(17).name = 'OmniTrak Pocket Door Module';
device(17).id = 22;

device(18).sku = 'OT-PR';
device(18).name = 'OmniTrak Pellet Receiver Module';
device(18).id = 8;

device(19).sku = 'OT-TH';
device(19).name = 'OmniTrak Thermal Activity Tracking Module';
device(19).id = 18;

device(20).sku = 'PB-LA';
device(20).name = 'VPB Linear Autopositioner';
device(20).id = 26;

device(21).sku = 'PB-LD';
device(21).name = 'VPB Liquid Dispenser';
device(21).id = 23;

device(22).sku = 'PB-PD';
device(22).name = 'VPB Pellet Dispenser';
device(22).id = 24;

device(23).sku = 'ST-AP';
device(23).name = 'SensiTrak Arm Proprioception Module';
device(23).id = 15;

device(24).sku = 'ST-TC';
device(24).name = 'SensiTrak Tactile Carousel Module';
device(24).id = 14;

device(25).sku = 'ST-VT';
device(25).name = 'SensiTrak Vibrotactile Module';
device(25).id = 12;

device(26).sku = 'XN-RI';
device(26).name = 'XNerve Replay IMU';
device(26).id = 25;


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Cage_Light_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Cage_Light_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_CAGE_LIGHT_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which can control overhead cage lights.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'OT-3P',...
                'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'light')                                            %If there's a "light" field in the control structure...
            ctrl = rmfield(ctrl,'light');                                   %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Overhead cage light functions.
ctrl.light = [];                                                            %Create a field to hold overhead cage light functions.

%Turn on/off the overhead cage light.
ctrl.light.on = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CAGE_LIGHT_ON,...
    varargin{:});                                  
ctrl.light.off = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CAGE_LIGHT_OFF,...
    varargin{:});

%Request/set the RGBW values for the overhead cage light (0-255).
ctrl.light.rgbw.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CAGE_LIGHT_RGBW,...
    'reply',{4,'uint8'},...
    varargin{:});               
ctrl.light.rgbw.set = ...
    @(rgbw,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CAGE_LIGHT_RGBW,...
    'data',{rgbw,'uint8'},...
    varargin{:});

%Request/set the overhead cage light duration, in milliseconds.
ctrl.light.dur.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CAGE_LIGHT_DUR,...
    'reply',{1,'uint16'},...
    varargin{:});           
ctrl.light.dur.set = ...
    @(dur,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CAGE_LIGHT_DUR,...
    'data',{dur,'uint16'},...
    varargin{:});

    


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Common_Functions(ctrl, otsc_codes)

%Vulintus_OTSC_Common_Functions.m - Vulintus, Inc., 2022
%
%   VULINTUS_OTSC_COMMON_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to a function structure for control of 
%   Vulintus OmniTrak devices over the serial line.
%   
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2022-02-25 - Drew Sloan - Function first created, adapted from
%                             MotoTrak_Controller_V2pX_Serial_Functions.m.
%   2022-05-24 - Drew Sloan - Added a 'verbose' output option to the
%                             "read_stream" function.
%   2023-09-27 - Drew Sloan - Merged the OTSC protocol into the OmniTrak
%                             Serial Communication (OTSC) protocol and
%                             changed this function name from 
%                             "OTSC_Common_Serial_Functions" to
%                             "Vulintus_OTSC_Common_Functions".
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.
vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".


%Serial line management functions.
ctrl.otsc = [];                                                             %Create a field to hold OTSC functions.

%Clear the serial line.
ctrl.otsc.clear = vulintus_serial.flush;    

%Close and delete the serial connection.
ctrl.otsc.close = ...
    @()Vulintus_Serial_Close(serialcon,otsc_codes.STREAM_ENABLE);           

%Verify OTSC communication.
ctrl.otsc.verify = ...
    @(varargin)Vulintus_Serial_Comm_Verification(serialcon,...
    otsc_codes.REQ_COMM_VERIFY,...
    otsc_codes.COMM_VERIFY,...
    varargin{:});         


%Device information functions.
ctrl.device = [];                                                           %Create a field to hold device info.

%Request the device ID number.
ctrl.device.id = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_DEVICE_ID,...
    'reply',{1,'uint16'},...
    varargin{:});                

%Request the firmware filename, upload date, or upload time.
ctrl.device.firmware.filename = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_FW_FILENAME,...
    'reply',{NaN,'char'}, ...
    varargin{:});                
ctrl.device.firmware.date = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_FW_DATE,...
    'reply',{NaN,'char'},...
    varargin{:});                          
ctrl.device.firmware.time = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_FW_TIME,...
    'reply',{NaN,'char'},...
    varargin{:});

%Request the device microcontroller unique ID number.
ctrl.device.mcu_serialnum = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_MCU_SERIALNUM,...
    'reply',{NaN,'uint8'},...
    varargin{:});                    

%Request/set the user-set device alias.
ctrl.device.alias.userset.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_USERSET_ALIAS,...
    'reply',{NaN,'char'},...
    varargin{:});    
ctrl.device.alias.userset.set = ...
    @(alias,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.USERSET_ALIAS,...
    'data',{length(alias),'uint8'; alias,'char'},...
    varargin{:}); 
                 
%Request/set the Vulintus alias (adjective/noun serial number) for the device.
ctrl.device.alias.vulintus.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_VULINTUS_ALIAS,...
    'reply',{NaN,'char'},...
    varargin{:});          
ctrl.device.alias.vulintus.set = ...
    @(alias,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.VULINTUS_ALIAS,...
    'data',{length(alias),'uint8'; alias,'char'},...
    varargin{:});
          

%Streaming control functions.
ctrl.stream = [];                                                           %Create a field to hold streaming functions.

%Enable/disable streaming from the device.
ctrl.stream.enable = ...
    @(enable,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.STREAM_ENABLE,...
    'data',{enable,'uint8'},...
    varargin{:});                            

%Request/set the current streaming period, in microseconds.
ctrl.stream.period.set = ...
    @(period,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.STREAM_PERIOD,...
    'data',{period,'uint32'},...
    varargin{:});
ctrl.stream.period.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_STREAM_PERIOD,...
    'reply',{1,'uint32'},...
    varargin{:});              

%Read in any streaming data.
ctrl.stream.read = @(varargin)Vulintus_Serial_Read_Stream(serialcon,...
    otsc_codes,varargin{:});                                                


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Cue_Light_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Cue_Light_Functions.m - Vulintus, Inc., 2023
%
%   VULINTUS_OTSC_CUE_LIGHT_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have cue light capabilities.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-03 - Drew Sloan - Function first created.
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2024-01-31 - Drew Sloan - Added optional input arguments for
%                             passthrough commands.
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%                             Changed the function name from 
%                             "Vulintus_OTSC_Light_Functions" to
%                             "Vulintus_OTSC_Cue_Light_Functions".
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'MT-PP',...
                'OT-3P',...
                'OT-NP',...
                'OT-PR',...
                'OT-LR'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'cue')                                              %If there's a "cue" field in the control structure...
            ctrl = rmfield(ctrl,'cue');                                     %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Cue light functions.
ctrl.cue = [];                                                              %Create a field to hold cue light functions.

%Show the specified cue light.
ctrl.cue.on = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_ON,...
    'data',{i,'uint8'},...
    varargin{:});                         

%Turn off any active cue light.
ctrl.cue.off = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_OFF,...
    varargin{:});         

%Request/set the current cue light index.
ctrl.cue.index.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CUE_LIGHT_INDEX,...
    'reply',{1,'uint8'},...
    varargin{:});             
ctrl.cue.index.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_INDEX,...
    'data',{i,'uint8'},...
    varargin{:});

%Request/set the current cue light queue index.
ctrl.cue.queue_index.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CUE_LIGHT_QUEUE_INDEX,...
    'reply',{1,'uint8'},...
    varargin{:});   
ctrl.cue.queue_index.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_QUEUE_INDEX,...
    'data',{i,'uint8'},...
    varargin{:});

%Request/set the RGBW values for the current cue light (0-255).
ctrl.cue.rgbw.get =...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CUE_LIGHT_RGBW,...
    'reply',{4,'uint8'},...
    varargin{:});       
ctrl.cue.rgbw.set = ...
    @(rgbw,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_RGBW,...
    'data',{rgbw,'uint8'},...
    varargin{:});

%Request/set the current cue light duration, in milliseconds.
ctrl.cue.dur.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_CUE_LIGHT_DUR,...
    'reply',{1,'uint16'},...
    varargin{:});         
ctrl.cue.dur.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUE_LIGHT_DUR,...
    'data',{i,'uint16'},...
    varargin{:});

     


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Dispenser_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Dispenser_Functions.m - Vulintus, Inc., 2022
%
%   VULINTUS_OTSC_DISPENSER_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to a function structure for control of 
%   Vulintus OmniTrak devices over the serial line. These functions are 
%   designed to be used with the "serialport" object introduced in MATLAB 
%   R2019b and will not work with the older "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'MT-PP','OT-3P','OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'feed')                                             %If there's a "feed" field in the control structure...
            ctrl = rmfield(ctrl,'feed');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Pellet/liquid dispenser control functions.
ctrl.feed = [];                                                             %Create a field to hold feeder functions.

%Trigger dispensing on the currently-selected dispenser.
ctrl.feed.start = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TRIGGER_FEEDER,...
    varargin{:});                         

%Immediately shut off any active dispensing trigger.
ctrl.feed.stop = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.STOP_FEED,...
    varargin{:});                                                  

%Request/set the current dispenser index.
ctrl.feed.cur_feeder.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_CUR_FEEDER,...
    'reply',{1,'uint8'},...
    varargin{:});      
ctrl.feed.cur_feeder.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.CUR_FEEDER,...
    'data',{i,'uint8'},...
    varargin{:});                                                 

%Request/set the current dispenser trigger duration, in milliseconds.
ctrl.feed.trig_dur.get = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_FEED_TRIG_DUR,...
    'reply',{1,'uint16'},...
    varargin{:});
ctrl.feed.trig_dur.set = @(dur)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.FEED_TRIG_DUR,...
    'data',{dur,'uint16'},...
    varargin{:});


%% ***********************************************************************
function ctrl = Vulintus_OTSC_IR_Detector_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_IR_Detector_Functions.m - Vulintus, Inc., 2023
%
%   VULINTUS_OTSC_IR_Detector_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have IR detector sensors.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2024-01-31 - Drew Sloan - Added optional input arguments for
%                             passthrough commands.
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%                           - Renamed script from
%                             "Vulintus_OTSC_Nosepoke_Functions" to 
%                             "Vulintus_OTSC_IR_Detector_Functions".
%


%List the Vulintus devices that use these functions.
device_list = { 'MT-PP',...
                'OT-3P',...
                'OT-NP',...
                'OT-PR',...
                'OT-LR'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'irdet')                                            %If there's a "ir" field in the control structure...
            ctrl = rmfield(ctrl,'irdet');                                   %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%IR detecto status functions.
ctrl.irdet = [];                                                            %Create a field to hold IR detector functions.

%Request the current IR detector status bitmask.
ctrl.irdet.bits = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_BITMASK,...
    'reply',{1,'uint32'; 1,'uint8'},...
    varargin{:});                                               

%Request the current IR detector analog reading.
ctrl.irdet.adc = ...
   @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_ADC,...
   'reply',{1, 'uint32'; 1,'uint16'},...
   'timestamp',...
   varargin{:});        

%Request the minimum and maximum ADC values of the IR detector sensor history, in ADC ticks.
ctrl.irdet.minmax = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_MINMAX,...
    'reply',{2,'uint16'},...
    varargin{:});                                                           

%Request/set the current IR detector threshold setting, normalized from 0 to 1.
ctrl.irdet.thresh_fl.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_THRESH_FL,...
    'reply',{1,'single'},...
    varargin{:});                                                           
ctrl.irdet.thresh_fl.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.POKE_THRESH_FL,...
    'data',{thresh,'single'},...
    varargin{:});

%Request/set the current IR detector auto-threshold setting, in ADC ticks.
ctrl.irdet.thresh_adc.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_THRESH_ADC,...
    'reply',{1,'uint16'},...
    varargin{:});                                                           
ctrl.irdet.thresh_adc.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.POKE_THRESH_ADC,...
    'data',{thresh,'uint16'},...
    varargin{:});

%Request/set the current IR detector auto-thresholding setting (0 = fixed, 1 = autoset).
ctrl.irdet.auto_thresh.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_POKE_THRESH_AUTO,...
    'reply',{1,'uint8'},...
    varargin{:});                                                           
ctrl.irdet.auto_thresh.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.POKE_THRESH_AUTO,...
    'data',{i,'uint8'},...
    varargin{:});


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Lick_Sensor_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Lick_Sensor_Functions.m - Vulintus, Inc., 2023
%
%   VULINTUS_OTSC_LICK_SENSOR_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have lick detection sensors.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-05-09 - Drew Sloan - Function first created, adapted from
%                             "Vulintus_OTSC_Nosepoke_Functions.m".
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'OT-3P'};


%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'lick')                                             %If there's a "lick" field in the control structure...
            ctrl = rmfield(ctrl,'lick');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Lick sensor status functions.
ctrl.lick = [];                                                             %Create a field to hold lick sensor functions.

%Request the current lick sensor status bitmask.
ctrl.lick.bits = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_BITMASK,...
    'reply',{1, 'uint32'; 1,'uint8'},...
    varargin{:});     

%Request the current lick sensor capacitance reading.
ctrl.lick.cap = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_CAP,...
    'reply',{1,'uint32'; 1,'uint16'},...
    varargin{:});        

%Request the minimum and maximum capacitance values of the lick sensor capacitance history.
ctrl.lick.minmax = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_MINMAX,...
    'reply',{2,'uint16'},...
    varargin{:});                 

%Request/set the current lick sensor threshold setting, normalized from 0 to 1.
ctrl.lick.thresh_fl.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_THRESH_FL,...
    'reply',{1,'single'},...
    varargin{:});     
ctrl.lick.thresh_fl.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.LICK_THRESH_FL, ...
    'data',{thresh,'single'},...
    varargin{:});

%Request/set the current lick sensor auto-threshold setting.
ctrl.lick.thresh_cap.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_THRESH_CAP,...
    'reply',{1,'uint16'},...
    varargin{:});    
ctrl.lick.thresh_cap.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.LICK_THRESH_CAP,...
    'data',{thresh,'uint16'},...
    varargin{:});

%Request/set the current lick sensor auto-thresholding setting (0 = fixed, 1 = autoset).
ctrl.lick.auto_thresh.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_LICK_THRESH_AUTO,...
    'reply',{1,'uint8'},...
    varargin{:});      
ctrl.lick.auto_thresh.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.LICK_THRESH_AUTO,...
    'data',{i,'uint8'},...
    varargin{:});

%Request/set the current lick sensor reset timeout duration, in milliseconds (0 = no time-out reset).
ctrl.lick.reset_timeout.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.OTSC_REQ_LICK_RESET_TIMEOUT,...
    'reply',{1,'uint16'},...
    varargin{:});    
ctrl.lick.reset_timeout.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.OTSC_LICK_RESET_TIMEOUT,...
    'data',{thresh,'uint16'},...
    varargin{:});

 


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Linear_Motion_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Linear_Motion_Functions.m - Vulintus, Inc., 2023
%
%   VULINTUS_OTSC_LINEAR_MOTION_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have linear motion capabilities, i.e. stepper 
%   motors and actuators.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-02-02 - Drew Sloan - Function first created.
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-04 - Drew Sloan - Renamed script from
%                             "Vulintus_OTSC_Movement_Functions.m" to
%                             "Vulintus_OTSC_Linear_Motion_Functions.m".
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'MT-PP','OT-PD','PB-LA','ST-AP'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'move')                                             %If there's a "move" field in the control structure...
            ctrl = rmfield(ctrl,'move');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.get_

%Module linear motion functions.
ctrl.move = [];                                                             %Create a field to hold linear motion functions.

%Initiate the homing routine on the module. 
ctrl.move.rehome = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MODULE_REHOME,...
    varargin{:});                                  

%Retract the module movement to its starting or base position. 
ctrl.move.retract = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MODULE_RETRACT,...
    varargin{:});                                 

%Request the current position of the module movement, in millimeters.
ctrl.move.cur_position = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_CUR_POS_MM,...
    'reply',{1,'single'},...
    varargin{:});                                                           

%Request/set the current target position of a module movement, in millimeters.
ctrl.move.target.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_TARGET_POS_MM,...
    'reply',{1,'single'},...
    varargin{:});                                                           
ctrl.move.target.set = ...
    @(target_in_mm,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TARGET_POS_MM,...
    'data',{target_in_mm,'single'},...
    varargin{:});

%Request/set the current minimum position of a module movement, in millimeters.
ctrl.move.min_position.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MIN_POS_MM,...
    'reply',{1,'single'},...
    varargin{:});                                                           
ctrl.move.min_position.set = ...
    @(pos_in_mm,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MIN_POS_MM,...
    'data',{pos_in_mm,'single'},...
    varargin{:});

%Request/set the current maximum position of a module movement, in millimeters.
ctrl.move.max_position.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MAX_POS_MM,...
    'reply',{1,'single'},...
    varargin{:});      
ctrl.move.max_position.set = ...
    @(pos_in_mm,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MAX_POS_MM,...
    'data',{pos_in_mm,'single'},...
    varargin{:});

%Request/set the current minimum speed, in millimeters/second.
ctrl.move.min_speed.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MIN_SPEED_MM_S,...
    'reply',{1,'single'},...
    varargin{:});                                                           
ctrl.move.min_speed.set = ...
    @(speed_in_mmps,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MIN_SPEED_MM_S,...
    'data',{speed_in_mmps,'single'},...
    varargin{:});

%Request/set the current maximum speed, in millimeters/second.
ctrl.move.max_speed.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MAX_SPEED_MM_S,...
    'reply',{1,'single'},...
    varargin{:});   
ctrl.move.max_speed.set = ...
    @(speed_in_mmps,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MAX_SPEED_MM_S,...
    'data',{speed_in_mmps,'single'},...
    varargin{:});

%Request/set the current movement acceleration, in millimeters/second^2.
ctrl.move.acceleration.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_ACCEL_MM_S2,...
    'reply',{1,'single'},...
    varargin{:});
ctrl.move.acceleration.set = ...
    @(accel_in_mmps2,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.ACCEL_MM_S2,...
    'data',{accel_in_mmps2,'single'},...
    varargin{:});


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Memory_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Memory_Functions.m - Vulintus, Inc., 2022
%
%   VULINTUS_OTSC_MEMORY_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have non-volatile memory.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2023-01-30 - Drew Sloan - Renamed function from
%                             "Vulintus_OTSC_EEPROM_Functions.m" to
%                             "Vulintus_OTSC_Memory_Functions.m".
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'OT-3P',...
                'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'nvm')                                              %If there's a "nvm" field in the control structure...
            ctrl = rmfield(ctrl,'nvm');                                     %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Non-volatile memory functions.
ctrl.nvm = [];                                                              %Create a field to hold non-volatile memory functions.

%Request the device's non-volatile memory size.
ctrl.nvm.get_size = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_NVM_SIZE,...
    'reply',{1,'uint32'},...
    varargin{:});             

%Read/write bytes to non-volatile memory.
ctrl.nvm.read = ...
    @(addr,N,type)Vulintus_Serial_EEPROM_Read(serialcon,...
    otsc_codes.WRITE_TO_NVM,addr,N,type);
ctrl.nvm.write = ...
    @(addr,data,type)Vulintus_Serial_EEPROM_Write(serialcon,...
    otsc_codes.WRITE_TO_NVM,addr,data,type);                                


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Motor_Setup_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Motor_Setup_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_MOTOR_SETUP_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have motors with configurable control parameters
%   i.e. coil current, microstepping, etc.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-04 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'MT-PP',...
                'OT-PD',...
                'ST-TC',...
                'ST-AP'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'motor')                                            %If there's a "motor" field in the control structure...
            ctrl = rmfield(ctrl,'motor');                                   %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Motor setup functions.
ctrl.motor = [];                                                            %Create a field to hold motor setup functions.

%Request/set the current motor current setting, in milliamps.
ctrl.motor.current.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MOTOR_CURRENT,...
    'reply',{1,'uint16'},...
    varargin{:});                                                           
ctrl.motor.current.set = ...
    @(current_in_mA,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MOTOR_CURRENT,...
    'data',{current_in_mA,'uint16'},...
    varargin{:});

%Request/set the maximum possible motor current setting, in milliamps.
ctrl.motor.current_max.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MAX_MOTOR_CURRENT,...
    'reply',{1,'uint16'},...
    varargin{:});                                                           
ctrl.motor.current_max.set = ...
    @(current_in_mA,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MAX_MOTOR_CURRENT,...
    'data',{current_in_mA,'uint16'},...
    varargin{:});


%% ***********************************************************************
function ctrl = Vulintus_OTSC_OTMP_Monitoring_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_OTMP_Monitoring_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_OTMP_MONITORING_FUNCTIONS defines and adds OmniTrak 
%   Serial Communication (OTSC) functions to the control structure for 
%   Vulintus OmniTrak devices which have downstream-facing OmniTrak Module 
%   Port (OTMP) connections. As of June 2024, this only applies to the
%   OmniTrak Common Controller (OT-CC).
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'otmp')                                             %If there's a "otmp" field in the control structure...
            ctrl = rmfield(ctrl,'otmp');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%OmniTrak Module Port (OTMP) monitoring functions.
ctrl.otmp = [];

%Request the OmniTrak Module Port (OTMP) output current for the specified port.
ctrl.otmp.iout = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_IOUT,...
    'data',{otmp_index,'uint8'},...
    'reply',{1,'uint8'; 1,'single'},...
    varargin{:});                                                           

%Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
ctrl.otmp.active = ...
    @(varargin)Vulintus_OTSC_OTMP_Monitoring_Active_Ports(serialcon,...
	otsc_codes.REQ_OTMP_ACTIVE_PORTS,...
    varargin{:});    

%Request/set the specified OmniTrak Module Port (OTMP) high voltage supply setting (0 = off <default>, 1 = high voltage
ctrl.otmp.high_volt.get = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_HIGH_VOLT,...
    'data',{otmp_index,'uint8'},...
    'reply',{2,'uint8'},...
    varargin{:});
ctrl.otmp.high_volt.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.POKE_THRESH_FL,...
    'data',{thresh,'single'},...
    varargin{:});

%Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.
ctrl.otmp.overcurrent = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_OVERCURRENT,...
    'reply',{1,'uint8'},...
    varargin{:});


%Request the OmniTrak Module Port (OTMP) output current for the specified port.
function active_ports = Vulintus_OTSC_OTMP_Monitoring_Active_Ports(serialcon,code,varargin)
otmp_bitmask = Vulintus_OTSC_Transaction(serialcon,...
    code,...
    'reply',{2,'uint8'},...
    varargin{:});
active_ports = bitget(otmp_bitmask(2),1:otmp_bitmask(1));


%% ***********************************************************************
function [pass_down_cmd, pass_up_cmd] = Vulintus_OTSC_Passthrough_Commands

%	Vulintus_OTSC_Passthrough_Commands.m
%
%	Vulintus, Inc.
%
%	OmniTrak Serial Communication (OTSC) library.
%	Simplified function for loading just the passthrough block codes.
%
%	Library documentation:
%	https://github.com/Vulintus/OmniTrak_Serial_Communication
%
%	This function was programmatically generated: 2024-06-11, 03:37:20 (UTC)
%

pass_down_cmd = 48350;		%Route the immediately following block downstream to the specified port or VPB device.
pass_up_cmd = 48351;		%Route the immediately following block upstream, typically to the controller or computer.


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Thermal_Image_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Thermal_Image_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_THERMAL_IMAGE_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have thermal imaging sensors.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'HT-TH'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'therm_im')                                         %If there's a "therm_im" field in the control structure...
            ctrl = rmfield(ctrl,'therm_im');                                %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Thermal imaging functions.
ctrl.therm_im = [];                                                         %Create a field to hold thermal imaging functions.

%Request the current thermal hotspot x-y position, in units of pixels.
ctrl.therm_im.hot_pix = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_XY_PIX,...
    'reply',{1, 'uint32'; 3,'uint8'; 1,'single'},...
    varargin{:});                                                           

%Request a thermal pixel image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
ctrl.therm_im.pixels_dk = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_PIXELS_INT_K,...
    'reply',{1, 'uint32', 3,'uint8'; 1024,'uint16'},...
    varargin{:});                                               

%Request a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius.
ctrl.therm_im.pixels_fp62 = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_PIXELS_FP62,...
    'reply',{1, 'uint32'; 1027,'uint8'},...
    varargin{:});                                               


%% ***********************************************************************
function ctrl = Vulintus_OTSC_Tone_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Tone_Functions.m - Vulintus, Inc., 2023
%
%   VULINTUS_OTSC_TONE_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have tone-playing capabilities.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-09-28 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2024-01-31 - Drew Sloan - Added optional input arguments for
%                             passthrough commands.
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'MT-PP',...
                'OT-3P',...
                'OT-CC',...
                'OT-NP',...
                'OT-PR',...
                'OT-LR',...
                'ST-AP'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'tone')                                             %If there's a "tone" field in the control structure...
            ctrl = rmfield(ctrl,'tone');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Tone functions.
ctrl.tone = [];                                                             %Create a subfield to hold tone functions.

%Play the specified tone.
ctrl.tone.on = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.PLAY_TONE,...
    'data',{i,'uint8'},...
    varargin{:});                            

%Stop any currently-playing tone.
ctrl.tone.off = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.STOP_TONE,...
    varargin{:});                                      

%Request/set the current tone index.
ctrl.tone.index.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_TONE_INDEX,...
    'reply',{1,'uint8'},...
    varargin{:});     
ctrl.tone.index.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TONE_INDEX,...
    'data',{i,'uint8'},...
    varargin{:});

%Request/set the current tone frequency.
ctrl.tone.freq.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_TONE_FREQ,...
    'reply',{1,'uint16'},...
    varargin{:});       
ctrl.tone.freq.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TONE_FREQ,...
    'data',{i,'uint16'},...
    varargin{:});

%Request/set the current tone duration.
ctrl.tone.dur.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_TONE_DUR,...
    'reply',{1,'uint16'},...
    varargin{:});         
ctrl.tone.dur.set = ...
    @(i,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TONE_DUR,...
    'data',{i,'uint16'},...
    varargin{:});

%Request/set the tone volume, normalized from 0 to 1.
ctrl.tone.volume.get =  ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_TONE_VOLUME,...
    'reply',{1,'single'},...
    varargin{:});  
ctrl.tone.volume.set = ...
    @(volume,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.TONE_VOLUME,...
    'data',{volume,'single'},...
    varargin{:});


%% ***********************************************************************
function varargout = Vulintus_OTSC_Transaction(serialcon,cmd,varargin)

%Vulintus_Serial_Request.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_TRANSACTION sends an OTSC code ("cmd") followed by any
%   specified accompanying data ("data"), and then can wait for a reply
%   consisting of a the specified number of values in the specified format 
%   ('int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'uint64',...
%   'single', or 'double'), unless no requested reply ("req") is expected 
%   or unless told not to wait ("nowait"). If the number of values in the
%   requested data is set to NaN, it will read the first byte of the reply
%   following the OTSC code use that value as the number of expected values
%   in the reply.
%
%   UPDATE LOG:
%   2024-06-07 - Drew Sloan - Consolidated "Vulintus_Serial_Send",
%                             "Vulintus_Serial_Request", and 
%                             "Vulintus_Serial_Request_Bytes" into a
%                             single function.
%


wait_for_reply = 1;                                                         %Wait for the reply by default.
passthrough = 0;                                                            %Assume this is not a passthrough command.
data = {};                                                                  %Assume that no code-folling data will be sent.
req = {};                                                                   %Assume that no reply will be requested.

i = 1;                                                                      %Initialize a input variable counter.
while i <= numel(varargin)                                                  %Step through all of the variable input arguments.  
    if ischar(varargin{i})                                                  %If the input is characters...
        switch lower(varargin{i})                                           %Switch between recognized arguments.
            case 'nowait'                                                   %If the user specified not to wait for the reply...
                wait_for_reply = 0;                                         %Don't wait for the reply.
                i = i + 1;                                                  %Increment the variable counter.
            case 'passthrough'                                              %If this is a passthrough command..
                passthrough = 1;                                            %Set the passthrough flag to 1.
                pass_target = varargin{i+1};                                %Grab the passthrough target.
                i = i + 2;                                                  %Increment the variable counter by two.
            case 'data'                                                     %If OTSC code-following data is specified...
                data = varargin{i+1};                                       %Grab the code-following data.
                i = i + 2;                                                  %Increment the variable counter by two.
            case 'reply'                                                    %If an expected reply is specified...
                req = varargin{i+1};                                        %Grab the requested data ounts and types.
                i = i + 2;                                                  %Increment the variable counter by two.
        end
    else                                                                    %Otherwise...
        error('ERROR IN %s: Unrecognized input type''%s''.',...
            upper(mfilename),class(varargin{i}));                           %Show an error.
    end
end

varargout = cell(1,size(req,1)+1);                                          %Create a cell array to hold the variable output arguments.

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".
type_size = @(data_type)Vulintus_Return_Data_Type_Size(data_type);          %Create a shortened pointer to the data type size toolbox functions.

if vulintus_serial.bytes_available() > 0 && wait_for_reply                  %If there's currently any data on the serial line.
    vulintus_serial.flush();                                                %Flush any existing bytes off the serial line.
end

if passthrough                                                              %If the passthrough command was included...
    [pass_down_cmd, pass_up_cmd] = Vulintus_OTSC_Passthrough_Commands;      %Grab the passthrough commands.
    data_N = 2;                                                             %Set the expected size of the data packet (start with 2 bytes for the OTSC code).
    for i = 1:size(data,1)                                                  %Step through each requested data type.
        byte_size = Vulintus_Return_Data_Type_Size(data{i,2});              %Grab the byte size of the data type.
        data_N = data_N + numel(data{i,1})*byte_size;                       %Add the number of expected bytes to the total.
    end
    vulintus_serial.write(pass_down_cmd,'uint16');                          %Write the fixed-length passthrough command.
    vulintus_serial.write(pass_target,'uint8');                             %Write the target port index and a zero to indicate the command comes from the computer.
    vulintus_serial.write(data_N,'uint8');                                  %Write the number of subsequent bytes to pass.
end

vulintus_serial.write(cmd,'uint16');                                        %Write the command to the serial line.
for i = 1:size(data,1)                                                      %Step through each row of the code-following data.
    vulintus_serial.write(data{i,1},data{i,2});                             %Write the data to the serial line.
end

if ~isempty(req) && wait_for_reply                                          %If we're waiting for the reply.

    req_N = 2;                                                              %Set the expected size of the data packet.
    reply_bytes = zeros(size(req,1));                                       %Create a matrix to hold the number of bytes for each requested type.
    for i = 1:size(req,1)                                                   %Step through each requested data type.
        if ~isnan(req{i,1})                                                 %If the number of requested elements isn't NaN...            
            byte_size = type_size(req{i,2});                                %Grab the byte size of the requested data type.
            reply_bytes(i) = req{i,1}*byte_size;                            %Set the number of bytes expected for this requested data type.
        else                                                                %Otherwise, if the number of elements is NaN.
           reply_bytes(i) = 1;                                              %Add one byte to the number expected data packet size.
        end
    end
    req_N = req_N + sum(reply_bytes);                                       %Sum the number of bytes for each requested data type.
    
    timeout = 1.0;                                                          %Set a one second time-out for the following loop.
    timeout_timer = tic;                                                    %Start a stopwatch.
    while toc(timeout_timer) < timeout && ...
            vulintus_serial.bytes_available() <  req_N                      %Loop for 1 seconds or until the expected reply shows up on the serial line.
        pause(0.005);                                                       %Pause for 5 milliseconds.
    end

    if vulintus_serial.bytes_available() < req_N                            %If there's not at least the expected number of bytes on the serial line...
        cprintf([1,0.5,0],['Vulintus_OTSC_Transaction Timeout! %1.0f '...
            'of %1.0f requested bytes returned.\n'],...
            vulintus_serial.bytes_available(), req_N);                      %Indicate a timeout occured.
        vulintus_serial.flush();                                            %Flush any remaining bytes off the serial line.
        return                                                              %Skip execution of the rest of the function.
    end

    if ~passthrough                                                         %If this wasn't a passthrough request...        

        code = vulintus_serial.read(1,'uint16');                            %Read in the unsigned 16-bit integer block code.
        req_N = req_N - 2;                                                  %Update the expected number of bytes in the data packet.
        for i = 1:size(req,1)                                               %Step through each requested data type.
            if isnan(req{i,1})                                              %If the number of requested elements is NaN...
                req{i,1} = vulintus_serial.read(1,'uint8');                 %Set the number of requested elements to the next byte.
                reply_bytes(i) = req{i,1}*type_size(req{i,2});              %Update the number of bytes expected for this data typ.
                req_N = req_N + reply_bytes(i) - 1;                         %Update the expected number of bytes in the data packet.
            end
            while toc(timeout_timer) < timeout && ...
                    vulintus_serial.bytes_available() < req_N               %Loop for 1 seconds or until the expected reply shows up on the serial line.
                pause(0.001);                                               %Pause for 1 millisecond.
            end
            if vulintus_serial.bytes_available() < req_N                    %If there's not at least the expected number of bytes on the serial line...       
                vulintus_serial.flush();                                    %Flush any remaining bytes off the serial line.
                return                                                      %Skip execution of the rest of the function.
            end
            if req{i,1} > 0                                                 %If a nonzero count is requested...
                varargout{i} = vulintus_serial.read(req{i,1},req{i,2});     %Read in the requested values as the specified data type.
            end
            req_N = req_N - reply_bytes(i);                                 %Upate the number of expected bytes in the data packet.
        end
        varargout{size(req,1)+1} = code;                                    %Return the reply OTSC code as the last output argument.

    else                                                                    %Otherwise, if this was a passthrough request...

        code = [];                                                          %Create an empty matrix to hold the reply OTSC code. 
        buffer = uint8(zeros(1,1024));                                      %Create a buffer to hold the received bytes.
        buff_i = 0;                                                         %Create a buffer index.
        read_N = 0;                                                         %Keep track of the number of bytes to read.
        i = 1;                                                              %Create a reply type index.
        timeout = 0.1;                                                      %Set a 100 millisecond time-out for the following loop.
        timeout_timer = tic;                                                %Start a stopwatch.        
        while toc(timeout_timer) < timeout && req_N > 0                     %Loop until the time-out duration has passed.

            if vulintus_serial.bytes_available()                            %If there's serial bytes available...
                if read_N                                                   %If there's still bytes to read...
                    n_bytes = vulintus_serial.bytes_available();            %Grab the number of bytes available on the serial line.
                    n_bytes = min(n_bytes, read_N);                         %Read in the smaller of the number of bytes available or the bytes remaining in the block.
                    if pass_source == pass_target                           %If these bytes come from the target.
                        buffer(buff_i + (1:n_bytes)) = ...
                            vulintus_serial.read(n_bytes,'uint8');          %Read in the bytes.
                        buff_i = buff_i + n_bytes;                          %Increment the buffer index.                                     
                    else                                                    %Otherwise...
                        vulintus_serial.read(n_bytes,'uint8');              %Read in and ignore the bytes.
                    end
                    read_N = read_N - n_bytes;                              %Decrement the bytes left to read.
                elseif vulintus_serial.bytes_available() >= 5               %Otherwise, if there's at least 5 bytes on the serial line...
                    passthru_code = vulintus_serial.read(1,'uint16');       %Read in the unsigned 16-bit integer block code.
                    if passthru_code ~= pass_up_cmd                         %If the block code isn't for an upstream passthrough...
                        vulintus_serial.flush();                            %Flush any remaining bytes off the serial line.
                        return                                              %Skip the rest of the function.
                    end
                    pass_source = vulintus_serial.read(1,'uint8');          %Read in the unsigned 8-bit source ID.
                    read_N = vulintus_serial.read(1,'uint16');              %Read in the unsigned 16-bit number of bytes.
                end
                timeout_timer = tic;                                        %Restart the stopwatch. 
            end

            if isempty(code)                                                %If the OTSC reply code hasn't been read yet...
                if buff_i >= 2                                              %If at least two bytes have been read into the buffer...
                    code = typecast(buffer(1:2),'uint16');                  %Read the reply OTSC from the buffer.
                    if buff_i > 2                                           %If there's more bytes left in the buffer.
                        buffer(1:buff_i-2) = buffer(3:buff_i);              %Shift the values in the buffer.
                    end
                    buff_i = buff_i - 2;                                    %Decrement the buffer index.
                    req_N = req_N - 2;                                      %Update the expected number of bytes in the data packet.
                end
            elseif isnan(req{i,1}) && buff_i >= 1                           %If the number of requested elements is NaN...
                req{i,1} = buffer(1);                                       %Set the number of requested elements to the next byte.                            
                reply_bytes(i) = req{i,1}*type_size(req{i,2});              %Update the number of bytes expected for this data typ.
                if buff_i > 1                                               %If there's more bytes left in the buffer.
                    buffer(1:buff_i-1) = buffer(2:buff_i);                  %Shift the values in the buffer.
                end
                buff_i = buff_i - 1;                                        %Decrement the buffer index.
                req_N = req_N + reply_bytes(i) - 1;                         %Update the expected number of bytes in the data packet.
            elseif buff_i >= reply_bytes(i) && req{i,1} > 0                 %If the buffer contains all of the next requested data type...
                if strcmpi(req{i,2},'char')                                 %If we're reading characters...
                    varargout{i} = ...
                        char(buffer(1:reply_bytes(i)));                     %Convert the bytes to characters.
                else                                                        %Otherwise...
                    varargout{i} = ...
                        typecast(buffer(1:reply_bytes(i)),...
                        req{i,2});                                          %Typecast the bytes from the buffer to the requested type.
                end
                if buff_i > reply_bytes(i)                                  %If there's more bytes left in the buffer.
                    buffer(1:buff_i-reply_bytes(i)) = ...
                        buffer(reply_bytes(i) + 1:buff_i);                  %Shift the values in the buffer.
                end
                buff_i = buff_i - reply_bytes(i);                           %Decrement the buffer index.
                req_N = req_N - reply_bytes(i);                             %Upate the number of expected bytes in the data packet.
                i = i + 1;                                                  %Increment the data type index.
            elseif req{i,1} == 0                                            %If zero bytes are being returned...
                i = i + 1;                                                  %Increment the data type index.
            end       

            pause(0.001);                                                   %Pause for 1 millisecond.
        end
        if req_N                                                            %If bytes were left unread...
            fprintf(1,'Vulintus_OTSC_Transaction Timeout!');                %Indicate a timeout occured.
        end
        varargout{size(req,1)+1} = code;                                    %Return the reply OTSC code as the last output argument.

    end

    vulintus_serial.flush();                                                %Flush any remaining bytes off the serial line.
end


%% ***********************************************************************
function ctrl = Vulintus_OTSC_WiFi_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_WiFi_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_WIFI_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices with integrated WiFi modules.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-01-30 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'HT-TH',...
                'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'wifi')                                             %If there's a "wifi" field in the control structure...
            ctrl = rmfield(ctrl,'wifi');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Controller status functions.
ctrl.wifi = [];                                                             %Create a field to hold WiFi functions.

%Request the device's MAC address.
ctrl.wifi.mac_addr = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_MAC_ADDR,...
    'reply',{1,'uint8'},...
    varargin{:});                    


%% ***********************************************************************
function vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon)

%Vulintus_Serial_Basic_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_SERIAL_BASIC_FUNCTIONS creates a function structure including
%   the basic read, write, bytes available, and flush functions for either 
%   a 'serialport' or 'serial' class object.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%


vulintus_serial = struct;                                                   %Create a structure.

switch class(serialcon)                                                     %Switch between the types of serial connections.

    case 'internal.Serialport'                                              %Newer serialport functions.
        vulintus_serial.bytes_available = @serialcon.NumBytesAvailable;     %Number of bytes available.
        vulintus_serial.flush = @(varargin)flush(serialcon,varargin{:});    %Buffer flush functions.
        vulintus_serial.read = ...
            @(count,datatype)read(serialcon,count,datatype);                %Read data from the serialport object.
        vulintus_serial.write = ...
            @(data,datatype)write(serialcon,data,datatype);                 %Write data to the serialport object.

    case 'serial'                                                           %Older, deprecated serial functions.
        vulintus_serial.bytes_available = @serialcon.BytesAvailable;        %Number of bytes available.
        vulintus_serial.flush = ...
            @()Vulintus_Serial_Basic_Functions_Flush_Serial(serialcon);     %Buffer flush functions.
        vulintus_serial.read = ...
            @(count,datatype)fread(serialcon,count,datatype);               %Read data from the serialport object.
        vulintus_serial.write = ...
            @(data,datatype)fwrite(serialcon,data,datatype);                %Write data to the serialport object.

end


function Vulintus_Serial_Basic_Functions_Flush_Serial(serialcon)
if serialcon.BytesAvailable                                                 %If there's currently any data on the serial line.
    fread(serialcon,serialcon.BytesAvailable);                              %Clear the input buffer.
end


%% ***********************************************************************
function Vulintus_Serial_Close(serialcon,stream_cmd)

%Vulintus_Serial_Close.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_CLOSE closes the specified serial connection,
%   performing all necessary housekeeping functions and then deleting the
%   objects.
%
%   UPDATE LOG:
%   02/25/2022 - Drew Sloan - Function first created.
%

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".
Vulintus_OTSC_Transaction(serialcon,...
    stream_cmd,...
    'data',{0,'uint8'});                                                    %Disable streaming on the device.
pause(0.01);                                                                %Pause for 10 milliseconds.
vulintus_serial.flush();                                                    %Clear the input buffers.
delete(serialcon);                                                          %Delete the serial object.


%% ***********************************************************************
function comm_check = Vulintus_Serial_Comm_Verification(serialcon,ver_cmd,ver_key,stream_cmd,varargin)

%Vulintus_Serial_Comm_Verification.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_COMM_VERIFICATION sends the communication verification
%   code and the verification key to the device connected through the
%   specified serial object, and checks for a matching reply.
%
%   UPDATE LOG:
%   2022-02-25 - Drew Sloan - Function first created.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


wait_for_reply = 1;                                                         %Wait for the reply by default.
msg_type = 'none';                                                          %Don't print waiting messages by default.
for i = 1:length(varargin)                                                  %Step through any optional input arguments.
    if ischar(varargin{i}) && strcmpi(varargin{i},'nowait')                 %If the user specified not to wait for the reply...
        wait_for_reply = 0;                                                 %Don't wait for the reply.
    elseif isstruct(varargin{i}) && strcmpi(varargin{i}.type,'big_waitbar') %If a big waitbar structure was passed...
        msg_handle = varargin{i};                                           %Set the message display handle to the structure.
        msg_type = 'big_waitbar';                                           %Set the message display type to "big_waitbar".
    elseif ishandle(varargin{i}) && isprop(varargin{i},'Type')              %If a graphics handles was passed.     
        msg_type = lower(varargin{i}.Type);                                 %Grab the object type.
        if strcmpi(varargin{i}.Type,'uicontrol')                            %If the object is a uicontrol...
            msg_type = lower(varargin{i}.Style);                            %Grab the uicontrol style.
        end
        msg_handle = varargin{i};                                           %Set the message display handle to the text object.
    end
end

comm_check = 0;                                                             %Assume the verification will fail by default.

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

if vulintus_serial.bytes_available() > 0 && wait_for_reply                  %If there's any data on the serial line and we're waiting for a reply...
    Vulintus_OTSC_Transaction(serialcon,stream_cmd,{0,'uint8'});          %Disable streaming on the device.
    timeout = datetime('now') + seconds(1);                                 %Set a time-out point for the following loop.
    while datetime('now') < timeout && ...
            vulintus_serial.bytes_available() > 0                           %Loop until all data is cleared off the serial line.        
        pause(0.05);                                                        %Pause for 50 milliseconds.
        vulintus_serial.flush();                                            %Flush any existing bytes off the serial line.
    end
end
vulintus_serial.write(ver_cmd,'uint16');                                    %Write the verification command.
    
if ~wait_for_reply                                                          %If we're not waiting for the reply.
    return                                                                  %Exit the function.
end

switch msg_type                                                             %Switch between the message display types.
    case 'text'                                                             %Text object on an axes.
        message = get(msg_handle,'string');                                 %Grab the current message in the text object.
        message(end+1) = '.';                                               %Add a period to the end of the message.
        set(msg_handle,'string',message);                                   %Update the message in the text label on the figure.
    case {'listbox','uitextarea'}                                           %UIControl messagebox.
        Append_Msg(msg_handle,'.');                                         %Add a period to the last message in the messagebox.
    case 'big_waitbar'                                                      %Vulintus' big waitbar.
        val = 1 - 0.9*(1 - msg_handle.value());                             %Calculate a new value for the waitbar.
        msg_handle.value(val);                                              %Update the waitbar value.
end

timeout_timer = tic;                                                        %Start a timeout timer.
while vulintus_serial.bytes_available() <= 2 && toc(timeout_timer) < 1.0    %Loop until a reply is received.
    pause(0.01);                                                            %Pause for 10 milliseconds.
end

if vulintus_serial.bytes_available() >= 2                                   %If there's at least 2 bytes on the serial line.
    ver_code = vulintus_serial.read(1,'uint16');                            %Read in 1 unsigned 16-bit integer.
    if ver_code == ver_key                                                  %If the value matches the verification code...
        comm_check = 1;                                                     %Set the OTSC communication flag to 1.
    end
end
vulintus_serial.flush();                                                    %Clear the input and output buffers.


%% ***********************************************************************
function [reply, code] = Vulintus_Serial_EEPROM_Read(serialcon,cmd,addr,N,datatype)

%Vulintus_Serial_EEPROM_Read.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_EEPROM_READ sends the EEPROM read request
%   command, followed by the target address and number of bytes to read.
%   The function will then read in the received bytes as the type specified
%   by the user.
%
%   UPDATE LOG:
%   2022-03-03 - Drew Sloan - Function first created, adapted from
%                             Vulintus_Serial_Request_uint32.m.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%

reply = [];                                                                 %Assume no reply values will be received by default.
code = 0;                                                                   %Assume no reply code will be received by default.

switch lower(datatype)                                                      %Switch between the available data types...
    case {'uint8','int8','char'}                                            %For 8-bit data types...
        bytes_per_val = 1;                                                  %The number of bytes is the size of the request.
    case {'uint16','int16'}                                                 %For 16-bit data types...
        bytes_per_val = 2;                                                  %The number of bytes is the 2x size of the request.
    case {'uint32','int32','single'}                                        %For 32-bit data types...
        bytes_per_val = 4;                                                  %The number of bytes is the 4x size of the request. 
    case {'double'}                                                         %For 64-bit data types...
        bytes_per_val = 8;                                                  %The number of bytes is the 8x size of the request.
end

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

if vulintus_serial.bytes_available() > 0                                    %If there's currently any data on the serial line.
    vulintus_serial.flush();                                                %Flush any existing bytes off the serial line.
end
vulintus_serial.write(cmd,'uint16');                                        %Write the command.
vulintus_serial.write(addr,'uint32');                                       %Write the EEPROM address.
vulintus_serial.write(N*bytes_per_val,'uint8');                             %Write the number of bytes to read back.
vulintus_serial.write(0,'uint8');                                           %Write a dummy byte to drive the Serial read loop on the device.
    
timeout_timer = tic;                                                        %Start a time-out timer.
while toc(timeout_timer) < 1 && ...
        vulintus_serial.bytes_available() < (2 + N*bytes_per_val)           %Loop for 1 second or until the expected reply shows up on the serial line.
    pause(0.01);                                                            %Pause for 10 milliseconds.
end
if vulintus_serial.bytes_available() >= 2                                   %If a block code was returned...
    code = vulintus_serial.read(1,'uint16');                                %Read in the unsigned 16-bit integer block code.
else                                                                        %Otherwise...
    return                                                                  %Skip execution of the rest of the function
end
N = floor(vulintus_serial.bytes_available()/bytes_per_val);                 %Set the number of values to read.
if N > 0                                                                    %If there's any integers on the serial line...        
    reply = vulintus_serial.read(N,datatype);                               %Read in the requested values as the specified type.
    reply = double(reply);                                                  %Convert the output type to double to play nice with comparisons in MATLAB.
end
vulintus_serial.flush();                                                    %Flush any remaining bytes off the serial line.


%% ***********************************************************************
function Vulintus_Serial_EEPROM_Write(serialcon,cmd,addr,data,type)

%Vulintus_Serial_EEPROM_Write.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_EEPROM_WRITE sends via serial, in order, the 
%       1) OTMP command to write bytes to the EEPROM,
%       2) target EEPROM address, followed by the,
%       3) number of bytes to write, and
%       4) bytes of the specified data, broken down by data type.
%
%   UPDATE LOG:
%   2022-03-03 - Drew Sloan - Function first created, adapted from
%                             Vulintus_OTSC_Transaction_uint32.m.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

vulintus_serial.write(cmd,'uint16');                                        %Write the EEPROM write command.
vulintus_serial.write(addr,'uint32');                                       %Write the target EEPROM address.
if isempty(data)                                                            %If no data was sent...
    vulintus_serial.write(0,'uint8');                                       %Send a zero for the number of following bytes.
else                                                                        %Otherwise, if data is to be sent...
    switch lower(type)                                                      %Switch between the available data types...
        case {'uint8','int8','char'}                                        %For 8-bit data types...
            N = numel(data);                                                %The number of bytes is the size of the array.
        case {'uint16','int16'}                                             %For 16-bit data types...
            N = 2*numel(data);                                              %The number of bytes is the 2x size of the array.
        case {'uint32','int32','single'}                                    %For 32-bit data types...
            N = 4*numel(data);                                              %The number of bytes is the 4x size of the array. 
        case {'double'}                                                     %For 64-bit data types...
            N = 8*numel(data);                                              %The number of bytes is the 8x size of the array.
    end
    vulintus_serial.write(data,type);                                       %Send the data as the specified type.
end


%% ***********************************************************************
function [ctrl, varargout] = Vulintus_Serial_Load_OTSC_Functions(ctrl, varargin)

%Vulintus_Serial_Load_OTSC_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_SERIAL_LOAD_OTSC_FUNCTIONS adds OmniTrak Serial Communication 
%   (OTSC) functions to the control structure for Vulintus devices using
%   the OTSC protocol.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%

varargout{1} = {};                                                          %Assume we will return zero device SKUs.

if nargin > 1                                                               %If the user passed the OTSC codes...
    otsc_codes = varargin{1};                                               %Grab the OTSC codes from the variable input arguments.
else                                                                        %Otherwise...
    otsc_codes = Vulintus_Load_OTSC_Codes;                                  %Load the OmniTrak Serial Communication (OTSC) codes.
end

device_list = Vulintus_Load_OTSC_Device_IDs;                                %Load the OTSC device list.
[device_id, code] = ctrl.device.id();                                       %Grab the OTSC device id.
if code ~= otsc_codes.DEVICE_ID || ...
        ~any(device_id == [device_list.id])                                 %If the return code was wrong or the device ID isn't recognized...
    ctrl.device.sku = [];                                                   %Set the device name to empty brackets in the structure.
else                                                                        %Otherwise, if the device was recognized...
    ctrl.device.sku = device_list(device_id == [device_list.id]).sku;       %Save the device SKU (4-character product code) to the structure.
    ctrl.device.name = device_list(device_id == [device_list.id]).name;     %Save the full device name to the structure.
end

devices = {ctrl.device.sku};                                                %Put the primary device SKU into a cell array.
ctrl = Vulintus_OTSC_OTMP_Monitoring_Functions(ctrl, otsc_codes, devices);  %OTMP-monitoring functions.
if isfield(ctrl,'otmp')                                                     %If this device has downstream-facing module ports...    
    active_ports = ctrl.otmp.active();                                      %Check which ports are active.    
    for i = 1:length(active_ports)                                          %Step through all of the ports.
        if active_ports(i)                                                  %If there's a device on this port.
            [device_id, code] = ctrl.device.id('passthrough',i);            %Grab the OTSC device id.            
            if isempty(device_id)                                           %If no code was returned.
                cprintf([1,0.5,0],['OmniTrak Module Port #%1.0f is '...
                    'drawing power, but not responding to OTSC '...
                    'communication!\n'],i);                                 %Indicate the port is not responding.
                ctrl.otmp.port(i).connected = -1;                           %Label the port as non-responding.
                ctrl.otmp.port(i).sku = [];                                 %Set the SKU field to empty.
            elseif code ~= otsc_codes.DEVICE_ID || ...
                    ~any(device_id == [device_list.id])                     %If the return code was wrong or the device ID isn't recognized...
                ctrl.otmp.port(i).sku = [];                                 %Set the device name to empty brackets in the structure.
            else                                                            %Otherwise, if the device was recognized...
                ctrl.otmp.port(i).sku = ...
                    device_list(device_id == [device_list.id]).sku;         %Save the device SKU (4-character product code) to the structure.
                ctrl.otmp.port(i).name = ...
                    device_list(device_id == [device_list.id]).name;        %Save the full device name to the structure.
            end
            ctrl.otmp.port(i).connected = 1;                                %Label the port as connected.
        else                                                                %Otherwise, if there's not device on this port.
            ctrl.otmp.port(i).connected = 0;                                %Label the port as disconnected
            ctrl.otmp.port(i).sku = [];                                     %Set the SKU field to empty.
        end
    end
    devices = horzcat(devices,{ctrl.otmp.port.sku});                        %Add the connected devices to the device SKU list.
    devices(cellfun(@isempty,devices)) = [];                                %Kick out the empty cells.
end

%Device-specific OTSC functions.
ctrl = Vulintus_OTSC_Cage_Light_Functions(ctrl, otsc_codes, devices);       %Overhead cage light functions.
ctrl = Vulintus_OTSC_Cue_Light_Functions(ctrl, otsc_codes, devices);        %Cue light functions.
ctrl = Vulintus_OTSC_Dispenser_Functions(ctrl, otsc_codes, devices);        %Pellet/liquid dispenser control functions.
ctrl = Vulintus_OTSC_Lick_Sensor_Functions(ctrl, otsc_codes, devices);      %Lick sensor functions.
ctrl = Vulintus_OTSC_Linear_Motion_Functions(ctrl, otsc_codes, devices);    %Module linear motion functions.
ctrl = Vulintus_OTSC_Memory_Functions(ctrl, otsc_codes, devices);           %Nonvolatile memory access functions.
ctrl = Vulintus_OTSC_Motor_Setup_Functions(ctrl, otsc_codes, devices);      %Motor setup functions.
ctrl = Vulintus_OTSC_IR_Detector_Functions(ctrl, otsc_codes, devices);      %IR detector functions.
ctrl = Vulintus_OTSC_Thermal_Image_Functions(ctrl, otsc_codes, devices);    %Thermal imaging functions.
ctrl = Vulintus_OTSC_Tone_Functions(ctrl, otsc_codes, devices);             %Tone-playing functions.  
ctrl = Vulintus_OTSC_WiFi_Functions(ctrl, otsc_codes, devices);             %WiFi functions.   

% ctrl = Vulintus_OTSC_STAP_Functions(ctrl, otsc_codes, devices);             %STAP-specific functions.
% ctrl = Vulintus_OTSC_STTC_Functions(ctrl, otsc_codes, devices);             %STTC-specific functions.

varargout{1} = devices;                                                     %Return a list of the connected devices.


%% ***********************************************************************
function [port_list, varargout] = Vulintus_Serial_Port_List(varargin)

%Vulintus_Serial_Port_List.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_LIST finds all connected serial port devices and
%   pairs the assigned COM port with device descriptions stored in the
%   system registry.
%
%   UPDATE LOG:
%   2021-11-29 - Drew Sloan - Function first created.
%   2024-02-27 - Drew Sloan - Branched the port matching file read
%                             functions into dedicated functions.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%

if datetime(version('-date')) > datetime('2019-09-17')                      %If the version is 2019b or newer...
    use_serialport = true;                                                  %Use the newer serialport functions by default.
else                                                                        %Otherwise...
    use_serialport = false;                                                 %Use the older serial functions by default.
end
if nargin > 0                                                               %If at least one input argument was included...
    use_serialport = varargin{1};                                           %Assume the serial function version setting was passed.
end

% List all active COM ports.
if use_serialport                                                           %If we're using the newer serialport functions...
    ports = serialportlist('all');                                          %Grab all serial ports.    
    available_ports = serialportlist('available');                          %Find all ports that are currently available.
else                                                                        %Otherwise, if we're using the older serial functions...
    ports = instrhwinfo('serial');                                          %Grab information about the available serial ports.
    available_ports = ports.AvailableSerialPorts;                           %Find all ports that are currently available.
    ports = ports.SerialPorts;                                              %Save the list of all serial ports regardless of whether they're busy.
end
port_list = cell(numel(ports),4);                                           %Create an N-by-4 cell array to hold port info.
if isempty(ports)                                                           %If no serial ports were found...
    port_list = {};                                                         %Set the function output to empty.
    return                                                                  %Skip execution of the rest of the function.
end

% Label ports as available or busy.
for i = 1:numel(ports)                                                      %Step through each port.
    port_list{i,1} = ports{i};                                              %Copy the port name to the first column of the list.
    if any(strcmpi(port_list{i,1},available_ports))                         %If the serial port is available...
        port_list{i,2} = 'available';                                       %List the port as available.
    else                                                                    %Otherwise...
        port_list{i,2} = 'busy';                                            %List the port as busy.
    end
end

% Grab the VID, PID, and device description for all known USB devices.
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';              %Set the registry query field.
[~, txt] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);     %Query the registry for all USB devices.
txt = textscan(txt,'%s','delimiter','\t');                                  %Parse the text by row.
txt = cat(1,txt{:});                                                        %Reshape the cell array into a vertical array.
dev_info = struct(  'description',  [],...
                    'alias',        [],...
                    'port',         [],...
                    'vid',          [],...
                    'pid',          []);                                    %Create a structure to hold device information.
dev_i = 0;                                                                  %Create a device counter.
for i = 1:length(txt)                                                       %Step through each entry.
    if startsWith(txt{i},key)                                               %If the line starts with the key.
        dev_i = dev_i + 1;                                                  %Increment the device counter.
        if contains(txt{i},'VID_')                                          %If this line includes a VID.
            j = strfind(txt{i},'VID_');                                     %Find the device VID.
            dev_info(dev_i).vid = txt{i}(j+4:j+7);                          %Grab the VID.
        end
        if contains(txt{i},'PID_')                                          %If this line includes a PID.
            j = strfind(txt{i},'PID_');                                     %Find the device PID.
            dev_info(dev_i).pid = txt{i}(j+4:j+7);                          %Grab the PID.
        end
        if contains(txt{i+1},'REG_SZ')                                      %If this line includes a device description.
            j = strfind(txt{i+1},'REG_SZ');                                 %Find the REG_SZ preceding the description on the following line.
            dev_info(dev_i).description = strtrim(txt{i+1}(j+7:end));       %Grab the port description.
        end
    end
end
keepers = zeros(length(dev_info),1);                                        %Create a matrix to mark devices for exclusion.
for i = 1:length(dev_info)                                                  %Step through each device.
    if contains(dev_info(i).description,'(COM')                             %If the description includes a COM port.
        j = strfind(dev_info(i).description,'(COM');                        %Find the start of the COM port number.
        dev_info(i).port = dev_info(i).description(j+1:end-1);              %Grab the COM port number.
        dev_info(i).description(j:end) = [];                                %Trim the port number off the description.
        dev_info(i).description = strtrim(dev_info(i).description);         %Trim off any leading or following spaces.
        keepers(i) = 1;                                                     %Mark the device for inclusion.
    end
end
dev_info(keepers == 0) = [];                                                %Kick out all non-COM devices.


% Check the VIDs and PIDs for Vulintus devices.
usb_pid_list = Vulintus_USB_VID_PID_List;                                   %Grab the list of USB VIDs and PIDs for Vulintus devices.
for i = 1:length(dev_info)                                                  %Step through each device.    
    a = strcmpi(dev_info(i).vid,usb_pid_list(:,1));                         %Find all Vulintus devices with this VID.
    b = strcmpi(dev_info(i).pid,usb_pid_list(:,2));                         %Find all Vulintus devices with this PID.
    if any(a & b)                                                           %If there's a match for both...
        dev_info(i).description = usb_pid_list{a & b, 3};                   %Replace the device description.
    end
end

% Check the port matching file for any user-set aliases.
pairing_info = Vulintus_Serial_Port_Matching_File_Read;                     %Read in the saved pairing info.
if ~isempty(pairing_info)                                                   %If any port-pairing information was found.
    for i = 1:length(dev_info)                                              %Step through each device.    
        a = strcmpi(dev_info(i).port,pairing_info(:,1));                    %Find any matches for this COM port.
        if any(a)                                                           %If there's a match...            
            dev_info(i).alias = pairing_info{a,3};                          %Set the device alias.
            if ~any(strcmpi(dev_info(i).description,usb_pid_list(:,3)))     %If the device descrciption wasn't set from the VID/PID...
                dev_info(i).description = pairing_info{a,2};                %Set the device description.
            end
        end
    end
end

% Pair each active port with it's device information.
for i = 1:size(port_list,1)                                                 %Step through each port.
    j = strcmpi({dev_info.port},port_list{i,1});                            %Find the port in the USB device list.    
    if any(j)                                                               %If a matching port was found...
        port_list{i,3} = dev_info(j).description;                           %Grab the port description.
        port_list{i,4} = dev_info(j).alias;                                 %Grab the device alias.
    elseif ~isempty(pairing_info)                                           %Otherwise...
        j = strcmpi(port_list{i,1}, pairing_info(:,1));                     %Check for matches in the saved pairing info.
        if any(j)                                                           %If there's pairing info for this COM port...
            port_list{i,3} = pairing_info{j,2};                             %Grab the port description.
            port_list{i,4} = pairing_info{j,3};                             %Grab the device alias.
            dev_info(end+1).port = port_list{i,1};                          %#ok<AGROW> %Add the COM port to the device list.
            dev_info(end).description = pairing_info{j,2};                  %Copy over the device description.
            dev_info(end).alias = pairing_info{j,3};                        %Copy over the userset alias.
        end
    end
end

% Set the output arguments.
varargout{1} = dev_info;                                                    %Return the device info (if requested).


%% ***********************************************************************
function pairing_info = Vulintus_Serial_Port_Matching_File_Read

%Vulintus_Serial_Port_Matching_File_Read.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_MATCHING_FILE_READ reads in the historical COM port
%   pairing information stored in the Vulintus Common Configuration AppData
%   folder.
%
%   UPDATE LOG:
%   2024-02-27 - Drew Sloan - Function first created, branched from
%                             Vulintus_Serial_Port_List.m.
%

config_path = Vulintus_Set_AppData_Path('Common Configuration');            %Grab the directory for common Vulintus task application data.
port_matching_file = fullfile(config_path,...
    'omnitrak_com_port_info_new.config');                                   %Set the filename for the port matching file.

if exist(port_matching_file,'file')                                         %If the port matching file exists...
    pairing_info = Vulintus_TSV_File_Read(port_matching_file);              %Read in the saved pairing info.
else                                                                        %Otherwise, if the port matching file doesn't exist...
    pairing_info = {};                                                      %Return an empty cell array.
end


%% ***********************************************************************
function Vulintus_Serial_Port_Matching_File_Update(com_port, device_name, alias)

%Vulintus_Serial_Port_Matching_File_Update.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_MATCHING_FILE_UPDATE updates the historical COM 
%   port pairing information stored in the Vulintus Common Configuration 
%   AppData folder with the currently-connected device information.
%
%   UPDATE LOG:
%   2024-02-27 - Drew Sloan - Function first created, branched from
%                             Vulintus_Serial_Port_List.m.
%

config_path = Vulintus_Set_AppData_Path('Common Configuration');            %Grab the directory for common Vulintus task application data.
port_matching_file = fullfile(config_path,...
    'omnitrak_com_port_info_new.config');                                   %Set the filename for the port matching file.

if exist(port_matching_file,'file')                                         %If the port matching file exists...
    pairing_info = Vulintus_TSV_File_Read(port_matching_file);              %Read in the saved pairing info.
else                                                                        %Otherwise, if the port matching file doesn't exist...
    pairing_info = {};                                                      %Return an empty cell array.
end

if ~isempty(pairing_info)                                                   %If the pairing info isn't empty...
    i = ~strcmpi(pairing_info(:,1), com_port) & ...
        strcmpi(pairing_info(:,3), alias);                                  %Check to see if this alias is matched with any other COM port
    pairing_info(i,:) = [];                                                 %Kick out the outdated pairings.   
    i = strcmpi(pairing_info(:,1), com_port);                               %Check to see if this COM port is already in the port matching file.
else                                                                        %Otherwise, if the pairing info is empty...
    i = 0;                                                                  %Set the index to zero.
end

if ~any(i)                                                                  %If the port isn't in the existing list.    
    i = size(pairing_info,1) + 1;                                           %Add a new row.
end
pairing_info(i,:) = {com_port, device_name, alias};                         %Add the device information to the list.

for i = 1:size(pairing_info,1)                                              %Step through each device.
    if isempty(pairing_info{i,3})                                           %If there is no alias...
        pairing_info{i,3} = char(255);                                      %Set the alias to "ÿ".
    end
end

pairing_info = sortrows(pairing_info,[3,1,2]);                              %Sort the pairing info by alias, then COM port, then device type.

for i = 1:size(pairing_info,1)                                              %Step through each device.
    if strcmpi(pairing_info{i,3},char(255))                                 %If the alias is set to "ÿ"...
        pairing_info{i,3} = [];                                             %Set the alias to empty brackets.
    end
end

Vulintus_TSV_File_Write(pairing_info, port_matching_file);                  %Write the pairing info back to the port matching file.


%% ***********************************************************************
function [data, block_i] = Vulintus_Serial_Read_Stream(serialcon,serial_codes,varargin)

%Vulintus_Serial_Read_Stream.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_READ_STREAM checks the serial line for any new
%   streaming data, and returns an data structure organizing any data
%   packets it finds.
%
%   UPDATE LOG:
%   03/03/2022 - Drew Sloan - Function first created.
%   05/24/2022 - Drew Sloan - Added a 'verbose' output option for debugging
%       purposes.
%   12/05/2022 - Camilo - added functionality for douple optical switch

verbose = 0;                                                                %Default to non-verbose output.
for i = 1:numel(varargin)                                                   %Step through all of the variable input arguments.
    switch lower(varargin{i})                                               %Switch between recognized arguments.
        case 'verbose'                                                      %Request verbose output.
            verbose = 1;                                                    %Set the verbose flag to 1.            
            all_codenames = fieldnames(serial_codes);                       %Grab all of the serial code names.
            all_codes = nan(size(all_codenames));                           %Create a matrix to hold all serial codes.
            for j = 1:numel(all_codes)                                      %Step through each code...            
                if isequal(all_codenames{j},upper(all_codenames{j}))        %If the fieldname is all uppercase...
                    all_codes(j) = serial_codes.(all_codenames{j});         %Grab the value for each serial code name.
                end
            end
            all_codenames(isnan(all_codes)) = [];                           %Kick out all non-code fields.
            all_codes(isnan(all_codes)) = [];                               %Kick out all NaN values.
    end
end

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

data = struct('type',[],'timestamp',[],'value',[]);                         %Assume no streaming data has been received.
block_i = 0;                                                                %Data block counter.
read_next = 1;                                                              %Boolean for ending a stream read leaving bytes on the serial line.

while (vulintus_serial.bytes_available() > 1) && (read_next)                %Loop for as long as there's two or more bytes available.
    
    if ~isempty(serialcon.UserData)                                         %If a block code was queued from a previous read.
        code = serialcon.UserData;                                          %Load the code.
        serialcon.UserData = [];                                            %Clear the queued block code from the serial object's UserData.
    else                                                                    %Otherwise...
        code = vulintus_serial.read(1,'uint16');                            %Read in the next unsigned 16-bit integer block code.
        
        if verbose == 1                                                     %If verbose debugging output is requested...
            fprintf(1,'%1.0f >> ', code);                                   %Print the code value.
            fprintf(1,'%s\n',...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes));                                             %Print the code name.
        end
        
    end
    
    block_i = block_i + 1;                                                  %Increment the block count.
    
    switch code                                                             %Switch between the recognized serial codes.
                
        case {  serial_codes.AP_ERROR,...
                }                                                           %Simple notifications.
            codename = ...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes);                                              %Match the codename.
            data(block_i).type = codename(6:end);                           %Save the packet type to the data structure.
            continue                                                        %Skip to the next block code.
            
        case {  serial_codes.ERROR_INDICATOR,...
                serial_codes.CENTER_OFFSET,...
                }                                                           %2-byte packet codes.
            packet_size = 2;                                                %Number of bytes in the associated packet.
            
        case {  serial_codes.MOVEMENT_START,...
                serial_codes.MOVEMENT_COMPLETE,...
                serial_codes.HOMING_COMPLETE,...
                serial_codes.RECENTER_COMPLETE,...                          % added by -cs
                serial_codes.FORCE_BASELINE,...
                serial_codes.FORCE_SLOPE,...
                }                                                           %4-byte packet codes.
            packet_size = 4;                                                %Number of bytes in the associated packet.
            
        case {  serial_codes.POKE_BITMASK,...
                serial_codes.LICK_BITMASK,...
                serial_codes.DISPENSE_FIRMWARE,...
             }                                                              %5-byte packet codes.
            packet_size = 5;                                                %Number of bytes in the associated packet.
            
%         case {  serial_codes.STAP_FORCE_VAL,...
%                 serial_codes.STTC_FORCE_VAL}                                %6-byte packet codes.
%             packet_size = 6;                                                %Number of bytes in the associated packet.

        case serial_codes.LICK_CAP
            packet_size = 8;                                                %Number of bytes in the associated packet.

        case serial_codes.THERM_XY_PIX
            packet_size = 9;                                                %Number of bytes in the associated packet.

        case serial_codes.THERM_PIXELS_FP62
            packet_size = 1031;                                             %Number of bytes in the associated packet.
            
        otherwise                                                           %Any unrecognized block code.
            codename = ...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes);                                              %Match the codename.
            if isempty(codename)                                            %If the code value isn't recognized at all...
                warning('%s - Unknown OTSC block code: %1.0f',...
                    upper(mfilename),code);                                 %Create the warning message. 
            elseif strcmpi(codename,'UNKNOWN_BLOCK_ERROR')                  %If the code was for an unknown block error...
                warning(['%s - Controller reported an unknown block ' ...
                    'error for OTSC block value 0x%X.'],...
                    upper(mfilename),...
                    vulintus_serial.read(1,'uint16'));                      %Create the warning message. 
            else                                                            %Otherwise...
                warning(['%s - Need to finish coding for packet'...
                    ' type ''%s''.'],upper(mfilename),codename);            %Create the warning message. 
            end                    
            flush(serialcon);                                               %Flush any remaining bytes off the serial line.
            continue                                                        %Skip to the next block code.
            
    end
    
    if vulintus_serial.bytes_available() >= packet_size                     %If the expected packet was received...
        
        switch code                                                         %Switch between the recognized serial codes.               
            
            case serial_codes.ERROR_INDICATOR                               %Error indicator.
                data(block_i).type = 'CC_ERROR_INDICATOR';                  %Label the packet as a error indicator.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer error code.
                
            case serial_codes.MOVEMENT_START                                %Timestamped movement start indicator.
                data(block_i).type = 'CC_MOVEMENT_START';                   %Label the packet as a movement start indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                
            case serial_codes.MOVEMENT_COMPLETE                             %Timestamped movement complete indicator.
                data(block_i).type = 'CC_MOVEMENT_COMPLETE';                %Label the packet as a movement complete indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                
            case serial_codes.HOMING_COMPLETE                               %Timestamped homing complete indicator.
                data(block_i).type = 'CC_HOMING_COMPLETE';                  %Label the packet as a homing complete indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.                
            
            case serial_codes.RECENTER_COMPLETE                             %Timestamped recenter complete indicator. -cs
                data(block_i).type = 'RECENTER_COMPLETE';                   %Label the packet as a recetner complete indicator. -cs
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');   

            case serial_codes.DISPENSE_FIRMWARE                             %Report that a feeding was automatically triggered in the device firmware.
                data(block_i).type = 'DISPENSE_FIRMWARE';                   %Label the packet as a dispenser timing.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the dispenser index.
                % fprintf(1,'DISPENSE_FIRMWARE\n');

            case serial_codes.THERM_PIXELS_FP62                             %Thermal pixel image as a fixed-point 6/2 type.
                data(block_i).type = 'THERM_PIXELS_FP62';                   %Label the packet as a thermal pixel image..
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = vulintus_serial.read(1027,'uint8');   %Read in the thermal image.

            case serial_codes.THERM_XY_PIX                                  %Current thermal hotspot x-y position, in units of pixels.
                data(block_i).type = 'THERM_XY_PIX';                        %Label the packet as a thermal pixel image..
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = [vulintus_serial.read(3,'uint8'),...
                    vulintus_serial.read(1,'single')];                      %Read in the hotspot data.

            case serial_codes.POKE_BITMASK                                  %Timestamped nosepoke value.
                data(block_i).type = 'POKE_BITMASK';                        %Label the packet as a nosepoke value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the unsigned 8-bit integer bitmask.            

            case serial_codes.LICK_BITMASK                                  %Timestamped lick sensor value.
                data(block_i).type = 'LICK_BITMASK';                        %Label the packet as a lick sensor value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the unsigned 8-bit integer bitmask.
                % fprintf(1,'LICK_BITMASK\n');

            case serial_codes.LICK_CAP                                      %Timestamped lick sensor value.
                data(block_i).type = 'LICK_CAP';                            %Label the packet as a nosepoke value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = [vulintus_serial.read(2,'uint8'),...
                    vulintus_serial.read(1,'uint16')];                      %Read in the unsigned 8-bit integer bitmask.
                % fprintf(1,'LICK_CAP\n');

            case serial_codes.FORCE_VAL                                     %Timestamped STTC force value.
                data(block_i).type = 'FORCE_VAL';                           %Label the packet as a force value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer ADC reading.
                
%             case serial_codes.FORCE_VAL                                     %Timestamped STAP force value.
%                 data(block_i).type = 'FORCE_VAL';                           %Label the packet as a force value.
%                 data(block_i).timestamp = ...
%                     vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
%                 data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer ADC reading.
                
            case serial_codes.FORCE_BASELINE                                %STAP force calibration baseline value.
                data(block_i).type = 'FORCE_BASELINE';                      %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
            case serial_codes.FORCE_SLOPE                                   %STAP force calibration slope value.
                data(block_i).type = 'FORCE_SLOPE';                         %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
%             case serial_codes.FORCE_BASELINE                                %STTC force calibration baseline value.
%                 data(block_i).type = 'FORCE_BASELINE';                      %Label the packet as a force value.
%                 data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
%                 
%             case serial_codes.FORCE_SLOPE                                   %STTC force calibration slope value.
%                 data(block_i).type = 'FORCE_SLOPE';                         %Label the packet as a force value.
%                 data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
            case serial_codes.CENTER_OFFSET                                 %STAP center offset calibration value.
                data(block_i).type = 'CENTER_OFFSET';                       %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the saved 16-bit unsigned integer offset value.
            
        end
    
    else                                                            %Otherwise, if the serial read timed out...
        serialcon.UserData = code;                                  %Save the block code for the next stream read call.
        block_i = block_i - 1;                                      %Decrement the block count.
        read_next = 0;                                              %Stop the stream read.
    end
end


function codename = Vulintus_Serial_Read_Stream_Match_Codename(code,serial_codes)
fields = fieldnames(serial_codes);                                          %Grab all of the field names.
values = struct2cell(serial_codes);                                         %Grab all of the values as a cell array.
values = cell2mat(values(4:end));                                           %Convert the cell array to a matrix.
i = find(code == values) + 3;                                               %Find the index matching the code.
if ~isempty(i)                                                              %If a match was found...
    codename = fields{i};                                                   %Return the fieldname.
else                                                                        %Otherwise...
    codename = [];                                                          %Return empty brackets.
end


%% ***********************************************************************
function port = Vulintus_Serial_Select_Port(use_serialport, varargin)

%Vulintus_Serial_Select_Port.m - Vulintus, Inc., 2021
%
%   VULINTUS_SERIAL_SELECT_PORT detects available serial ports for Vulintus
%   OmniTrak devices and compares them to serial ports previously 
%   identified as being connected to OmniTrak systems.
%
%   UPDATE LOG:
%   2021-09-14 - Drew Sloan - Function first created, adapted from
%                             MotoTrak_Select_Serial_Port.m.
%   2024-02-28 - Drew Sloan - Renamed function from
%                             "OmniTrak_Select_Serial_Port" to 
%                             "Vulintus_Serial_Select_Port".
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


port = [];                                                                  %Set the function output to empty by default.
spec_port = [];                                                             %Seth the specified port variable to empty brackets.
if nargin > 1                                                               %If an optional input argument was included...
    spec_port = varargin{1};                                                %Assume the input is a specified port number.    
end

dpc = get(0,'ScreenPixelsPerInch')/2.54;                                    %Grab the dots-per-centimeter of the screen.
set(0,'units','pixels');                                                    %Set the screensize units to pixels.
scrn = get(0,'ScreenSize');                                                 %Grab the screensize.
btn_w = 15*dpc;                                                             %Set the width for all buttons, in pixels.
lbl_w = 3*dpc;                                                              %Set the width for all available/busy labels.
ui_h = 1.2*dpc;                                                             %Set the height for all buttons, in pixels.
ui_sp = 0.1*dpc;                                                            %Set the spacing between UI components.
fig_w = 3*ui_sp + btn_w + lbl_w;                                            %Set the figure width.
btn_fontsize = 18;                                                          %Set the fontsize for buttons.
lbl_fontsize = 16;                                                          %Set the fontsize for labels.
ln_w = 2;                                                                   %Set the linewidth for labels.                    
    
while isempty(port)                                                         %Loop until a COM port is chosen.
    
    port_list = Vulintus_Serial_Port_List(use_serialport);                  %Find all COM ports and any associated ID information.

    if isempty(port_list)                                                   %If no OmniTrak devices were found...
        errordlg(['ERROR: No Vulintus OmniTrak devices were detected '...
            'on this computer!'],'No OmniTrak Devices!');                   %Show an error in a dialog box.
        return                                                              %Skip execution of the rest of the function.
    end
    
    if ~isempty(spec_port)                                                  %If a port was specified...
        i = strcmpi(port_list(:,1),spec_port);                              %Find the index for the specified port.
        if any(i)                                                           %If there's a match to any port in the list.
            if strcmpi(port_list{i,2},'available')                          %If the specified port is available...
                port = port_list{i,1};                                      %Return the specified port.
                return                                                      %Skip execution of the rest of the function.
            end
        end
        spec_port = [];                                                     %Otherwise, if the specified port isn't found or is busy, ignore the input.
    end

    if size(port_list,1) == 1 && strcmpi(port_list{1,2},'available')        %If there's only one COM port and it's available...
        port = port_list{1,1};                                              %Automatically select that port.
    else                                                                    %Otherwise, if no port was automatically chosen...
        fig_h = (size(port_list,1) + 1)*(ui_h + ui_sp) + ui_sp;             %Set the height of the port selection figure.
        fig = uifigure;                                                     %Create a UI figure.
        fig.Units = 'pixels';                                               %Set the units to pixels.
        fig.Position = [scrn(3)/2-fig_w/2, scrn(4)/2-fig_h/2,fig_w,fig_h];  %St the figure position
        fig.Resize = 'off';                                                 %Turn off figure resizing.
        fig.Name = 'Select A Serial Port';                                  %Set the figure name.
        [img, alpha_map] = Vulintus_Load_Vulintus_Logo_Circle_Social_48px;  %Use the Vulintus Social Logo for an icon.
        img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);            %Match the icon board to the figure.
        fig.Icon = img;                                                     %Set the figure icon.
        for i = 1:size(port_list,1)                                         %Step through each port.
            if isempty(port_list{i,4})                                      %If the system type is unknown...
                str = sprintf('  %s: %s', port_list{i,[1,3]});              %Show the port with just the system type included.                
            else                                                            %Otherwise...
                str = sprintf('  %s: %s (%s)', port_list{i,[1,3,4]});       %Show the port with the alias included.
            end
            x = ui_sp;                                                      %Set the x-coordinate for a button.
            y = fig_h-i*(ui_h+ui_sp);                                       %Set the y-coordinate for a button.
            temp_btn = uibutton(fig);                                       %Put a new UI button on the figure.
            temp_btn.Position = [x, y, btn_w, ui_h];                        %Set the button position.
            temp_btn.FontName = 'Arial';                                    %Set the font name.
            temp_btn.FontWeight = 'bold';                                   %Set the fontweight to bold.
            temp_btn.FontSize = btn_fontsize;                               %Set the fontsize.
            temp_btn.Text = str;                                            %Set the button text.
            temp_btn.HorizontalAlignment = 'left';                          %Align the text to the left.
            temp_btn.ButtonPushedFcn = {@OSSP_Button_press,fig,i};          %Set the button push callback.
            x = x + ui_sp + btn_w;                                          %Set the x-coordinate for a label.
            temp_ax = uiaxes(fig);                                          %Create temporary axes for making a pretty label.
            temp_ax.InnerPosition = [x, y, lbl_w, ui_h];                    %Set the axes position.
            temp_ax.XLim = [0, lbl_w];                                      %Set the x-axis limits.
            temp_ax.YLim = [0, ui_h];                                       %Set the y-axis limits.
            temp_ax.Visible = 'off';                                        %Make the axes invisible.
            temp_ax.Toolbar.Visible = 'off';                                %Make the toolbar invisible.
            temp_rect = rectangle(temp_ax);                                 %Create a rectangle in the axes.            
            temp_rect.Position = [ln_w/2, ln_w/2, lbl_w-ln_w, ui_h-ln_w];   %Set the rectangle position.
            temp_rect.Curvature = 0.5;                                      %Set the rectangle curvature.
            temp_rect.LineWidth = ln_w;                                     %Set the linewidth.
            if strcmpi(port_list{i,2},'available')                          %If the port is available...
                temp_rect.FaceColor = [0.75 1 0.75];                        %Color the label light green.
                temp_rect.EdgeColor = [0 0.5 0];                            %Color the edges dark green.
            else                                                            %Otherwise...
                temp_rect.FaceColor = [1 0.75 0.75];                        %Color the label light red.
                temp_rect.EdgeColor = [0.5 0 0];                            %Color the edges dark red.
            end
            temp_txt = text(temp_ax);                                       %Create text on the UI axes.
            temp_txt.String = upper(port_list{i,2});                        %Set the text string to show the port availability.            
            temp_txt.Position = [lbl_w/2, ui_h/2];                          %Set the text position.
            temp_txt.HorizontalAlignment = 'center';                        %Align the text to the center.
            temp_txt.VerticalAlignment = 'middle';                          %Align the text to the middle.
            temp_txt.FontName = 'Arial';                                    %Set the font name.
            temp_txt.FontWeight = 'normal';                                 %Set the fontweight to bold.
            temp_txt.FontSize = lbl_fontsize;                               %Set the fontsize.
        end
        x = ui_sp;                                                          %Set the x-coordinate for a button.
        y = ui_sp;                                                          %Set the y-coordinate for a button.
        temp_btn = uibutton(fig);                                           %Put a new UI button on the figure.
        temp_btn.Position = [x, y, btn_w + lbl_w + ui_sp, ui_h];            %Set the button position.
        temp_btn.FontName = 'Arial';                                        %Set the font name.
        temp_btn.FontWeight = 'bold';                                       %Set the fontweight to bold.
        temp_btn.FontSize = btn_fontsize;                                   %Set the fontsize.
        temp_btn.Text = 'Re-Scan Ports';                                    %Set the button text.
        temp_btn.HorizontalAlignment = 'center';                            %Align the text to the center.
        temp_btn.ButtonPushedFcn = {@OSSP_Button_press,fig,0};              %Set the button push callback.
        drawnow;                                                            %Immediately update the figure.
        uiwait(fig);                                                        %Wait for the user to push a button on the pop-up figure.
        if ishandle(fig)                                                    %If the user didn't close the figure without choosing a port...
            i = fig.UserData;                                               %Grab the selected port index.
            if i ~= 0                                                       %If the user didn't press "Re-Scan"...
                port = port_list{i,1};                                      %Set the selected port.
            end
            close(fig);                                                     %Close the figure.   
        else                                                                %Otherwise, if the user closed the figure without choosing a port...
           return                                                           %Skip execution of the rest of the function.
        end
    end
end


function OSSP_Button_press(~,~,fig,i)
fig.UserData = i;                                                           %Set the figure UserData property to the specified value.
uiresume(fig);                                                              %Resume execution.


%% ***********************************************************************
function Add_Msg(msgbox,new_msg)
%
%Add_Msg.m - Vulintus, Inc.
%
%   ADD_MSG displays messages in a listbox on a GUI, adding new messages to
%   the bottom of the list.
%
%   Add_Msg(listbox,new_msg) adds the string or cell array of strings
%   specified in the variable "new_msg" as the last entry or entries in the
%   ListBox or Text Area whose handle is specified by the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2016-09-09 - Drew Sloan - Fixed the bug caused by setting the
%                             ListboxTop property to an non-existent item.
%   2021-11-26 - Drew Sloan - Added the option to post status messages to a
%                             scrolling text area (uitextarea).
%   2022-02-02 - Drew Sloan - Fixed handling of the UIControl ListBox type
%                             to now use the "style" for identification.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

for gui_i = 1:length(msgbox)                                                %Step through each messagebox.

    switch get(msgbox(gui_i),'type')                                        %Switch between the recognized components.
        
        case 'uicontrol'                                                    %If the messagebox is a listbox...
            switch get(msgbox(gui_i),'style')                               %Switch between the recognized uicontrol styles.
                
                case 'listbox'                                              %If the messagebox is a listbox...
                    messages = get(msgbox(gui_i),'string');                 %Grab the current string in the messagebox.
                    if isempty(messages)                                    %If there's no messages yet in the messagebox...
                        messages = {};                                      %Create an empty cell array to hold messages.
                    elseif ~iscell(messages)                                %If the string property isn't yet a cell array...
                        messages = {messages};                              %Convert the messages to a cell array.
                    end
                    messages{end+1} = new_msg;                              %Add the new message to the listbox.
                    set(msgbox(gui_i),'string',messages);                   %Update the strings in the listbox.
                    set(msgbox(gui_i),'value',length(messages),...
                        'ListboxTop',length(messages));                     %Set the value of the listbox to the newest messages.
                    set(msgbox(gui_i),'min',0,...
                        'max',2',...
                        'selectionhighlight','off',...
                        'value',[]);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                    drawnow;                                                %Update the GUI.
                    
            end
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = msgbox(gui_i).Value;                                 %Grab the current strings in the messagebox.
            if ~iscell(messages)                                            %If the string property isn't yet a cell array...
                messages = {messages};                                      %Convert the messages to a cell array.
            end
            checker = 1;                                                    %Create a matrix to check for non-empty cells.
            for i = 1:numel(messages)                                       %Step through each message.
                if ~isempty(messages{i})                                    %If there any non-empty messages...
                    checker = 0;                                            %Set checker equal to zero.
                end
            end
            if checker == 1                                                 %If all messages were empty.
                messages = {};                                              %Set the messages to an empty cell array.
            end
            messages{end+1} = new_msg;                                      %Add the new message to the listbox.
            msgbox(gui_i).Value = messages;                                 %Update the strings in the Text Area.        
            drawnow;                                                        %Update the GUI.
            scroll(msgbox(gui_i),'bottom');                                 %Scroll to the bottom of the Text Area.
    end

end
        


%% ***********************************************************************
function Append_Msg(msgbox,new_txt)

%
%APPEND_MSG.m - Vulintus, Inc., 2023
%
%   APPEND_MSG displays messages in a listbox on a GUI, adding the 
%   specified text to the message at the bottom of the list.
%
%   Append_Msg(msgbox,new_txt) adds the text passed in the variable
%   "new_txt" to the last entry in the listbox or text area whose handle is
%   specified by the variable "msgbox".
%
%   UPDATE LOG:
%   2023-09-27 - Drew Sloan - Function first created, adapted from
%                             "Replace_Msg.m".
%

switch get(msgbox,'type')                                                   %Switch between the recognized components.
    
    case 'uicontrol'                                                        %If the messagebox is a listbox...
        switch get(msgbox,'style')                                          %Switch between the recognized uicontrol styles.
            
            case 'listbox'                                                  %If the messagebox is a listbox...
                messages = get(msgbox,'string');                            %Grab the current string in the messagebox.
                if isempty(messages)                                        %If there's no messages yet in the messagebox...
                    messages = {};                                          %Create an empty cell array to hold messages.
                elseif ~iscell(messages)                                    %If the string property isn't yet a cell array...
                    messages = {messages};                                  %Convert the messages to a cell array.
                end
                if iscell(new_txt)                                          %If the new message is a cell array...
                    new_txt = new_txt{1};                                   %Convert the first cell of the new message to characters.
                end
                messages{end} = horzcat(messages{end},new_txt);             %Add the new text to the end of the last message.
                set(msgbox,'string',messages);                              %Updat the list items.
                set(msgbox,'value',length(messages));                       %Set the value of the listbox to the newest messages.
                drawnow;                                                    %Update the GUI.
                a = get(msgbox,'listboxtop');                               %Grab the top-most value of the listbox.
                set(msgbox,'min',0,...
                    'max',2',...
                    'selectionhighlight','off',...
                    'value',[],...
                    'listboxtop',a);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                drawnow;                                                    %Update the GUI.
                
        end
        
    case 'uitextarea'                                                       %If the messagebox is a uitextarea...
        messages = msgbox.Value;                                            %Grab the current strings in the messagebox.
        if ~iscell(messages)                                                %If the string property isn't yet a cell array...
            messages = {messages};                                          %Convert the messages to a cell array.
        end
        checker = 1;                                                        %Create a matrix to check for non-empty cells.
        for i = 1:numel(messages)                                           %Step through each message.
            if ~isempty(messages{i})                                        %If there any non-empty messages...
                checker = 0;                                                %Set checker equal to zero.
            end
        end
        if checker == 1                                                     %If all messages were empty.
            messages = {};                                                  %Set the messages to an empty cell array.
        end
        if iscell(new_txt)                                                  %If the new message is a cell array...
            new_txt = new_txt{1};                                           %Convert the first cell of the new message to characters.
        end
        messages{end} = horzcat(messages{end},new_txt);                     %Add the new text to the end of the last message.
        msgbox.Value = messages';                                           %Update the strings in the Text Area.
        scroll(msgbox,'bottom');                                            %Scroll to the bottom of the Text Area.
        drawnow;                                                            %Update the GUI.
        
end


%% ***********************************************************************
function Clear_Msg(varargin)

%
%Clear_Msg.m - Vulintus, Inc.
%
%   CLEAR_MSG deleles all messages in a listbox on a GUI.
%
%   CLEAR_MSG(msgbox) or CLEAR_MSG(~,~,msgbox) clears all messages out of
%   the ListBox / uitextarea whose handle is specified in the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2013-01-24 - Drew Sloan - Function first created.
%   2021-11-26 - Drew Sloan - Added functionality to use scrolling text
%                             areas (uitextarea) as messageboxes.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

if nargin == 1                                                              %If there's only one input argument...
    msgbox = varargin{1};                                                   %The listbox handle is the first input argument.
elseif nargin == 3                                                          %Otherwise, if there's three input arguments...
    msgbox = varargin{3};                                                   %The listbox handle is the third input argument.
end

for i = 1:length(msgbox)                                                    %Step through each messagebox.

    if strcmpi(get(msgbox(1),'type'),'uicontrol')                           %If the messagebox is a uicontrol...
        msgbox_type = get(msgbox(1),'style');                               %Grab the style property.
    else                                                                    %Otherwise...
        msgbox_type = get(msgbox(1),'type');                                %Grab the type property.
    end
    
    switch msgbox_type                                                      %Switch between the recognized components.
        
        case 'listbox'                                                      %If the messagebox is a listbox...
            set(msgbox(1),'string',{},...
                'min',0,...
                'max',0',...
                'selectionhighlight','off',...
                'value',[]);                                                %Clear the messages and set the properties on the listbox to make it look like a simple messagebox.
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = {''};                                                %Create a cell array with one empty entry.
            msgbox(1).Value = messages;                                     %Update the strings in the Text Area.
            scroll(msgbox(1),'bottom');                                     %Scroll to the bottom of the Text Area.
            drawnow;                                                        %Update the GUI.
            
    end

end 


%% ***********************************************************************
function [data, structure] = Read_Google_Spreadsheet(url)

%
%Read_Google_Spreadsheet.m - Rennaker Lab, 2010
%
%   Read_Google_Spreadsheet reads in spreadsheet data from Google Documents
%   spreadsheets and returns the data as a 2-D cell array.  To use this
%   function, you must first publish the document as a webpage with Plain
%   Text (TXT) formatting.
%
%   data = Read_Google_Spreadsheet(url) reads the spreadsheet data from the
%   Google Document link specified by "url" and returns it in the cell
%   array "data".
%   
%   UPDATE LOG:
%   07/07/2014 - Drew Sloan - Removed string-formating checks to work
%       around Google Docs updates.
%   07/06/2016 - Drew Sloan - Replaced "urlread" with "webread" when the
%       function is run on MATLAB versions 2014b+.


%% Download the spreadsheet as a string.
v = version;                                                                %Grab the MATLAB version.
v = str2double(v(1:3));                                                     %Convert the first three characters of the version to a number.
options = weboptions('Timeout',10);                                         %Set the timeout duration to 10 seconds.
if v >= 8.4 || isdeployed                                                   %If the MATLAB version is 2014b or later, or is deployed compiled code...
    urldata = webread(url,options);                                         %Use the WEBREAD function to read in the data from the Google spreadsheet as a string.
else                                                                        %Otherwise, for earlier versions...
    urldata = urlread(url,options);                                         %Use the URLREAD function to read in the data from the Google spreadsheet as a string.
end


%% Convert the single string output from urlread into a cell array corresponding to cells in the spreadsheet.
tab = sprintf('\t');                                                        %Make a tab string for finding delimiters.
newline = sprintf('\n');                                                    %Make a new-line string for finding new lines.
a = find(urldata == tab | urldata == newline);                              %Find all delimiters in the string.
a = [0, a, length(urldata)+1];                                              %Add indices for the first and last elements of the string.
urldata = [urldata, newline];                                               %Add a new line to the end of the string to avoid confusing the spreadsheet-reading loop.
column = 1;                                                                 %Count across columns.
row = 1;                                                                    %Count down rows.
data = {};                                                                  %Make a cell array to hold the spreadsheet-formated data.
for i = 2:length(a)                                                         %Step through each entry in the string.
    if a(i) == a(i-1)+1                                                     %If there is no entry for this cell...
        data{row,column} = [];                                              %...assign an empty matrix.
    else                                                                    %Otherwise...
        data{row,column} = urldata((a(i-1)+1):(a(i)-1));                    %...read one entry from the string.
    end
    if urldata(a(i)) == tab                                                 %If the delimiter was a tab...
        column = column + 1;                                                %...advance the column count.
    else                                                                    %Otherwise, if the delimiter was a new-line...
        column = 1;                                                         %...reset the column count to 1...
        row = row + 1;                                                      %...and add one to the row count.
    end
end


%% Make a numeric matrix converting every cell to a number.
checker = zeros(size(data,1),size(data,2));                                 %Pre-allocate a matrix to hold boolean is-numeric checks.
numdata = nan(size(data,1),size(data,2));                                   %Pre-allocate a matrix to hold the numeric data.
for i = 1:size(data,1)                                                      %Step through each row.      
    for j = 1:size(data,2)                                                  %Step through each column.
        numdata(i,j) = str2double(data{i,j});                               %Convert the cell contents to a double-precision number.
        %If this cell's data is numeric, or if the cell is empty, or contains a placeholder like *, -, or NaN...
        if ~isnan(numdata(i,j)) || isempty(data{i,j}) ||...
                any(strcmpi(data{i,j},{'*','-','NaN'}))
            checker(i,j) = 1;                                               %Indicate that this cell has a numeric entry.
        end
    end
end
if all(checker(:))                                                          %If all the cells have numeric entries...
    data = numdata;                                                         %...save the data as a numeric matrix.
end


%% ***********************************************************************
function Replace_Msg(msgbox,new_msg)

%
%REPLACE_MSG.m - Rennaker Neural Engineering Lab, 2013
%
%   REPLACE_MSG displays messages in a listbox on a GUI, replacing messages
%   at the bottom of the list with new lines.
%
%   Replace_Msg(listbox,new_msg) replaces the last N entry or entries in
%   the listbox or text area whose handle is specified by the variable 
%   "msgbox" with the string or cell array of strings specified in the 
%   variable "new_msg".
%
%   UPDATE LOG:
%   2013-01-24 - Drew Sloan - Function first created.
%   2021-11-26 - Drew Sloan - Added functionality to use scrolling text
%                             areas (uitextarea) as messageboxes.
%

switch get(msgbox,'type')                                                   %Switch between the recognized components.
    
    case 'uicontrol'                                                        %If the messagebox is a listbox...
        switch get(msgbox,'style')                                          %Switch between the recognized uicontrol styles.
            
            case 'listbox'                                                  %If the messagebox is a listbox...
                messages = get(msgbox,'string');                            %Grab the current string in the messagebox.
                if isempty(messages)                                        %If there's no messages yet in the messagebox...
                    messages = {};                                          %Create an empty cell array to hold messages.
                elseif ~iscell(messages)                                    %If the string property isn't yet a cell array...
                    messages = {messages};                                  %Convert the messages to a cell array.
                end
                if ~iscell(new_msg)                                         %If the new message isn't a cell array...
                    new_msg = {new_msg};                                    %Convert the new message to a cell array.
                end
                messages(end+1-(1:length(new_msg))) = new_msg;              %Add the new message where the previous last message was.
                set(msgbox,'string',messages);                              %Show that the Arduino connection was successful on the messagebox.
                set(msgbox,'value',length(messages));                       %Set the value of the listbox to the newest messages.
                drawnow;                                                    %Update the GUI.
                a = get(msgbox,'listboxtop');                               %Grab the top-most value of the listbox.
                set(msgbox,'min',0,...
                    'max',2',...
                    'selectionhighlight','off',...
                    'value',[],...
                    'listboxtop',a);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                drawnow;                                                    %Update the GUI.
                
        end
        
    case 'uitextarea'                                                       %If the messagebox is a uitextarea...
        messages = msgbox.Value;                                            %Grab the current strings in the messagebox.
        if ~iscell(messages)                                                %If the string property isn't yet a cell array...
            messages = {messages};                                          %Convert the messages to a cell array.
        end
        checker = 1;                                                        %Create a matrix to check for non-empty cells.
        for i = 1:numel(messages)                                           %Step through each message.
            if ~isempty(messages{i})                                        %If there any non-empty messages...
                checker = 0;                                                %Set checker equal to zero.
            end
        end
        if checker == 1                                                     %If all messages were empty.
            messages = {};                                                  %Set the messages to an empty cell array.
        end
        if ~iscell(new_msg)                                                 %If the new message isn't a cell array...
            new_msg = {new_msg};                                            %Convert the new message to a cell array.
        end
        messages(end+1-(1:length(new_msg))) = new_msg;                      %Add the new message where the previous last message was.
        msgbox.Value = messages;                                            %Update the strings in the Text Area.
        scroll(msgbox,'bottom');                                            %Scroll to the bottom of the Text Area.
        drawnow;                                                            %Update the GUI.
        
end


%% ***********************************************************************
function toolbox_exists = Vulintus_Check_MATLAB_Toolboxes(toolbox, varargin)

%
%Vulintus_Check_MATLAB_Toolboxes.m - Vulintus, Inc.
%
%   This script checks the MATLAB installation for the specified required
%   toolbox and throws an error if it isn't found.
%   
%   UPDATE LOG:
%   2024-01-24 - Drew Sloan - Function first created.
%


if ~isdeployed                                                              %If the function is running as a script instead of deployed code...
    matproducts = ver;                                                      %Grab all of the installed MATLAB products.
    toolbox_exists = any(strcmpi({matproducts.Name},toolbox));              %Check to see if the toolbox is installed.
    if ~toolbox_exists                                                      %If the specified toolbox isn't installed...
        fcn = dbstack;                                                      %Grab the function call stack that led to this line.       
        str = sprintf(['"%s.m" requires the MATLAB %s, which is not '...
            'installed on your computer. You will need to install the '...
            'toolbox or run a compiled version of the program.'],...
            fcn(end).name, toolbox);                                        %Create the text for an error dialog.
        errordlg(str,'Missing Required MATLAB Toolbox');                    %Show an error dialog.
    end
else                                                                        %Otherise, if the function is compiled...
    toolbox_exists = 1;                                                     %Assume the toolbox exists.
end


%% ***********************************************************************
function target_struct = Vulintus_Copy_Subfield(target_struct, source_struct, src_fields)

%
%Vulintus_Copy_Subfield.m - Vulintus, Inc.
%
%   VULINTUS_COPY_SUBFIELD is a recursive function that copies a subfield
%   from "source_struct" to "target_struct", including all field branches.
%   
%   UPDATE LOG:
%   2024-03-08 - Drew Sloan - Function first created.
%


if isfield(source_struct,src_fields{1})                                     %If the first field exists in the source structure...
    if length(src_fields) == 1                                              %If this is the highest level specified...
        target_struct.(src_fields{1}) = source_struct.(src_fields{1});      %Copy the field to the target structure.
    else                                                                    %Otherwise...
        if ~isfield(target_struct,src_fields{1})                            %If the field doesn't exist on the target structure...
            target_struct.(src_fields{1}) = struct;                         %Initialize the field.
        end
        target_struct.(src_fields{1}) = ...
            Vulintus_Copy_Subfield(target_struct.(src_fields{1}),...
            source_struct.(src_fields{1}), src_fields(2:end));              %Recursively call this function to copy the next branch level.
    end
end


%% ***********************************************************************
function data = Vulintus_JSON_File_Read(file)

%
%Vulintus_JSON_File_Read.m - Vulintus, Inc.
%
%   VULINTUS_JSON_FILE_READ reads in data from a JSON-formatted text file.
%   
%   UPDATE LOG:
%   2023-06-08 - Drew Sloan - Function first created, adapted from
%                             "Vulintus_Read_TSV_File.m".
%   2024-03-08 - Drew Sloan - Renamed file from "Vulintus_Read_JSON_File"
%                             to "Vulintus_JSON_File_Read".
%

[fid, errmsg] = fopen(file,'rt');                                           %Open the stage configuration file saved previously for reading as text.
if fid == -1                                                                %If the file could not be opened...
    str = sprintf(['Could not read the specified JSON file:\n\n%s\n\n'...
        'Error:\n\n%s'],file,errmsg);                                       %Create a warning string.
    warndlg(str,'Vulintus_Read_JSON_File Error');                           %Show a warning.
    close(fid);                                                             %Close the file.
    data = [];                                                              %Set the output data variable to empty brackets.
    return                                                                  %Skip execution of the rest of the function.
end
txt = fread(fid,'*char')';                                                  %Read in the file data as text.
fclose(fid);                                                                %Close the configuration file.
if any(txt == '\')                                                          %If there's any forward slashes...    
    txt = strrep(txt,'\','\\');                                             %Replace all single forward slashes with two slashes.
    k = strfind(txt,'\\\');                                                 %Look for any triple forward slashes...
    txt(k) = [];                                                            %Kick out the extra forward slashes.
end
data = jsondecode(txt);                                                     %Convert the text to data.


%% ***********************************************************************
function Vulintus_JSON_File_Write(data,filename)

%
%Vulintus_JSON_File_Write.m - Vulintus, Inc.
%
%   VULINTUS_JSON_FILE_WRITE saves the elements of the variable "data" to
%   a JSON-formatted text file specified by "filename", with "data" being
%   any supported MATLAB data type.
%   
%   UPDATE LOG:
%   2023-06-08 - Drew Sloan - Function first created, adapted from
%                             "Vulintus_Write_TSV_File.m".
%   2024-03-08 - Drew Sloan - Added the "PrettyPrint" option to the
%                             "jsonencode" function.
%                             Renamed file from "Vulintus_Write_JSON_File"
%                             to "Vulintus_JSON_File_Write".
%


[fid, errmsg] = fopen(filename,'wt');                                       %Open a text-formatted configuration file to save the stage information.
if fid == -1                                                                %If a file could not be created...
    str = sprintf(['Could not create the specified JSON file:\n\n%s\n\n'...
        'Error:\n\n%s'],filename,errmsg);                                   %Create a warning string.
    warndlg(str,'Vulintus_Write_JSON_File Error');                          %Show a warning.
    return                                                                  %Skip execution of the rest of the function.
end
txt = jsonencode(data,PrettyPrint=true);                                    %Convert the data to JSON-formatted text.
if any(txt == '\')                                                          %If there's any forward slashes...    
    txt = strrep(txt,'\','\\');                                             %Replace all single forward slashes with two slashes.
    k = strfind(txt,'\\\');                                                 %Look for any triple forward slashes...
    txt(k) = [];                                                            %Kick out the extra forward slashes.
end
fprintf(fid,txt);                                                           %Write the text to the file.
fclose(fid);                                                                %Close the JSON file.    


%% ***********************************************************************
function target_struct = Vulintus_Merge_Structures(target_struct, source_struct)

%
%Vulintus_Merge_Structures.m - Vulintus, Inc.
%
%   VULINTUS_MERGE_STRUCTURES is a recursive function that takes all the 
%   fields from "source_struct" and copies them into "target_struct". If a 
%   field exists and isn't empty in both "target_struct" and 
%   "source_struct", the field in "target_struct" will be overwritten.
%   
%   UPDATE LOG:
%   2024-03-08 - Drew Sloan - Function first created.
%


src_fields = fieldnames(source_struct);                                     %Grab all of the field names from the source structure.
for f = 1:length(src_fields)                                                %Step through each field.    
    if isstruct(source_struct.(src_fields{f}))                              %If this field is a structure...
        if ~isfield(target_struct,src_fields{f})                            %If this field doesn't exist in the target structure...
            target_struct.(src_fields{f}) = struct;                         %Create an empty structure for the field.
        end
        target_struct.(src_fields{f}) = ...
            Vulintus_Merge_Structures(target_struct.(src_fields{f}),...
            source_struct.(src_fields{f}));                                 %Recursively call this function to handle all sub-fields.
    else                                                                    %Otherwise...
        if ~isfield(target_struct,src_fields{f}) || ...
                ~isempty(source_struct.(src_fields{f}))                     %If this field doesn't exist in the target structure...
            target_struct.(src_fields{f}) = source_struct.(src_fields{f});  %Copy the field.
        end
    end
end


%% ***********************************************************************
function timestamp = Vulintus_Placeholder_Check(placeholder_file, wait_time)

%
%Vulintus_Placeholder_Check.m - Vulintus, Inc.
%
%   VULINTUS_PLACEHOLDER_CHECK checks for a temporary placeholder file in
%   the specified location and then waits until the file is cleared or the
%   specified expiration time if a placeholder file is found.
%
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created.
%

timestamp = [];                                                             %Assume the timestamp will be empty by default.

if ~exist(placeholder_file,'file')                                          %If the placeholder file doesn't exist...
    return                                                                  %Skip the rest of the function.
end

fid = fopen(placeholder_file,'r');                                         %Open the placeholder file for reading.
timestamp = fread(fid,1,'float64');                                         %Read in the timestamp from the file.
fclose(fid);                                                                %Close the file.

if ~isempty(timestamp)                                                      %If a timestamp was found...
    timestamp = datetime(timestamp,'ConvertFrom','datenum');                %Convert the serial date number into the DateTime type.
    time_since_placeholder = seconds(datetime('now') - timestamp);          %Calculate the number of seconds since the placeholder was created.
    placeholder_timer = tic;                                                %Start a timer.
    while exist(placeholder_file,'file') && ...
            time_since_placeholder < wait_time && ...
            toc(placeholder_timer) < wait_time                              %Loop until the placeholder is deleted or the specified wait time has passed.
        pause(0.05);                                                        %Pause for 50 milliseconds.
    end
end

if exist(placeholder_file,'file')                                           %If the placeholder still exists...
    delete(placeholder_file);                                               %Delete the placeholder file.
end


%% ***********************************************************************
function timestamp = Vulintus_Placeholder_Set(placeholder_file)

%
%Vulintus_Placeholder_Set.m - Vulintus, Inc.
%
%   VULINTUS_PLACEHOLDER_SET creates a new placeholder file at the
%   specified location containing the file create time as a single 64-bit
%   timestamp in the serial date number format.
%
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created.
%

fid = fopen(placeholder_file,'w');                                          %Open the placeholder file for writing.
timestamp = datenum(datetime('now'));                                       %#ok<DATNM> %Grab the serial date number for the current 
fwrite(fid,timestamp,'float64');                                            %Write the timestamp to the file as a 64-bit floating point number.
fclose(fid);                                                                %Close the file.


%% ***********************************************************************
function n_bytes = Vulintus_Return_Data_Type_Size(data_type)

%Vulintus_Return_Data_Type_Size.m - Vulintus, Inc., 2024
%
%   VULINTUS_RETURN_DATA_TYPE_SIZE returns the size, in bytes, of a single
%   element of the classes specified by "data_type".
%
%   UPDATE LOG:
%   2024-06-07 - Drew Sloan - Function first created.
%

switch lower(data_type)                                                     %Switch between the available data types...
    case {'int8','uint8','char'}                                            %For 8-bit data types...
        n_bytes = 1;                                                        %The number of bytes is the size of the request.
    case {'int16','uint16'}                                                 %For 16-bit data types...
        n_bytes = 2;                                                        %The number of bytes is the 2x size of the request.
    case {'int32','uint32','single'}                                        %For 32-bit data types...
        n_bytes = 4;                                                        %The number of bytes is the 4x size of the request. 
    case {'uint64','double'}                                                %For 64-bit data types...
        n_bytes = 8;                                                        %The number of bytes is the 8x size of the request.
    otherwise                                                               %For any unrecognized classes.
        error('ERROR IN %s: Unrecognized variable class "%s"',...
            upper(mfilename),data_type);                                    %Show an error.
end     


%% ***********************************************************************
function data = Vulintus_TSV_File_Read(file)

%
%Vulintus_TSV_File_Read.m - Vulintus, Inc.
%
%   VULINTUS_TSV_FILE_READ reads in data from a spreadsheet-formated TSV
%   file.
%   
%   UPDATE LOG:
%   2016-09-12 - Drew Sloan - Moved the TSV-reading code from
%                             Vulintus_Read_Stages.m to this function.
%   2016-09-13 - Drew Sloan - Generalized the MotoTrak TSV-reading program
%                             to also work with OmniTrak and future
%                             behavior programs.
%   2022-04-26 - Drew sloan - Replaced "sprintf('\n')" with MATLAB's
%                             built-in "newline" function.
%   2024-05-06 - Drew Sloan - Renamed from "Vulintus_Read_TSV_File" to 
%                             "Vulintus_TSV_File_Read".
%


[fid, errmsg] = fopen(file,'rt');                                           %Open the stage configuration file saved previously for reading as text.
if fid == -1                                                                %If the file could not be opened...
    warndlg(sprintf(['Could not open the stage file '...
        'in:\n\n%s\n\nError:\n\n%s'],file,...
        errmsg),'Vulintus File Read Error');                                %Show a warning.
    close(fid);                                                             %Close the file.
    data = [];                                                              %Set the output data variable to empty brackets.
    return                                                                  %Return to the calling function.
end
txt = fread(fid,'*char')';                                                  %Read in the file data as text.
fclose(fid);                                                                %Close the configuration file.
tab = sprintf('\t');                                                        %Make a tab string for finding delimiters.
a = find(txt == tab | txt == newline);                                      %Find all delimiters in the string.
a = [0, a, length(txt)+1];                                                  %Add indices for the first and last elements of the string.
txt = [txt, newline];                                                       %Add a new line to the end of the string to avoid confusing the spreadsheet-reading loop.
column = 1;                                                                 %Count across columns.
row = 1;                                                                    %Count down rows.
data = {};                                                                  %Make a cell array to hold the spreadsheet-formated data.
for i = 2:length(a)                                                         %Step through each entry in the string.
    if a(i) == a(i-1)+1                                                     %If there is no entry for this cell...
        data{row,column} = [];                                              %...assign an empty matrix.
    else                                                                    %Otherwise...
        data{row,column} = txt((a(i-1)+1):(a(i)-1));                        %...read one entry from the string.
    end
    if txt(a(i)) == tab                                                     %If the delimiter was a tab or a comma...
        column = column + 1;                                                %...advance the column count.
    else                                                                    %Otherwise, if the delimiter was a new-line...
        column = 1;                                                         %...reset the column count to 1...
        row = row + 1;                                                      %...and add one to the row count.
    end
end


%% ***********************************************************************
function Vulintus_TSV_File_Write(data,filename)

%
%Vulintus_TSV_File_Write.m - Vulintus, Inc.
%
%   VULINTUS_TSV_FILE_WRITE saves the elements of the cell array "data" in
%   a TSV-formatted spreadsheet specified by "filename".
%   
%   UPDATE LOG:
%   2016-09-13 - Drew Sloan - Generalized the MotoTrak TSV-writing program
%                             to also work with OmniTrak and future 
%                             behavior programs.
%   2024-05-06 - Drew Sloan - Renamed from "Vulintus_Write_TSV_File" to 
%                             "Vulintus_TSV_File_Write".
%


[fid, errmsg] = fopen(filename,'wt');                                       %Open a text-formatted configuration file to save the stage information.
if fid == -1                                                                %If a file could not be created...
    warndlg(sprintf(['Could not create stage file backup '...
        'in:\n\n%s\n\nError:\n\n%s'],filename,...
        errmsg),'OmniTrak File Write Error');                               %Show a warning.
end
for i = 1:size(data,1)                                                      %Step through the rows of the stage data.
    for j = 1:size(data,2)                                                  %Step through the columns of the stage data.
        data{i,j}(data{i,j} < 32) = [];                                     %Kick out all special characters.
        fprintf(fid,'%s',data{i,j});                                        %Write each element of the stage data as tab-separated values.
        if j < size(data,2)                                                 %If this isn't the end of a row...
            fprintf(fid,'\t');                                              %Write a tab to the file.
        elseif i < size(data,1)                                             %Otherwise, if this isn't the last row...
            fprintf(fid,'\n');                                              %Write a carriage return to the file.
        end
    end
end
fclose(fid);                                                                %Close the stages TSV file.    


%% ***********************************************************************
function waitbar = big_waitbar(varargin)

figsize = [2,16];                                                           %Set the default figure size, in centimeters.
barcolor = 'b';                                                             %Set the default waitbar color.
titlestr = 'Waiting...';                                                    %Set the default waitbar title.
txtstr = 'Waiting...';                                                      %Set the default waitbar string.
val = 0;                                                                    %Set the default value of the waitbar to zero.

str = {'FigureSize','Color','Title','String','Value'};                      %List the allowable parameter names.
for i = 1:2:length(varargin)                                                %Step through any optional input arguments.
    if ~ischar(varargin{i}) || ~any(strcmpi(varargin{i},str))               %If the first optional input argument isn't one of the expected property names...
        beep;                                                               %Play the Matlab warning noise.
        cprintf('red','%s\n',['ERROR IN BIG_WAITBAR: Property '...
            'name not recognized! Optional input properties are:']);        %Show an error.
        for j = 1:length(str)                                               %Step through each allowable parameter name.
            cprintf('red','\t%s\n',str{j});                                 %List each parameter name in the command window, in red.
        end
        return                                                              %Skip execution of the rest of the function.
    else                                                                    %Otherwise...
        if strcmpi(varargin{i},'FigureSize')                                %If the optional input property is "FigureSize"...
            figsize = varargin{i+1};                                        %Set the figure size to that specified, in centimeters.            
        elseif strcmpi(varargin{i},'Color')                                 %If the optional input property is "Color"...
            barcolor = varargin{i+1};                                       %Set the waitbar color the specified color.
        elseif strcmpi(varargin{i},'Title')                                 %If the optional input property is "Title"...
            titlestr = varargin{i+1};                                       %Set the waitbar figure title to the specified string.
        elseif strcmpi(varargin{i},'String')                                %If the optional input property is "String"...
            txtstr = varargin{i+1};                                         %Set the waitbar text to the specified string.
        elseif strcmpi(varargin{i},'Value')                                 %If the optional input property is "Value"...
            val = varargin{i+1};                                            %Set the waitbar value to the specified value.
        end
    end    
end

orig_units = get(0,'units');                                                %Grab the current system units.
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'Screensize');                                                  %Grab the screensize.
h = figsize(1);                                                             %Set the height of the figure.
w = figsize(2);                                                             %Set the width of the figure.
fig = figure('numbertitle','off',...
    'name',titlestr,...
    'units','centimeters',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h],...
    'menubar','none',...
    'resize','off');                                                        %Create a figure centered in the screen.
ax = axes('units','centimeters',...
    'position',[0.25,0.25,w-0.5,h/2-0.3],...
    'parent',fig);                                                          %Create axes for showing loading progress.
if val > 1                                                                  %If the specified value is greater than 1...
    val = 1;                                                                %Set the value to 1.
elseif val < 0                                                              %If the specified value is less than 0...
    val = 0;                                                                %Set the value to 0.
end    
obj = fill(val*[0 1 1 0 0],[0 0 1 1 0],barcolor,'edgecolor','k');           %Create a fill object to show loading progress.
set(ax,'xtick',[],'ytick',[],'box','on','xlim',[0,1],'ylim',[0,1]);         %Set the axis limits and ticks.
txt = uicontrol(fig,'style','text','units','centimeters',...
    'position',[0.25,h/2+0.05,w-0.5,h/2-0.3],'fontsize',10,...
    'horizontalalignment','left','backgroundcolor',get(fig,'color'),...
    'string',txtstr);                                                       %Create a text object to show the current point in the wait process.  
set(0,'units',orig_units);                                                  %Set the system units back to the original units.

waitbar.type = 'big_waitbar';                                               %Set the structure type.
waitbar.title = @(str)SetTitle(fig,str);                                    %Set the function for changing the waitbar title.
waitbar.string = @(str)SetString(fig,txt,str);                              %Set the function for changing the waitbar string.
% waitbar.value = @(val)SetVal(fig,obj,val);                                  %Set the function for changing waitbar value.
waitbar.value = @(varargin)GetSetVal(fig,obj,varargin{:});                  %Set the function for reading/setting the waitbar value.
waitbar.color = @(val)SetColor(fig,obj,val);                                %Set the function for changing waitbar color.
waitbar.close = @()CloseWaitbar(fig);                                       %Set the function for closing the waitbar.
waitbar.isclosed = @()WaitbarIsClosed(fig);                                 %Set the function for checking whether the waitbar figure is closed.

drawnow;                                                                    %Immediately show the waitbar.


%% This function sets the name/title of the waitbar figure.
function SetTitle(fig,str)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(fig,'name',str);                                                    %Set the figure name to the specified string.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


%% This function sets the string on the waitbar figure.
function SetString(fig,txt,str)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(txt,'string',str);                                                  %Set the string in the text object to the specified string.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


% %% This function sets the current value of the waitbar.
% function SetVal(fig,obj,val)
% if ishandle(fig)                                                            %If the waitbar figure is still open...
%     if val > 1                                                              %If the specified value is greater than 1...
%         val = 1;                                                            %Set the value to 1.
%     elseif val < 0                                                          %If the specified value is less than 0...
%         val = 0;                                                            %Set the value to 0.
%     end
%     set(obj,'xdata',val*[0 1 1 0 0]);                                       %Set the patch object to extend to the specified value.
%     drawnow;                                                                %Immediately update the figure.
% else                                                                        %Otherwise...
%     warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
% end


%% This function reads/sets the waitbar value.
function val = GetSetVal(fig,obj,varargin)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    if nargin > 2                                                           %If a value was passed.
        val = varargin{1};                                                  %Grab the specified value.
        if val > 1                                                          %If the specified value is greater than 1...
            val = 1;                                                        %Set the value to 1.
        elseif val < 0                                                      %If the specified value is less than 0...
            val = 0;                                                        %Set the value to 0.
        end
        set(obj,'xdata',val*[0 1 1 0 0]);                                   %Set the patch object to extend to the specified value.
        drawnow;                                                            %Immediately update the figure.
    else                                                                    %Otherwise...
        val = get(obj,'xdata');                                             %Grab the x-coordinates from the patch object.
        val = val(2);                                                       %Return the right-hand x-coordinate.
    end
else                                                                        %Otherwise...
    warning('Cannot access the waitbar figure. It has been closed.');       %Show a warning.
end
    


%% This function sets the color of the waitbar.
function SetColor(fig,obj,val)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(obj,'facecolor',val);                                               %Set the patch object to have the specified facecolor.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


%% This function closes the waitbar figure.
function CloseWaitbar(fig)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    close(fig);                                                             %Close the waitbar figure.
    drawnow;                                                                %Immediately update the figure to allow it to close.
end


%% This function returns a logical value indicate whether the waitbar figure has been closed.
function isclosed = WaitbarIsClosed(fig)
isclosed = ~ishandle(fig);                                                  %Check to see if the figure handle is still a valid handle.


%% ***********************************************************************
function X = boxsmooth(X,wsize)
%Box smoothing function for 2-D matrices.

%X = BOXSMOOTH(X,WSIZE) performs a box-type smoothing function on 2-D
%matrices with window width and height equal to WSIZE.  If WSIZE isn't
%given, the function uses a default value of 5.

if (nargin < 2)                                                             %If the use didn't specify a box size...
    wsize = 5;                                                              %Set the default box size to a 5x5 square.
end     
if (nargin < 1)                                                             %If the user entered no input arguments...
   error('BoxSmooth requires 2-D matrix input.');                           %Show an error.
end

if length(wsize) == 1                                                       %If the user only inputted one dimension...
    rb = round(wsize);                                                      %Round the number of row bins to the nearest integer.
    cb = rb;                                                                %Set the number of column bins equal to the number of row bins.
elseif length(wsize) == 2                                                   %If the user inputted two dimensions...
    rb = round(wsize(1));                                                   %Round the number of row bins to the nearest integer.
    cb = round(wsize(2));                                                   %Round the number of column bins to the nearest integer.
else                                                                        %Otherwise, if the 
    error('The input box size for the boxsmooth can only be a one- or two-element matrix.');
end

w = ones(rb,cb);                                                            %Make a matrix to hold bin weights.
if rem(rb,2) == 0                                                           %If the number of row bins is an even number.
    rb = rb + 1;                                                            %Add an extra bin to the number of row bins.
    w([1,end+1],:) = 0.5;                                                   %Set the tail bins to have half-weight.
end
if rem(cb,2) == 0                                                           %If the number of column bins is an even number.
    cb = cb + 1;                                                            %Add an extra bin to the number of row bins.
    w(:,end+1) = w(:,1);                                                    %Make a new column of weights with the weight of the first column.
    w(:,[1,end]) = 0.5*w(:,[1,end]);                                        %Set the tail bins to have half-weight.
end

[r,c] = size(X);                                                            %Find the number of rows and columns in the input matrix.
S = nan(r+rb-1,c+cb-1);                                                     %Pre-allocate an over-sized matrix to hold the original data.
S((1:r)+(rb-1)/2,(1:c)+(cb-1)/2) = X;                                       %Copy the original matrix to the center of the over-sized matrix.

temp = zeros(size(w));                                                      %Pre-allocate a temporary matrix to hold the box values.
for i = 1:r                                                                 %Step through each row of the original matrix.
    for j = 1:c                                                             %Step through each column of the original matrix.
        temp(:) = S(i:(i+rb-1),j:(j+cb-1));                                 %Pull all of the bin values into a temporary matrix.
        k = ~isnan(temp(:));                                                %Find all the non-NaN bins.
        X(i,j) = sum(w(k).*temp(k))/sum(w(k));                              %Find the weighted mean of the box and save it to the original matrix.
    end
end


%% ***********************************************************************
function count = cprintf(style,format,varargin)
% CPRINTF displays styled formatted text in the Command Window
%
% Syntax:
%    count = cprintf(style,format,...)
%
% Description:
%    CPRINTF processes the specified text using the exact same FORMAT
%    arguments accepted by the built-in SPRINTF and FPRINTF functions.
%
%    CPRINTF then displays the text in the Command Window using the
%    specified STYLE argument. The accepted styles are those used for
%    Matlab's syntax highlighting (see: File / Preferences / Colors / 
%    M-file Syntax Highlighting Colors), and also user-defined colors.
%
%    The possible pre-defined STYLE names are:
%
%       'Text'                 - default: black
%       'Keywords'             - default: blue
%       'Comments'             - default: green
%       'Strings'              - default: purple
%       'UnterminatedStrings'  - default: dark red
%       'SystemCommands'       - default: orange
%       'Errors'               - default: light red
%       'Hyperlinks'           - default: underlined blue
%
%       'Black','Cyan','Magenta','Blue','Green','Red','Yellow','White'
%
%    STYLE beginning with '-' or '_' will be underlined. For example:
%          '-Blue' is underlined blue, like 'Hyperlinks';
%          '_Comments' is underlined green etc.
%
%    STYLE beginning with '*' will be bold (R2011b+ only). For example:
%          '*Blue' is bold blue;
%          '*Comments' is bold green etc.
%    Note: Matlab does not currently support both bold and underline,
%          only one of them can be used in a single cprintf command. But of
%          course bold and underline can be mixed by using separate commands.
%
%    STYLE also accepts a regular Matlab RGB vector, that can be underlined
%    and bolded: -[0,1,1] means underlined cyan, '*[1,0,0]' is bold red.
%
%    STYLE is case-insensitive and accepts unique partial strings just
%    like handle property names.
%
%    CPRINTF by itself, without any input parameters, displays a demo
%
% Example:
%    cprintf;   % displays the demo
%    cprintf('text',   'regular black text');
%    cprintf('hyper',  'followed %s','by');
%    cprintf('key',    '%d colored', 4);
%    cprintf('-comment','& underlined');
%    cprintf('err',    'elements\n');
%    cprintf('cyan',   'cyan');
%    cprintf('_green', 'underlined green');
%    cprintf(-[1,0,1], 'underlined magenta');
%    cprintf([1,0.5,0],'and multi-\nline orange\n');
%    cprintf('*blue',  'and *bold* (R2011b+ only)\n');
%    cprintf('string');  % same as fprintf('string') and cprintf('text','string')
%
% Bugs and suggestions:
%    Please send to Yair Altman (altmany at gmail dot com)
%
% Warning:
%    This code heavily relies on undocumented and unsupported Matlab
%    functionality. It works on Matlab 7+, but use at your own risk!
%
%    A technical description of the implementation can be found at:
%    <a href="http://undocumentedmatlab.com/blog/cprintf/">http://UndocumentedMatlab.com/blog/cprintf/</a>
%
% Limitations:
%    1. In R2011a and earlier, a single space char is inserted at the
%       beginning of each CPRINTF text segment (this is ok in R2011b+).
%
%    2. In R2011a and earlier, consecutive differently-colored multi-line
%       CPRINTFs sometimes display incorrectly on the bottom line.
%       As far as I could tell this is due to a Matlab bug. Examples:
%         >> cprintf('-str','under\nline'); cprintf('err','red\n'); % hidden 'red', unhidden '_'
%         >> cprintf('str','regu\nlar'); cprintf('err','red\n'); % underline red (not purple) 'lar'
%
%    3. Sometimes, non newline ('\n')-terminated segments display unstyled
%       (black) when the command prompt chevron ('>>') regains focus on the
%       continuation of that line (I can't pinpoint when this happens). 
%       To fix this, simply newline-terminate all command-prompt messages.
%
%    4. In R2011b and later, the above errors appear to be fixed. However,
%       the last character of an underlined segment is not underlined for
%       some unknown reason (add an extra space character to make it look better)
%
%    5. In old Matlab versions (e.g., Matlab 7.1 R14), multi-line styles
%       only affect the first line. Single-line styles work as expected.
%       R14 also appends a single space after underlined segments.
%
%    6. Bold style is only supported on R2011b+, and cannot also be underlined.
%
% Change log:
%    2012-08-09: Graceful degradation support for deployed (compiled) and non-desktop applications; minor bug fixes
%    2012-08-06: Fixes for R2012b; added bold style; accept RGB string (non-numeric) style
%    2011-11-27: Fixes for R2011b
%    2011-08-29: Fix by Danilo (FEX comment) for non-default text colors
%    2011-03-04: Performance improvement
%    2010-06-27: Fix for R2010a/b; fixed edge case reported by Sharron; CPRINTF with no args runs the demo
%    2009-09-28: Fixed edge-case problem reported by Swagat K
%    2009-05-28: corrected nargout behavior sugegsted by Andreas Gäb
%    2009-05-13: First version posted on <a href="http://www.mathworks.com/matlabcentral/fileexchange/authors/27420">MathWorks File Exchange</a>
%
% See also:
%    sprintf, fprintf

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.08 $  $Date: 2012/10/17 21:41:09 $

  persistent majorVersion minorVersion
  if isempty(majorVersion)
      %v = version; if str2double(v(1:3)) <= 7.1
      %majorVersion = str2double(regexprep(version,'^(\d+).*','$1'));
      %minorVersion = str2double(regexprep(version,'^\d+\.(\d+).*','$1'));
      %[a,b,c,d,versionIdStrs]=regexp(version,'^(\d+)\.(\d+).*');  %#ok unused
      v = sscanf(version, '%d.', 2);
      majorVersion = v(1); %str2double(versionIdStrs{1}{1});
      minorVersion = v(2); %str2double(versionIdStrs{1}{2});
  end

  % The following is for debug use only:
  %global docElement txt el
  if ~exist('el','var') || isempty(el),  el=handle([]);  end  %#ok mlint short-circuit error ("used before defined")
  if nargin<1, showDemo(majorVersion,minorVersion); return;  end
  if isempty(style),  return;  end
  if all(ishandle(style)) && length(style)~=3
      dumpElement(style);
      return;
  end

  % Process the text string
  if nargin<2, format = style; style='text';  end
  %error(nargchk(2, inf, nargin, 'struct'));
  %str = sprintf(format,varargin{:});

  % In compiled mode
  try useDesktop = usejava('desktop'); catch, useDesktop = false; end
  if isdeployed | ~useDesktop %#ok<OR2> - for Matlab 6 compatibility
      % do not display any formatting - use simple fprintf()
      % See: http://undocumentedmatlab.com/blog/bold-color-text-in-the-command-window/#comment-103035
      % Also see: https://mail.google.com/mail/u/0/?ui=2&shva=1#all/1390a26e7ef4aa4d
      % Also see: https://mail.google.com/mail/u/0/?ui=2&shva=1#all/13a6ed3223333b21
      count1 = fprintf(format,varargin{:});
  else
      % Else (Matlab desktop mode)
      % Get the normalized style name and underlining flag
      [underlineFlag, boldFlag, style] = processStyleInfo(style);

      % Set hyperlinking, if so requested
      if underlineFlag
          format = ['<a href="">' format '</a>'];

          % Matlab 7.1 R14 (possibly a few newer versions as well?)
          % have a bug in rendering consecutive hyperlinks
          % This is fixed by appending a single non-linked space
          if majorVersion < 7 || (majorVersion==7 && minorVersion <= 1)
              format(end+1) = ' ';
          end
      end

      % Set bold, if requested and supported (R2011b+)
      if boldFlag
          if (majorVersion > 7 || minorVersion >= 13)
              format = ['<strong>' format '</strong>'];
          else
              boldFlag = 0;
          end
      end

      % Get the current CW position
      cmdWinDoc = com.mathworks.mde.cmdwin.CmdWinDocument.getInstance;
      lastPos = cmdWinDoc.getLength;

      % If not beginning of line
      bolFlag = 0;  %#ok
      %if docElement.getEndOffset - docElement.getStartOffset > 1
          % Display a hyperlink element in order to force element separation
          % (otherwise adjacent elements on the same line will be merged)
          if majorVersion<7 || (majorVersion==7 && minorVersion<13)
              if ~underlineFlag
                  fprintf('<a href=""> </a>');  %fprintf('<a href=""> </a>\b');
              elseif format(end)~=10  % if no newline at end
                  fprintf(' ');  %fprintf(' \b');
              end
          end
          %drawnow;
          bolFlag = 1;
      %end

      % Get a handle to the Command Window component
      mde = com.mathworks.mde.desk.MLDesktop.getInstance;
      cw = mde.getClient('Command Window');
      xCmdWndView = cw.getComponent(0).getViewport.getComponent(0);

      % Store the CW background color as a special color pref
      % This way, if the CW bg color changes (via File/Preferences), 
      % it will also affect existing rendered strs
      com.mathworks.services.Prefs.setColorPref('CW_BG_Color',xCmdWndView.getBackground);

      % Display the text in the Command Window
      count1 = fprintf(2,format,varargin{:});

      %awtinvoke(cmdWinDoc,'remove',lastPos,1);   % TODO: find out how to remove the extra '_'
      drawnow;  % this is necessary for the following to work properly (refer to Evgeny Pr in FEX comment 16/1/2011)
      docElement = cmdWinDoc.getParagraphElement(lastPos+1);
      if majorVersion<7 || (majorVersion==7 && minorVersion<13)
          if bolFlag && ~underlineFlag
              % Set the leading hyperlink space character ('_') to the bg color, effectively hiding it
              % Note: old Matlab versions have a bug in hyperlinks that need to be accounted for...
              %disp(' '); dumpElement(docElement)
              setElementStyle(docElement,'CW_BG_Color',1+underlineFlag,majorVersion,minorVersion); %+getUrlsFix(docElement));
              %disp(' '); dumpElement(docElement)
              el(end+1) = handle(docElement);  %#ok used in debug only
          end

          % Fix a problem with some hidden hyperlinks becoming unhidden...
          fixHyperlink(docElement);
          %dumpElement(docElement);
      end

      % Get the Document Element(s) corresponding to the latest fprintf operation
      while docElement.getStartOffset < cmdWinDoc.getLength
          % Set the element style according to the current style
          %disp(' '); dumpElement(docElement)
          specialFlag = underlineFlag | boldFlag;
          setElementStyle(docElement,style,specialFlag,majorVersion,minorVersion);
          %disp(' '); dumpElement(docElement)
          docElement2 = cmdWinDoc.getParagraphElement(docElement.getEndOffset+1);
          if isequal(docElement,docElement2),  break;  end
          docElement = docElement2;
          %disp(' '); dumpElement(docElement)
      end

      % Force a Command-Window repaint
      % Note: this is important in case the rendered str was not '\n'-terminated
      xCmdWndView.repaint;

      % The following is for debug use only:
      el(end+1) = handle(docElement);  %#ok used in debug only
      %elementStart  = docElement.getStartOffset;
      %elementLength = docElement.getEndOffset - elementStart;
      %txt = cmdWinDoc.getText(elementStart,elementLength);
  end

  if nargout
      count = count1;
  end
  return;  % debug breakpoint

% Process the requested style information
function [underlineFlag,boldFlag,style] = processStyleInfo(style)
  underlineFlag = 0;
  boldFlag = 0;

  % First, strip out the underline/bold markers
  if ischar(style)
      % Styles containing '-' or '_' should be underlined (using a no-target hyperlink hack)
      %if style(1)=='-'
      underlineIdx = (style=='-') | (style=='_');
      if any(underlineIdx)
          underlineFlag = 1;
          %style = style(2:end);
          style = style(~underlineIdx);
      end

      % Check for bold style (only if not underlined)
      boldIdx = (style=='*');
      if any(boldIdx)
          boldFlag = 1;
          style = style(~boldIdx);
      end
      if underlineFlag && boldFlag
          warning('YMA:cprintf:BoldUnderline','Matlab does not support both bold & underline')
      end

      % Check if the remaining style sting is a numeric vector
      %styleNum = str2num(style); %#ok<ST2NM>  % not good because style='text' is evaled!
      %if ~isempty(styleNum)
      if any(style==' ' | style==',' | style==';')
          style = str2num(style); %#ok<ST2NM>
      end
  end

  % Style = valid matlab RGB vector
  if isnumeric(style) && length(style)==3 && all(style<=1) && all(abs(style)>=0)
      if any(style<0)
          underlineFlag = 1;
          style = abs(style);
      end
      style = getColorStyle(style);

  elseif ~ischar(style)
      error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

  % Style name
  else
      % Try case-insensitive partial/full match with the accepted style names
      validStyles = {'Text','Keywords','Comments','Strings','UnterminatedStrings','SystemCommands','Errors', ...
                     'Black','Cyan','Magenta','Blue','Green','Red','Yellow','White', ...
                     'Hyperlinks'};
      matches = find(strncmpi(style,validStyles,length(style)));

      % No match - error
      if isempty(matches)
          error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

      % Too many matches (ambiguous) - error
      elseif length(matches) > 1
          error('YMA:cprintf:AmbigStyle','Ambiguous style name - supply extra characters for uniqueness')

      % Regular text
      elseif matches == 1
          style = 'ColorsText';  % fixed by Danilo, 29/8/2011

      % Highlight preference style name
      elseif matches < 8
          style = ['Colors_M_' validStyles{matches}];

      % Color name
      elseif matches < length(validStyles)
          colors = [0,0,0; 0,1,1; 1,0,1; 0,0,1; 0,1,0; 1,0,0; 1,1,0; 1,1,1];
          requestedColor = colors(matches-7,:);
          style = getColorStyle(requestedColor);

      % Hyperlink
      else
          style = 'Colors_HTML_HTMLLinks';  % CWLink
          underlineFlag = 1;
      end
  end

% Convert a Matlab RGB vector into a known style name (e.g., '[255,37,0]')
function styleName = getColorStyle(rgb)
  intColor = int32(rgb*255);
  javaColor = java.awt.Color(intColor(1), intColor(2), intColor(3));
  styleName = sprintf('[%d,%d,%d]',intColor);
  com.mathworks.services.Prefs.setColorPref(styleName,javaColor);

% Fix a bug in some Matlab versions, where the number of URL segments
% is larger than the number of style segments in a doc element
function delta = getUrlsFix(docElement)  %#ok currently unused
  tokens = docElement.getAttribute('SyntaxTokens');
  links  = docElement.getAttribute('LinkStartTokens');
  if length(links) > length(tokens(1))
      delta = length(links) > length(tokens(1));
  else
      delta = 0;
  end

% fprintf(2,str) causes all previous '_'s in the line to become red - fix this
function fixHyperlink(docElement)
  try
      tokens = docElement.getAttribute('SyntaxTokens');
      urls   = docElement.getAttribute('HtmlLink');
      urls   = urls(2);
      links  = docElement.getAttribute('LinkStartTokens');
      offsets = tokens(1);
      styles  = tokens(2);
      doc = docElement.getDocument;

      % Loop over all segments in this docElement
      for idx = 1 : length(offsets)-1
          % If this is a hyperlink with no URL target and starts with ' ' and is collored as an error (red)...
          if strcmp(styles(idx).char,'Colors_M_Errors')
              character = char(doc.getText(offsets(idx)+docElement.getStartOffset,1));
              if strcmp(character,' ')
                  if isempty(urls(idx)) && links(idx)==0
                      % Revert the style color to the CW background color (i.e., hide it!)
                      styles(idx) = java.lang.String('CW_BG_Color');
                  end
              end
          end
      end
  catch
      % never mind...
  end

% Set an element to a particular style (color)
function setElementStyle(docElement,style,specialFlag, majorVersion,minorVersion)
  %global tokens links urls urlTargets  % for debug only
  global oldStyles
  if nargin<3,  specialFlag=0;  end
  % Set the last Element token to the requested style:
  % Colors:
  tokens = docElement.getAttribute('SyntaxTokens');
  try
      styles = tokens(2);
      oldStyles{end+1} = styles.cell;

      % Correct edge case problem
      extraInd = double(majorVersion>7 || (majorVersion==7 && minorVersion>=13));  % =0 for R2011a-, =1 for R2011b+
      %{
      if ~strcmp('CWLink',char(styles(end-hyperlinkFlag))) && ...
          strcmp('CWLink',char(styles(end-hyperlinkFlag-1)))
         extraInd = 0;%1;
      end
      hyperlinkFlag = ~isempty(strmatch('CWLink',tokens(2)));
      hyperlinkFlag = 0 + any(cellfun(@(c)(~isempty(c)&&strcmp(c,'CWLink')),tokens(2).cell));
      %}

      styles(end-extraInd) = java.lang.String('');
      styles(end-extraInd-specialFlag) = java.lang.String(style);  %#ok apparently unused but in reality used by Java
      if extraInd
          styles(end-specialFlag) = java.lang.String(style);
      end

      oldStyles{end} = [oldStyles{end} styles.cell];
  catch
      % never mind for now
  end
  
  % Underlines (hyperlinks):
  %{
  links = docElement.getAttribute('LinkStartTokens');
  if isempty(links)
      %docElement.addAttribute('LinkStartTokens',repmat(int32(-1),length(tokens(2)),1));
  else
      %TODO: remove hyperlink by setting the value to -1
  end
  %}

  % Correct empty URLs to be un-hyperlinkable (only underlined)
  urls = docElement.getAttribute('HtmlLink');
  if ~isempty(urls)
      urlTargets = urls(2);
      for urlIdx = 1 : length(urlTargets)
          try
              if urlTargets(urlIdx).length < 1
                  urlTargets(urlIdx) = [];  % '' => []
              end
          catch
              % never mind...
              a=1;  %#ok used for debug breakpoint...
          end
      end
  end
  
  % Bold: (currently unused because we cannot modify this immutable int32 numeric array)
  %{
  try
      %hasBold = docElement.isDefined('BoldStartTokens');
      bolds = docElement.getAttribute('BoldStartTokens');
      if ~isempty(bolds)
          %docElement.addAttribute('BoldStartTokens',repmat(int32(1),length(bolds),1));
      end
  catch
      % never mind - ignore...
      a=1;  %#ok used for debug breakpoint...
  end
  %}
  
  return;  % debug breakpoint

% Display information about element(s)
function dumpElement(docElements)
  %return;
  numElements = length(docElements);
  cmdWinDoc = docElements(1).getDocument;
  for elementIdx = 1 : numElements
      if numElements > 1,  fprintf('Element #%d:\n',elementIdx);  end
      docElement = docElements(elementIdx);
      if ~isjava(docElement),  docElement = docElement.java;  end
      %docElement.dump(java.lang.System.out,1)
      disp(' ');
      disp(docElement)
      tokens = docElement.getAttribute('SyntaxTokens');
      if isempty(tokens),  continue;  end
      links = docElement.getAttribute('LinkStartTokens');
      urls  = docElement.getAttribute('HtmlLink');
      try bolds = docElement.getAttribute('BoldStartTokens'); catch, bolds = []; end
      txt = {};
      tokenLengths = tokens(1);
      for tokenIdx = 1 : length(tokenLengths)-1
          tokenLength = diff(tokenLengths(tokenIdx+[0,1]));
          if (tokenLength < 0)
              tokenLength = docElement.getEndOffset - docElement.getStartOffset - tokenLengths(tokenIdx);
          end
          txt{tokenIdx} = cmdWinDoc.getText(docElement.getStartOffset+tokenLengths(tokenIdx),tokenLength).char;  %#ok
      end
      lastTokenStartOffset = docElement.getStartOffset + tokenLengths(end);
      txt{end+1} = cmdWinDoc.getText(lastTokenStartOffset, docElement.getEndOffset-lastTokenStartOffset).char;  %#ok
      %cmdWinDoc.uiinspect
      %docElement.uiinspect
      txt = strrep(txt',sprintf('\n'),'\n');
      try
          data = [tokens(2).cell m2c(tokens(1)) m2c(links) m2c(urls(1)) cell(urls(2)) m2c(bolds) txt];
          if elementIdx==1
              disp('    SyntaxTokens(2,1) - LinkStartTokens - HtmlLink(1,2) - BoldStartTokens - txt');
              disp('    ==============================================================================');
          end
      catch
          try
              data = [tokens(2).cell m2c(tokens(1)) m2c(links) txt];
          catch
              disp([tokens(2).cell m2c(tokens(1)) txt]);
              try
                  data = [m2c(links) m2c(urls(1)) cell(urls(2))];
              catch
                  % Mtlab 7.1 only has urls(1)...
                  data = [m2c(links) urls.cell];
              end
          end
      end
      disp(data)
  end

% Utility function to convert matrix => cell
function cells = m2c(data)
  %datasize = size(data);  cells = mat2cell(data,ones(1,datasize(1)),ones(1,datasize(2)));
  cells = num2cell(data);

% Display the help and demo
function showDemo(majorVersion,minorVersion)
  fprintf('cprintf displays formatted text in the Command Window.\n\n');
  fprintf('Syntax: count = cprintf(style,format,...);  click <a href="matlab:help cprintf">here</a> for details.\n\n');
  url = 'http://UndocumentedMatlab.com/blog/cprintf/';
  fprintf(['Technical description: <a href="' url '">' url '</a>\n\n']);
  fprintf('Demo:\n\n');
  boldFlag = majorVersion>7 || (majorVersion==7 && minorVersion>=13);
  s = ['cprintf(''text'',    ''regular black text'');' 10 ...
       'cprintf(''hyper'',   ''followed %s'',''by'');' 10 ...
       'cprintf(''key'',     ''%d colored'',' num2str(4+boldFlag) ');' 10 ...
       'cprintf(''-comment'',''& underlined'');' 10 ...
       'cprintf(''err'',     ''elements:\n'');' 10 ...
       'cprintf(''cyan'',    ''cyan'');' 10 ...
       'cprintf(''_green'',  ''underlined green'');' 10 ...
       'cprintf(-[1,0,1],  ''underlined magenta'');' 10 ...
       'cprintf([1,0.5,0], ''and multi-\nline orange\n'');' 10];
   if boldFlag
       % In R2011b+ the internal bug that causes the need for an extra space
       % is apparently fixed, so we must insert the sparator spaces manually...
       % On the other hand, 2011b enables *bold* format
       s = [s 'cprintf(''*blue'',   ''and *bold* (R2011b+ only)\n'');' 10];
       s = strrep(s, ''')',' '')');
       s = strrep(s, ''',5)',' '',5)');
       s = strrep(s, '\n ','\n');
   end
   disp(s);
   eval(s);


%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%
% - Fix: Remove leading space char (hidden underline '_')
% - Fix: Find workaround for multi-line quirks/limitations
% - Fix: Non-\n-terminated segments are displayed as black
% - Fix: Check whether the hyperlink fix for 7.1 is also needed on 7.2 etc.
% - Enh: Add font support


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_HabiTrak_V1_Icon_48px

%VULINTUS_LOAD_HABITRAK_V1_ICON_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:19:49
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	 255,   0,  13,  11,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  11,  11,   0, 255;
				   0,  13,  79, 209, 242, 242, 242, 242, 207,  32,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  32, 208, 242, 242, 242, 242, 208,  78,  13,   0;
				  13,  79, 242, 242, 242, 242, 242, 242, 127,  92, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  91, 127, 242, 242, 242, 242, 242, 242,  78,  11;
				  11, 210, 242, 242, 242, 242, 242, 242, 121, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102, 121, 242, 242, 242, 242, 242, 242, 208,  11;
				   1, 241, 242, 242, 242, 242, 242, 242, 121, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102, 121, 242, 242, 242, 242, 242, 242, 241,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 127,  91, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  90, 127, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 208,  33,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  34, 208, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 219,  69,  64,  64,  64,  64,  68, 217, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 123,  64,  64,  64,  64,  64,  64, 124, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 202,  65,  64,  64,  64,  64,  64,  64,  64, 199, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 241, 101,  64,  64,  64,  64,  64,  64,  64,  64,  98, 240, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 177,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 178, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 235,  84,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  83, 235, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 154,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 154, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 226,  73,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  72, 224, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 132,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 132, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 209,  65,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 207, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 112,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 109, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 186,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 187, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 238,  90,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  88, 238, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 164,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 165, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 230,  77,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  76, 229, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 140,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 141, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 218,  68,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  68, 216, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 118,  64,  64,  64,  77, 134, 153, 145,  96,  64,  64,  64,  64,  64,  64,  64,  64,  96, 145, 153, 134,  77,  64,  64,  64, 119, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 242, 196,  64,  64,  65, 156, 247, 255, 255, 255, 254, 197,  79,  64,  64,  64,  64,  79, 197, 254, 255, 255, 255, 247, 156,  65,  64,  64, 194, 242, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 240,  99,  64,  64, 169, 255, 255, 255, 255, 255, 255, 255, 221,  73,  64,  64,  73, 221, 255, 255, 255, 255, 255, 255, 255, 169,  64,  64,  97, 240, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 242, 173,  64,  64, 106, 254, 255, 255, 255, 255, 255, 255, 255, 255, 167,  64,  64, 167, 255, 255, 255, 255, 255, 255, 255, 255, 254, 107,  64,  64, 174, 242, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 234,  82,  64,  64, 179, 255, 255, 255, 255, 255, 255, 255, 255, 255, 240,  65,  65, 240, 255, 255, 255, 255, 255, 255, 255, 255, 255, 179,  64,  64,  80, 233, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 242, 151,  64,  64,  64, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 216,  64,  64,  64, 152, 242, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 222,  70,  64,  64,  64, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 216,  64,  64,  64,  71, 221, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 242, 127,  64,  64,  64,  64, 179, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 179,  64,  64,  64,  64, 128, 242, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 205,  65,  64,  64,  64,  64, 105, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 105,  64,  64,  64,  64,  65, 202, 242, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 242, 106,  64,  64,  64,  64,  63,  64, 167, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 167,  64,  63,  64,  64,  64,  64, 104, 241, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 242, 182,  64,  64,  64,  64,  64,  64,  64,  65, 153, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 153,  65,  64,  64,  64,  64,  64,  64,  64, 182, 242, 242, 242, 242,   1;
				   1, 242, 242, 242, 238,  88,  64,  64,  64,  64,  64,  64,  64,  64,  64,  76, 131, 153, 143,  99, 224, 255, 255, 255, 255, 255, 255, 225,  99, 143, 153, 131,  77,  64,  64,  64,  64,  64,  64,  64,  64,  64,  87, 236, 242, 242, 242,   1;
				   1, 242, 242, 242, 159,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 101, 251, 255, 101, 101, 255, 254, 108,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 160, 242, 242, 242,   1;
				   1, 242, 242, 227,  74,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 166, 255, 157, 158, 255, 167,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  73, 225, 242, 242,   1;
				   1, 242, 242, 137,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  70, 224, 255, 255, 224,  70,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 138, 242, 242,   1;
				   1, 242, 213,  67,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 104, 252, 253, 106,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  66, 210, 242,   1;
				   1, 242, 113,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 119, 119,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 111, 242,   1;
				   1, 242, 205, 127,  71,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  71, 128, 205, 242,   1;
				   1, 242, 242, 242, 235, 182, 117,  68,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 105, 171, 233, 242, 242, 242,   1;
				   1, 241, 242, 242, 242, 242, 242, 226, 167, 113,  71,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  71, 113, 167, 227, 242, 242, 242, 242, 242, 241,   1;
				  11, 209, 242, 242, 242, 242, 242, 242, 242, 242, 235, 193, 149, 110,  73,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  73, 111, 149, 194, 236, 242, 242, 242, 242, 242, 242, 242, 242, 207,  11;
				  11,  78, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 240, 212, 183, 159, 134, 109,  96,  87,  76,  68,  68,  76,  87,  96, 110, 134, 159, 184, 213, 240, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  76,  11;
				   0,  13,  78, 207, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 207,  77,  13,   0;
				 255,   0,  11,  11,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  12,  11,   0, 255];
im(:,:,2) = [	 255,   0,  11,  10,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  10,  11,   0, 255;
				   0,  12,  71, 187, 217, 217, 217, 217, 186,  29,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  29, 186, 217, 217, 217, 217, 186,  70,  12,   0;
				  11,  71, 217, 217, 217, 217, 217, 217, 114,  91, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  90, 114, 217, 217, 217, 217, 217, 217,  70,  11;
				  10, 188, 217, 217, 217, 217, 217, 217, 108, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102, 108, 217, 217, 217, 217, 217, 217, 186,  10;
				   1, 216, 217, 217, 217, 217, 217, 217, 108, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102, 108, 217, 217, 217, 217, 217, 217, 216,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 114,  90, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  90, 114, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 186,  30,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  31, 186, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 197,  68,  64,  64,  64,  64,  67, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 114,  64,  64,  64,  64,  64,  64, 115, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 182,  65,  64,  64,  64,  64,  64,  64,  64, 180, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 216,  96,  64,  64,  64,  64,  64,  64,  64,  64,  94, 215, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 161,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 162, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 211,  82,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  80, 211, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 142,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 142, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 203,  72,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  71, 202, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 123,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 122, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 189,  65,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 187, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 105,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 102, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 169,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 170, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 214,  86,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  85, 214, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 150,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 151, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 207,  75,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  74, 206, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 130,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 130, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 196,  67,  64,  64,  88, 135, 153, 146, 107,  65,  64,  64,  64,  64,  64,  64,  65, 107, 146, 153, 135,  88,  64,  64,  67, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 110,  64,  81, 189, 253, 255, 255, 255, 255, 221, 110,  64,  64,  64,  64, 110, 221, 255, 255, 255, 255, 253, 189,  81,  64, 111, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 217, 178,  64,  87, 230, 255, 248, 192, 166, 177, 233, 255, 252, 128,  64,  64, 128, 252, 255, 233, 177, 166, 192, 248, 255, 230,  87,  64, 175, 217, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 215,  94,  65, 214, 255, 212,  84,  64,  64,  64,  68, 167, 255, 249,  93,  93, 249, 255, 167,  68,  64,  64,  64,  84, 212, 255, 215,  65,  92, 215, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 217, 158,  64, 125, 255, 233,  75,  64,  64,  64,  64,  64,  64, 183, 255, 185, 185, 255, 183,  64,  64,  64,  64,  64,  64,  75, 233, 255, 125,  64, 159, 217, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 210,  79,  64, 186, 255, 148,  64,  64,  64,  64,  64,  64,  64,  87, 254, 255, 255, 254,  87,  64,  64,  64,  64,  64,  64,  64, 148, 255, 186,  64,  78, 209, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 217, 139,  64,  64, 217, 255, 104,  64,  64,  64,  64,  64,  64,  64,  64, 233, 255, 255, 233,  64,  64,  64,  64,  64,  64,  64,  64, 104, 255, 217,  64,  64, 139, 217, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 200,  70,  64,  64, 217, 255, 104,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 104, 255, 216,  64,  64,  70, 199, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 217, 118,  64,  64,  64, 185, 255, 149,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 149, 255, 187,  64,  64,  64, 119, 217, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 185,  65,  64,  64,  64, 122, 255, 234,  76,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  76, 234, 255, 122,  64,  64,  64,  65, 183, 217, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 217, 100,  64,  64,  64,  64,  65, 213, 255, 213,  86,  64,  64,  64,  69,  75,  64,  64,  64,  64,  64,  64,  75,  69,  64,  64,  64,  86, 213, 255, 213,  65,  64,  64,  64,  64,  99, 216, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 217, 166,  64,  64,  64,  64,  64,  64,  86, 230, 255, 249, 194, 166, 179, 236, 191,  64,  64,  64,  64,  64,  64, 191, 236, 179, 166, 194, 249, 255, 230,  86,  64,  64,  64,  64,  64,  64, 166, 217, 217, 217, 217,   1;
				   1, 217, 217, 217, 214,  85,  64,  64,  64,  64,  64,  64,  64,  80, 187, 253, 255, 255, 255, 255, 255, 128,  64,  64,  64,  64, 123, 255, 255, 255, 255, 255, 253, 188,  80,  64,  64,  64,  64,  64,  64,  64,  84, 212, 217, 217, 217,   1;
				   1, 217, 217, 217, 146,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  86, 133, 153, 143, 161, 255, 240,  81,  25,  25,  79, 238, 255, 162, 143, 153, 133,  86,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 147, 217, 217, 217,   1;
				   1, 217, 217, 204,  73,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 202, 255, 196,  39,  40, 191, 255, 206,  65,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  72, 203, 217, 217,   1;
				   1, 217, 217, 126,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  87, 245, 255, 128, 123, 255, 245,  88,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 127, 217, 217,   1;
				   1, 217, 192,  66,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 140, 255, 239, 239, 255, 142,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  66, 190, 217,   1;
				   1, 217, 106,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 200, 255, 255, 201,  65,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 104, 217,   1;
				   1, 217, 185, 118,  70,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  71, 139, 139,  71,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  70, 119, 185, 217,   1;
				   1, 217, 217, 217, 211, 166, 110,  67,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65,  99, 156, 209, 217, 217, 217,   1;
				   1, 216, 217, 217, 217, 217, 217, 203, 152, 106,  70,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  70, 106, 152, 204, 217, 217, 217, 217, 217, 216,   1;
				  10, 187, 217, 217, 217, 217, 217, 217, 217, 217, 211, 175, 137, 103,  72,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  72, 104, 137, 175, 212, 217, 217, 217, 217, 217, 217, 217, 217, 186,  10;
				  11,  70, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 215, 191, 167, 146, 124, 102,  91,  84,  74,  67,  67,  74,  84,  91, 103, 124, 146, 167, 192, 215, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217,  68,  11;
				   0,  12,  70, 186, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 186,  69,  12,   0;
				 255,   0,  11,  10,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  11,   9,   0, 255];
im(:,:,3) = [	 255,   0,   2,   2,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   2,   2,   0, 255;
				   0,   2,  12,  33,  38,  38,  38,  38,  32,  12,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  12,  33,  38,  38,  38,  38,  33,  12,   2,   0;
				   2,  12,  38,  38,  38,  38,  38,  38,  20,  89, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  88,  20,  38,  38,  38,  38,  38,  38,  12,   2;
				   1,  33,  38,  38,  38,  38,  38,  38,  19, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102,  19,  38,  38,  38,  38,  38,  38,  33,   2;
				   0,  38,  38,  38,  38,  38,  38,  38,  19, 102, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 102,  19,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  20,  88, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204,  87,  20,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  33,  12,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  12,  33,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  66, 249, 255, 255, 255, 255, 250,  69,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 184, 255, 255, 255, 255, 255, 255, 183,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  87, 254, 255, 255, 255, 255, 255, 255, 255,  90,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  39, 209, 255, 255, 255, 255, 255, 255, 255, 255, 212,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 117, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 116,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  46, 229, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 232,  47,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 145, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 144,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  58, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  59,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 172, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 172,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  78, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 253,  81,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 197, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 201,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 106, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 105,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  42, 223, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 225,  43,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 133, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 132,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  52, 239, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  54,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 161, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 161,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  68, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251,  70,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 189, 255, 255, 255, 241, 185, 166, 174, 223, 255, 255, 255, 255, 255, 255, 255, 255, 223, 174, 166, 185, 241, 255, 255, 255, 188,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  38,  93, 255, 255, 254, 163,  71,  64,  64,  64,  65, 122, 240, 255, 255, 255, 255, 240, 122,  65,  64,  64,  64,  71, 163, 254, 255, 255,  97,  38,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38,  40, 212, 255, 255, 150,  64,  64,  64,  64,  64,  64,  64,  98, 246, 255, 255, 246,  98,  64,  64,  64,  64,  64,  64,  64, 150, 255, 255, 215,  41,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  38, 122, 255, 255, 213,  65,  64,  64,  64,  64,  64,  64,  64,  64, 152, 255, 255, 152,  64,  64,  64,  64,  64,  64,  64,  64,  65, 212, 255, 255, 121,  38,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38,  48, 234, 255, 255, 140,  64,  64,  64,  64,  64,  64,  64,  64,  64,  79, 253, 253,  79,  64,  64,  64,  64,  64,  64,  64,  64,  64, 140, 255, 255, 235,  50,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  38, 149, 255, 255, 255, 103,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 103, 255, 255, 255, 149,  38,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  62, 246, 255, 255, 255, 103,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 103, 255, 255, 255, 247,  64,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38, 178, 255, 255, 255, 255, 140,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 140, 255, 255, 255, 255, 177,  38,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  84, 254, 255, 255, 255, 255, 214,  65,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  65, 214, 255, 255, 255, 255, 254,  87,  38,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38, 204, 255, 255, 255, 255, 255, 255, 152,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64, 152, 255, 255, 255, 255, 255, 255, 206,  39,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  38, 111, 255, 255, 255, 255, 255, 255, 255, 254, 166,  72,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  64,  72, 166, 254, 255, 255, 255, 255, 255, 255, 255, 110,  38,  38,  38,  38,   0;
				   0,  38,  38,  38,  43, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242, 188, 166, 176, 220,  95,  64,  64,  64,  64,  64,  64,  94, 220, 176, 166, 188, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 227,  45,  38,  38,  38,   0;
				   0,  38,  38,  38, 139, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 218,  68,  64,  25,  25,  64,  65, 211, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 138,  38,  38,  38,   0;
				   0,  38,  38,  56, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 153,  64,  39,  40,  64, 152, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244,  58,  38,  38,   0;
				   0,  38,  38, 166, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249,  95,  64,  64,  95, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 166,  38,  38,   0;
				   0,  38,  73, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  66,  66, 213, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252,  76,  38,   0;
				   0,  38, 195, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 200, 200, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,  38,   0;
				   0,  38,  84, 178, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 177,  84,  38,   0;
				   0,  38,  38,  38,  46, 110, 190, 251, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 253, 205, 125,  50,  38,  38,  38,   0;
				   0,  38,  38,  38,  38,  38,  38,  58, 130, 195, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 195, 130,  57,  38,  38,  38,  38,  38,  38,   0;
				   1,  33,  38,  38,  38,  38,  38,  38,  38,  38,  46,  98, 152, 199, 243, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243, 198, 151,  98,  45,  38,  38,  38,  38,  38,  38,  38,  38,  32,   2;
				   2,  12,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  40,  75, 109, 139, 170, 201, 216, 226, 241, 250, 250, 240, 226, 216, 200, 170, 139, 109,  74,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  12,   2;
				   0,   2,  12,  32,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  32,  12,   2,   0;
				 255,   0,   2,   2,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   2,   2,   0, 255];
alpha_map = [	   0,   8, 140, 238, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 238, 139,   8,   0;
				   8, 216, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 215,   7;
				 141, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 138;
				 238, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 237;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 238, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 237;
				 139, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 138;
				   7, 215, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 214,   7;
				   0,   7, 138, 237, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 236, 136,   7,   0];
varargout = {alpha_map};


%% ***********************************************************************
function [img, varargout] = Vulintus_Load_Icon(varargin)

%
%Vulintus_Load_Icon.m - Vulintus, Inc.
%
%   VULINTUS_LOAD_ICON loads the Vulintus icon for the specified system
%   name at the specified pixel resolution. If no pixel resolution is
%   specified, it returns a 48x48 pixels icon. If a figure handle is also
%   specified, it will match transparent pixels of the icon to the figure
%   title bar color.
%   
%   UPDATE LOG:
%   2024-06-11 - Drew Sloan - Function first created.
%


system_name = 'vulintus';                                                   %Assume that the general Vulintus icon is requested.
num_pix = 48;                                                               %Assume a 48x48 pixel icon is requested.
fig = [];                                                                   %Assume no figure handle is specified.

for i = 1:nargin                                                            %Step through all of the variable input arguments.
    switch class(varargin{i})                                               %Switch between the different classes of input.
        case 'matlab.ui.Figure'                                             %Figure handle.
            fig = varargin{i};                                              %Set the figure handle.
        case 'char'                                                         %Character array.
            system_name = varargin{i};                                      %Set the system name.
        case 'double'                                                       %Number.
            num_pix = varagin{i};                                           %Set the pixel resolution.
        otherwise                                                           %Otherwise...
            error('ERROR IN %s: Unrecognized input type ''%s''.',...
                upper(mfilename),class(varargin{i}));                       %Show an error.
    end
end

switch (num_pix)                                                            %Switch between the requested pixel resolutions.
    otherwise                                                               %For all other resolutions.
        switch lower(system_name)                                           %Switch between the recognized system names.
            case 'habitrak'                                                 %HabiTrak.
                [img, alpha_map] = Vulintus_Load_HabiTrak_V1_Icon_48px;     %Use the HabiTrak icon.
            case 'mototrak'                                                 %MotoTrak.
                [img, alpha_map] = Vulintus_Load_MotoTrak_V2_Icon_48px;     %Use the MotoTrak V2 icon.
            case 'omnihome'                                                 %OmniHome.
                [img, alpha_map] = Vulintus_Load_OmniHome_V1_Icon_48px;     %Use the OmniHome icon.
            case 'omnitrak'                                                 %OmniTrak.
                [img, alpha_map] = Vulintus_Load_OmniTrak_V1_Icon_48px;     %Use the OmniTrak icon.    
            case 'sensitrak'                                                %SensiTrak.
                [img, alpha_map] = Vulintus_Load_SensiTrak_V1_Icon_48px;    %Use the SensiTrak icon.
            case 'vulintus'                                                 %General Vulintus icon.
                [img, alpha_map] = ...
                    Vulintus_Load_Vulintus_Logo_Circle_Social_48px;         %Use the Vulintus Social Logo.
            otherwise                                                       %For all other system names.
                error('ERROR IN %s: No matching system name for "%s".',...
                    upper(mfilename),system_name);                          %Show an error.
        end
end
if ishandle(fig)                                                            %If a figure handle was provided...
    img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);                %Match the icon background to the figure.
end
varargout{1} = alpha_map;                                                   %Return the alpha map, if requested.


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_MotoTrak_V2_Icon_48px

%VULINTUS_LOAD_MOTOTRAK_V2_ICON_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:20:23
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	   0, 179, 153, 126, 119, 115, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 115, 119, 127, 154, 184,   0;
				 179, 133, 161, 223, 235, 236, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 220, 156, 134, 184;
				 153, 160, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 154, 155;
				 129, 219, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 218, 128;
				 121, 232, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 123;
				 116, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 246, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 118;
				 116, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 244, 237, 172, 159, 162, 195, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 115;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 173, 126, 111, 111, 111, 112, 141, 194, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 173, 115, 111, 111, 111, 111, 111, 111, 117, 170, 244, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 244, 146, 111, 111, 111, 111, 111, 111, 111, 111, 114, 186, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 246, 154, 111, 111, 111, 111, 111, 111, 111, 111, 111, 149, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 246, 245, 245, 245, 185, 131, 111, 111, 111, 111, 111, 111, 111, 111, 145, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 114, 239, 245, 245, 245, 245, 244, 246, 237, 203, 176, 163, 155, 149, 141, 131, 115, 111, 111, 111, 111, 111, 111, 111, 111, 163, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 114, 239, 245, 245, 245, 171, 136, 124, 113, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 131, 241, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 114, 239, 245, 245, 245, 245, 165, 117, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 117, 178, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 189, 129, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 117, 151, 188, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 245, 227, 146, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 112, 148, 217, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 160, 114, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 123, 180, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 179, 123, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 118, 186, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 216, 140, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 133, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 244, 161, 112, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 159, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 238, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 171, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 116, 200, 245, 245, 245, 245, 245, 245, 245, 245, 246, 246, 245, 245, 245, 245, 238, 112;
				 111, 238, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 128, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 145, 245, 245, 245, 245, 245, 245, 241, 162, 150, 155, 171, 243, 245, 245, 238, 112;
				 111, 238, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 151, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 113, 199, 245, 245, 245, 245, 241, 142, 131, 148, 140, 114, 138, 240, 245, 238, 111;
				 111, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 171, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 154, 246, 245, 245, 246, 158, 136, 236, 245, 245, 173, 111, 179, 245, 238, 112;
				 111, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 229, 115, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 123, 242, 245, 245, 228, 116, 182, 245, 245, 245, 244, 116, 166, 245, 238, 112;
				 111, 238, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 244, 140, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 186, 245, 245, 170, 124, 243, 245, 245, 245, 244, 123, 191, 245, 238, 112;
				 112, 233, 245, 245, 245, 229, 150, 149, 221, 244, 233, 217, 203, 195, 189, 179, 167, 141, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 160, 245, 245, 160, 141, 246, 245, 245, 245, 245, 185, 245, 245, 238, 112;
				 112, 138, 139, 139, 141, 133, 111, 111, 162, 244, 228, 170, 154, 134, 113, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 144, 246, 245, 162, 145, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 151, 154, 155, 158, 154, 115, 114, 180, 245, 245, 245, 245, 244, 218, 168, 150, 128, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 136, 245, 245, 164, 139, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 235, 245, 245, 245, 245, 213, 211, 245, 245, 245, 245, 245, 245, 245, 245, 245, 246, 145, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 128, 245, 245, 170, 135, 245, 245, 245, 245, 245, 245, 245, 245, 238, 112;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 163, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 121, 245, 245, 179, 133, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 112, 238, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 209, 112, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 128, 245, 245, 180, 131, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 132, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 136, 245, 245, 171, 138, 244, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 112, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 154, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 145, 245, 245, 163, 144, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 176, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 163, 245, 245, 147, 157, 246, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 117, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 119, 228, 245, 229, 121, 200, 245, 245, 245, 245, 245, 245, 245, 245, 238, 113;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 246, 188, 118, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 161, 245, 245, 154, 142, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 179, 118, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 145, 242, 232, 156, 120, 200, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 113, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 173, 117, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 147, 142, 122, 136, 192, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 114, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 168, 115, 111, 111, 111, 111, 111, 111, 111, 111, 111, 113, 138, 174, 187, 162, 163, 203, 246, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 114;
				 115, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 225, 164, 159, 158, 158, 158, 156, 157, 159, 161, 163, 187, 234, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 115;
				 118, 239, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 118;
				 122, 236, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 238, 123;
				 128, 219, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 217, 129;
				 154, 158, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 245, 153, 155;
				 179, 134, 158, 222, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 218, 155, 136, 175;
				   0, 184, 154, 128, 115, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 117, 119, 128, 155, 175,   0];
im(:,:,2) = [	   0, 153, 136, 113, 106, 103, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 103, 106, 113, 136, 170,   0;
				 153, 119, 142, 194, 204, 206, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 192, 138, 120, 170;
				 136, 142, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 136, 137;
				 115, 191, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 190, 115;
				 109, 202, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 110;
				 105, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 107;
				 104, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 203, 150, 139, 143, 171, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 153, 114, 100, 100, 100, 101, 125, 171, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 153, 103, 100, 100, 100, 100, 100, 100, 105, 149, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 212, 129, 100, 100, 100, 100, 100, 100, 100, 100, 103, 164, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 102;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 137, 100, 100, 100, 100, 100, 100, 100, 100, 100, 132, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 102;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 214, 213, 174, 117, 100, 100, 100, 100, 100, 100, 100, 100, 129, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 102;
				 103, 209, 213, 213, 213, 213, 214, 213, 208, 180, 155, 145, 138, 132, 125, 116, 103, 100, 100, 100, 100, 100, 100, 100, 100, 143, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 102, 209, 213, 213, 214, 147, 121, 111, 101, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 117, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 102, 209, 213, 213, 213, 213, 145, 105, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 105, 154, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 164, 115, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 105, 134, 167, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 196, 129, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 101, 130, 189, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 141, 102, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 110, 157, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 157, 110, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 107, 164, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 188, 124, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 118, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 211, 142, 101, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 140, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 153, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 104, 174, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 100, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 114, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 130, 213, 213, 213, 213, 213, 213, 210, 143, 133, 137, 150, 211, 213, 213, 206, 101;
				 100, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 214, 134, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 101, 172, 213, 213, 213, 213, 212, 126, 116, 130, 125, 102, 123, 209, 213, 206, 100;
				 100, 207, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 151, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 136, 213, 213, 213, 213, 139, 122, 204, 213, 213, 152, 100, 156, 213, 206, 101;
				 100, 207, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 200, 103, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 110, 212, 213, 213, 197, 105, 159, 213, 213, 213, 212, 104, 146, 213, 206, 101;
				 100, 206, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 212, 124, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 163, 213, 213, 148, 111, 210, 213, 213, 213, 212, 110, 169, 213, 206, 101;
				 101, 201, 213, 213, 213, 197, 133, 132, 194, 214, 204, 191, 177, 169, 165, 155, 147, 126, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 141, 213, 213, 142, 126, 213, 213, 213, 213, 213, 165, 212, 213, 206, 101;
				 101, 123, 124, 124, 125, 119, 100, 100, 142, 213, 201, 149, 136, 119, 101, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 128, 213, 213, 143, 129, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 134, 136, 138, 140, 136, 103, 103, 158, 213, 213, 213, 213, 212, 190, 146, 132, 113, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 121, 213, 213, 146, 124, 214, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 205, 213, 213, 213, 213, 187, 185, 214, 213, 213, 213, 213, 213, 213, 213, 213, 212, 130, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 115, 212, 213, 149, 120, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 207, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 145, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 109, 212, 213, 157, 119, 212, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 182, 101, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 113, 212, 213, 159, 118, 214, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 214, 117, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 121, 213, 213, 151, 122, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 208, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 136, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 130, 213, 213, 145, 128, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 153, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 144, 213, 214, 131, 138, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 205, 105, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 107, 200, 213, 198, 108, 173, 213, 213, 213, 213, 213, 213, 213, 213, 206, 101;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 166, 106, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 140, 213, 213, 136, 126, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 102;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 157, 107, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 129, 208, 202, 139, 108, 176, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 102;
				 101, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 153, 105, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 130, 127, 109, 122, 170, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 102, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 148, 103, 100, 100, 100, 100, 100, 100, 100, 100, 100, 101, 123, 154, 161, 143, 145, 179, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 103, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 214, 210, 145, 139, 140, 140, 140, 138, 138, 140, 142, 145, 164, 204, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 103;
				 106, 209, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 107;
				 110, 205, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 206, 110;
				 114, 191, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 190, 116;
				 137, 139, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 213, 136, 137;
				 153, 120, 140, 193, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 206, 190, 136, 121, 159;
				   0, 170, 137, 113, 103, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 105, 107, 115, 137, 159,   0];
im(:,:,3) = [	   0,  89, 114, 138, 143, 146, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 146, 143, 137, 113,  85,   0;
				  89, 131, 108,  56,  46,  45,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  58, 112, 130,  85;
				 114, 108,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 114, 112;
				 134,  59,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  60, 136;
				 141,  48,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 140;
				 146,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 144;
				 145,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  46,  99, 109, 107,  79,  36,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 146,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 100, 137, 150, 150, 150, 149, 126,  78,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 146,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  96, 147, 150, 150, 150, 150, 150, 150, 145, 101,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 146,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 121, 150, 150, 150, 150, 150, 150, 150, 150, 147,  88,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 147,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  38, 113, 150, 150, 150, 150, 150, 150, 150, 150, 150, 119,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 147,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  81, 133, 150, 150, 150, 150, 150, 150, 150, 150, 121,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 147,  42,  37,  37,  37,  37,  38,  37,  44,  73,  95, 107, 112, 119, 126, 134, 146, 150, 150, 150, 150, 150, 150, 150, 150, 105,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 148,  42,  37,  37,  37, 100, 129, 139, 148, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 133,  40,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 148,  42,  37,  37,  37,  37, 103, 146, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 145,  94,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  42,  37,  37,  37,  37,  37,  83, 134, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 145, 117,  82,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  42,  37,  37,  37,  37,  37,  37,  53, 121, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 149, 120,  60,  36,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 148,  42,  37,  37,  37,  37,  37,  37,  37,  36, 108, 148, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 139,  93,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  38,  92, 139, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 144,  83,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  64, 127, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 132,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  40, 108, 149, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 111,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  36, 100, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 145,  79,  37,  37,  37,  37,  37,  37,  37,  37,  36,  37,  37,  37,  37,  37,  43, 149;
				 150,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  38, 137, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 121,  38,  37,  37,  37,  37,  37,  40, 107, 117, 112,  96,  40,  37,  37,  43, 149;
				 150,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  38, 117, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 148,  76,  37,  37,  37,  37,  41, 124, 134, 120, 126, 148, 126,  41,  37,  43, 150;
				 150,  43,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  98, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 115,  38,  37,  37,  37, 110, 129,  46,  37,  37,  99, 150,  92,  37,  43, 149;
				 150,  43,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  47, 147, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 139,  38,  37,  37,  53, 146,  92,  37,  37,  37,  38, 145, 103,  37,  43, 149;
				 150,  43,  37,  37,  37,  37,  38,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 127, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150,  87,  37,  37, 101, 139,  40,  37,  37,  37,  38, 140,  81,  37,  43, 149;
				 149,  49,  37,  37,  37,  49, 117, 117,  57,  37,  48,  61,  71,  81,  86,  94, 102, 125, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 109,  37,  37, 108, 125,  38,  37,  37,  37,  37,  85,  36,  37,  43, 149;
				 149, 127, 126, 126, 124, 132, 150, 150, 108,  37,  50, 102, 113, 131, 148, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 122,  37,  37, 107, 121,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149, 116, 114, 112, 111, 114, 147, 147,  92,  37,  37,  37,  37,  36,  59, 102, 117, 136, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 130,  36,  37, 105, 126,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  44,  38,  38,  38,  38,  66,  68,  38,  37,  37,  37,  37,  37,  37,  37,  37,  37, 121, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 136,  38,  37, 102, 129,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  43,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 105, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 141,  38,  37,  92, 132,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  65, 149, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 136,  38,  37,  92, 132,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 133, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 130,  36,  37,  98, 128,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 113, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 121,  37,  37, 106, 122,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 148,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  95, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 107,  37,  37, 119, 110,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  48, 145, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 142,  49,  37,  52, 142,  77,  37,  37,  37,  37,  37,  37,  37,  37,  43, 149;
				 148,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  87, 144, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 109,  37,  37, 114, 124,  36,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  94, 144, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 120,  40,  48, 113, 143,  73,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 148;
				 149,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  96, 146, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 121, 124, 142, 129,  80,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 148,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 103, 147, 150, 150, 150, 150, 150, 150, 150, 150, 150, 149, 128,  94,  89, 107, 105,  76,  38,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 146,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  45, 105, 109, 111, 111, 111, 111, 110, 111, 108, 105,  87,  51,  37,  38,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 147;
				 144,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  38,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 144;
				 140,  45,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  43, 140;
				 137,  59,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  60, 135;
				 113, 111,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 115, 112;
				  89, 131, 110,  56,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  45,  60, 113, 130,  96;
				   0,  85, 113, 136, 146, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 145, 142, 136, 112,  96,   0];
alpha_map = [	   0,  20, 203, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 251, 197,  18,   0;
				  20, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244,  18;
				 203, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 194;
				 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249;
				 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 230, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 218,  99, 126, 176, 157,  94, 133, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 180, 127, 250, 255, 255, 255, 255, 235,  88, 199, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 233, 122, 255, 255, 255, 255, 255, 255, 255, 254, 144, 193, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 167, 226, 255, 255, 255, 255, 255, 255, 255, 255, 255, 107, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 190, 196, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215, 181, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242, 212, 179, 146,  22, 247, 255, 255, 255, 255, 255, 255, 255, 255, 225, 172, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 206, 174, 142, 110,  86, 102, 123, 153, 189, 215, 235, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 155, 235, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 124,  97, 241, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 108, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 152, 151, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  76, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 199, 101, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 210,  99, 158, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 235,  91, 226, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 219,  93, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 253, 127, 175, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 112, 205, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 183, 117, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 104, 235, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 225,  91, 237, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  94, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 115, 189, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 180, 178, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 175, 143, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  97, 250, 255, 255, 255, 255, 255, 255, 230, 189, 215, 251, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 128, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224, 156, 255, 255, 255, 255, 250, 108, 159, 213, 194, 122, 109, 245, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 197, 210, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 101, 253, 255, 255, 255, 112, 232, 248, 219, 235, 255, 238, 117, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251, 140, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 200, 190, 255, 255, 188, 187, 240,  95, 186, 152, 134, 255, 108, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  98, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 253, 100, 255, 255,  96, 255, 119, 247, 255, 255,  95, 255, 138, 252, 255, 255;
				 255, 255, 255, 255, 255, 252, 176, 177, 252, 255, 255, 255, 255, 255, 255, 255, 143, 237, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 103, 254, 252, 141, 252, 102, 255, 255, 255,  95, 253, 104, 255, 255, 255;
				 255, 162, 153, 153, 153,  88, 211, 212,  67,  69,  80,  88, 108, 110, 119, 130, 125, 233, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 175, 213, 227, 167, 233, 163, 255, 255, 255, 172,  99, 161, 255, 255, 255;
				 255, 239, 237, 237, 234, 245, 255, 255, 165,  96,  76, 123, 199, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 228, 165, 233, 162, 225, 174, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 205, 199, 189, 182, 199, 255, 255, 116, 248, 255, 244, 184, 119,  82, 140, 213, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242, 127, 247, 143, 237, 160, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 208, 204, 204, 204, 170,  97,  98, 197, 255, 255, 255, 255, 255, 255, 240, 178,  89, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 107, 255, 132, 243, 146, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 235, 155, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 253, 101, 255, 127, 245, 131, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  94, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 250, 107, 255, 122, 247, 123, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 124, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242, 133, 255, 140, 240, 145, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 195, 199, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224, 174, 239, 156, 228, 171, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251, 123, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 158, 233, 179, 220, 185, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  91, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  93, 255,  98, 253, 106, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215, 114, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 171, 200, 159, 199, 232, 133, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 201, 117, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223,  38, 101, 191, 254,  84, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 186, 125, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 222, 231, 253, 240, 105, 214, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 172, 141, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 239, 114, 117, 157, 158,  94, 135, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 185,  17, 148, 176, 182, 182, 182, 188, 187, 180, 163, 155, 123,  85, 152, 238, 255, 251, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 230, 221, 221, 221, 221, 221, 228, 238, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254;
				 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249;
				 196, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 192;
				  20, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242,  16;
				   0,  18, 196, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 249, 194,  16,   0];
varargout = {alpha_map};


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_OmniHome_V1_Icon_48px

%VULINTUS_LOAD_OMNIHOME_V1_ICON_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:38:48
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  79,  83,  84,  80, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  88, 210, 210,  89,  83, 255, 255, 255, 255, 255, 255,  73,  75,  75,  75,  75,  75,  70, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  90, 217, 242, 242, 216,  88,  81, 255, 255, 255,  79,  85,  88,  91,  91,  91,  91,  91,  81,  84, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  90, 217, 242, 242, 242, 242, 216,  88,  81, 255, 255,  85, 154, 242, 242, 242, 242, 242, 242, 229,  84,  71, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 217,  90,  83, 255,  89, 185, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 217,  90,  83,  89, 185, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  88, 217, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 216,  89,  80, 185, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  90, 217, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 216,  89, 185, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  88, 217, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 216, 200, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,  81,  87, 215, 242, 244, 247, 249, 249, 247, 243, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 243, 247, 249, 249, 247, 244, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,  82,  88, 215, 244, 251, 240, 187, 161, 162, 191, 244, 250, 243, 242, 242, 242, 242, 242, 242, 242, 242, 243, 250, 244, 191, 162, 161, 187, 240, 251, 244, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  81,  90, 216, 245, 249, 159,  82,  77,  77,  77,  77,  85, 172, 252, 244, 242, 242, 242, 242, 242, 242, 244, 252, 172,  85,  77,  77,  77,  77,  82, 159, 249, 245, 242, 104,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,  82,  88, 215, 243, 251, 126,  77,  77,  77,  77,  77,  77,  77,  77, 143, 252, 243, 242, 242, 242, 242, 243, 252, 143,  77,  77,  77,  77,  77,  77,  77,  77, 126, 251, 243, 218,  90,  83, 255, 255, 255, 255, 255;
				 255, 255, 255, 255,  82,  88, 215, 242, 251, 165,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 184, 249, 242, 242, 242, 242, 249, 184,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 164, 251, 242, 218,  90,  83, 255, 255, 255, 255;
				 255, 255, 255,  82,  88, 215, 242, 243, 245,  85,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  97, 252, 242, 242, 242, 242, 252,  97,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  85, 245, 243, 242, 218,  90,  83, 255, 255, 255;
				 255, 255,  82,  88, 215, 242, 242, 246, 199,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 219, 246, 244, 244, 246, 219,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 198, 246, 242, 242, 217,  90,  83, 255, 255;
				 255,  82,  88, 215, 242, 242, 242, 248, 174,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 179, 231, 231, 231, 231, 179,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 174, 248, 242, 242, 242, 217,  90,  83, 255;
				  78,  88, 216, 242, 242, 242, 242, 248, 179,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 178, 248, 242, 242, 242, 242, 217,  90,  79;
				  89, 188, 242, 242, 242, 242, 242, 246, 212,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 212, 246, 242, 242, 242, 242, 242, 187,  90;
				  86, 137, 217, 220, 220, 220, 220, 224, 252,  99,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  99, 252, 224, 220, 220, 220, 220, 217, 136,  87;
				  77,  87,  86,  86,  86,  86,  84,  98, 249, 198,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 198, 249,  98,  84,  86,  86,  86,  86,  87,  77;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 252, 172,  78,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  78, 172, 252, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 243, 252, 209, 117,  77,  77,  77,  78, 125, 174,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77, 173, 125,  78,  77,  77,  77, 117, 209, 252, 243, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 247, 253, 238, 211, 212, 242, 252, 253, 143,  77,  77,  77,  77,  77,  77,  77,  77, 143, 253, 252, 242, 212, 211, 238, 253, 247, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 244, 245, 245, 243, 242, 244, 245,  97,  77,  77,  77,  77,  77,  77,  94, 243, 244, 242, 243, 245, 245, 244, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 248, 203,  77,  77, 130, 130,  77,  77, 199, 248, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 252, 144,  92, 254, 254,  92, 143, 253, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 244, 244,  98, 188, 188,  95, 243, 245, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 248, 207,  78,  77, 199, 248, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 252, 144, 143, 253, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 244, 243, 243, 244, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 245, 245, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 247, 248, 244, 242, 242, 242, 244, 248, 246, 242, 242, 242, 243, 247, 248, 243, 242, 242, 242, 246, 248, 245, 242, 242, 242, 244, 248, 247, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 241, 198, 148, 244, 245, 242, 246, 240, 144, 209, 241, 242, 242, 245, 203, 184, 248, 244, 242, 244, 230, 174, 239, 245, 242, 245, 247, 178, 215, 244, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 244, 230,   9,   7, 102, 239, 242, 238,  82,   7,  14, 243, 243, 246, 218,  77,  77, 169, 246, 242, 250,  90,  77, 112, 245, 242, 242, 145,  77,  79, 237, 244,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 244, 231,  10,   7, 105, 239, 242, 238,  84,   7,  16, 243, 243, 246, 220,  77,  77, 171, 246, 242, 250,  90,  77, 113, 244, 242, 242, 147,  77,  79, 238, 244,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 241, 204, 155, 244, 245, 242, 246, 242, 151, 213, 241, 242, 242, 245, 208, 189, 248, 244, 242, 244, 232, 179, 241, 246, 242, 245, 247, 183, 219, 244, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 246, 248, 244, 242, 242, 242, 244, 248, 246, 242, 242, 242, 242, 247, 247, 243, 242, 242, 242, 246, 248, 245, 242, 242, 242, 244, 248, 246, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  79,  95, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242,  95,  79, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  73,  83, 217, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 217,  83,  78, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,  83,  82,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  77,  84,  81, 255, 255, 255, 255, 255, 255, 255];
im(:,:,2) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 191, 192, 192, 193, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 212, 212, 193, 190, 255, 255, 255, 255, 255, 255, 191, 188, 188, 188, 188, 188, 185, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 213, 217, 217, 213, 194, 192, 255, 255, 255, 193, 192, 193, 194, 194, 194, 194, 194, 191, 193, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 213, 217, 217, 217, 217, 213, 194, 192, 255, 255, 190, 203, 217, 217, 217, 217, 217, 217, 215, 192, 184, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 213, 193, 190, 255, 193, 208, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 213, 193, 190, 193, 208, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 213, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 213, 193, 192, 208, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 213, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 213, 193, 208, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 194, 213, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 213, 211, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 217, 222, 232, 237, 237, 232, 221, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 221, 232, 237, 237, 232, 222, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 193, 193, 212, 222, 243, 249, 231, 221, 222, 232, 250, 241, 220, 217, 217, 217, 217, 217, 217, 217, 217, 220, 241, 250, 232, 222, 221, 231, 249, 243, 222, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 192, 194, 213, 226, 250, 220, 193, 191, 191, 191, 191, 194, 225, 250, 223, 217, 217, 217, 217, 217, 217, 223, 250, 225, 194, 191, 191, 191, 191, 193, 220, 250, 226, 217, 195, 192, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 193, 193, 212, 221, 251, 209, 191, 191, 191, 191, 191, 191, 191, 191, 215, 250, 219, 217, 217, 217, 217, 219, 250, 215, 191, 191, 191, 191, 191, 191, 191, 191, 209, 251, 221, 214, 193, 190, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 193, 193, 212, 217, 242, 223, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 230, 238, 217, 217, 217, 217, 238, 230, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 222, 242, 217, 214, 193, 190, 255, 255, 255, 255;
				 255, 255, 255, 193, 193, 212, 217, 220, 250, 194, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 198, 252, 218, 217, 217, 218, 252, 198, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 194, 250, 220, 217, 214, 193, 190, 255, 255, 255;
				 255, 255, 193, 193, 212, 217, 217, 230, 235, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 242, 229, 222, 222, 229, 242, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 235, 230, 217, 217, 213, 193, 190, 255, 255;
				 255, 193, 193, 212, 217, 217, 217, 234, 226, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 228, 246, 246, 246, 246, 228, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 226, 234, 217, 217, 217, 213, 193, 190, 255;
				 193, 194, 213, 217, 217, 217, 217, 234, 228, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 227, 234, 217, 217, 217, 217, 213, 193, 192;
				 194, 208, 217, 217, 217, 217, 217, 227, 239, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 239, 227, 217, 217, 217, 217, 217, 209, 193;
				 192, 200, 213, 213, 213, 213, 213, 215, 252, 199, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 199, 252, 215, 213, 213, 213, 213, 213, 200, 192;
				 179, 192, 193, 193, 193, 193, 192, 195, 236, 234, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 234, 236, 195, 192, 193, 193, 193, 193, 193, 179;
				 255, 255, 255, 255, 255, 255, 188, 195, 218, 247, 225, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 225, 247, 218, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 220, 246, 238, 205, 191, 191, 191, 191, 208, 226, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 226, 208, 191, 191, 191, 191, 205, 238, 246, 220, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 232, 249, 249, 239, 240, 250, 248, 249, 215, 191, 191, 191, 191, 191, 191, 191, 191, 215, 249, 248, 250, 240, 239, 249, 249, 232, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 222, 227, 226, 221, 217, 224, 250, 198, 191, 191, 191, 191, 191, 191, 197, 250, 224, 217, 221, 226, 227, 222, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 236, 236, 191, 191, 210, 210, 191, 191, 235, 236, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 218, 247, 215, 196, 255, 255, 196, 215, 248, 218, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 223, 250, 198, 231, 231, 197, 250, 224, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 236, 238, 191, 191, 235, 236, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 218, 248, 215, 215, 248, 218, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 224, 250, 250, 224, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 226, 226, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 218, 231, 234, 223, 217, 217, 217, 224, 235, 230, 217, 217, 217, 218, 232, 234, 221, 217, 217, 217, 228, 235, 226, 217, 217, 217, 223, 234, 231, 218, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 243, 239, 227, 251, 225, 217, 228, 250, 226, 242, 240, 217, 218, 247, 235, 229, 251, 222, 217, 236, 244, 225, 248, 232, 217, 226, 251, 227, 239, 243, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 224, 247, 191, 191, 216, 241, 217, 243, 210, 191, 193, 251, 220, 228, 240, 191, 191, 224, 237, 218, 252, 196, 191, 204, 248, 217, 241, 215, 191, 192, 247, 224, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 224, 247, 192, 191, 216, 240, 217, 243, 211, 191, 193, 251, 220, 228, 241, 191, 191, 224, 237, 218, 252, 196, 191, 204, 248, 217, 241, 216, 191, 192, 247, 223, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 242, 240, 228, 251, 225, 217, 228, 250, 228, 242, 239, 217, 218, 246, 236, 230, 250, 222, 217, 235, 245, 227, 249, 230, 217, 225, 251, 228, 240, 242, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 230, 234, 222, 217, 217, 217, 223, 234, 229, 217, 217, 217, 218, 231, 233, 221, 217, 217, 217, 227, 234, 225, 217, 217, 217, 222, 234, 230, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 188, 195, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 195, 188, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 182, 192, 213, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 213, 192, 196, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 193, 192, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 192, 255, 255, 255, 255, 255, 255, 255];
im(:,:,3) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  50,  50,  50,  50, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  41,  41,  51,  52, 255, 255, 255, 255, 255, 255,  55,  53,  53,  53,  53,  53,  46, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  40,  38,  38,  40,  51,  50, 255, 255, 255,  53,  51,  50,  50,  50,  50,  50,  50,  50,  50, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  40,  38,  38,  38,  38,  40,  51,  50, 255, 255,  49,  46,  38,  38,  38,  38,  38,  38,  39,  51,  57, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  40,  50,  52, 255,  49,  43,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  40,  50,  52,  49,  43,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  40,  51,  51,  43,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  40,  50,  43,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  51,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  40,  41,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,  49,  50,  40,  38,  67, 126, 153, 152, 121,  61,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  61, 121, 152, 153, 126,  67,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,  51,  50,  40,  66, 188, 236, 177, 148, 149, 181, 240, 176,  57,  38,  38,  38,  38,  38,  38,  38,  38,  57, 176, 240, 181, 149, 148, 177, 236, 188,  66,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  50,  51,  40,  87, 236, 145,  57,  51,  51,  51,  51,  61, 160, 229,  72,  38,  38,  38,  38,  38,  38,  72, 229, 160,  61,  51,  51,  51,  51,  57, 145, 236,  87,  38,  49,  51, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,  51,  50,  40,  63, 234, 107,  51,  51,  51,  51,  51,  51,  51,  51, 126, 224,  50,  38,  38,  38,  38,  50, 224, 126,  51,  51,  51,  51,  51,  51,  51,  51, 107, 234,  63,  39,  50,  52, 255, 255, 255, 255, 255;
				 255, 255, 255, 255,  51,  50,  40,  38, 180, 152,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 174, 155,  38,  38,  38,  38, 155, 174,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 151, 180,  38,  39,  50,  52, 255, 255, 255, 255;
				 255, 255, 255,  51,  50,  40,  38,  58, 242,  61,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  73, 240,  43,  38,  38,  43, 240,  73,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  60, 242,  58,  38,  39,  50,  52, 255, 255, 255;
				 255, 255,  51,  50,  40,  38,  38, 109, 191,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 213, 106,  67,  67, 106, 213,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 190, 110,  38,  38,  40,  50,  52, 255, 255;
				 255,  51,  50,  40,  38,  38,  38, 137, 162,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 168, 228, 228, 228, 228, 168,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 162, 137,  38,  38,  38,  40,  50,  52, 255;
				  49,  51,  40,  38,  38,  38,  38, 132, 168,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 167, 132,  38,  38,  38,  38,  40,  50,  50;
				  49,  43,  38,  38,  38,  38,  38,  97, 205,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 205,  97,  38,  38,  38,  38,  38,  42,  50;
				  50,  46,  40,  40,  40,  40,  40,  48, 240,  77,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  77, 240,  48,  40,  40,  40,  40,  40,  46,  51;
				  51,  49,  50,  51,  51,  51,  50,  50, 147, 189,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 189, 147,  50,  50,  51,  51,  51,  50,  49,  51;
				 255, 255, 255, 255, 255, 255,  49,  50,  44, 210, 160,  52,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  52, 160, 210,  44,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  54, 204, 202,  97,  51,  51,  51,  53, 106, 162,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51, 161, 106,  53,  51,  51,  51,  97, 202, 204,  54,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  41, 126, 222, 235, 205, 206, 240, 212, 220, 127,  51,  51,  51,  51,  51,  51,  51,  51, 126, 221, 212, 240, 206, 205, 235, 223, 126,  41,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  64,  92,  91,  59,  38,  77, 238,  74,  51,  51,  51,  51,  51,  51,  71, 236,  78,  38,  59,  91,  92,  64,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 144, 196,  51,  51, 112, 112,  51,  51, 191, 145,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  41, 211, 128,  68, 254, 254,  68, 127, 215,  42,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  74, 237,  75, 178, 178,  72, 238,  81,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38, 144, 200,  52,  51, 191, 146,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  42, 212, 128, 127, 214,  42,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  77, 236, 236,  78,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  89,  89,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  41, 116, 138,  71,  38,  38,  38,  79, 138, 109,  40,  38,  38,  47, 123, 134,  62,  38,  38,  38, 101, 140,  87,  38,  38,  38,  72, 138, 115,  41,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  39, 192, 197, 162, 236,  87,  38, 102, 233, 159, 206, 175,  38,  44, 213, 186, 167, 235,  67,  38, 152, 216, 158, 227, 122,  38,  87, 236, 162, 198, 192,  39,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  76, 223,  53,  51, 129, 179,  38, 198, 113,  51,  57, 237,  58, 102, 200,  51,  51, 153, 153,  42, 243,  65,  51,  91, 221,  38, 181, 129,  51,  53, 224,  75,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  75, 224,  53,  51, 131, 179,  38, 197, 114,  51,  58, 238,  57, 101, 203,  51,  51, 155, 152,  41, 243,  66,  51,  92, 220,  38, 179, 130,  51,  53, 224,  75,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  39, 189, 201, 166, 236,  83,  38,  98, 234, 163, 209, 170,  38,  43, 210, 190, 172, 233,  65,  38, 148, 218, 163, 229, 119,  38,  85, 236, 166, 202, 187,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  41, 112, 132,  69,  38,  38,  38,  75, 135, 104,  39,  38,  38,  46, 120, 129,  59,  38,  38,  38,  97, 135,  83,  38,  38,  38,  69, 132, 111,  41,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  49,  50,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  50,  49, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,  55,  51,  40,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  40,  51,  59, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,  52,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  51,  50,  53, 255, 255, 255, 255, 255, 255, 255];
alpha_map = [	   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  87, 239, 238,  86,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 246,  98,   0,   0,   0,   0,   0,   0,  28,  34,  34,  34,  34,  34,  11,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 255, 255, 245,  97,   0,   0,   0,  29, 226, 244, 241, 241, 241, 241, 241, 248, 127,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 255, 255, 255, 255, 245,  97,   0,   0, 150, 251, 255, 255, 255, 255, 255, 255, 255, 247,  18,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0, 181, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98, 181, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246, 233, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,  98, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  97, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243, 106,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0,   0,   0,   0;
				   0,   0,   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0,   0,   0;
				   0,   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0,   0;
				   0,  90, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  98,   0;
				  78, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  77;
				 192, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 189;
				 149, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 146;
				  10, 173, 230, 232, 232, 232, 236, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246, 236, 232, 232, 232, 230, 172,  10;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  42, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  42,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,  14, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  13,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,  98, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  97,   0,   0,   0,   0,   0,   0,   0];
varargout = {alpha_map};


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_OmniTrak_V1_Icon_48px

%VULINTUS_LOAD_OMNITRAK_V1_ICON_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:39:04
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	   0,  73,  87,  86,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  88,  86,  85,   0;
				  73,  87, 136, 227, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 227, 135,  86,  85;
				  87, 136, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 134,  87;
				  86, 227, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 225,  87;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 247,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 249, 243, 235, 230, 227, 232, 237, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 249, 241, 235, 230, 228, 232, 237, 249, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 240, 220, 131,  84,  78,  78,  78,  98, 164, 235, 247, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 239, 215, 126,  81,  78,  78,  78, 102, 172, 236, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 238, 147,  78,  78,  78,  78,  78,  78,  78,  78,  88, 209, 243, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 249, 237, 136,  78,  78,  78,  78,  78,  78,  78,  78,  92, 217, 244, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 240, 127,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  79, 203, 245, 248, 248, 248, 248, 248, 248, 248, 248, 248, 238, 115,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  81, 214, 247, 248, 248, 248,  80;
				  80, 248, 248, 248, 245, 168,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  84, 231, 248, 248, 248, 248, 248, 248, 248, 248, 243, 153,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  88, 234, 248, 248, 248,  80;
				  80, 248, 248, 248, 234,  83,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 138, 242, 248, 248, 248, 248, 248, 248, 248, 230,  79,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 155, 244, 248, 248,  80;
				  80, 248, 248, 250, 185,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  80, 234, 248, 248, 248, 248, 248, 248, 249, 168,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  86, 236, 248, 248,  80;
				  80, 248, 248, 243, 127,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 216, 248, 248, 248, 248, 248, 248, 238, 115,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 225, 248, 248,  80;
				  80, 248, 248, 237, 108,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 196, 245, 244, 244, 244, 244, 244, 241,  99,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 209, 249, 248,  80;
				  80, 248, 248, 238, 110,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 110, 137, 137, 137, 137, 137, 137, 137,  81,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 212, 249, 248,  80;
				  80, 248, 248, 244, 131,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 227, 248, 248,  80;
				  80, 248, 248, 249, 193,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  90, 236, 248, 248,  80;
				  80, 248, 248, 248, 235,  87,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 166, 245, 248, 248,  80;
				  80, 248, 248, 248, 246, 184,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  95, 236, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 240, 144,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  86, 223, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 241, 171,  81,  78,  78,  78,  78,  78,  78,  78,  81,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  86,  79,  78,  78,  78,  78,  78,  78,  78, 105, 228, 247, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 244, 231, 156,  97,  78,  78,  81, 116, 202, 239,  95,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 212, 228, 146,  93,  78,  78,  81, 122, 198, 238, 249, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 247, 236, 235, 232, 236, 239, 249, 249, 209,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78, 150, 241, 248, 245, 236, 233, 233, 236, 241, 249, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 241, 140,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  97, 237, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 235,  90,  78,  78,  78,  78,  78,  78,  78,  78,  79, 215, 249, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 201,  78,  78,  78,  78,  78,  78,  78,  78, 155, 242, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 240, 130,  78,  78,  78,  78,  78,  78, 100, 238, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 233,  87,  78,  78,  78,  78,  79, 220, 249, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 247, 192,  78,  83,  83,  78, 161, 243, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 240, 122, 180, 179, 102, 238, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 249, 231,  96,  91, 221, 249, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 246, 182, 167, 243, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 238, 238, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 249, 249, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,  80;
				  80, 248, 248, 249, 235, 223, 230, 246, 248, 248, 248, 248, 248, 238, 225, 226, 241, 248, 248, 248, 248, 248, 242, 227, 225, 237, 248, 248, 248, 248, 248, 243, 227, 224, 236, 248, 248, 248, 248, 248, 244, 228, 224, 235, 248, 248, 248,  80;
				  80, 248, 248, 229, 102,  78,  81, 194, 246, 248, 248, 248, 235, 127,  78,  78, 154, 239, 248, 248, 248, 240, 164,  79,  78, 120, 234, 248, 248, 248, 241, 170,  79,  78, 116, 233, 248, 248, 248, 243, 182,  80,  78, 109, 232, 248, 248,  80;
				  80, 248, 247, 138,  78,  78,  78,  81, 229, 248, 248, 249, 191,  78,  78,  78,  78, 217, 248, 248, 248, 221,  78,  78,  78,  78, 180, 249, 248, 248, 223,  78,  78,  78,  78, 170, 250, 248, 248, 226,  79,  78,  78,  78, 156, 249, 248,  80;
				  80, 248, 240, 113,  78,  78,  78,  78, 222, 248, 248, 250, 162,  78,  78,  78,  78, 200, 248, 248, 248, 210,  78,  78,  78,  78, 148, 250, 248, 248, 214,  78,  78,  78,  78, 138, 248, 248, 248, 218,  78,  78,  78,  78, 126, 245, 248,  80;
				  80, 248, 249, 176,  78,  78,  78, 100, 234, 248, 248, 248, 216,  78,  78,  78,  83, 227, 248, 248, 248, 229,  86,  78,  78,  78, 209, 249, 248, 248, 230,  88,  78,  78,  78, 202, 249, 248, 248, 231,  93,  78,  78,  78, 192, 249, 248,  80;
				  80, 248, 248, 236, 175, 111, 136, 228, 249, 248, 248, 248, 241, 200, 116, 122, 216, 246, 248, 248, 248, 247, 219, 125, 114, 195, 239, 248, 248, 248, 248, 222, 127, 113, 191, 239, 248, 248, 248, 249, 225, 131, 112, 184, 237, 248, 247,  80;
				  86, 227, 248, 248, 249, 238, 245, 248, 248, 248, 248, 248, 248, 249, 240, 243, 249, 248, 248, 248, 248, 248, 249, 244, 240, 249, 248, 248, 248, 248, 248, 249, 244, 239, 249, 248, 248, 248, 248, 248, 248, 244, 239, 249, 248, 248, 225,  87;
				  86, 134, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 133,  88;
				  73,  86, 134, 225, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 225, 133,  88,  85;
				   0,  85,  88,  87,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,  87,  88,  85,   0];
im(:,:,2) = [	   0, 182, 190, 190, 188, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 188, 190, 191, 170,   0;
				 182, 191, 199, 212, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 212, 199, 190, 170;
				 190, 198, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 199, 191;
				 191, 212, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 211, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 220, 233, 241, 241, 240, 241, 239, 228, 216, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 221, 233, 241, 241, 241, 241, 238, 227, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 216, 234, 239, 209, 191, 189, 189, 189, 197, 220, 243, 225, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 216, 237, 236, 207, 190, 189, 189, 189, 198, 222, 242, 223, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 217, 241, 213, 189, 189, 189, 189, 189, 189, 189, 189, 193, 235, 230, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 218, 242, 210, 189, 189, 189, 189, 189, 189, 189, 189, 194, 238, 227, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 241, 207, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 233, 227, 215, 215, 215, 215, 215, 215, 215, 215, 216, 242, 203, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 190, 237, 225, 215, 215, 215, 190;
				 190, 215, 215, 215, 229, 221, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 191, 242, 217, 215, 215, 215, 215, 215, 215, 215, 232, 215, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 193, 243, 216, 215, 215, 190;
				 190, 215, 215, 215, 243, 191, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 211, 233, 215, 215, 215, 215, 215, 215, 216, 242, 190, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 217, 231, 215, 215, 190;
				 190, 215, 215, 224, 226, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 190, 242, 215, 215, 215, 215, 215, 215, 227, 220, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 192, 241, 215, 215, 190;
				 190, 215, 215, 232, 207, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 237, 217, 215, 215, 215, 215, 215, 235, 203, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 240, 215, 215, 190;
				 190, 215, 215, 235, 200, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 230, 234, 230, 230, 230, 230, 230, 244, 197, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 235, 218, 215, 190;
				 190, 215, 215, 235, 201, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 201, 211, 211, 211, 211, 211, 211, 211, 190, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 235, 218, 215, 190;
				 190, 215, 215, 232, 209, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 241, 215, 215, 190;
				 190, 215, 215, 223, 228, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 194, 240, 215, 215, 190;
				 190, 215, 215, 215, 243, 192, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 221, 229, 215, 215, 190;
				 190, 215, 215, 215, 227, 227, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 195, 242, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 238, 212, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 192, 240, 222, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 216, 239, 222, 190, 189, 189, 189, 189, 189, 189, 189, 190, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 192, 189, 189, 189, 189, 189, 189, 189, 189, 199, 241, 225, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 230, 242, 217, 196, 189, 189, 190, 203, 233, 247, 195, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 236, 241, 214, 194, 189, 189, 190, 205, 231, 240, 221, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 217, 229, 238, 241, 241, 241, 235, 222, 223, 235, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 214, 234, 218, 230, 239, 242, 241, 241, 234, 223, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 235, 211, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 196, 242, 216, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 217, 243, 194, 189, 189, 189, 189, 189, 189, 189, 189, 189, 237, 223, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 224, 232, 189, 189, 189, 189, 189, 189, 189, 189, 217, 233, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 237, 208, 189, 189, 189, 189, 189, 189, 197, 243, 216, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 217, 243, 192, 189, 189, 189, 189, 190, 239, 222, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 226, 228, 189, 190, 190, 189, 219, 232, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 239, 206, 204, 204, 198, 242, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 218, 242, 193, 192, 239, 221, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 228, 226, 220, 230, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 240, 242, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 219, 220, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 190;
				 190, 215, 215, 218, 236, 237, 238, 225, 215, 215, 215, 215, 216, 232, 237, 237, 230, 215, 215, 215, 215, 215, 229, 237, 237, 233, 216, 215, 215, 215, 215, 228, 237, 237, 234, 217, 215, 215, 215, 215, 227, 237, 237, 235, 218, 215, 215, 190;
				 190, 215, 216, 239, 198, 189, 190, 229, 225, 215, 215, 215, 237, 207, 189, 189, 216, 232, 215, 215, 215, 231, 219, 189, 189, 204, 238, 215, 215, 215, 230, 221, 189, 189, 202, 239, 215, 215, 215, 228, 225, 190, 189, 201, 240, 216, 215, 190;
				 190, 215, 228, 211, 189, 189, 189, 190, 238, 215, 215, 220, 228, 189, 189, 189, 189, 236, 215, 215, 215, 237, 189, 189, 189, 189, 224, 222, 215, 215, 237, 189, 189, 189, 189, 221, 224, 215, 215, 238, 190, 189, 189, 189, 216, 225, 215, 190;
				 190, 215, 232, 202, 189, 189, 189, 189, 236, 215, 215, 224, 218, 189, 189, 189, 189, 230, 218, 215, 216, 234, 189, 189, 189, 189, 214, 227, 215, 215, 235, 189, 189, 189, 189, 211, 228, 215, 215, 236, 189, 189, 189, 189, 207, 229, 215, 190;
				 190, 215, 224, 223, 189, 189, 189, 197, 236, 215, 215, 217, 236, 189, 189, 189, 191, 239, 215, 215, 215, 238, 192, 189, 189, 189, 234, 219, 215, 215, 238, 193, 189, 189, 189, 231, 220, 215, 215, 237, 195, 189, 189, 189, 228, 222, 215, 190;
				 190, 215, 215, 234, 223, 201, 210, 239, 219, 215, 215, 215, 228, 231, 203, 206, 236, 223, 215, 215, 215, 223, 237, 206, 202, 229, 229, 215, 215, 215, 221, 238, 207, 202, 228, 230, 215, 215, 215, 220, 239, 209, 202, 226, 232, 215, 215, 190;
				 191, 212, 215, 215, 224, 232, 229, 217, 215, 215, 215, 215, 215, 221, 231, 230, 219, 215, 215, 215, 215, 215, 218, 230, 231, 222, 215, 215, 215, 215, 215, 218, 230, 231, 222, 215, 215, 215, 215, 215, 217, 229, 231, 223, 215, 215, 211, 191;
				 191, 198, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 198, 190;
				 182, 190, 199, 211, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 215, 211, 198, 190, 170;
				   0, 170, 190, 190, 190, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 189, 190, 190, 190, 170,   0];
im(:,:,3) = [	   0,  73,  56,  55,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  55,  54,  43,   0;
				  73,  55,  50,  39,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  39,  50,  55,  43;
				  56,  49,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  50,  55;
				  55,  39,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  39,  55;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  55;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  62, 140, 196, 199, 199, 198, 180, 111,  40,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  68, 146, 197, 199, 199, 199, 175, 105,  39,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  41, 154, 195, 115,  62,  56,  56,  56,  79, 145, 205,  94,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  45, 164, 190, 110,  60,  56,  56,  56,  83, 152, 202,  86,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  48, 193, 126,  56,  56,  56,  56,  56,  56,  56,  56,  67, 186, 127,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  55, 199, 115,  56,  56,  56,  56,  56,  56,  56,  56,  72, 194, 113,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  40, 187, 108,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  57, 180, 105,  37,  37,  37,  37,  37,  37,  37,  37,  42, 196,  97,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  59, 191,  91,  37,  37,  37,  56;
				  56,  37,  37,  37, 122, 148,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  63, 205,  49,  37,  37,  37,  37,  37,  37,  37, 139, 133,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  68, 206,  43,  37,  37,  56;
				  56,  37,  37,  39, 206,  61,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 119, 144,  37,  37,  37,  37,  37,  37,  45, 204,  58,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 135, 127,  37,  37,  56;
				  56,  37,  37,  87, 160,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  58, 201,  37,  37,  37,  37,  37,  37, 104, 146,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  65, 194,  37,  37,  56;
				  56,  37,  37, 139, 111,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 190,  50,  37,  37,  37,  37,  37, 155,  97,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 199,  38,  37,  56;
				  56,  37,  37, 161,  90,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 171, 144, 125, 125, 125, 125, 125, 206,  79,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 182,  56,  37,  56;
				  56,  37,  37, 158,  92,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  92, 122, 122, 122, 122, 122, 122, 122,  60,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 184,  53,  37,  56;
				  56,  37,  37, 135, 115,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 200,  38,  37,  56;
				  56,  37,  37,  79, 167,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  70, 188,  37,  37,  56;
				  56,  37,  37,  38, 204,  66,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 145, 116,  37,  37,  56;
				  56,  37,  37,  37, 108, 162,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  76, 202,  40,  37,  37,  56;
				  56,  37,  37,  37,  37, 171, 125,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  65, 199,  75,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  42, 178, 149,  59,  56,  56,  56,  56,  56,  56,  56,  60,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  65,  57,  56,  56,  56,  56,  56,  56,  56,  86, 203,  94,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  38, 128, 204, 137,  78,  56,  56,  59,  99, 178, 225,  75,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 189, 203, 128,  72,  56,  56,  60, 105, 173, 188,  68,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  48, 116, 178, 198, 198, 197, 159,  77,  83, 185,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56, 130, 150,  52, 127, 183, 199, 198, 194, 151,  80,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 157, 120,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  77, 201,  42,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  46, 205,  70,  56,  56,  56,  56,  56,  56,  56,  56,  57, 192,  81,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  92, 177,  56,  56,  56,  56,  56,  56,  56,  56, 136, 144,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 167, 112,  56,  56,  56,  56,  56,  56,  81, 203,  41,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  49, 206,  66,  56,  56,  56,  56,  58, 197,  75,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 100, 168,  56,  55,  55,  56, 141, 138,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 178, 103,  45,  45,  83, 198,  40,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  53, 205,  60,  57, 197,  69,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 114, 158, 146, 131,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37, 186, 195,  39,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  60,  65,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  56;
				  56,  37,  37,  56, 165, 182, 180,  97,  37,  37,  37,  37,  43, 146, 183, 182, 126,  38,  37,  37,  37,  37, 120, 182, 183, 150,  45,  37,  37,  37,  37, 115, 182, 183, 154,  47,  37,  37,  37,  37, 106, 182, 183, 159,  51,  37,  37,  56;
				  56,  37,  45, 192,  83,  56,  60, 169,  98,  37,  37,  37, 173, 106,  56,  56, 133, 145,  37,  37,  37, 134, 141,  57,  56, 100, 180,  37,  37,  37, 126, 148,  57,  56,  96, 184,  38,  37,  37, 113, 158,  58,  56,  90, 189,  40,  37,  56;
				  56,  37, 114, 121,  56,  56,  56,  60, 182,  37,  37,  64, 162,  56,  56,  56,  56, 185,  40,  37,  37, 187,  56,  56,  56,  56, 153,  76,  37,  37, 186,  56,  56,  56,  56, 146,  85,  37,  37, 184,  58,  56,  56,  56, 134,  98,  37,  56;
				  56,  37, 137,  96,  56,  56,  56,  56, 182,  37,  37,  87, 139,  56,  56,  56,  56, 170,  52,  37,  42, 178,  56,  56,  56,  56, 129, 100,  37,  39, 182,  56,  56,  56,  56, 122, 109,  37,  37, 183,  56,  56,  56,  56, 110, 122,  37,  56;
				  56,  37,  87, 153,  56,  56,  56,  81, 167,  37,  37,  49, 185,  56,  56,  56,  61, 189,  37,  37,  37, 186,  65,  56,  56,  56, 178,  57,  37,  37, 182,  68,  56,  56,  56, 173,  63,  37,  37, 176,  73,  56,  56,  56, 164,  73,  37,  56;
				  56,  37,  37, 155, 152,  93, 119, 192,  58,  37,  37,  37, 117, 172,  99, 106, 186,  88,  37,  37,  37,  80, 189, 108,  97, 167, 126,  37,  37,  37,  75, 190, 111,  95, 163, 133,  37,  37,  37,  67, 191, 115,  94, 158, 143,  37,  37,  55;
				  55,  39,  37,  37,  88, 140, 116,  46,  37,  37,  37,  37,  37,  70, 134, 127,  58,  37,  37,  37,  37,  37,  55, 124, 136,  75,  37,  37,  37,  37,  37,  53, 123, 137,  77,  37,  37,  37,  37,  37,  50, 120, 139,  82,  37,  37,  39,  56;
				  54,  50,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  49,  56;
				  73,  55,  50,  39,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  37,  40,  49,  56,  43;
				   0,  43,  55,  55,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  56,  55,  55,  43,   0];
alpha_map = [	   0,   7, 137, 237, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 236, 136,   6,   0;
				   7, 214, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 213,   6;
				 137, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 135;
				 236, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 235;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251;
				 236, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 234;
				 136, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 133;
				   7, 213, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 211,   6;
				   0,   6, 134, 235, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 235, 134,   6,   0];
varargout = {alpha_map};


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_SensiTrak_V1_Icon_48px

%VULINTUS_LOAD_SENSITRAK_V1_ICON_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:39:21
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 129, 128, 131, 255;
				 128, 131, 189, 235, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 235, 192, 131, 123;
				 128, 189, 242, 242, 242, 242, 242, 242, 238, 176, 129, 128, 141, 193, 238, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 238, 192, 140, 128, 129, 177, 238, 242, 242, 242, 242, 242, 242, 188, 128;
				 129, 235, 242, 242, 242, 242, 242, 225, 149, 128, 131, 182, 238, 242, 242, 242, 242, 239, 213, 185, 163, 145, 135, 130, 130, 135, 145, 164, 185, 214, 239, 242, 242, 242, 242, 238, 181, 130, 128, 149, 226, 242, 242, 242, 242, 242, 234, 129;
				 128, 242, 242, 242, 242, 242, 215, 135, 128, 145, 221, 242, 242, 242, 242, 220, 174, 135, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 135, 174, 220, 242, 242, 242, 242, 220, 144, 128, 136, 216, 242, 242, 242, 242, 242, 128;
				 128, 242, 242, 242, 242, 210, 132, 128, 165, 237, 242, 242, 242, 220, 160, 128, 128, 128, 149, 179, 204, 221, 235, 240, 240, 235, 221, 204, 178, 149, 128, 128, 128, 160, 221, 242, 242, 242, 236, 163, 128, 132, 210, 242, 242, 242, 242, 128;
				 128, 242, 242, 242, 217, 132, 128, 171, 240, 242, 242, 238, 177, 129, 128, 133, 179, 224, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 223, 179, 133, 128, 130, 178, 238, 242, 242, 241, 175, 128, 132, 215, 242, 242, 242, 128;
				 128, 242, 242, 225, 135, 128, 175, 242, 242, 242, 225, 148, 128, 130, 179, 235, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 234, 178, 130, 128, 149, 226, 242, 242, 242, 174, 128, 136, 226, 242, 242, 128;
				 128, 242, 238, 149, 128, 165, 241, 242, 242, 218, 136, 128, 146, 221, 242, 242, 242, 242, 239, 210, 175, 151, 137, 130, 130, 137, 151, 175, 210, 239, 242, 242, 242, 242, 220, 145, 128, 137, 218, 242, 242, 241, 164, 128, 149, 238, 242, 128;
				 128, 242, 176, 128, 145, 237, 242, 242, 217, 133, 128, 163, 237, 242, 242, 242, 230, 175, 133, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 134, 175, 231, 242, 242, 242, 237, 162, 128, 133, 218, 242, 242, 237, 144, 128, 177, 242, 128;
				 128, 242, 129, 131, 221, 242, 242, 225, 136, 128, 169, 241, 242, 242, 238, 183, 132, 128, 128, 150, 186, 215, 232, 240, 240, 232, 215, 185, 150, 128, 128, 132, 184, 238, 242, 242, 240, 169, 128, 137, 226, 242, 242, 220, 130, 129, 242, 128;
				 128, 242, 128, 182, 242, 242, 238, 148, 128, 163, 240, 242, 242, 231, 152, 128, 128, 167, 225, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 225, 166, 128, 128, 153, 231, 242, 242, 240, 162, 128, 150, 238, 242, 242, 180, 128, 242, 128;
				 128, 242, 140, 238, 242, 242, 177, 128, 146, 237, 242, 242, 221, 140, 128, 144, 219, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 218, 143, 128, 141, 221, 242, 242, 237, 145, 128, 179, 242, 242, 237, 140, 242, 128;
				 128, 242, 192, 242, 242, 220, 129, 130, 220, 242, 242, 231, 141, 128, 155, 233, 242, 242, 242, 236, 198, 163, 145, 132, 132, 145, 163, 198, 236, 242, 242, 242, 234, 158, 128, 140, 230, 242, 242, 220, 130, 130, 221, 242, 242, 191, 242, 128;
				 128, 242, 238, 242, 242, 160, 128, 179, 242, 242, 238, 152, 128, 157, 240, 242, 242, 246, 251, 244, 173, 128, 128, 128, 128, 128, 128, 173, 244, 251, 246, 242, 242, 239, 157, 128, 153, 238, 242, 242, 177, 128, 161, 242, 242, 238, 242, 128;
				 128, 242, 242, 242, 220, 128, 133, 235, 242, 242, 183, 128, 144, 234, 242, 242, 243, 246, 178, 251, 242, 206, 225, 238, 238, 224, 206, 242, 251, 178, 246, 243, 242, 242, 233, 143, 128, 185, 242, 242, 234, 133, 128, 220, 242, 242, 242, 128;
				 128, 242, 242, 242, 174, 128, 179, 242, 242, 230, 132, 128, 219, 242, 242, 232, 245, 219, 128, 185, 251, 242, 242, 242, 242, 242, 242, 251, 184, 128, 220, 245, 233, 242, 242, 217, 128, 133, 231, 242, 242, 179, 128, 175, 242, 242, 242, 128;
				 128, 242, 242, 239, 135, 128, 224, 242, 242, 174, 128, 167, 242, 242, 238, 170, 245, 232, 128, 130, 237, 244, 242, 242, 242, 242, 244, 237, 130, 128, 233, 245, 170, 238, 242, 242, 166, 128, 176, 242, 242, 223, 128, 136, 239, 242, 242, 128;
				 128, 242, 242, 213, 128, 149, 242, 242, 239, 134, 128, 225, 242, 242, 187, 134, 240, 253, 136, 128, 186, 250, 242, 242, 242, 242, 250, 185, 128, 137, 253, 240, 133, 188, 242, 242, 224, 128, 134, 239, 242, 242, 148, 128, 214, 242, 242, 128;
				 128, 242, 242, 185, 128, 179, 242, 242, 210, 128, 151, 242, 242, 234, 134, 128, 237, 252, 164, 128, 138, 251, 242, 242, 242, 242, 251, 138, 128, 164, 252, 236, 128, 134, 235, 242, 242, 149, 128, 211, 242, 242, 178, 128, 185, 242, 242, 128;
				 128, 242, 242, 163, 128, 204, 242, 242, 175, 128, 186, 242, 242, 198, 128, 158, 242, 249, 199, 128, 128, 218, 246, 242, 242, 246, 218, 128, 128, 200, 248, 242, 158, 128, 199, 242, 242, 185, 128, 176, 242, 242, 203, 128, 164, 242, 242, 128;
				 128, 242, 242, 146, 128, 222, 242, 242, 151, 128, 215, 242, 242, 227, 163, 197, 242, 244, 243, 131, 128, 176, 251, 242, 242, 251, 175, 128, 131, 244, 244, 242, 196, 164, 227, 242, 242, 214, 128, 152, 242, 242, 221, 128, 147, 242, 242, 128;
				 128, 242, 242, 136, 128, 234, 242, 242, 137, 128, 234, 244, 252, 253, 245, 236, 242, 242, 252, 173, 128, 133, 246, 243, 243, 246, 133, 128, 174, 252, 242, 242, 236, 245, 253, 252, 244, 234, 128, 138, 242, 242, 233, 128, 136, 242, 242, 128;
				 128, 242, 242, 131, 128, 239, 242, 242, 131, 128, 241, 251, 175, 158, 238, 248, 242, 242, 247, 225, 128, 128, 195, 249, 250, 195, 128, 128, 226, 246, 242, 242, 248, 237, 157, 176, 251, 241, 128, 131, 242, 242, 239, 128, 131, 242, 242, 128;
				 128, 242, 242, 131, 128, 239, 242, 242, 131, 128, 241, 250, 195, 128, 137, 224, 249, 242, 242, 253, 138, 128, 136, 213, 213, 136, 128, 138, 253, 242, 242, 249, 224, 136, 128, 196, 249, 241, 128, 131, 242, 242, 239, 128, 131, 242, 242, 128;
				 128, 242, 242, 136, 128, 234, 242, 242, 137, 128, 234, 244, 250, 147, 128, 133, 219, 250, 242, 252, 166, 128, 128, 128, 128, 128, 128, 166, 251, 242, 250, 219, 133, 128, 147, 251, 244, 234, 128, 138, 242, 242, 233, 128, 136, 242, 242, 128;
				 128, 242, 242, 146, 128, 221, 242, 242, 152, 128, 215, 242, 248, 234, 137, 128, 131, 212, 251, 250, 186, 128, 128, 128, 128, 128, 128, 186, 250, 251, 212, 131, 128, 137, 234, 248, 242, 214, 128, 153, 242, 242, 220, 128, 147, 242, 242, 128;
				 128, 242, 242, 163, 128, 204, 242, 242, 175, 128, 185, 242, 242, 250, 228, 134, 128, 129, 196, 253, 175, 128, 128, 128, 128, 128, 128, 176, 253, 196, 129, 128, 134, 228, 250, 242, 242, 185, 128, 176, 242, 242, 203, 128, 164, 242, 242, 128;
				 128, 242, 242, 185, 128, 179, 242, 242, 210, 128, 150, 242, 242, 242, 251, 216, 129, 128, 128, 134, 128, 128, 128, 128, 128, 128, 128, 128, 133, 128, 128, 129, 216, 251, 242, 242, 242, 149, 128, 212, 242, 242, 177, 128, 185, 242, 242, 128;
				 128, 242, 242, 213, 128, 149, 242, 242, 239, 134, 128, 225, 242, 242, 241, 252, 193, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 192, 252, 241, 242, 242, 224, 128, 134, 239, 242, 242, 148, 128, 215, 242, 242, 128;
				 128, 242, 242, 239, 135, 128, 223, 242, 242, 175, 128, 166, 242, 242, 239, 243, 253, 155, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 153, 253, 244, 239, 242, 242, 165, 128, 176, 242, 242, 222, 128, 136, 240, 242, 242, 128;
				 128, 242, 242, 242, 174, 128, 179, 242, 242, 231, 132, 128, 218, 242, 242, 238, 248, 227, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 227, 248, 238, 242, 242, 216, 128, 133, 231, 242, 242, 178, 128, 175, 242, 242, 242, 128;
				 128, 242, 242, 242, 220, 128, 133, 234, 242, 242, 184, 128, 143, 233, 242, 242, 242, 253, 160, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 161, 253, 242, 242, 242, 233, 142, 128, 185, 242, 242, 233, 132, 128, 220, 242, 242, 242, 128;
				 128, 242, 238, 242, 242, 160, 128, 178, 242, 242, 238, 153, 128, 157, 240, 242, 242, 248, 214, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 214, 248, 242, 242, 239, 156, 128, 154, 239, 242, 242, 176, 128, 162, 242, 242, 237, 242, 128;
				 128, 242, 192, 242, 242, 221, 130, 130, 220, 242, 242, 231, 141, 128, 155, 232, 242, 243, 248, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 248, 243, 242, 234, 158, 128, 140, 230, 242, 242, 220, 129, 130, 222, 242, 242, 191, 242, 128;
				 128, 242, 140, 237, 242, 242, 178, 128, 145, 237, 242, 242, 221, 141, 128, 143, 217, 242, 254, 145, 128, 128, 128, 128, 128, 128, 128, 128, 146, 254, 242, 216, 142, 128, 141, 222, 242, 242, 236, 144, 128, 180, 242, 242, 237, 139, 242, 128;
				 128, 242, 128, 181, 242, 242, 238, 149, 128, 162, 240, 242, 242, 231, 153, 128, 128, 221, 251, 179, 128, 128, 128, 128, 128, 128, 128, 128, 180, 251, 221, 128, 128, 154, 231, 242, 242, 240, 161, 128, 150, 239, 242, 242, 179, 128, 242, 128;
				 128, 242, 129, 130, 220, 242, 242, 226, 137, 128, 169, 240, 242, 242, 238, 185, 132, 176, 246, 237, 131, 128, 128, 128, 128, 128, 128, 131, 236, 246, 176, 133, 185, 239, 242, 242, 240, 168, 128, 137, 227, 242, 242, 220, 130, 129, 242, 128;
				 128, 242, 177, 128, 144, 236, 242, 242, 218, 133, 128, 162, 237, 242, 242, 242, 231, 179, 233, 253, 153, 128, 128, 128, 128, 128, 128, 153, 253, 232, 178, 232, 242, 242, 242, 236, 161, 128, 133, 219, 242, 242, 236, 144, 128, 178, 242, 128;
				 128, 242, 238, 149, 128, 163, 241, 242, 242, 218, 137, 128, 145, 220, 242, 242, 242, 242, 242, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 242, 242, 242, 242, 242, 219, 144, 128, 137, 219, 242, 242, 241, 162, 128, 150, 239, 242, 128;
				 128, 242, 242, 226, 136, 128, 174, 242, 242, 242, 226, 150, 128, 130, 177, 234, 242, 242, 242, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 242, 242, 242, 233, 176, 129, 128, 150, 227, 242, 242, 241, 173, 128, 136, 227, 242, 242, 128;
				 128, 242, 242, 242, 218, 132, 128, 171, 240, 242, 242, 238, 179, 130, 128, 133, 179, 223, 242, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 242, 223, 178, 133, 128, 130, 180, 239, 242, 242, 241, 174, 128, 132, 216, 242, 242, 242, 128;
				 128, 242, 242, 242, 242, 210, 132, 128, 164, 236, 242, 242, 242, 221, 161, 128, 128, 128, 224, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 223, 128, 128, 128, 162, 222, 242, 242, 242, 236, 163, 128, 132, 211, 242, 242, 242, 242, 128;
				 128, 242, 242, 242, 242, 242, 216, 135, 128, 144, 220, 242, 242, 242, 242, 220, 175, 136, 219, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 219, 136, 175, 220, 242, 242, 242, 242, 220, 144, 128, 136, 217, 242, 242, 242, 242, 242, 128;
				 128, 235, 242, 242, 242, 242, 242, 226, 149, 128, 130, 180, 237, 242, 242, 242, 242, 239, 237, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 237, 240, 242, 242, 242, 242, 237, 179, 130, 128, 150, 227, 242, 242, 242, 242, 242, 234, 128;
				 128, 192, 242, 242, 242, 242, 242, 242, 238, 177, 129, 128, 139, 191, 238, 242, 242, 242, 242, 252, 153, 128, 128, 128, 128, 128, 128, 153, 252, 242, 242, 242, 242, 237, 191, 139, 128, 129, 178, 239, 242, 242, 242, 242, 242, 242, 191, 128;
				 134, 131, 188, 234, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 242, 234, 191, 130, 128;
				 255, 132, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 255];
im(:,:,2) = [	 255,  27,  27,  25,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27,  28, 255;
				  27,  30, 129, 205, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 205, 133,  30,  28;
				  25, 129, 217, 217, 217, 217, 217, 217, 211, 108,  28,  26,  47, 134, 209, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 209, 133,  45,  26,  29, 109, 211, 217, 217, 217, 217, 217, 217, 127,  26;
				  26, 205, 217, 217, 217, 217, 217, 188,  61,  26,  30, 116, 209, 217, 217, 217, 217, 212, 170, 120,  85,  55,  38,  29,  29,  38,  55,  86, 120, 169, 212, 217, 217, 217, 217, 209, 114,  29,  26,  63, 190, 217, 217, 217, 217, 217, 204,  27;
				  26, 217, 217, 217, 217, 217, 172,  38,  26,  55, 182, 217, 217, 217, 217, 179, 103,  38,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  38, 103, 180, 217, 217, 217, 217, 180,  53,  26,  39, 174, 217, 217, 217, 217, 217,  26;
				  26, 217, 217, 217, 217, 162,  33,  26,  88, 207, 217, 217, 217, 181,  80,  26,  26,  26,  61, 111, 154, 183, 205, 214, 214, 205, 182, 154, 110,  61,  26,  26,  26,  81, 182, 217, 217, 217, 206,  85,  26,  34, 163, 217, 217, 217, 217,  26;
				  26, 217, 217, 217, 175,  34,  26,  98, 214, 217, 217, 210, 109,  29,  26,  36, 112, 186, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 185, 111,  36,  26,  29, 110, 211, 217, 217, 214, 103,  26,  33, 172, 217, 217, 217,  26;
				  26, 217, 217, 189,  38,  26, 103, 217, 217, 217, 188,  59,  26,  29, 112, 205, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 204, 110,  29,  26,  61, 190, 217, 217, 217, 103,  26,  39, 190, 217, 217,  26;
				  26, 217, 211,  61,  26,  89, 214, 217, 217, 176,  40,  26,  56, 182, 217, 217, 217, 217, 212, 163, 103,  66,  42,  29,  29,  42,  66, 104, 163, 212, 217, 217, 217, 217, 180,  55,  26,  41, 177, 217, 217, 214,  86,  26,  63, 211, 217,  26;
				  26, 217, 107,  26,  55, 208, 217, 217, 175,  35,  26,  85, 208, 217, 217, 217, 198, 103,  36,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  37, 103, 199, 217, 217, 217, 208,  84,  26,  35, 177, 217, 217, 207,  53,  26, 109, 217,  26;
				  26, 217,  28,  30, 182, 217, 217, 188,  40,  26,  96, 214, 217, 217, 211, 118,  34,  26,  27,  64, 124, 172, 199, 214, 214, 199, 172, 123,  64,  26,  26,  34, 119, 211, 217, 217, 214,  95,  26,  41, 190, 217, 217, 181,  29,  29, 217,  26;
				  26, 217,  26, 116, 217, 217, 210,  59,  26,  85, 214, 217, 217, 199,  66,  26,  27,  90, 189, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 188,  89,  27,  26,  68, 199, 217, 217, 214,  84,  26,  62, 211, 217, 217, 114,  26, 217,  26;
				  26, 217,  46, 209, 217, 217, 109,  26,  56, 208, 217, 217, 182,  46,  26,  53, 177, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 176,  52,  26,  47, 183, 217, 217, 207,  54,  26, 111, 217, 217, 208,  45, 217,  26;
				  26, 217, 133, 217, 217, 180,  29,  29, 181, 217, 217, 199,  47,  26,  71, 201, 217, 217, 217, 208, 144,  85,  55,  34,  34,  55,  85, 144, 208, 217, 217, 217, 204,  75,  26,  45, 197, 217, 217, 179,  29,  29, 183, 217, 217, 132, 217,  26;
				  26, 217, 209, 217, 217,  80,  26, 111, 217, 217, 210,  66,  26,  74, 214, 217, 217, 228, 245, 224, 102,  26,  26,  26,  26,  26,  26, 102, 224, 245, 228, 217, 217, 213,  73,  26,  68, 211, 217, 217, 109,  26,  82, 217, 217, 209, 217,  26;
				  26, 217, 217, 217, 179,  26,  36, 205, 217, 217, 118,  26,  53, 203, 217, 217, 220, 238, 117, 246, 219, 157, 188, 209, 209, 187, 157, 219, 246, 117, 239, 220, 217, 217, 202,  52,  26, 120, 217, 217, 203,  35,  27, 180, 217, 217, 217,  26;
				  26, 217, 217, 217, 103,  26, 112, 217, 217, 198,  34,  27, 177, 217, 217, 201, 227, 190,  26, 128, 243, 217, 217, 217, 217, 217, 217, 243, 127,  26, 192, 227, 201, 217, 217, 175,  27,  35, 199, 217, 217, 111,  26, 103, 217, 217, 217,  26;
				  26, 217, 217, 212,  38,  26, 186, 217, 217, 103,  26,  90, 217, 217, 210,  99, 225, 213,  26,  30, 223, 224, 217, 217, 217, 217, 224, 222,  30,  26, 215, 225,  99, 211, 217, 217,  88,  26, 105, 217, 217, 184,  26,  39, 213, 217, 217,  26;
				  26, 217, 217, 170,  26,  61, 217, 217, 212,  37,  27, 189, 217, 217, 125,  37, 216, 251,  40,  26, 131, 239, 217, 217, 217, 217, 239, 129,  26,  42, 252, 215,  35, 127, 217, 217, 187,  27,  37, 213, 217, 217,  59,  26, 170, 217, 217,  26;
				  26, 217, 217, 120,  26, 111, 217, 217, 162,  26,  65, 217, 217, 204,  37,  26, 208, 246,  91,  26,  44, 248, 218, 217, 217, 218, 248,  44,  26,  91, 246, 208,  26,  37, 205, 217, 217,  63,  26, 164, 217, 217, 110,  26, 122, 217, 217,  26;
				  26, 217, 217,  85,  26, 154, 217, 217, 103,  26, 124, 217, 217, 144,  26,  78, 217, 236, 154,  26,  26, 189, 229, 217, 217, 229, 188,  26,  26, 156, 236, 217,  76,  26, 145, 217, 217, 122,  26, 105, 217, 217, 152,  26,  87, 217, 217,  26;
				  26, 217, 217,  56,  26, 184, 217, 217,  66,  26, 172, 217, 217, 192,  85, 142, 217, 224, 233,  31,  26, 112, 242, 217, 217, 242, 110,  26,  32, 235, 224, 217, 140,  86, 192, 217, 217, 170,  26,  67, 217, 217, 182,  26,  58, 217, 217,  26;
				  26, 217, 217,  39,  26, 203, 217, 217,  41,  26, 204, 223, 247, 248, 226, 207, 217, 217, 246, 107,  26,  36, 238, 221, 221, 237,  35,  26, 109, 246, 217, 217, 207, 226, 248, 247, 223, 204,  26,  43, 217, 217, 202,  26,  40, 217, 217,  26;
				  26, 217, 217,  30,  26, 213, 217, 217,  30,  26, 215, 242, 110,  80, 223, 234, 217, 217, 230, 200,  26,  26, 146, 239, 239, 146,  26,  26, 202, 230, 217, 217, 235, 222,  79, 113, 242, 215,  26,  31, 217, 217, 212,  26,  31, 217, 217,  26;
				  26, 217, 217,  30,  26, 213, 217, 217,  30,  26, 216, 239, 147,  26,  42, 199, 238, 217, 218, 250,  44,  26,  40, 180, 179,  40,  26,  45, 251, 218, 217, 238, 199,  41,  26, 149, 239, 215,  26,  31, 217, 217, 212,  26,  31, 217, 217,  26;
				  26, 217, 217,  39,  26, 203, 217, 217,  41,  26, 204, 222, 245,  60,  26,  35, 190, 240, 217, 245,  95,  26,  26,  26,  26,  26,  26,  95, 245, 217, 240, 189,  35,  26,  61, 246, 222, 204,  26,  43, 217, 217, 202,  26,  40, 217, 217,  26;
				  26, 217, 217,  56,  26, 183, 217, 217,  66,  26, 172, 217, 235, 216,  43,  26,  31, 177, 242, 239, 131,  26,  26,  26,  26,  26,  26, 131, 239, 243, 177,  31,  26,  43, 216, 234, 217, 170,  26,  68, 217, 217, 181,  26,  58, 217, 217,  26;
				  26, 217, 217,  85,  26, 154, 217, 217, 104,  26, 123, 217, 217, 240, 207,  37,  26,  28, 149, 251, 111,  26,  26,  26,  26,  26,  26, 113, 251, 148,  28,  26,  38, 207, 240, 217, 217, 121,  26, 106, 217, 217, 152,  26,  87, 217, 217,  26;
				  26, 217, 217, 120,  26, 111, 217, 217, 163,  26,  64, 217, 217, 217, 242, 184,  28,  26,  26,  37,  27,  26,  26,  26,  26,  26,  26,  27,  36,  26,  26,  28, 185, 242, 217, 217, 217,  61,  26, 165, 217, 217, 109,  26, 122, 217, 217,  26;
				  26, 217, 217, 170,  26,  60, 217, 217, 212,  37,  27, 188, 217, 217, 216, 248, 143,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26, 142, 248, 216, 217, 217, 186,  26,  37, 213, 217, 217,  59,  26, 171, 217, 217,  26;
				  26, 217, 217, 212,  38,  26, 185, 217, 217, 104,  26,  89, 217, 217, 214, 221, 250,  74,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  71, 250, 221, 214, 217, 217,  88,  26, 105, 217, 217, 184,  26,  39, 214, 217, 217,  26;
				  26, 217, 217, 217, 103,  26, 111, 217, 217, 199,  34,  27, 176, 217, 217, 210, 233, 204,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27, 205, 233, 210, 217, 217, 174,  27,  35, 199, 217, 217, 110,  26, 103, 217, 217, 217,  26;
				  26, 217, 217, 217, 180,  27,  36, 204, 217, 217, 119,  26,  52, 202, 217, 217, 217, 250,  84,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  86, 249, 216, 217, 217, 202,  50,  26, 122, 217, 217, 202,  34,  27, 181, 217, 217, 217,  26;
				  26, 217, 209, 217, 217,  81,  26, 110, 217, 217, 211,  68,  26,  73, 214, 217, 217, 234, 181,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26, 181, 233, 217, 217, 213,  74,  26,  69, 212, 217, 217, 108,  26,  83, 217, 217, 208, 217,  26;
				  26, 217, 133, 217, 217, 182,  29,  29, 180, 217, 217, 199,  48,  26,  71, 200, 217, 220, 242,  27,  26,  26,  26,  26,  26,  26,  26,  26,  27, 242, 220, 217, 203,  75,  26,  45, 198, 217, 217, 179,  29,  29, 184, 217, 217, 131, 217,  26;
				  26, 217,  45, 208, 217, 217, 110,  26,  55, 208, 217, 217, 183,  47,  26,  52, 175, 217, 251,  57,  26,  26,  26,  26,  26,  26,  26,  26,  58, 251, 217, 174,  50,  26,  48, 184, 217, 217, 206,  53,  26, 113, 217, 217, 208,  44, 217,  26;
				  26, 217,  26, 114, 217, 217, 211,  61,  26,  84, 214, 217, 217, 199,  68,  26,  27, 181, 242, 118,  26,  26,  26,  26,  26,  26,  26,  26, 119, 242, 181,  27,  26,  69, 199, 217, 217, 214,  81,  26,  64, 212, 217, 217, 112,  26, 217,  26;
				  26, 217,  29,  29, 180, 217, 217, 190,  41,  26,  95, 214, 217, 217, 211, 120,  34, 106, 229, 222,  32,  26,  26,  26,  26,  26,  26,  31, 220, 228, 105,  35, 122, 212, 217, 217, 214,  94,  26,  42, 191, 217, 217, 179,  29,  29, 217,  26;
				  26, 217, 109,  26,  53, 206, 217, 217, 177,  35,  26,  84, 207, 217, 217, 217, 199, 110, 201, 249,  72,  26,  26,  26,  26,  26,  26,  72, 249, 200, 110, 199, 217, 217, 217, 206,  81,  26,  35, 177, 217, 217, 206,  53,  26, 110, 217,  26;
				  26, 217, 211,  63,  26,  85, 214, 217, 217, 177,  41,  26,  54, 179, 217, 217, 217, 217, 217, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 217, 217, 217, 217, 217, 178,  53,  26,  42, 177, 217, 217, 214,  84,  26,  64, 212, 217,  26;
				  26, 217, 217, 190,  39,  26, 103, 217, 217, 217, 190,  62,  26,  29, 109, 203, 217, 217, 217, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 217, 217, 217, 202, 108,  29,  26,  64, 191, 217, 217, 216, 102,  26,  40, 191, 217, 217,  26;
				  26, 217, 217, 217, 176,  34,  26,  98, 214, 217, 217, 211, 111,  29,  26,  35, 111, 184, 217, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 217, 184, 110,  35,  26,  29, 113, 212, 217, 217, 214, 103,  26,  33, 173, 217, 217, 217,  26;
				  26, 217, 217, 217, 217, 163,  34,  26,  86, 206, 217, 217, 217, 183,  82,  27,  26,  26, 186, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 185,  26,  26,  27,  83, 184, 217, 217, 217, 206,  84,  26,  34, 164, 217, 217, 217, 217,  26;
				  26, 217, 217, 217, 217, 217, 174,  38,  26,  53, 180, 217, 217, 217, 217, 180, 103,  39, 178, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 178,  39, 104, 181, 217, 217, 217, 217, 179,  53,  26,  40, 175, 217, 217, 217, 217, 217,  26;
				  26, 205, 217, 217, 217, 217, 217, 190,  63,  26,  29, 114, 208, 217, 217, 217, 217, 213, 208, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 208, 214, 217, 217, 217, 217, 207, 112,  29,  26,  64, 191, 217, 217, 217, 217, 217, 204,  26;
				  25, 133, 217, 217, 217, 217, 217, 217, 211, 109,  29,  26,  44, 132, 209, 217, 217, 217, 217, 247,  72,  26,  26,  26,  26,  26,  26,  72, 247, 217, 217, 217, 217, 208, 131,  44,  26,  29, 110, 212, 217, 217, 217, 217, 217, 217, 132,  27;
				  27,  29, 127, 204, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 217, 204, 132,  30,  21;
				 255,  28,  26,  25,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  25,  28, 255];
im(:,:,3) = [	 255,  27,  27,  25,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27,  28, 255;
				  18,  26,  32,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  37,  32,  26,  19;
				  25,  32,  38,  38,  38,  38,  38,  38,  38,  31,  26,  26,  27,  32,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  37,  33,  27,  26,  26,  32,  38,  38,  38,  38,  38,  38,  38,  32,  26;
				  26,  37,  38,  38,  38,  38,  38,  36,  28,  26,  26,  32,  38,  38,  38,  38,  38,  38,  35,  32,  30,  28,  27,  26,  26,  27,  28,  30,  32,  35,  38,  38,  38,  38,  38,  37,  32,  26,  26,  28,  36,  38,  38,  38,  38,  38,  37,  27;
				  26,  38,  38,  38,  38,  38,  35,  26,  26,  28,  36,  38,  38,  38,  38,  36,  31,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27,  30,  36,  38,  38,  38,  38,  36,  28,  26,  27,  35,  38,  38,  38,  38,  38,  26;
				  26,  38,  38,  38,  38,  34,  26,  26,  30,  37,  38,  38,  38,  36,  30,  26,  26,  26,  28,  31,  34,  36,  37,  38,  38,  37,  36,  34,  31,  28,  26,  26,  26,  30,  36,  38,  38,  38,  37,  30,  26,  26,  34,  38,  38,  38,  38,  26;
				  26,  38,  38,  38,  36,  27,  26,  30,  37,  38,  38,  38,  32,  26,  26,  27,  31,  36,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  36,  31,  27,  26,  27,  31,  38,  38,  38,  38,  30,  26,  26,  35,  38,  38,  38,  26;
				  26,  38,  38,  36,  27,  26,  30,  38,  38,  38,  36,  28,  26,  27,  31,  37,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  37,  32,  27,  26,  28,  36,  38,  38,  38,  31,  26,  27,  36,  38,  38,  26;
				  26,  38,  38,  28,  26,  30,  38,  38,  38,  36,  27,  26,  28,  36,  38,  38,  38,  38,  38,  34,  30,  29,  27,  26,  26,  27,  29,  31,  34,  38,  38,  38,  38,  38,  36,  28,  26,  27,  36,  38,  38,  38,  30,  26,  28,  38,  38,  26;
				  26,  38,  31,  26,  28,  37,  38,  38,  36,  27,  26,  30,  37,  38,  38,  38,  37,  30,  27,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27,  30,  37,  38,  38,  38,  37,  29,  26,  27,  36,  38,  38,  37,  28,  26,  32,  38,  26;
				  26,  38,  26,  26,  36,  38,  38,  36,  27,  26,  31,  38,  38,  38,  38,  31,  26,  26,  26,  29,  32,  35,  37,  38,  38,  37,  35,  32,  28,  26,  26,  27,  32,  38,  38,  38,  37,  31,  26,  27,  36,  38,  38,  36,  26,  26,  38,  26;
				  26,  38,  26,  32,  38,  38,  38,  28,  26,  30,  37,  38,  38,  37,  28,  26,  26,  30,  36,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  36,  30,  26,  26,  28,  37,  38,  38,  37,  29,  26,  28,  38,  38,  38,  31,  26,  38,  26;
				  26,  38,  27,  37,  38,  38,  32,  26,  28,  37,  38,  38,  36,  27,  26,  27,  35,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  36,  28,  26,  27,  36,  38,  38,  37,  28,  26,  31,  38,  38,  37,  27,  38,  26;
				  26,  38,  32,  38,  38,  36,  26,  27,  36,  38,  38,  36,  27,  26,  29,  37,  38,  38,  38,  37,  33,  30,  28,  27,  27,  28,  30,  33,  37,  38,  38,  38,  37,  29,  26,  27,  37,  38,  38,  36,  27,  27,  36,  38,  38,  33,  38,  26;
				  26,  38,  38,  38,  38,  30,  26,  31,  38,  38,  38,  28,  26,  29,  38,  38,  38,  99, 196,  75,  31,  26,  26,  26,  26,  26,  26,  31,  75, 195,  99,  38,  38,  38,  29,  26,  28,  38,  38,  38,  32,  26,  29,  38,  38,  37,  38,  26;
				  26,  38,  38,  38,  36,  26,  27,  37,  38,  38,  31,  26,  27,  37,  38,  38,  59, 233, 117, 229,  60,  34,  36,  37,  37,  36,  34,  61, 229, 117, 233,  58,  38,  38,  37,  28,  26,  32,  38,  38,  37,  27,  26,  36,  38,  38,  38,  26;
				  26,  38,  38,  38,  31,  26,  31,  38,  38,  37,  26,  26,  35,  38,  38,  37,  95, 190,  26, 128, 185,  38,  38,  38,  38,  38,  38, 187, 127,  26, 192,  93,  37,  38,  38,  36,  26,  27,  36,  38,  38,  31,  26,  30,  38,  38,  38,  26;
				  26,  38,  38,  38,  26,  26,  36,  38,  38,  30,  26,  30,  38,  38,  38,  31,  85, 213,  26,  30, 223,  76,  38,  38,  38,  38,  78, 222,  30,  26, 215,  83,  31,  38,  38,  38,  30,  26,  31,  38,  38,  36,  26,  27,  38,  38,  38,  26;
				  26,  38,  38,  35,  26,  28,  38,  38,  38,  27,  26,  36,  38,  38,  32,  27,  42, 245,  40,  26, 131, 165,  38,  38,  38,  38, 166, 129,  26,  42, 246,  43,  27,  32,  38,  38,  36,  26,  26,  38,  38,  38,  29,  26,  35,  38,  38,  26;
				  26,  38,  38,  32,  26,  31,  38,  38,  34,  26,  29,  38,  38,  37,  27,  26,  37, 204,  91,  26,  44, 237,  45,  38,  38,  46, 238,  44,  26,  91, 204,  37,  26,  26,  37,  38,  38,  28,  26,  34,  38,  38,  32,  26,  32,  38,  38,  26;
				  26,  38,  38,  30,  26,  34,  38,  38,  30,  26,  32,  38,  38,  33,  26,  29,  38, 147, 154,  26,  26, 189, 106,  38,  38, 108, 188,  26,  26, 156, 145,  38,  29,  26,  34,  38,  38,  32,  26,  31,  38,  38,  34,  26,  30,  38,  38,  26;
				  26,  38,  38,  28,  26,  36,  38,  38,  29,  26,  35,  38,  38,  37,  30,  33,  38,  78, 233,  31,  26, 112, 180,  38,  38, 182, 110,  26,  32, 235,  75,  38,  33,  30,  37,  38,  38,  35,  26,  28,  38,  38,  36,  26,  28,  38,  38,  26;
				  26,  38,  38,  27,  26,  37,  38,  38,  27,  26,  37,  74, 209, 214,  89,  37,  38,  38, 205, 107,  26,  36, 234,  60,  61, 234,  35,  26, 109, 203,  38,  38,  37,  90, 215, 208,  73,  37,  26,  27,  38,  38,  37,  26,  27,  38,  38,  26;
				  26,  38,  38,  26,  26,  38,  38,  38,  26,  26,  38, 184, 110,  80, 222, 138,  38,  38, 114, 200,  26,  26, 146, 163, 164, 146,  26,  26, 202, 112,  38,  38, 138, 220,  79, 113, 181,  38,  26,  26,  38,  38,  38,  26,  26,  38,  38,  26;
				  26,  38,  38,  26,  26,  38,  38,  38,  26,  26,  38, 166, 147,  26,  42, 199, 158,  39,  45, 244,  44,  26,  40, 180, 179,  40,  26,  45, 244,  45,  39, 159, 199,  41,  26, 149, 163,  38,  26,  26,  38,  38,  38,  26,  26,  38,  38,  26;
				  26,  38,  38,  27,  26,  37,  38,  38,  27,  26,  38,  68, 241,  60,  26,  35, 190, 169,  41, 197,  95,  26,  26,  26,  26,  26,  26,  95, 196,  41, 169, 189,  35,  26,  61, 241,  66,  37,  26,  27,  38,  38,  37,  26,  27,  38,  38,  26;
				  26,  38,  38,  28,  26,  36,  38,  38,  28,  26,  35,  38, 138, 216,  43,  26,  31, 177, 184, 166, 131,  26,  26,  26,  26,  26,  26, 131, 166, 184, 177,  31,  26,  43, 216, 137,  38,  35,  26,  28,  38,  38,  36,  26,  28,  38,  38,  26;
				  26,  38,  38,  30,  26,  34,  38,  38,  31,  26,  32,  38,  39, 168, 207,  37,  26,  28, 149, 249, 111,  26,  26,  26,  26,  26,  26, 113, 249, 148,  28,  26,  38, 207, 168,  39,  38,  32,  26,  31,  38,  38,  34,  26,  30,  38,  38,  26;
				  26,  38,  38,  32,  26,  31,  38,  38,  34,  26,  28,  38,  38,  40, 184, 184,  28,  26,  26,  37,  27,  26,  26,  26,  26,  26,  26,  27,  36,  26,  26,  28, 185, 184,  40,  38,  38,  28,  26,  35,  38,  38,  32,  26,  32,  38,  38,  26;
				  26,  38,  38,  35,  26,  28,  38,  38,  38,  27,  26,  36,  38,  38,  47, 212, 143,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26, 142, 212,  46,  38,  38,  36,  26,  26,  38,  38,  38,  29,  26,  35,  38,  38,  26;
				  26,  38,  38,  38,  27,  26,  36,  38,  38,  31,  26,  30,  38,  38,  38,  63, 240,  74,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  71, 239,  64,  38,  38,  38,  30,  26,  31,  38,  38,  35,  26,  27,  38,  38,  38,  26;
				  26,  38,  38,  38,  30,  26,  31,  38,  38,  37,  27,  26,  36,  38,  38,  37, 131, 204,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  27, 205, 131,  38,  38,  38,  35,  26,  27,  36,  38,  38,  31,  26,  30,  38,  38,  38,  26;
				  26,  38,  38,  38,  36,  26,  27,  37,  38,  38,  32,  26,  28,  37,  38,  38,  41, 224,  84,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  86, 224,  41,  38,  38,  37,  28,  26,  32,  38,  38,  37,  27,  26,  36,  38,  38,  38,  26;
				  26,  38,  37,  38,  38,  30,  26,  31,  38,  38,  38,  28,  26,  29,  38,  38,  38, 132, 181,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26, 181, 132,  38,  38,  38,  29,  26,  29,  38,  38,  38,  31,  26,  29,  38,  38,  37,  38,  26;
				  26,  38,  33,  38,  38,  36,  27,  27,  36,  38,  38,  36,  27,  26,  29,  37,  38,  57, 242,  27,  26,  26,  26,  26,  26,  26,  26,  26,  27, 242,  57,  38,  37,  29,  26,  27,  37,  38,  38,  35,  26,  26,  35,  38,  38,  33,  38,  26;
				  26,  38,  27,  37,  38,  38,  31,  26,  28,  37,  38,  38,  36,  27,  26,  28,  36,  38, 232,  57,  26,  26,  26,  26,  26,  26,  26,  26,  58, 232,  38,  35,  28,  26,  27,  36,  38,  38,  37,  27,  26,  31,  38,  38,  37,  27,  38,  26;
				  26,  38,  26,  32,  38,  38,  38,  28,  26,  29,  37,  38,  38,  37,  28,  26,  26,  35, 182, 118,  26,  26,  26,  26,  26,  26,  26,  26, 119, 181,  35,  26,  26,  29,  36,  38,  38,  37,  29,  26,  28,  38,  38,  38,  31,  26,  38,  26;
				  26,  38,  26,  26,  36,  38,  38,  36,  27,  26,  31,  37,  38,  38,  38,  32,  27,  31, 104, 222,  32,  26,  26,  26,  26,  26,  26,  31, 220, 104,  31,  27,  32,  38,  38,  38,  37,  31,  26,  27,  37,  38,  38,  36,  26,  26,  38,  26;
				  26,  38,  31,  26,  28,  37,  38,  38,  36,  27,  26,  29,  37,  38,  38,  38,  36,  32,  37, 222,  72,  26,  26,  26,  26,  26,  26,  72, 222,  37,  32,  37,  38,  38,  38,  37,  29,  26,  27,  35,  38,  38,  37,  27,  26,  31,  38,  26;
				  26,  38,  38,  28,  26,  30,  38,  38,  38,  36,  27,  26,  28,  36,  38,  38,  38,  38,  38, 212,  72,  26,  26,  26,  26,  26,  26,  72, 211,  38,  38,  38,  38,  38,  35,  28,  26,  27,  35,  38,  38,  38,  29,  26,  29,  38,  38,  26;
				  26,  38,  38,  36,  27,  26,  31,  38,  38,  38,  37,  28,  26,  27,  32,  37,  38,  38,  38, 212,  72,  26,  26,  26,  26,  26,  26,  72, 211,  38,  38,  38,  37,  31,  26,  26,  28,  37,  38,  38,  38,  31,  26,  27,  37,  38,  38,  26;
				  26,  38,  38,  38,  36,  27,  26,  30,  37,  38,  38,  38,  31,  27,  26,  27,  31,  36,  38, 212,  72,  26,  26,  26,  26,  26,  26,  72, 211,  38,  36,  31,  27,  26,  26,  31,  38,  38,  38,  38,  30,  26,  26,  35,  38,  38,  38,  26;
				  26,  38,  38,  38,  38,  34,  26,  26,  30,  37,  38,  38,  38,  36,  29,  26,  26,  26,  36, 212,  72,  26,  26,  26,  26,  26,  26,  72, 211,  36,  26,  26,  26,  29,  35,  38,  38,  38,  37,  30,  26,  26,  34,  38,  38,  38,  38,  26;
				  26,  38,  38,  38,  38,  38,  35,  27,  26,  28,  36,  38,  38,  38,  38,  36,  30,  27,  35, 212,  72,  26,  26,  26,  26,  26,  26,  72, 211,  35,  27,  31,  36,  38,  38,  38,  38,  36,  27,  26,  27,  36,  38,  38,  38,  38,  38,  26;
				  26,  37,  38,  38,  38,  38,  38,  36,  28,  26,  26,  31,  37,  38,  38,  38,  38,  38,  37, 211,  72,  26,  26,  26,  26,  26,  26,  72, 211,  37,  38,  38,  38,  38,  38,  37,  31,  26,  26,  29,  37,  38,  38,  38,  38,  38,  37,  26;
				  25,  32,  38,  38,  38,  38,  38,  38,  38,  32,  26,  26,  27,  33,  37,  38,  38,  38,  38, 211,  72,  26,  26,  26,  26,  26,  26,  72, 211,  38,  38,  38,  38,  37,  33,  28,  26,  26,  31,  38,  38,  38,  38,  38,  38,  38,  33,  27;
				  27,  26,  32,  37,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,  37,  33,  26,  21;
				 255,  28,  26,  25,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  26,  25,  28, 255];
alpha_map = [	   0,  28, 171, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 242, 173,  37,   0;
				  28, 237, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 237,  27;
				 171, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 169;
				 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 240;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 240;
				 173, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 171;
				  38, 236, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 237,  36;
				   0,  27, 169, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241, 171,  36,   0];
varargout = {alpha_map};


%% ***********************************************************************
function [im, varargout] = Vulintus_Load_Vulintus_Logo_Circle_Social_48px

%VULINTUS_LOAD_VULINTUS_LOGO_CIRCLE_SOCIAL_48PX
%
%	Vulintus, Inc.
%
%	Software icon defined in script.
%
%	This function was programmatically generated: 28-Feb-2024 12:39:59
%

im = uint8(zeros(48,48,3));
im(:,:,1) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,   9,  18,  14,   7,   3,   3,   7,  14,  18,   9,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  15,   7,  63, 133, 173, 212, 228, 239, 239, 228, 211, 172, 132,  61,   7,  15,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  10,   8,  77, 178, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 177,  76,   7,  10,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   8, 105, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224, 102,   8,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  13,  60, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  57,  13,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,   9, 143, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 142,   9,   3, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  15, 199, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,  15,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  21, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  21,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  15, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  15,   3, 255, 255, 255, 255, 255;
				 255, 255, 255, 255,   0,   9, 200, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,   9,   0, 255, 255, 255, 255;
				 255, 255, 255,   0,  13, 144, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 142,  13,   0, 255, 255, 255;
				 255, 255, 255,   6,  60, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  58,   8, 255, 255, 255;
				 255, 255,   0,   9, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,   8,   0, 255, 255;
				 255, 255,  10, 105, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 102,  12, 255, 255;
				 255,   0,   8, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224,   7,   0, 255;
				 255,   2,  77, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  76,   2, 255;
				 255,  15, 178, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 176,  16, 255;
				   0,   7, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   7,   0;
				   0,  63, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243, 255,  59,   0;
				   9, 132, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 190, 110, 132, 255, 131,   9;
				  18, 174, 255, 176,  34,  34,  92, 119, 119, 119, 240,  97,  54,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  75,  77, 246, 150, 255, 171,  18;
				  13, 211, 255, 249,  30,   0,  91, 255, 255, 255, 210,   1, 173, 255, 255, 255, 255, 255,  94, 107, 255, 158, 162, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213, 120, 133, 255, 209,  13;
				   7, 229, 255, 255, 148,   0,   3, 218, 255, 255,  87,  44, 253, 255, 255, 255, 255, 255,  35,  54, 255,  64,  81, 255, 255, 255, 255, 255, 255, 255, 231, 122, 193, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 255, 227,   8;
				   3, 241, 255, 255, 247,  25,   0,  97, 255, 215,   2, 148, 170, 219, 255, 184, 186, 255,  35,  54, 255, 181, 188, 255, 177, 212, 194, 158, 235, 255, 125,   0, 110, 209, 211, 170, 244, 244, 170, 211, 255, 226, 158, 166, 240, 255, 240,   3;
				   3, 241, 255, 255, 255, 141,   0,   5, 222,  92,  40, 195,   0, 146, 255,  40,  48, 255,  35,  54, 255,  34,  53, 255,  25,  26,   2,   0,  45, 255,  22,   0,  11, 127, 122,   0, 221, 221,   0, 122, 226,  13,  40,  41, 212, 255, 240,   3;
				   7, 229, 255, 255, 255, 244,  21,   0,  72,   3, 162, 198,   0, 145, 255,  39,  47, 255,  35,  54, 255,  34,  53, 255,  27,  32, 247,  98,   0, 227, 186,   0, 165, 255, 124,   0, 221, 220,   0, 122, 185,   0,  90, 229, 255, 255, 227,   8;
				  13, 211, 255, 255, 255, 255, 135,   0,   0,  35, 251, 201,   0, 142, 255,  37,  46, 255,  35,  54, 255,  34,  53, 255,  28,  58, 255, 128,   0, 214, 188,   0, 164, 255, 130,   0, 218, 219,   0, 121, 252, 116,  10,  11, 197, 255, 209,  13;
				  18, 173, 255, 255, 255, 255, 242,  18,   0, 156, 255, 217,   0,  68, 172,   8,  44, 255,  35,  54, 255,  34,  53, 255,  29,  58, 255, 130,   0, 212, 198,   0,  98, 221, 146,   0, 125, 124,   0, 119, 233, 206, 184,   0, 125, 255, 171,  18;
				   9, 132, 255, 255, 255, 255, 255, 129,  30, 250, 255, 255,  83,   0,  30,  59,  41, 255,  35,  54, 255,  34,  53, 255,  30,  59, 255, 131,   0, 212, 249,  50,   0, 127, 230,  34,   0,  71,  16, 116, 173,   3,   0,  36, 216, 255, 131,   9;
				   0,  61, 255, 255, 255, 255, 255, 245, 224, 255, 255, 255, 255, 235, 251, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 235, 254, 255, 253, 234, 255, 255, 255, 255, 246, 227, 255, 255, 255,  58,   0;
				   0,   7, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   6,   0;
				 255,  15, 177, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 175,  16, 255;
				 255,   2,  76, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  75,   2, 255;
				 255,   0,   7, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223,   8,   0, 255;
				 255, 255,  10, 102, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 100,  11, 255, 255;
				 255, 255,   0,   8, 214, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,   8,   0, 255, 255;
				 255, 255, 255,   6,  57, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  56,   6, 255, 255, 255;
				 255, 255, 255,   0,  13, 141, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 140,  13,   0, 255, 255, 255;
				 255, 255, 255, 255,   0,   9, 198, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,   8,   0, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  13, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  13,   0, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  21, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  20,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  13, 197, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,  14,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,   9, 142, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 140,   8,   0, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  13,  57, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,  56,  13,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   8, 102, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223, 100,   8,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  10,   7,  75, 176, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 175,  74,   8,  11,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  16,   7,  60, 132, 172, 210, 227, 239, 239, 227, 209, 171, 131,  59,   6,  16,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,   9,  18,  14,   7,   3,   3,   8,  14,  18,   9,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
im(:,:,2) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,   9,  18,  14,   7,   3,   3,   7,  14,  18,   9,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  15,   7,  63, 133, 173, 212, 228, 239, 239, 228, 211, 172, 132,  61,   7,  15,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  10,   8,  77, 178, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 177,  76,   7,  10,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   8, 105, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224, 102,   8,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  13,  60, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  57,  13,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,   9, 143, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 142,   9,   3, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  15, 199, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,  15,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  21, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  21,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  15, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  15,   3, 255, 255, 255, 255, 255;
				 255, 255, 255, 255,   0,   9, 200, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,   9,   0, 255, 255, 255, 255;
				 255, 255, 255,   0,  13, 144, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 142,  13,   0, 255, 255, 255;
				 255, 255, 255,   6,  60, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  58,   8, 255, 255, 255;
				 255, 255,   0,   9, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,   8,   0, 255, 255;
				 255, 255,  10, 105, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 102,  12, 255, 255;
				 255,   0,   8, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224,   7,   0, 255;
				 255,   2,  77, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  76,   2, 255;
				 255,  15, 178, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 176,  16, 255;
				   0,   7, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   7,   0;
				   0,  63, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243, 255,  59,   0;
				   9, 132, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 190, 110, 132, 255, 131,   9;
				  18, 174, 255, 176,  34,  34,  92, 119, 119, 119, 240,  97,  54,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  75,  77, 246, 150, 255, 171,  18;
				  13, 211, 255, 249,  30,   0,  91, 255, 255, 255, 210,   1, 173, 255, 255, 255, 255, 255,  94, 107, 255, 158, 162, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213, 120, 133, 255, 209,  13;
				   7, 229, 255, 255, 148,   0,   3, 218, 255, 255,  87,  44, 253, 255, 255, 255, 255, 255,  35,  54, 255,  64,  81, 255, 255, 255, 255, 255, 255, 255, 231, 122, 193, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 255, 227,   8;
				   3, 241, 255, 255, 247,  25,   0,  97, 255, 215,   2, 148, 170, 219, 255, 184, 186, 255,  35,  54, 255, 181, 188, 255, 177, 212, 194, 158, 235, 255, 125,   0, 110, 209, 211, 170, 244, 244, 170, 211, 255, 226, 158, 166, 240, 255, 240,   3;
				   3, 241, 255, 255, 255, 141,   0,   5, 222,  92,  40, 195,   0, 146, 255,  40,  48, 255,  35,  54, 255,  34,  53, 255,  25,  26,   2,   0,  45, 255,  22,   0,  11, 127, 122,   0, 221, 221,   0, 122, 226,  13,  40,  41, 212, 255, 240,   3;
				   7, 229, 255, 255, 255, 244,  21,   0,  72,   3, 162, 198,   0, 145, 255,  39,  47, 255,  35,  54, 255,  34,  53, 255,  27,  32, 247,  98,   0, 227, 186,   0, 165, 255, 124,   0, 221, 220,   0, 122, 185,   0,  90, 229, 255, 255, 227,   8;
				  13, 211, 255, 255, 255, 255, 135,   0,   0,  35, 251, 201,   0, 142, 255,  37,  46, 255,  35,  54, 255,  34,  53, 255,  28,  58, 255, 128,   0, 214, 188,   0, 164, 255, 130,   0, 218, 219,   0, 121, 252, 116,  10,  11, 197, 255, 209,  13;
				  18, 173, 255, 255, 255, 255, 242,  18,   0, 156, 255, 217,   0,  68, 172,   8,  44, 255,  35,  54, 255,  34,  53, 255,  29,  58, 255, 130,   0, 212, 198,   0,  98, 221, 146,   0, 125, 124,   0, 119, 233, 206, 184,   0, 125, 255, 171,  18;
				   9, 132, 255, 255, 255, 255, 255, 129,  30, 250, 255, 255,  83,   0,  30,  59,  41, 255,  35,  54, 255,  34,  53, 255,  30,  59, 255, 131,   0, 212, 249,  50,   0, 127, 230,  34,   0,  71,  16, 116, 173,   3,   0,  36, 216, 255, 131,   9;
				   0,  61, 255, 255, 255, 255, 255, 245, 224, 255, 255, 255, 255, 235, 251, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 235, 254, 255, 253, 234, 255, 255, 255, 255, 246, 227, 255, 255, 255,  58,   0;
				   0,   7, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   6,   0;
				 255,  15, 177, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 175,  16, 255;
				 255,   2,  76, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  75,   2, 255;
				 255,   0,   7, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223,   8,   0, 255;
				 255, 255,  10, 102, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 100,  11, 255, 255;
				 255, 255,   0,   8, 214, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,   8,   0, 255, 255;
				 255, 255, 255,   6,  57, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  56,   6, 255, 255, 255;
				 255, 255, 255,   0,  13, 141, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 140,  13,   0, 255, 255, 255;
				 255, 255, 255, 255,   0,   9, 198, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,   8,   0, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  13, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  13,   0, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  21, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  20,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  13, 197, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,  14,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,   9, 142, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 140,   8,   0, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  13,  57, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,  56,  13,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   8, 102, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223, 100,   8,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  10,   7,  75, 176, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 175,  74,   8,  11,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  16,   7,  60, 132, 172, 210, 227, 239, 239, 227, 209, 171, 131,  59,   6,  16,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,   9,  18,  14,   7,   3,   3,   8,  14,  18,   9,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
im(:,:,3) = [	 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,  10,  19,  16,   8,   4,   4,   8,  16,  19,  10,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  17,   8,  64, 133, 173, 212, 228, 239, 239, 228, 211, 172, 132,  62,   8,  17,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  12,   9,  78, 178, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 177,  77,   8,  12,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   9, 106, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224, 103,   9,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  14,  61, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  59,  14,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,  10, 143, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 142,  10,   3, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  16, 199, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,  17,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  22, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  22,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  16, 216, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,  17,   3, 255, 255, 255, 255, 255;
				 255, 255, 255, 255,   0,  10, 200, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 198,  10,   0, 255, 255, 255, 255;
				 255, 255, 255,   0,  14, 144, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 142,  14,   0, 255, 255, 255;
				 255, 255, 255,   6,  61, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  59,   8, 255, 255, 255;
				 255, 255,   0,  10, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 215,   9,   0, 255, 255;
				 255, 255,  12, 106, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 103,  14, 255, 255;
				 255,   0,   9, 225, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 224,   8,   0, 255;
				 255,   2,  78, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  77,   2, 255;
				 255,  17, 178, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 176,  17, 255;
				   0,   8, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   8,   0;
				   0,  64, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243, 255,  60,   0;
				  10, 132, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 190, 110, 132, 255, 131,  10;
				  19, 174, 255, 176,  34,  34,  92, 119, 119, 119, 240,  97,  54,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  85,  75,  77, 246, 150, 255, 171,  20;
				  14, 211, 255, 249,  30,   0,  91, 255, 255, 255, 210,   1, 173, 255, 255, 255, 255, 255,  94, 107, 255, 158, 162, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213, 120, 133, 255, 209,  14;
				   8, 229, 255, 255, 148,   0,   3, 218, 255, 255,  87,  44, 253, 255, 255, 255, 255, 255,  35,  54, 255,  64,  81, 255, 255, 255, 255, 255, 255, 255, 231, 122, 193, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 255, 227,   9;
				   4, 241, 255, 255, 247,  25,   0,  97, 255, 215,   2, 148, 170, 219, 255, 184, 186, 255,  35,  54, 255, 181, 188, 255, 177, 212, 194, 158, 235, 255, 125,   0, 110, 209, 211, 170, 244, 244, 170, 211, 255, 226, 158, 166, 240, 255, 240,   4;
				   4, 241, 255, 255, 255, 141,   0,   5, 222,  92,  40, 195,   0, 146, 255,  40,  48, 255,  35,  54, 255,  34,  53, 255,  25,  26,   2,   0,  45, 255,  22,   0,  11, 127, 122,   0, 221, 221,   0, 122, 226,  13,  40,  41, 212, 255, 240,   4;
				   8, 229, 255, 255, 255, 244,  21,   0,  72,   3, 162, 198,   0, 145, 255,  39,  47, 255,  35,  54, 255,  34,  53, 255,  27,  32, 247,  98,   0, 227, 186,   0, 165, 255, 124,   0, 221, 220,   0, 122, 185,   0,  90, 229, 255, 255, 227,   9;
				  14, 211, 255, 255, 255, 255, 135,   0,   0,  35, 251, 201,   0, 142, 255,  37,  46, 255,  35,  54, 255,  34,  53, 255,  28,  58, 255, 128,   0, 214, 188,   0, 164, 255, 130,   0, 218, 219,   0, 121, 252, 116,  10,  11, 197, 255, 209,  14;
				  19, 173, 255, 255, 255, 255, 242,  18,   0, 156, 255, 217,   0,  68, 172,   8,  44, 255,  35,  54, 255,  34,  53, 255,  29,  58, 255, 130,   0, 212, 198,   0,  98, 221, 146,   0, 125, 124,   0, 119, 233, 206, 184,   0, 125, 255, 171,  20;
				  10, 132, 255, 255, 255, 255, 255, 129,  30, 250, 255, 255,  83,   0,  30,  59,  41, 255,  35,  54, 255,  34,  53, 255,  30,  59, 255, 131,   0, 212, 249,  50,   0, 127, 230,  34,   0,  71,  16, 116, 173,   3,   0,  36, 216, 255, 131,  10;
				   0,  62, 255, 255, 255, 255, 255, 245, 224, 255, 255, 255, 255, 235, 251, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 235, 254, 255, 253, 234, 255, 255, 255, 255, 246, 227, 255, 255, 255,  59,   0;
				   0,   8, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248,   7,   0;
				 255,  17, 177, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 175,  17, 255;
				 255,   2,  77, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  76,   2, 255;
				 255,   0,   8, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223,   9,   0, 255;
				 255, 255,  12, 103, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 101,  12, 255, 255;
				 255, 255,   0,   9, 214, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,   9,   0, 255, 255;
				 255, 255, 255,   6,  59, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254,  57,   6, 255, 255, 255;
				 255, 255, 255,   0,  14, 141, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 140,  14,   0, 255, 255, 255;
				 255, 255, 255, 255,   0,  10, 198, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,   9,   0, 255, 255, 255, 255;
				 255, 255, 255, 255, 255,   3,  15, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  15,   0, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255,   5,  22, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 214,  21,   5, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255,   5,  15, 197, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 196,  15,   5, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255,   3,  10, 142, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 140,   9,   0, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  14,  59, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,  57,  14,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   6,   9, 103, 224, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 223, 101,   9,   6,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,  12,   8,  76, 176, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 175,  75,   9,  12,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   2,  17,   8,  61, 132, 172, 210, 227, 239, 239, 227, 209, 171, 131,  60,   7,  17,   2,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255;
				 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,  10,  20,  16,   8,   4,   4,   9,  16,  20,  10,   0,   0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
alpha_map = [	   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  24,  88, 148, 198, 230, 245, 252, 252, 245, 230, 197, 148,  87,  23,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  19, 110, 215, 250, 242, 254, 255, 255, 255, 255, 255, 255, 255, 255, 254, 241, 250, 214, 109,  18,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  27, 150, 247, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 246, 148,  26,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   5, 123, 246, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 246, 120,   5,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,  39, 219, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 217,  37,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,  84, 245, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 245,  81,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0, 106, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 104,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0, 105, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246, 104,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,  83, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247,  80,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,  39, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  37,   0,   0,   0,   0;
				   0,   0,   0,   6, 219, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 218,   5,   0,   0,   0;
				   0,   0,   0, 122, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 122,   0,   0,   0;
				   0,   0,  27, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  26,   0,   0;
				   0,   0, 149, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 249, 149,   0,   0;
				   0,  19, 247, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  18,   0;
				   0, 110, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 108,   0;
				   0, 215, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 213,   0;
				  24, 249, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 250,  22;
				  88, 242, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  86;
				 149, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 148;
				 198, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 195;
				 232, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 230;
				 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251;
				 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 251;
				 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 243;
				 231, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 230;
				 197, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 195;
				 148, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 147;
				  88, 241, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 241,  85;
				  23, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 250,  21;
				   0, 214, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 211,   0;
				   0, 108, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 107,   0;
				   0,  18, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  18,   0;
				   0,   0, 148, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 145,   0,   0;
				   0,   0,  26, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245,  24,   0,   0;
				   0,   0,   0, 120, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 118,   0,   0,   0;
				   0,   0,   0,   5, 217, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 216,   5,   0,   0,   0;
				   0,   0,   0,   0,  37, 245, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244,  36,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,  82, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 246,  78,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0, 104, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 245, 103,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0, 104, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 247, 103,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,  81, 245, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 244,  78,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,  38, 218, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 216,  36,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   5, 121, 246, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 248, 245, 118,   5,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  26, 148, 246, 244, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 244, 246, 145,  24,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  18, 108, 213, 250, 241, 254, 255, 255, 255, 255, 255, 255, 255, 255, 254, 241, 250, 211, 107,  17,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0;
				   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  22,  86, 147, 196, 229, 244, 252, 252, 244, 229, 196, 146,  86,  21,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0];
varargout = {alpha_map};


%% ***********************************************************************
function usb_pid_list = Vulintus_USB_VID_PID_List

%Vulintus_USB_VID_PID_List.m - Vulintus, Inc.
%
%   VULINTUS_USB_VID_PID_LIST returns a cell array with USB vendor ID (VID) 
%   and product ID (PID) numbers assigned to Vulintus devices
%
%   UPDATE LOG:
%   2024-02-22 - Drew Sloan - Function first created.
%

usb_pid_list = {
    '04D8',     'E6C2',     'HabiTrak Thermal Activity Monitor';
    '0403',     '6A21',     'MotoTrak Pellet Pedestal Module';	
    '04D8',     'E6C3',     'OmniTrak Common Controller';
    '0403',     '6A20',     'OmniTrak Nosepoke Module';
    '0403',     '6A24',     'OmniTrak Three-Nosepoke Module';
	'0403',     '6A23',     'SensiTrak Arm Proprioception Module';
	'0403',     '6A22',     'SensiTrak Tactile Carousel Module';
	'0403',     '6A25',     'SensiTrak Vibrotactile Module';
	'04D8',     'E6AC',     'VPB Linear Autopositioner';
	'04D8',     'E62E',     'VPB Liquid Dispenser';
	'04D8',     'E6C0',     'VPB Ring Light';
};


