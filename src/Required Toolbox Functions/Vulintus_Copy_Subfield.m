function target_struct = Vulintus_Copy_Subfield(target_struct, source_struct, src_fields)

%
%Vulintus_Copy_Subfield.m - Vulintus, Inc.
%
%   VULINTUS_COPY_SUBFIELD is a recursive function that copies a subfield
%   from "source_struct" to "target_struct", including all field branches.
%   
%   UPDATE LOG:
%   2024-03-08 - Drew Sloan - Function first created.
%


if isfield(source_struct,src_fields{1})                                     %If the first field exists in the source structure...
    if length(src_fields) == 1                                              %If this is the highest level specified...
        target_struct.(src_fields{1}) = source_struct.(src_fields{1});      %Copy the field to the target structure.
    else                                                                    %Otherwise...
        if ~isfield(target_struct,src_fields{1})                            %If the field doesn't exist on the target structure...
            target_struct.(src_fields{1}) = struct;                         %Initialize the field.
        end
        target_struct.(src_fields{1}) = ...
            Vulintus_Copy_Subfield(target_struct.(src_fields{1}),...
            source_struct.(src_fields{1}), src_fields(2:end));              %Recursively call this function to copy the next branch level.
    end
end