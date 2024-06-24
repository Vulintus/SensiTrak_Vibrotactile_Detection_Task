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