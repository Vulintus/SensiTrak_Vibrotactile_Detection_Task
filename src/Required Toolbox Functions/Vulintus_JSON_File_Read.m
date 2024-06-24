function data = Vulintus_JSON_File_Read(file)

%
%Vulintus_JSON_File_Read.m - Vulintus, Inc.
%
%   VULINTUS_JSON_FILE_READ reads in data from a JSON-formatted text file.
%   
%   UPDATE LOG:
%   2023-06-08 - Drew Sloan - Function first created, adapted from
%                             "Vulintus_Read_TSV_File.m".
%   2024-03-08 - Drew Sloan - Renamed file from "Vulintus_Read_JSON_File"
%                             to "Vulintus_JSON_File_Read".
%

[fid, errmsg] = fopen(file,'rt');                                           %Open the stage configuration file saved previously for reading as text.
if fid == -1                                                                %If the file could not be opened...
    str = sprintf(['Could not read the specified JSON file:\n\n%s\n\n'...
        'Error:\n\n%s'],file,errmsg);                                       %Create a warning string.
    warndlg(str,'Vulintus_Read_JSON_File Error');                           %Show a warning.
    close(fid);                                                             %Close the file.
    data = [];                                                              %Set the output data variable to empty brackets.
    return                                                                  %Skip execution of the rest of the function.
end
txt = fread(fid,'*char')';                                                  %Read in the file data as text.
fclose(fid);                                                                %Close the configuration file.
if any(txt == '\')                                                          %If there's any forward slashes...    
    txt = strrep(txt,'\','\\');                                             %Replace all single forward slashes with two slashes.
    k = strfind(txt,'\\\');                                                 %Look for any triple forward slashes...
    txt(k) = [];                                                            %Kick out the extra forward slashes.
end
data = jsondecode(txt);                                                     %Convert the text to data.