function channels = input_channels(channels)

nchannels = length(channels);
typestring = {'data';'dic';'eggshell';'cortex'};

chans = 'Channel ';

liststring = '';
for i=1:nchannels
  liststring = [liststring chans num2str(i)];
  if (i<nchannels)
    liststring = [liststring '|'];
  end

  for j=1:length(typestring)
    if (strcmp(channels(i).type, typestring{j}))
      channels(i).type = j;

      break;
    end
  end
end

mygray = [0:255]' / 255;
mygray = [mygray mygray mygray];

hFig = figure(...
'PaperUnits','centimeters',...
'CloseRequestFcn',@channel_fig_CloseRequestFcn,...
'Color',[0.701960784313725 0.701960784313725 0.701960784313725],...
'Colormap', mygray,...
'MenuBar','none',...
'Name','Channel Identification',...
'NumberTitle','off',...
'Position',[34 306 567 294],...
'DeleteFcn',@empty,...
'HandleVisibility','callback',...
'Tag','channel_fig',...
'UserData',[],...
'Visible','off');

hOK = uicontrol(...
'Parent',hFig,...
'Units','normalized',...
'Callback',@channel_fig_CloseRequestFcn,...
'Position',[0.388007054673721 0.0170068027210884 0.17636684303351 0.0714285714285714],...
'String','OK',...
'Tag','pushbutton11');

hPanel = uipanel(...
'Parent',hFig,...
'Title','Channel 1',...
'Tag','uipanel',...
'Clipping','on',...
'Position',[0.174603174603175 0.108843537414966 0.80952380952381 0.853741496598639]);

hAxes = axes(...
'Parent',hPanel,...
'Position',[0.0461210431359685 0.0299145299145299 0.562899786780384 0.965811965811967],...
'Visible','off',...
'Tag','axes');

hText = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Position',[0.690831556503198 0.372649572649573 0.202558635394456 0.0811965811965812],...
'String','Channel type',...
'Style','text',...
'Tag','text18');

hName = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Position',[0.637526652452025 0.676068376068377 0.298507462686567 0.2982905982905984],...
'String','filename',...
'Style','text',...
'Tag','fname');

hDetrend = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Callback',@detrend_Callback,...
'Position',[0.70362473347548 0.090598290598291 0.176972281449893 0.0982905982905984],...
'String','Detrend',...
'Style','checkbox',...
'Tag','detrend');

hHotPixels = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Callback',@hotpix_Callback,...
'Position',[0.70362473347548 0.010598290598291 0.176972281449893 0.0982905982905984],...
'String','Hot Pixels',...
'Style','checkbox',...
'Tag','hot_pixels');

hColor = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Callback',@channel_color_Callback,...
'Position',[0.686567164179104 0.530769230769231 0.213219616204691 0.115384615384615],...
'String','Fluorophore color',...
'Tag','channel_color');

hType = uicontrol(...
'Parent',hPanel,...
'Units','normalized',...
'Callback',@channel_type_Callback,...
'Position',[0.667377398720682 0.261538461538462 0.245202558635394 0.0897435897435899],...
'String',typestring,...
'Style','popupmenu',...
'Value',1,...
'Tag','channel_type');

hChannel = uicontrol(...
'Parent',hFig,...
'Units','normalized',...
'Callback',@channel_list_Callback,...
'Position',[0.00881834215167548 0.112244897959184 0.156966490299824 0.829931972789116],...
'String',liststring,...
'Style','listbox',...
'Value',1,...
'Tag','channel_list');

handles = struct('uipanel', hPanel, ...
                 'fname', hName, ...
                 'detrend',hDetrend,...
                 'hot_pixels',hHotPixels,...
                 'channel_color',hColor,...
                 'channel_type',hType,...
                 'axes',hAxes,...
                 'channels',channels,...
                 'img',-1,...
                 'current',1);
             
set(hFig, 'UserData', handles);
%setfocus(hFig);
set(hFig,'Visible','on');
update_display(hFig, 1);

uiwait(hFig);

handles = get(hFig, 'UserData');
channels = handles.channels;

delete(hFig);
drawnow;

function empty(hObject, eventdata, handles)

function channel_list_Callback(hObject, eventdata, handles)
% hObject    handle to channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns channel_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_list

update_display(gcbf, get(hObject,'Value'));

% -- Update the display
function update_display(hfig, indx)

handles = get(hfig,'UserData');

handles.current = indx;
set(handles.uipanel,'Title',['Channel ' num2str(indx)]);
set(handles.fname,'String',handles.channels(indx).file);
set(handles.detrend,'Value',handles.channels(indx).detrend);
set(handles.hot_pixels,'Value',handles.channels(indx).hot_pixels);
set(handles.channel_color, 'BackgroundColor', handles.channels(indx).color);
set(handles.channel_type, 'Value', handles.channels(indx).type);

%drawnow;
%refresh(hfig);
img = load_data(handles.channels(indx),1);
if (handles.channels(indx).hot_pixels)
  img = imhotpixels(img);
end

if (ishandle(handles.img))
  set(handles.img,'CData',img);
else
  %cmap = colormap('gray');
  %image(load_data(handles.channels(indx),1),'Parent',handles.axes);
  %image(load_data(handles.channels(indx),1),'Parent',handles.axes,'CDataMapping','scaled','Visible','on');
  %axes(handles.axes);
  %get(handles.axes,'type')

  handles.img = image(img,'Parent',handles.axes,'CDataMapping','scaled');
  set(handles.axes,'Visible','off');
end

set(hfig, 'UserData', handles);

% --- Executes on button press in detrend.
function detrend_Callback(hObject, eventdata, handles)
% hObject    handle to detrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of detrend

hfig = gcbf;
handles = get(hfig, 'UserData');
handles.channels(handles.current).detrend = get(hObject, 'Value');
set(hfig, 'UserData', handles);

% --- Executes on button press in detrend.
function hotpix_Callback(hObject, eventdata, handles)
% hObject    handle to detrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of detrend

hfig = gcbf;
handles = get(hfig, 'UserData');
handles.channels(handles.current).hot_pixels = get(hObject, 'Value');
set(hfig, 'UserData', handles);

update_display(hfig, handles.current);

% --- Executes on button press in channel_color.
function channel_color_Callback(hObject, eventdata, handles)
% hObject    handle to channel_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcbf;
handles = get(hfig, 'UserData');
indx = handles.current;

handles.channels(indx).color = uisetcolor(handles.channels(indx).color);
set(handles.channel_color, 'BackgroundColor', handles.channels(indx).color);

set(hfig, 'UserData', handles);

% --- Executes on selection change in channel_type.
function channel_type_Callback(hObject, eventdata, handles)
% hObject    handle to channel_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns channel_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_type

hfig = gcbf;
handles = get(hfig, 'UserData');
handles.channels(handles.current).type = get(hObject, 'Value');
set(hfig, 'UserData', handles);

function channel_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to channel_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcbf;

handles = get(hfig,'UserData');
channels = handles.channels;
nchannels = length(channels);

contents = get(handles.channel_type,'String');
ntypes = length(contents);

detrend = logical(zeros(nchannels,1));
types = logical(zeros(nchannels,ntypes));
colors = zeros(nchannels,3);

data_indx = 0;
for i=1:ntypes
  if (strcmp(contents{i},'data'))
    data_indx = i;
    break;
  end
end

for i=1:nchannels
  detrend(i) = channels(i).detrend;
  types(i,channels(i).type) = true;
  colors(i,:) = channels(i).color;
  channels(i).type = contents{channels(i).type};
end

ok = true;
if (any(sum(types(:,[1:ntypes]~=data_indx,1),1) > 1))
  errordlg('Only the ''Data'' type can have more than one channel');
  ok = false;
end
if (ok & any(detrend & types(:,data_indx), 1))
  answer = questdlg('Some ''Data'' channels will be detrended, continue ?');
  ok = strcmp(answer,'Yes');
end
if (ok & size(unique(colors,'rows'),1)~=nchannels)
  answer = questdlg('Multiple channels have the same color, continue ?');
  ok = strcmp(answer,'Yes');
end

if (ok)
  handles.channels = channels;
  set(hfig,'UserData',handles);
  uiresume(hfig);
end
