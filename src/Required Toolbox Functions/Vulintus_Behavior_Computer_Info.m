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
