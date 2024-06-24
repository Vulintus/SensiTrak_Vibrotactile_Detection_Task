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
    
    if isfield(handles.program,'load_stage_fcn')                            %If a stage loading function is specified for this behavior...
        handles.program.load_stage_fcn(handles, gui_i);                     %Run the stages through the check function.
    end

end
