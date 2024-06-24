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