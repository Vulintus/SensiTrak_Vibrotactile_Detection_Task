function Vulintus_TSV_File_Write(data,filename)

%
%Vulintus_TSV_File_Write.m - Vulintus, Inc.
%
%   VULINTUS_TSV_FILE_WRITE saves the elements of the cell array "data" in
%   a TSV-formatted spreadsheet specified by "filename".
%   
%   UPDATE LOG:
%   2016-09-13 - Drew Sloan - Generalized the MotoTrak TSV-writing program
%                             to also work with OmniTrak and future 
%                             behavior programs.
%   2024-05-06 - Drew Sloan - Renamed from "Vulintus_Write_TSV_File" to 
%                             "Vulintus_TSV_File_Write".
%


[fid, errmsg] = fopen(filename,'wt');                                       %Open a text-formatted configuration file to save the stage information.
if fid == -1                                                                %If a file could not be created...
    warndlg(sprintf(['Could not create stage file backup '...
        'in:\n\n%s\n\nError:\n\n%s'],filename,...
        errmsg),'OmniTrak File Write Error');                               %Show a warning.
end
for i = 1:size(data,1)                                                      %Step through the rows of the stage data.
    for j = 1:size(data,2)                                                  %Step through the columns of the stage data.
        data{i,j}(data{i,j} < 32) = [];                                     %Kick out all special characters.
        fprintf(fid,'%s',data{i,j});                                        %Write each element of the stage data as tab-separated values.
        if j < size(data,2)                                                 %If this isn't the end of a row...
            fprintf(fid,'\t');                                              %Write a tab to the file.
        elseif i < size(data,1)                                             %Otherwise, if this isn't the last row...
            fprintf(fid,'\n');                                              %Write a carriage return to the file.
        end
    end
end
fclose(fid);                                                                %Close the stages TSV file.    