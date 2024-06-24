function Vulintus_JSON_File_Write(data,filename)

%
%Vulintus_JSON_File_Write.m - Vulintus, Inc.
%
%   VULINTUS_JSON_FILE_WRITE saves the elements of the variable "data" to
%   a JSON-formatted text file specified by "filename", with "data" being
%   any supported MATLAB data type.
%   
%   UPDATE LOG:
%   2023-06-08 - Drew Sloan - Function first created, adapted from
%                             "Vulintus_Write_TSV_File.m".
%   2024-03-08 - Drew Sloan - Added the "PrettyPrint" option to the
%                             "jsonencode" function.
%                             Renamed file from "Vulintus_Write_JSON_File"
%                             to "Vulintus_JSON_File_Write".
%


[fid, errmsg] = fopen(filename,'wt');                                       %Open a text-formatted configuration file to save the stage information.
if fid == -1                                                                %If a file could not be created...
    str = sprintf(['Could not create the specified JSON file:\n\n%s\n\n'...
        'Error:\n\n%s'],filename,errmsg);                                   %Create a warning string.
    warndlg(str,'Vulintus_Write_JSON_File Error');                          %Show a warning.
    return                                                                  %Skip execution of the rest of the function.
end
txt = jsonencode(data,PrettyPrint=true);                                    %Convert the data to JSON-formatted text.
if any(txt == '\')                                                          %If there's any forward slashes...    
    txt = strrep(txt,'\','\\');                                             %Replace all single forward slashes with two slashes.
    k = strfind(txt,'\\\');                                                 %Look for any triple forward slashes...
    txt(k) = [];                                                            %Kick out the extra forward slashes.
end
fprintf(fid,txt);                                                           %Write the text to the file.
fclose(fid);                                                                %Close the JSON file.    