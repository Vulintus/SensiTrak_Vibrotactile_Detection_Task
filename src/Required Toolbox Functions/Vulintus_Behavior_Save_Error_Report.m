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