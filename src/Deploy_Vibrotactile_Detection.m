function Deploy_Vibrotactile_Detection

%
%Deploy_Vibrotactile_Detection.m - Vulintus, Inc.
%
%   DEPLOY_VIBROTACTILE_DETECTION collates all of the *.m file dependencies 
%   for the SensiTrak vibrotactile detection task program into a single *.m 
%   file.
%
%   UPDATE LOG:
%   2024-06-24 - Drew Sloan - Function first created, adapted from
%                             Deploy_Pellet_Presentation.m
%


start_script = 'Vibrotactile_Detection_Startup.m';                          %Set the expected name of the initialization script.
collated_filename = 'Vulintus_Vibrotactile_Detection_Task.m';               %Set the name for the collated script.

temp = which(start_script);                                                 %Find the location of the start script.
[path, ~, ~] = fileparts(temp);                                             %Grab the parts of the collated file.
path(strfind(path,'\src'):end) = [];                                        %Find the parent directory of the "src" folder.
collated_filename = fullfile(path,collated_filename);                       %Add the parent direction to the collated script.

programs = Vulintus_Behavior_Program_List;                                  %Grab all of the common program information.
exclude_fcns = {programs.script_root}';                                     %Grab all of the behavior program script roots.
exclude_fcns(cellfun(@isempty,exclude_fcns)) = [];                          %Kick out all empty cells.
exclude_fcns = setdiff(exclude_fcns,{'Vibrotactile_Detection_*'});          %Grab all roots that aren't the current behavior.
exclude_fcns{end+1} = 'Connect_OmniTrak_Beta';                              %Also don't include the beta version of Connect OmniTrak.

[collated_file, ~] = Vulintus_Collate_Functions(start_script,...
    collated_filename,...
    'DepFunFolder','on',...
    'RemoveOrphans','on',...
    'ExcludeFcns',exclude_fcns);                                            %Call the generalized function-collating script.

winopen(collated_file);                                                     %Open the newly collated *.m file.