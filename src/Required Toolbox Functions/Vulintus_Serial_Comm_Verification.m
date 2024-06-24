function comm_check = Vulintus_Serial_Comm_Verification(serialcon,ver_cmd,ver_key,stream_cmd,varargin)

%Vulintus_Serial_Comm_Verification.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_COMM_VERIFICATION sends the communication verification
%   code and the verification key to the device connected through the
%   specified serial object, and checks for a matching reply.
%
%   UPDATE LOG:
%   2022-02-25 - Drew Sloan - Function first created.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


wait_for_reply = 1;                                                         %Wait for the reply by default.
msg_type = 'none';                                                          %Don't print waiting messages by default.
for i = 1:length(varargin)                                                  %Step through any optional input arguments.
    if ischar(varargin{i}) && strcmpi(varargin{i},'nowait')                 %If the user specified not to wait for the reply...
        wait_for_reply = 0;                                                 %Don't wait for the reply.
    elseif isstruct(varargin{i}) && strcmpi(varargin{i}.type,'big_waitbar') %If a big waitbar structure was passed...
        msg_handle = varargin{i};                                           %Set the message display handle to the structure.
        msg_type = 'big_waitbar';                                           %Set the message display type to "big_waitbar".
    elseif ishandle(varargin{i}) && isprop(varargin{i},'Type')              %If a graphics handles was passed.     
        msg_type = lower(varargin{i}.Type);                                 %Grab the object type.
        if strcmpi(varargin{i}.Type,'uicontrol')                            %If the object is a uicontrol...
            msg_type = lower(varargin{i}.Style);                            %Grab the uicontrol style.
        end
        msg_handle = varargin{i};                                           %Set the message display handle to the text object.
    end
end

comm_check = 0;                                                             %Assume the verification will fail by default.

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

if vulintus_serial.bytes_available() > 0 && wait_for_reply                  %If there's any data on the serial line and we're waiting for a reply...
    Vulintus_OTSC_Transaction(serialcon,stream_cmd,{0,'uint8'});          %Disable streaming on the device.
    timeout = datetime('now') + seconds(1);                                 %Set a time-out point for the following loop.
    while datetime('now') < timeout && ...
            vulintus_serial.bytes_available() > 0                           %Loop until all data is cleared off the serial line.        
        pause(0.05);                                                        %Pause for 50 milliseconds.
        vulintus_serial.flush();                                            %Flush any existing bytes off the serial line.
    end
end
vulintus_serial.write(ver_cmd,'uint16');                                    %Write the verification command.
    
if ~wait_for_reply                                                          %If we're not waiting for the reply.
    return                                                                  %Exit the function.
end

switch msg_type                                                             %Switch between the message display types.
    case 'text'                                                             %Text object on an axes.
        message = get(msg_handle,'string');                                 %Grab the current message in the text object.
        message(end+1) = '.';                                               %Add a period to the end of the message.
        set(msg_handle,'string',message);                                   %Update the message in the text label on the figure.
    case {'listbox','uitextarea'}                                           %UIControl messagebox.
        Append_Msg(msg_handle,'.');                                         %Add a period to the last message in the messagebox.
    case 'big_waitbar'                                                      %Vulintus' big waitbar.
        val = 1 - 0.9*(1 - msg_handle.value());                             %Calculate a new value for the waitbar.
        msg_handle.value(val);                                              %Update the waitbar value.
end

timeout_timer = tic;                                                        %Start a timeout timer.
while vulintus_serial.bytes_available() <= 2 && toc(timeout_timer) < 1.0    %Loop until a reply is received.
    pause(0.01);                                                            %Pause for 10 milliseconds.
end

if vulintus_serial.bytes_available() >= 2                                   %If there's at least 2 bytes on the serial line.
    ver_code = vulintus_serial.read(1,'uint16');                            %Read in 1 unsigned 16-bit integer.
    if ver_code == ver_key                                                  %If the value matches the verification code...
        comm_check = 1;                                                     %Set the OTSC communication flag to 1.
    end
end
vulintus_serial.flush();                                                    %Clear the input and output buffers.