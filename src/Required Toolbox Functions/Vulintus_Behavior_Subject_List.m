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