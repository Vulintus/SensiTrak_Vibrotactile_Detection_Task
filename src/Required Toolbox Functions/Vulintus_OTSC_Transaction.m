function varargout = Vulintus_OTSC_Transaction(serialcon,cmd,varargin)

%Vulintus_Serial_Request.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_TRANSACTION sends an OTSC code ("cmd") followed by any
%   specified accompanying data ("data"), and then can wait for a reply
%   consisting of a the specified number of values in the specified format 
%   ('int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'uint64',...
%   'single', or 'double'), unless no requested reply ("req") is expected 
%   or unless told not to wait ("nowait"). If the number of values in the
%   requested data is set to NaN, it will read the first byte of the reply
%   following the OTSC code use that value as the number of expected values
%   in the reply.
%
%   UPDATE LOG:
%   2024-06-07 - Drew Sloan - Consolidated "Vulintus_Serial_Send",
%                             "Vulintus_Serial_Request", and 
%                             "Vulintus_Serial_Request_Bytes" into a
%                             single function.
%


wait_for_reply = 1;                                                         %Wait for the reply by default.
passthrough = 0;                                                            %Assume this is not a passthrough command.
data = {};                                                                  %Assume that no code-folling data will be sent.
req = {};                                                                   %Assume that no reply will be requested.

i = 1;                                                                      %Initialize a input variable counter.
while i <= numel(varargin)                                                  %Step through all of the variable input arguments.  
    if ischar(varargin{i})                                                  %If the input is characters...
        switch lower(varargin{i})                                           %Switch between recognized arguments.
            case 'nowait'                                                   %If the user specified not to wait for the reply...
                wait_for_reply = 0;                                         %Don't wait for the reply.
                i = i + 1;                                                  %Increment the variable counter.
            case 'passthrough'                                              %If this is a passthrough command..
                passthrough = 1;                                            %Set the passthrough flag to 1.
                pass_target = varargin{i+1};                                %Grab the passthrough target.
                i = i + 2;                                                  %Increment the variable counter by two.
            case 'data'                                                     %If OTSC code-following data is specified...
                data = varargin{i+1};                                       %Grab the code-following data.
                i = i + 2;                                                  %Increment the variable counter by two.
            case 'reply'                                                    %If an expected reply is specified...
                req = varargin{i+1};                                        %Grab the requested data ounts and types.
                i = i + 2;                                                  %Increment the variable counter by two.
        end
    else                                                                    %Otherwise...
        error('ERROR IN %s: Unrecognized input type''%s''.',...
            upper(mfilename),class(varargin{i}));                           %Show an error.
    end
end

varargout = cell(1,size(req,1)+1);                                          %Create a cell array to hold the variable output arguments.

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".
type_size = @(data_type)Vulintus_Return_Data_Type_Size(data_type);          %Create a shortened pointer to the data type size toolbox functions.

if vulintus_serial.bytes_available() > 0 && wait_for_reply                  %If there's currently any data on the serial line.
    vulintus_serial.flush();                                                %Flush any existing bytes off the serial line.
end

if passthrough                                                              %If the passthrough command was included...
    [pass_down_cmd, pass_up_cmd] = Vulintus_OTSC_Passthrough_Commands;      %Grab the passthrough commands.
    data_N = 2;                                                             %Set the expected size of the data packet (start with 2 bytes for the OTSC code).
    for i = 1:size(data,1)                                                  %Step through each requested data type.
        byte_size = Vulintus_Return_Data_Type_Size(data{i,2});              %Grab the byte size of the data type.
        data_N = data_N + numel(data{i,1})*byte_size;                       %Add the number of expected bytes to the total.
    end
    vulintus_serial.write(pass_down_cmd,'uint16');                          %Write the fixed-length passthrough command.
    vulintus_serial.write(pass_target,'uint8');                             %Write the target port index and a zero to indicate the command comes from the computer.
    vulintus_serial.write(data_N,'uint8');                                  %Write the number of subsequent bytes to pass.
end

vulintus_serial.write(cmd,'uint16');                                        %Write the command to the serial line.
for i = 1:size(data,1)                                                      %Step through each row of the code-following data.
    vulintus_serial.write(data{i,1},data{i,2});                             %Write the data to the serial line.
end

if ~isempty(req) && wait_for_reply                                          %If we're waiting for the reply.

    req_N = 2;                                                              %Set the expected size of the data packet.
    reply_bytes = zeros(size(req,1));                                       %Create a matrix to hold the number of bytes for each requested type.
    for i = 1:size(req,1)                                                   %Step through each requested data type.
        if ~isnan(req{i,1})                                                 %If the number of requested elements isn't NaN...            
            byte_size = type_size(req{i,2});                                %Grab the byte size of the requested data type.
            reply_bytes(i) = req{i,1}*byte_size;                            %Set the number of bytes expected for this requested data type.
        else                                                                %Otherwise, if the number of elements is NaN.
           reply_bytes(i) = 1;                                              %Add one byte to the number expected data packet size.
        end
    end
    req_N = req_N + sum(reply_bytes);                                       %Sum the number of bytes for each requested data type.
    
    timeout = 1.0;                                                          %Set a one second time-out for the following loop.
    timeout_timer = tic;                                                    %Start a stopwatch.
    while toc(timeout_timer) < timeout && ...
            vulintus_serial.bytes_available() <  req_N                      %Loop for 1 seconds or until the expected reply shows up on the serial line.
        pause(0.005);                                                       %Pause for 5 milliseconds.
    end

    if vulintus_serial.bytes_available() < req_N                            %If there's not at least the expected number of bytes on the serial line...
        cprintf([1,0.5,0],['Vulintus_OTSC_Transaction Timeout! %1.0f '...
            'of %1.0f requested bytes returned.\n'],...
            vulintus_serial.bytes_available(), req_N);                      %Indicate a timeout occured.
        vulintus_serial.flush();                                            %Flush any remaining bytes off the serial line.
        return                                                              %Skip execution of the rest of the function.
    end

    if ~passthrough                                                         %If this wasn't a passthrough request...        

        code = vulintus_serial.read(1,'uint16');                            %Read in the unsigned 16-bit integer block code.
        req_N = req_N - 2;                                                  %Update the expected number of bytes in the data packet.
        for i = 1:size(req,1)                                               %Step through each requested data type.
            if isnan(req{i,1})                                              %If the number of requested elements is NaN...
                req{i,1} = vulintus_serial.read(1,'uint8');                 %Set the number of requested elements to the next byte.
                reply_bytes(i) = req{i,1}*type_size(req{i,2});              %Update the number of bytes expected for this data typ.
                req_N = req_N + reply_bytes(i) - 1;                         %Update the expected number of bytes in the data packet.
            end
            while toc(timeout_timer) < timeout && ...
                    vulintus_serial.bytes_available() < req_N               %Loop for 1 seconds or until the expected reply shows up on the serial line.
                pause(0.001);                                               %Pause for 1 millisecond.
            end
            if vulintus_serial.bytes_available() < req_N                    %If there's not at least the expected number of bytes on the serial line...       
                vulintus_serial.flush();                                    %Flush any remaining bytes off the serial line.
                return                                                      %Skip execution of the rest of the function.
            end
            if req{i,1} > 0                                                 %If a nonzero count is requested...
                varargout{i} = vulintus_serial.read(req{i,1},req{i,2});     %Read in the requested values as the specified data type.
            end
            req_N = req_N - reply_bytes(i);                                 %Upate the number of expected bytes in the data packet.
        end
        varargout{size(req,1)+1} = code;                                    %Return the reply OTSC code as the last output argument.

    else                                                                    %Otherwise, if this was a passthrough request...

        code = [];                                                          %Create an empty matrix to hold the reply OTSC code. 
        buffer = uint8(zeros(1,1024));                                      %Create a buffer to hold the received bytes.
        buff_i = 0;                                                         %Create a buffer index.
        read_N = 0;                                                         %Keep track of the number of bytes to read.
        i = 1;                                                              %Create a reply type index.
        timeout = 0.1;                                                      %Set a 100 millisecond time-out for the following loop.
        timeout_timer = tic;                                                %Start a stopwatch.        
        while toc(timeout_timer) < timeout && req_N > 0                     %Loop until the time-out duration has passed.

            if vulintus_serial.bytes_available()                            %If there's serial bytes available...
                if read_N                                                   %If there's still bytes to read...
                    n_bytes = vulintus_serial.bytes_available();            %Grab the number of bytes available on the serial line.
                    n_bytes = min(n_bytes, read_N);                         %Read in the smaller of the number of bytes available or the bytes remaining in the block.
                    if pass_source == pass_target                           %If these bytes come from the target.
                        buffer(buff_i + (1:n_bytes)) = ...
                            vulintus_serial.read(n_bytes,'uint8');          %Read in the bytes.
                        buff_i = buff_i + n_bytes;                          %Increment the buffer index.                                     
                    else                                                    %Otherwise...
                        vulintus_serial.read(n_bytes,'uint8');              %Read in and ignore the bytes.
                    end
                    read_N = read_N - n_bytes;                              %Decrement the bytes left to read.
                elseif vulintus_serial.bytes_available() >= 5               %Otherwise, if there's at least 5 bytes on the serial line...
                    passthru_code = vulintus_serial.read(1,'uint16');       %Read in the unsigned 16-bit integer block code.
                    if passthru_code ~= pass_up_cmd                         %If the block code isn't for an upstream passthrough...
                        vulintus_serial.flush();                            %Flush any remaining bytes off the serial line.
                        return                                              %Skip the rest of the function.
                    end
                    pass_source = vulintus_serial.read(1,'uint8');          %Read in the unsigned 8-bit source ID.
                    read_N = vulintus_serial.read(1,'uint16');              %Read in the unsigned 16-bit number of bytes.
                end
                timeout_timer = tic;                                        %Restart the stopwatch. 
            end

            if isempty(code)                                                %If the OTSC reply code hasn't been read yet...
                if buff_i >= 2                                              %If at least two bytes have been read into the buffer...
                    code = typecast(buffer(1:2),'uint16');                  %Read the reply OTSC from the buffer.
                    if buff_i > 2                                           %If there's more bytes left in the buffer.
                        buffer(1:buff_i-2) = buffer(3:buff_i);              %Shift the values in the buffer.
                    end
                    buff_i = buff_i - 2;                                    %Decrement the buffer index.
                    req_N = req_N - 2;                                      %Update the expected number of bytes in the data packet.
                end
            elseif isnan(req{i,1}) && buff_i >= 1                           %If the number of requested elements is NaN...
                req{i,1} = buffer(1);                                       %Set the number of requested elements to the next byte.                            
                reply_bytes(i) = req{i,1}*type_size(req{i,2});              %Update the number of bytes expected for this data typ.
                if buff_i > 1                                               %If there's more bytes left in the buffer.
                    buffer(1:buff_i-1) = buffer(2:buff_i);                  %Shift the values in the buffer.
                end
                buff_i = buff_i - 1;                                        %Decrement the buffer index.
                req_N = req_N + reply_bytes(i) - 1;                         %Update the expected number of bytes in the data packet.
            elseif buff_i >= reply_bytes(i) && req{i,1} > 0                 %If the buffer contains all of the next requested data type...
                if strcmpi(req{i,2},'char')                                 %If we're reading characters...
                    varargout{i} = ...
                        char(buffer(1:reply_bytes(i)));                     %Convert the bytes to characters.
                else                                                        %Otherwise...
                    varargout{i} = ...
                        typecast(buffer(1:reply_bytes(i)),...
                        req{i,2});                                          %Typecast the bytes from the buffer to the requested type.
                end
                if buff_i > reply_bytes(i)                                  %If there's more bytes left in the buffer.
                    buffer(1:buff_i-reply_bytes(i)) = ...
                        buffer(reply_bytes(i) + 1:buff_i);                  %Shift the values in the buffer.
                end
                buff_i = buff_i - reply_bytes(i);                           %Decrement the buffer index.
                req_N = req_N - reply_bytes(i);                             %Upate the number of expected bytes in the data packet.
                i = i + 1;                                                  %Increment the data type index.
            elseif req{i,1} == 0                                            %If zero bytes are being returned...
                i = i + 1;                                                  %Increment the data type index.
            end       

            pause(0.001);                                                   %Pause for 1 millisecond.
        end
        if req_N                                                            %If bytes were left unread...
            fprintf(1,'Vulintus_OTSC_Transaction Timeout!');                %Indicate a timeout occured.
        end
        varargout{size(req,1)+1} = code;                                    %Return the reply OTSC code as the last output argument.

    end

    vulintus_serial.flush();                                                %Flush any remaining bytes off the serial line.
end