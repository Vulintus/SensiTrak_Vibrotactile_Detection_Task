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