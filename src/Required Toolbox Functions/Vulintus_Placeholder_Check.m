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