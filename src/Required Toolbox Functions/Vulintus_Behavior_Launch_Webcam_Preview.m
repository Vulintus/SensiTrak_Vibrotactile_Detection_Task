function Vulintus_Behavior_Launch_Webcam_Preview

set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
pos = get(0,'screensize');                                                  %Grab the default position of the new figure.
w = 15;                                                                     %Set the preview width, in centimeters.
h = 9*w/16;                                                                 %Set the preview height, in centimeters.
pos = [pos(3)/2 - w/2, pos(4)/2 - h/2, w, h];                               %Set the figure position.
sp = 0.25;                                                                  %Set the space in between webcam buttons.

fig = figure('units','centimeters',...
    'position',pos,...
    'MenuBar','none',...
    'numbertitle','off',...
    'resize','on',...
    'name','Webcam Preview');                                               %Make a new figure.

cams = webcamlist;                                                          %Fetch all of the available webcams.
if numel(cams) == 1                                                         %If there's only one camera available...
    Open_Webcam_Preview(fig,[],cams{1});                                    %Open up the webcam preview immediately.
    return                                                                  %Skip execution of the rest of the function.
end

ui_h = (h - (numel(cams) + 1)*sp)/numel(cams);                              %Calculate the height of each button.
fontsize = 4*ui_h;                                                          %Set the button fontsize.

for i = 1:numel(cams)                                                       %Step through each available camera.
    pos = [sp, h - i*(ui_h + sp), w - 2*sp, ui_h];                          %Set the position for each uicontrol
    uicontrol('style','pushbutton',...
        'string',cams{i},...
        'fontsize',fontsize,...
        'units','centimeters',...
        'position',pos,...
        'callback',{@Open_Webcam_Prevew,cams{i}},...
        'parent',fig);       
end


function Open_Webcam_Prevew(hObject,~,camstring)
type = get(hObject,'type');                                                 %Grab the calling object type.
if strcmpi(type,'figure')                                                   %If the object handle is for a figure...
    obj = hObject;                                                          %Keep that object handles.
else                                                                        %Otherwise...
    obj = get(hObject,'parent');                                            %Grab the parent handle for the object.
end
temp = get(obj,'children');                                                 %Grab handles for all children of the figure.
delete(temp);                                                               %Delete all children.
ax = axes('units','normalized',...
    'position',[0,0,1,1],...
    'visible','off',...
    'parent',obj);                                                          %Create axes on the figure.
cam = webcam(camstring);                                                    %Create a webcam object.
img = snapshot(cam);                                                        %Grab a snapshot from the camera.
img_size = size(img);                                                       %Grab the image size.
pos = get(obj,'position');                                                  %Grab the figure position.
pos(4) = pos(3)*(img_size(1)/img_size(2));                                  %Re-adjust the height of the figure.
set(obj,'position',pos);                                                    %Update the figure position.
im = image(img,'parent',ax);                                                %Show the image in the axes.
preview(cam,im);                                                            %Show a preview of the webcam in the image.
set(obj,'ResizeFcn',{@Webcam_Figure_Resize,img_size(1)/img_size(2)});       %Set the resize figure callback.
set(obj,'CloseRequestFcn',{@Webcam_Figure_Close,cam});                      %Set the close figure callback.


function Webcam_Figure_Resize(hObject,~,ratio)
pos = get(hObject,'position');                                              %Grab the figure position.
pos(4) = pos(3)*ratio;                                                      %Re-adjust the height of the figure.
set(hObject,'position',pos);                                                %Update the figure position.


function Webcam_Figure_Close(hObject,~,cam)
delete(cam);                                                                %Delete the camera object.
delete(hObject);                                                            %Delete the figure.