function target_struct = Vulintus_Merge_Structures(target_struct, source_struct)

%
%Vulintus_Merge_Structures.m - Vulintus, Inc.
%
%   VULINTUS_MERGE_STRUCTURES is a recursive function that takes all the 
%   fields from "source_struct" and copies them into "target_struct". If a 
%   field exists and isn't empty in both "target_struct" and 
%   "source_struct", the field in "target_struct" will be overwritten.
%   
%   UPDATE LOG:
%   2024-03-08 - Drew Sloan - Function first created.
%


src_fields = fieldnames(source_struct);                                     %Grab all of the field names from the source structure.
for f = 1:length(src_fields)                                                %Step through each field.    
    if isstruct(source_struct.(src_fields{f}))                              %If this field is a structure...
        if ~isfield(target_struct,src_fields{f})                            %If this field doesn't exist in the target structure...
            target_struct.(src_fields{f}) = struct;                         %Create an empty structure for the field.
        end
        target_struct.(src_fields{f}) = ...
            Vulintus_Merge_Structures(target_struct.(src_fields{f}),...
            source_struct.(src_fields{f}));                                 %Recursively call this function to handle all sub-fields.
    else                                                                    %Otherwise...
        if ~isfield(target_struct,src_fields{f}) || ...
                ~isempty(source_struct.(src_fields{f}))                     %If this field doesn't exist in the target structure...
            target_struct.(src_fields{f}) = source_struct.(src_fields{f});  %Copy the field.
        end
    end
end