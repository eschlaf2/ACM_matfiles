function varargout = filter_footprints(varargin)
% FILTER_FOOTPRINTS MATLAB code for filter_footprints.fig
%      FILTER_FOOTPRINTS, by itself, creates a new FILTER_FOOTPRINTS or raises the existing
%      singleton*.
%
%      H = FILTER_FOOTPRINTS returns the handle to a new FILTER_FOOTPRINTS or the handle to
%      the existing singleton*.
%
%      FILTER_FOOTPRINTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FILTER_FOOTPRINTS.M with the given input arguments.
%
%      FILTER_FOOTPRINTS('Property','Value',...) creates a new FILTER_FOOTPRINTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before filter_footprints_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to filter_footprints_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help filter_footprints

% Last Modified by GUIDE v2.5 22-Dec-2016 10:47:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @filter_footprints_OpeningFcn, ...
                   'gui_OutputFcn',  @filter_footprints_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function plotter(hObject, eventdata, handles)
imagesc(reshape(sum(handles.spatmap(:,handles.keepInds),2),...
    handles.d1,handles.d2));
title('All')
if handles.roiN > 0
    hold on;
    contour(reshape(handles.spatmap(:,handles.roiN),...
        handles.d1,handles.d2),...
        [1 2], 'linewidth', 2, 'linecolor',[1 0 0]);
    hold off;
    title(num2str(handles.roiN))
end
set(gca, 'xtick',[],'ytick',[])


% --- Executes just before filter_footprints is made visible.
function filter_footprints_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to filter_footprints (see VARARGIN)

% Choose default command line output for filter_footprints
handles.roiN = 0;
handles.spatmap = varargin{1};
handles.d1 = 512; handles.d2 = 512;
handles.numrois = size(handles.spatmap,2);
smin = 0; smax = handles.numrois;
handles.slider1.Max = smax;
handles.slider1.Min = smin;
handles.slider1.Value = smin;
handles.slider1.SliderStep = [1/(smax-smin) 1];
handles.keepInds = true(size(handles.spatmap,2),1);
handles.output = handles.keepInds;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using filter_footprints.
if strcmp(get(hObject,'Visible'),'off')
    plotter(hObject, eventdata, handles);
end
handles.checkbox1.Enable = 'off';
uiwait(handles.figure1)

% UIWAIT makes filter_footprints wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = filter_footprints_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
handles.keepInds(handles.roiN) = ~get(hObject,'Value');
guidata(hObject,handles);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.roiN = round(get(hObject,'Value'));
plotter(hObject, eventdata, handles);
if handles.roiN == 0
    handles.checkbox1.Enable = 'off';
else
    handles.checkbox1.Enable = 'on';
    handles.checkbox1.Value = ~handles.keepInds(handles.roiN);
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

guidata(hObject, handles);


% --- Executes on button press in closebutton.
function closebutton_Callback(hObject, eventdata, handles)
% hObject    handle to closebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = handles.keepInds;

% Update handles structure
guidata(hObject, handles);

selection = questdlg(['Close and filter?'],...
                     ['Close and filter ...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

uiresume(handles.figure1)


% --- Executes during object creation, after setting all properties.
function checkbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1


% --- Executes on button press in keepall.
function keepall_Callback(hObject, eventdata, handles)
% hObject    handle to keepall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.keepInds = true(handles.numrois,1);
handles.checkbox1.Value = false;
plotter(hObject,[],handles);
guidata(hObject,handles);


% --- Executes on button press in deleteall.
function deleteall_Callback(hObject, eventdata, handles)
% hObject    handle to deleteall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.keepInds = false(handles.numrois,1);
handles.checkbox1.Value = true;
plotter(hObject,[],handles);
guidata(hObject,handles);


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[x, y, ~] = ginput(1); pixel = round([x y]);
pixel = sub2ind([handles.d1 handles.d2], pixel(1), pixel(2));
display(find(handles.spatmap(pixel,:) & handles.keepInds',1))
handles.roiN = find(handles.spatmap(pixel,:) & handles.keepInds',1);
display(handles.roiN)
plotter(hObject,[],handles);
guidata(hObject,handles);
