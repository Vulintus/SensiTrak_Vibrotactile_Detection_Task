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