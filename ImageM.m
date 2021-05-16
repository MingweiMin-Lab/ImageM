function ImageM()

%ImageM mimics the software ImageJ. Created by An Gong, 2021-01-17.
%Last update: 2021-05-16


global windows activeWin nonFigureList;
windows = [];
activeWin = [];
nonFigureList.contrastPanel = [];

%% define the user interface
hMain = figure('menubar', 'none', 'Visible', 'off', 'Position', [600 800 350 20],'NumberTitle','off','name', 'ImageM', 'Dockcontrols', 'off','Resize','off');
hMenuFile = uimenu(hMain, 'label', '&File');
uimenu(hMenuFile, 'label', 'Open', 'Accelerator', 'O','Callback',{@openFiugreFcn, blanks(0),'file'});
uimenu(hMenuFile, 'label', 'ImportAsStack', 'Accelerator', 'I','Callback',{@openFiugreFcn, blanks(0), 'folder'});
uimenu(hMenuFile, 'label', 'ImportFromVarible', 'Accelerator', 'V','Callback',{@openFiugreFcn, blanks(0), 'varible'});
uimenu(hMenuFile, 'label', 'Save', 'Accelerator', 'S','Callback',@menuSaveCallBackFcn);

hMenuImage = uimenu(hMain, 'label', '&Image');
uimenu(hMenuImage, 'label', 'Contrast', 'Callback',@menuContrastCallBackFcn);
uimenu(hMenuImage, 'label', 'Duplicate Shift+D', 'Callback', @menuDuplicateCallBackFcn);

hMenuProcess = uimenu(hMain, 'label', '&Process');
hMenuAnalyze = uimenu(hMain, 'label', '&Analyze');
hMenuWindows = uimenu(hMain, 'label', '&Window');

hMenuHelp = uimenu(hMain, 'label', '&Help');
hAbout = uimenu(hMenuHelp, 'label', 'About ImageM','Callback',@menuAboutCallBackFcn);


set(hMain, 'Visible', 'on');

%%
 

function sliderCallBackFcn(hObject, eventdata, handles)
    currentFrm = int16(get(hObject, 'value'));
    setappdata(hObject.Parent, 'currentFrm',currentFrm);
    %hImg = handles.hImg;
    imData = getappdata(hObject.Parent, 'imData');
    figInfo = getappdata(hObject.Parent, 'figInfo');
    fileFolder = figInfo.fileFolder;
    fileNames = figInfo.fileNames;
    imageType = figInfo.imageType;
    sizeInfo = figInfo.sizeInfo;
    hAxes = findobj(hObject.Parent, 'Type', 'Axes');
    if figInfo.virtualStack
        imDisp = imread(fullfile(fileFolder,fileNames{currentFrm}));
    else
        imDisp = imData(:,:,currentFrm);
    end   
    set(hAxes.Children, "CData", imDisp);
    text = strcat(num2str(currentFrm), "/",num2str(sizeInfo(3)),", ",num2str(sizeInfo(1)),"*",num2str(sizeInfo(2)), ", ", imageType);
    hText = handles.hText;
    set(hText, "string", text);
%     figure(hObject.Parent);
    
end

function createFigure(hObject,eventdata, handles, figInfo, imData)
    textBoxHeight = 15;
    sliderHeight = 20;
    gap = 5;
    ratio = 1;
    currentFrm = 1;
    width = figInfo.sizeInfo(1);
    height = figInfo.sizeInfo(2);
    if width<200
        ratio = round(200/width);
    elseif width>800
        ratio = 1/round(width/600);
    end
    windowName = figInfo.windowName;
    if ratio ~=1
        windowName = [windowName, '(',num2str(int8(100*ratio)),'%)'];
    end
    set(hObject,"position",[200, 200, width*ratio+2*gap, height*ratio+5*gap+textBoxHeight*2+sliderHeight], "name", windowName);
    figDisp = nan(figInfo.sizeInfo(1),figInfo.sizeInfo(2));
    if figInfo.virtualStack
        figDisp = imread(fullfile(figInfo.fileFolder,figInfo.fileNames{1}));
    else
        figDisp = imData(:,:,1);
    end
    textInit = strcat(num2str(figInfo.sizeInfo(1)),"*",num2str(figInfo.sizeInfo(2)), ",", figInfo.imageType);
    hText = uicontrol("style", "text", "position", [gap, figInfo.sizeInfo(2)*ratio+4*gap+sliderHeight+textBoxHeight, figInfo.sizeInfo(1)*ratio, textBoxHeight], "HorizontalAlignment", "left");
    hAxes = axes("units", "pixels", "Position", [gap, 3*gap+sliderHeight+textBoxHeight, figInfo.sizeInfo(1)*ratio, figInfo.sizeInfo(2)*ratio], "visible", "off", "parent", hObject);
    hImg = imshow(figDisp,[], "parent", hAxes);
    handles.hImg = hImg;
    handles.hText = hText;
    guidata(hObject, handles);

    setappdata(hObject,'figInfo',figInfo);
    setappdata(hObject,'imData',imData);
    setappdata(hObject,'currentFrm', currentFrm);

    
    if figInfo.sizeInfo(3)>1
        set(hText, "string", strcat(num2str(currentFrm), "/",num2str(figInfo.sizeInfo(3)),", ",num2str(figInfo.sizeInfo(1)),"*",num2str(figInfo.sizeInfo(2)), ", ", figInfo.imageType));
        hSlider = uicontrol("style", "slider", "value", currentFrm,"Min",1, "Max",figInfo.sizeInfo(3), "SliderStep",[1/(figInfo.sizeInfo(3)-1), 1/(figInfo.sizeInfo(3)-1)]);
        set(hSlider, "position", [gap, 2*gap+textBoxHeight, figInfo.sizeInfo(1)*ratio, sliderHeight]);
        set(hSlider,"Callback", {@sliderCallBackFcn,handles});
    else
        set(hText, "string", textInit);
    end
    set(hObject, "visible", "on");
    impixelinfo;
end

function figureCloseFcn(hObject,eventdata, handles)
    
   windows(windows==hObject)=[];
   delete(hObject);
    
end

function figurePresskeyFcn(hObject,eventdata, handles)

     if strcmp(eventdata.Key, 'return')
            figure(hMain);
     end
    switch eventdata.Character
        case 'D'
            menuDuplicateCallBackFcn();
     end
end


function buttonCallbackFcn(hObject,eventdata, handles)
    figInfo.virtualStack = 0;
    figInfo.sizeInfo = nan(1,3);
    figInfo.fileNames = [];
    figInfo.fileFolder = [];
    figInfo.windowName = [];
    figInfo.imageType = [];
    imData = [];
    
    hTemp = hObject.Parent;
    pop = findobj(hTemp, "Style","popupmenu");
    if length(string(pop.String))>1  %detect the situation of only one varible, need covert the name into a string first
        valName = pop.String{pop.Value};
    else
        valName = pop.String;
    end
    imData = evalin('base',valName);
    figInfo.windowName = valName;
    figInfo.sizeInfo(1) = size(imData,1);
    figInfo.sizeInfo(2) = size(imData,2);
    figInfo.sizeInfo(3) = 1;
    if length(size(imData))>2
        figInfo.sizeInfo(3) = size(imData,3);
    end
    figInfo.imageType=class(imData);
    setappdata(hTemp, 'figInfo', figInfo);
    setappdata(hTemp, 'imData', imData);
    uiresume(hTemp);
end

function [out1, out2] = getVaribleGUI()
        out1 = [];
        out2 = [];
        hTemp = figure('menubar', 'none', 'Position', [500 600 300 100],'NumberTitle','off','name', 'Choose a varible', 'Dockcontrols', 'off','Resize','off');
        set(hTemp, 'windowStyle','modal');
        pop = uicontrol(hTemp,'Style','popupmenu','Position', [70 50 60 20]);
        txt = uicontrol(hTemp, 'Style', 'text','String', 'Varibles', 'Position', [20 50 40 20] );
        button = uicontrol(hTemp, 'Style', 'pushButton','String', 'Ok', 'Position', [170 50 60 20]);
        set(button, 'Callback', @buttonCallbackFcn);
        vals = evalin('base', 'whos'); % get varible information in base workspace
        [valNames]={vals.name};
        valNames=string(valNames);
        pop.String = valNames;
        uiwait(hTemp);
        if ishandle(hTemp)
            out1 = getappdata(hTemp,'figInfo');
            out2 = getappdata(hTemp,'imData');
            delete(hTemp);
        end
end

function openFiugreFcn(hObject,eventdata, handles, type)

    figInfo.virtualStack = 1;
    figInfo.sizeInfo = nan(1,3);
    figInfo.fileNames = [];
    figInfo.fileFolder = [];
    figInfo.windowName = [];
    figInfo.imageType = [];
    imData = [];
    switch type
        case 'file'
             [fileName, fileFolder, index] = uigetfile({"*.tif; *.tiff; *.bmp; *.jpg"; "*.*"}, "File Selector");

             if index
                figInfo.fileFolder = fileFolder;
                figInfo.windowName = fileName;
                figInfo.fileNames = cellstr(fileName);
                imData = imread(fullfile(fileFolder, fileName));
                figInfo.imageType = class(imData);
                figInfo.sizeInfo(1) = size(imData,2);
                figInfo.sizeInfo(2) = size(imData,1);
                figInfo.sizeInfo(3) = 1;
             end
        case  'folder'
              fileFolder = uigetdir();
              if fileFolder ~= 0
                figInfo.fileFolder = fileFolder;
                filesInfo = dir(fullfile(fileFolder,"*.tif"));
                figInfo.fileNames = {filesInfo.name};
                imData = imread(fullfile(fileFolder,figInfo.fileNames{1}));
                figInfo.imageType = class(imData);
                width = size(imData,2); %get width
                height = size(imData,1); %get height
                figInfo.sizeInfo(1) = width;
                figInfo.sizeInfo(2) = height;
                figInfo.sizeInfo(3) = length(filesInfo);
                fileFolderNameSplit = split(fileFolder, "\");
                figInfo.windowName = fileFolderNameSplit{end};
              end
              case  'varible'
                [figInfo, imData] = getVaribleGUI;
                                
        otherwise
            warning('unproper parameter for opening figures!');
    end

    if ~isempty(imData)
        hFig = figure("menubar", "none","NumberTitle","off",'CreateFcn',{@createFigure, blanks(0), figInfo, imData},'DeleteFcn', @figureCloseFcn);
        set(hFig, 'WindowKeyPressFcn',@figurePresskeyFcn);
        windows = [windows, hFig];
    end
    
end %openFiugreFcn

function activeFig = getActiveFigure()
    activeFig = [];
    figHandles = findobj('Type', 'figure');
    for i = 1:length(figHandles)
        if ~isempty(windows) && ismember(figHandles(i), windows)
            activeFig = figHandles(i);
            break
        end
    end
end

function menuSaveCallBackFcn(hObject,eventdata, handles)
    
    activeWin = getActiveFigure();
    hAxes = activeWin.CurrentAxes;
    data = get(hAxes.Children, "CData");
    figInfo = getappdata(activeWin, 'figInfo');
    uisave('data', figInfo.windowName);
end

function menuDuplicateCallBackFcn(hObject,eventdata, handles)
    activeWin = getActiveFigure();
    hNew = copyobj(activeWin,0,'legacy');
    
%     figData = getappdata(activeWin, 'figData');
%     currentFrm = getappdata(activeWin, 'currentFrm');
    figInfo = getappdata(hNew, 'figInfo');
    oldName = split(figInfo.windowName, ".");
    if length(oldName) == 1
        figInfo.windowName = strcat(oldName{1},'-copy');
    else
        figInfo.windowName = strcat(oldName{1:end-1},'-copy.',oldName{end});
    end
    
    setappdata(hNew,'figInfo',figInfo);

%     setappdata(hNew,'figData',figData);
%     setappdata(hNew,'currentFrm', currentFrm);
    set(hNew, "name", figInfo.windowName);
    windows = [windows, hNew];
    activeWin = hNew;
end

function sliderMinCallBackFcn(hObject, eventdata, handles)
    activeWin = getActiveFigure();
    hAxes = activeWin.CurrentAxes;
    hTemp = hObject.Parent;
    handles=guidata(hObject);
    lastActiveWin = handles.activeWin;
    if(lastActiveWin~=activeWin)
        contrastPanelUpdate(hTemp);
        handles.activeWin=activeWin;
        guidata(hObject,handles);
    end
    
    
    hSliderMax = findobj(hTemp, 'tag', 'sliderMax');
    
    minSliderValue = get(hObject, 'value');
    maxSliderValue = get(hSliderMax, 'value');
    
    if minSliderValue>maxSliderValue
        set(hSliderMax, 'value', minSliderValue+(maxSliderValue-minSliderValue)*0.01);
    end
    set(hAxes, 'CLimMode','manual')
    set(hAxes, 'CLim', [minSliderValue, maxSliderValue])
    
    hAxes = findobj(hTemp,'Type','Axes');   
    set(hAxes, 'XTick', [minSliderValue, maxSliderValue]);
    set(hAxes, 'XTickLabel', string([minSliderValue, maxSliderValue]));
    
end

function sliderMaxCallBackFcn(hObject, eventdata, handles)
    activeWin = getActiveFigure();
    hAxes = activeWin.CurrentAxes;
    hTemp = hObject.Parent;
    handles=guidata(hObject);
    lastActiveWin = handles.activeWin;
    if(lastActiveWin~=activeWin)
        contrastPanelUpdate(hTemp);
        handles.activeWin=activeWin;
        guidata(hObject,handles);
    end
    
    
    hSliderMin = findobj(hTemp, 'tag', 'sliderMin');
    maxSliderValue = get(hObject, 'value');
    minSliderValue = get(hSliderMin, 'value');
    
    if minSliderValue>maxSliderValue
        set(hSliderMin, 'value', maxSliderValue-(maxSliderValue-minSliderValue)*0.01);
    end
    set(hAxes, 'CLimMode','manual')
    set(hAxes, 'CLim', [minSliderValue, maxSliderValue])
    
    hAxes = findobj(hTemp,'Type','Axes');   
    set(hAxes, 'XTick', [minSliderValue, maxSliderValue]);
    set(hAxes, 'XTickLabel', string([minSliderValue, maxSliderValue]));
    
end

function contrastPanelCreateFcn(hObject, eventdata, handles)

    boundary =15;
    gap = 5;
    sliderHeight = 15;
    textBoxHeight =15;
    histHeight = 6*sliderHeight;
    histWidth = 1.8*histHeight;
    buttonHeight = 20;
    windowWidth = boundary*2+histWidth;
    windowHeight = 2*boundary+3*textBoxHeight+2*sliderHeight+histHeight+gap*3+buttonHeight;
    
    nonFigureList.contrastPanel=hObject;
    contrastPanelPostion = getappdata(hMain, 'contrastPanelLocation');
    if isempty(contrastPanelPostion)
        set(hObject, 'Position', [600 300 windowWidth windowHeight],'NumberTitle','off');
    else
        set(hObject, 'Position', contrastPanelPostion,'NumberTitle','off');
    end
        posHist = [boundary, boundary+textBoxHeight*2+sliderHeight*3+gap*3+buttonHeight, histWidth, histHeight]; 
    
    if isempty(hObject.Children)
        btnAuto = uicontrol(hObject, 'Style', 'pushButton','String', 'Auto', 'Position', [boundary, boundary histWidth/2, buttonHeight], 'tag', 'btnAuto');
        btnReset = uicontrol(hObject, 'Style', 'pushButton','String', 'Reset', 'Position', [boundary+histWidth/2, boundary,histWidth/2, buttonHeight], 'tag', 'btnReset');

        uicontrol("style", "text", "position", [boundary, boundary+gap+buttonHeight, histWidth, textBoxHeight], "HorizontalAlignment", "center", 'String', 'Maximum');
        hSliderMax = uicontrol("style", "slider", "SliderStep",[0.05, 0.05], 'tag', 'sliderMax');
        set(hSliderMax, "position", [boundary, boundary+textBoxHeight+gap+buttonHeight, histWidth, sliderHeight]);


        uicontrol("style", "text", "position", [boundary, boundary+textBoxHeight+sliderHeight+gap*2+buttonHeight, histWidth, textBoxHeight], "HorizontalAlignment", "center", 'String', 'Minimum');
        hSliderMin = uicontrol("style", "slider", "SliderStep",[0.05, 0.05], 'tag', 'sliderMin');
        set(hSliderMin, "position", [boundary, boundary+textBoxHeight*2+sliderHeight+gap*2+buttonHeight, histWidth, sliderHeight]);

        hAxes = axes(hObject,"units", "pixels", "Position", posHist, "visible", "off");
    
    end
    
    activeWin = getActiveFigure();
    handles.activeWin=activeWin;

    if ishandle(activeWin)
        hAxes = activeWin.CurrentAxes;
        cLim=get(hAxes, 'CLim');
        cData = get(findobj(hAxes, 'Type', 'Image'), 'CData');
        allMin = min(cData, [], 'all');
        allMax = max(cData, [], 'all');

        if (allMin>cLim(1))
            allMin = cLim(1);
        end
        if (allMax<cLim(2))
            allMax=cLim(2);
        end
        set(hSliderMax , "value", cLim(2), "Min",allMin, "Max",allMax);
        set(hSliderMax, 'Callback', @sliderMaxCallBackFcn);
        set(hSliderMin , "value", cLim(1), "Min",allMin, "Max",allMax);
        set(hSliderMin, 'Callback', @sliderMinCallBackFcn);
        
        imhist(cData) %this will split the old axes into two, one is for colorbar
        axis tight
        hAxes = findobj(hObject,'Type','Axes');
        set(hAxes(2),'Position',posHist)
        set(hAxes(2), 'XLim', [allMin, allMax]);
        set(hAxes(2), 'XTick', cLim);
        set(hAxes(2), 'XTickLabel', string(cLim));
        set(hAxes(2), 'YTick', []);
        set(hAxes(2).Children,'Color', [0.25 0.25 0.25]);
        delete(hAxes(1));
    else
        set(hSliderMax , "value", 0.5, "Min",0, "Max",1);
        set(hSliderMax, 'Callback', []);
        set(hSliderMin , "value", 0.5, "Min",0, "Max",1);
        set(hSliderMin, 'Callback', []);
    end

    set(hObject, "visible", "on");
    guidata(hObject, handles);
end

function contrastPanelUpdate(hObject, eventdata, handles)
    
    hSliderMax = findobj(hObject, 'tag', 'sliderMax');
    hSliderMin = findobj(hObject, 'tag', 'sliderMin');
    activeWin = getActiveFigure();
    if ishandle(activeWin)
        
        hFigAxes = activeWin.CurrentAxes;
    
        cLim=get(hFigAxes, 'CLim');
        cData = get(findobj(hFigAxes, 'Type', 'Image'), 'CData');
        allMin = min(cData, [], 'all');
        allMax = max(cData, [], 'all');

        if (allMin>cLim(1))
            allMin = cLim(1);
        end
        if (allMax<cLim(2))
            allMax=cLim(2);
        end
        set(hSliderMax, "value", cLim(2), "Min",allMin, "Max",allMax);
        set(hSliderMin, "value", cLim(1), "Min",allMin, "Max",allMax);
        
        histAxes = findobj(hObject,'Type','Axes');
        posHist = histAxes.Position;
        imhist(cData) %this will split the old axes into two, one is for colorbar
        axis tight

        hAxes = findobj(hObject,'Type','Axes');
        set(hAxes(2),'Position',posHist);
        set(hAxes(2), 'XLim', [allMin, allMax]);
        set(hAxes(2), 'XTick', cLim);
        set(hAxes(2), 'XTickLabel', string(cLim));
        set(hAxes(2), 'YTick', []);
        set(hAxes(2).Children,'Color', [0.25 0.25 0.25]);
        delete(hAxes(1));

        minSliderValue = get(findobj(hObject, 'tag', 'sliderMin'), 'value');
        maxSliderValue = get(findobj(hObject, 'tag', 'sliderMax'), 'value');

        set(hFigAxes, 'CLim', [minSliderValue, maxSliderValue])
    else
        set(hSliderMax , "value", 0.5, "Min",0, "Max",1);
        set(hSliderMax, 'Callback', []);
        set(hSliderMin , "value", 0.5, "Min",0, "Max",1);
        set(hSliderMin, 'Callback', []);
        hAxes = findobj(hObject,'Type','Axes');
        set(hAxes, 'xTick', []);
        delete(hAxes.Children);
    end

    

    


end

function nonWindowPanelCloseFcn(hObject,eventdata, handles, panelType)
   
   nonFigureList=setfield(nonFigureList, panelType, []);
   setappdata(hMain, 'contrastPanelLocation', hObject.Position);
   delete(hObject);
    
end

function menuContrastCallBackFcn(hObject, eventdata, handles)
    
    if isempty(nonFigureList.contrastPanel)
        hTemp = figure('menubar', 'none', 'name', 'B&C', 'Dockcontrols', 'off','Resize','off', 'CreateFcn', @contrastPanelCreateFcn);
        set(hTemp, 'WindowButtonDownFcn', @contrastPanelUpdate);
        set(hTemp, 'DeleteFcn', {@nonWindowPanelCloseFcn, blanks(0),'contrastPanel'});
        setappdata(hMain, 'contrastPanelLocation', hTemp.Position);
    else
        hTemp=nonFigureList.contrastPanel;
        figure(hTemp);
    end
    
    
end

    
function menuAboutCallBackFcn(hObject, eventdata, handles)
    figure("menubar", "none","NumberTitle","off", "Position", [200, 300, 160, 100]);
    uicontrol("style", "text", "position", [10, 10, 100, 50], "HorizontalAlignment", "left",...
    "string", "ImageM mimics the software ImageJ. Created by An Gong, 2021-01-17.")
end

end

    