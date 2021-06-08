function ImageM()

%ImageM mimics the software ImageJ. Created by An Gong, 2021-01-17.
%Last update: 2021-06-02


global windows activeWin nonFigureList;
windows = [];
activeWin = [];
nonFigureList.contrastPanel = [];

%% define the user interface
hMain = figure('menubar', 'none', 'Visible', 'off', 'Position', [600 800 350 20],'NumberTitle','off','name', 'ImageM', 'Dockcontrols', 'off','Resize','off');
hMenuFile = uimenu(hMain, 'label', '&File');
uimenu(hMenuFile, 'label', 'Open', 'Accelerator', 'O','Callback',{@openFiugreFcn, blanks(0),'file',0});
uimenu(hMenuFile, 'label', 'OpenAsVirtualStack', 'Callback',{@openFiugreFcn, blanks(0),'file',1});
uimenu(hMenuFile, 'label', 'ImportAsStack', 'Accelerator', 'I','Callback',{@openFiugreFcn, blanks(0), 'folder',0});
uimenu(hMenuFile, 'label', 'ImportFromVarible', 'Accelerator', 'V','Callback',{@openFiugreFcn, blanks(0), 'varible',0});
uimenu(hMenuFile, 'label', 'Save', 'Accelerator', 'S','Callback',@menuSaveCallBackFcn);

hMenuImage = uimenu(hMain, 'label', '&Image');
uimenu(hMenuImage, 'label', 'Contrast Shift+C', 'Callback',@menuContrastCallBackFcn);
uimenu(hMenuImage, 'label', 'Duplicate Shift+D', 'Callback', @menuDuplicateCallBackFcn);

hMenuProcess = uimenu(hMain, 'label', '&Process');
hMenuAnalyze = uimenu(hMain, 'label', '&Analyze');
hMenuWindows = uimenu(hMain, 'label', '&Window');

hMenuHelp = uimenu(hMain, 'label', '&Help');
hAbout = uimenu(hMenuHelp, 'label', 'About ImageM','Callback',@menuAboutCallBackFcn);

set(hMain, 'Visible', 'on');

%%
function sliderCallBackFcn(hObject, eventdata, handles, sliderNum)
    figInfo =  getappdata(hObject.Parent, 'figInfo');
    winInfo = getappdata(hObject.Parent, 'winInfo');
    imData = getappdata(hObject.Parent, 'imData');
    hAxes = findobj(hObject.Parent, 'Type', 'Axes');
    
    currentFrm = winInfo.currentFrm;
    dimensionOrder = winInfo.dimensionOrder;
    dim = length(currentFrm);
    fileFolder = winInfo.fileFolder;
    fileNames = winInfo.fileNames;
    imageType = winInfo.imageType;    
    currentFrm(sliderNum) = int16(get(hObject, 'value'));
    
    winInfo.currentFrm = currentFrm;
    setappdata(hObject.Parent, 'winInfo',winInfo);
    if winInfo.isVirtualStack
        if class(figInfo) ~= "BioformatsImage"
            imData = imread(fullfile(fileFolder,fileNames{currentFrm}));
            setappdata(hObject.Parent, 'imData',imData);
            imDisp = imData;
        else
            if imageType == "RGB"
                planeNum = nan(1,3);
                fullOrder = 'ZTL';
                counter = 1;
                for i = 1:length(planeNum)
                    if contains(winInfo.dimensionOrder, fullOrder(i))
                        planeNum(i)=currentFrm(counter);
                        counter = counter+1;
                    else
                        planeNum(i)=1;
                    end
                end
                imDisp(:,:,1) = figInfo.getPlane([planeNum(1), 1, planeNum(2:end)]);
                imDisp(:,:,2) = figInfo.getPlane([planeNum(1), 2, planeNum(2:end)]);
                imDisp(:,:,3) = figInfo.getPlane([planeNum(1), 3, planeNum(2:end)]);
            else
                planeNum = nan(1,4);
                fullOrder = 'CZTL';
                counter = 1;
                for i = 1:length(planeNum)
                    if contains(winInfo.dimensionOrder, fullOrder(i))
                        planeNum(i)=currentFrm(counter);
                        counter = counter+1;
                    else
                        planeNum(i)=1;
                    end
                end
                if contains(figInfo.filename, "nd2")
                    imDisp = figInfo.getXYplane(planeNum(1), planeNum(4), planeNum(3)); %need to be the squence of "CLT"
                else
                    imDisp = figInfo.getPlane([planeNum(2), planeNum(1), planeNum(3), planeNum(4)]);  %need to be the squence of "ZCTL"
                end
                
            end
        end
        
    else
        imDisp =  getXYPlane(imData, currentFrm, imageType);
    end
    
    set(hAxes.Children, "CData", imDisp);

    if imageType == "RGB"
        switch dim
            case 1                             
                if winInfo.isVirtualStack
                    maxFrm = max(figInfo.sizeZ,figInfo.sizeT);
                else
                    maxFrm = size(imData, 4);
                end                
                text = strcat(num2str(currentFrm), "/",num2str(maxFrm),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
        end
                
    else  % for grayscale images         
        switch dim
            case 1                
                maxFrm = size(imData, 3);
                text = strcat(num2str(currentFrm), "/",num2str(maxFrm),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                
             case 2                
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                text = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
            case 3
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                maxFrm3 = size(imData, 5);
                
                maxFrm = nan(1,4);
                if winInfo.isVirtualStack
                    maxFrm(1)=figInfo.sizeC;
                    maxFrm(2)=figInfo.sizeZ;
                    maxFrm(3)=figInfo.sizeT;
                    maxFrm(4)=figInfo.seriesCount;
                    maxFrm(maxFrm==1)=[];
                    maxFrm1 = maxFrm(1);
                    maxFrm2 = maxFrm(2);
                    maxFrm3 = maxFrm(3);
                end
                
                text = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",dimensionOrder(5), num2str(currentFrm(3)), "/",num2str(maxFrm3),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
            case 4
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                maxFrm3 = size(imData, 5);
                maxFrm4 = size(imData, 6);
                
                text = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),...
                    ", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",dimensionOrder(5), num2str(currentFrm(3)), "/",num2str(maxFrm3),", ",...
                    ", ",dimensionOrder(6), num2str(currentFrm(4)), "/",num2str(maxFrm4),", ",...
                    num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);                
        end
    end
            
    hText = handles.hText;
    set(hText, "string", text);
    
end

function disp = getXYPlane(imData, currentFrm, imageType)
    dim = length(currentFrm);
    if imageType == "RGB"
        switch dim
            case 1
                disp = imData(:,:,:, currentFrm);
            case 2
                disp = imData(:,:,:, currentFrm(1), currentFrm(2));
            case 3
                disp = imData(:,:,:, currentFrm(1), currentFrm(2), currentFrm(3));
        end
    else
        switch dim
            case 1
                disp = imData(:,:,currentFrm);
            case 2
                disp = imData(:,:,currentFrm(1), currentFrm(2));
            case 3
                disp = imData(:,:,currentFrm(1), currentFrm(2), currentFrm(3));
            case 4
                disp = imData(:,:,currentFrm(1), currentFrm(2), currentFrm(3), currentFrm(4));
        end
    end
end

function figureCreateFcn(hObject,eventdata, handles, figInfo, winInfo, imData)
    textBoxHeight = 15;
    sliderHeight = 20;
    gap = 5;
    ratio = 1;
    
    currentFrm = winInfo.currentFrm;
    width = figInfo.width;
    height = figInfo.height;
    dimensionOrder = winInfo.dimensionOrder;
    dim = length(dimensionOrder);
    
    if width<200
        ratio = round(200/width);
    elseif width>800
        ratio = 1/round(width/600);
    end
    windowName = winInfo.windowName;
    if ratio ~=1
        windowName = [windowName, '(',num2str(int8(100*ratio)),'%)'];
    end
    
    figDisp = nan(figInfo.width,figInfo.height);
    if winInfo.isVirtualStack
        %figDisp = imread(fullfile(figInfo.fileFolder,figInfo.fileNames{1}));
        figDisp = imData;
    else
        %figDisp = imData(:,:,currentFrame);
        figDisp = getXYPlane(imData, currentFrm, winInfo.imageType);
    end
    
%% here is the layout of the figure windown

    textInit = strcat(num2str(figInfo.width),"*",num2str(figInfo.height), ",", winInfo.imageType);
    hText = uicontrol("style", "text", "HorizontalAlignment", "left");
    hAxes = axes("units", "pixels",  "visible", "off", "parent", hObject);
    hImg = imshow(figDisp,[], "parent", hAxes);
    handles.hImg = hImg;
    handles.hText = hText;
    guidata(hObject, handles);
    
    if winInfo.imageType == "RGB"
        switch dim
            case 3
                set(hObject,"position",[200, 200, width*ratio+2*gap, height*ratio+4*gap+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+3*gap+textBoxHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, figInfo.height*ratio]);
            case 4
                set(hObject,"position",[200, 200, width*ratio+2*gap, height*ratio+5*gap+sliderHeight+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+4*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 3*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, figInfo.height*ratio]);
                               
                if winInfo.isVirtualStack
                    maxFrm = max(figInfo.sizeZ,figInfo.sizeT);
                else
                    maxFrm = size(imData, 4);
                end
                
                textInit = strcat(num2str(currentFrm), "/",num2str(maxFrm),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                hSlider = uicontrol("style", "slider", "value", currentFrm,"Min",1, "Max",maxFrm, "SliderStep",[1/(maxFrm-1), 1/(maxFrm-1)]);
                set(hSlider, "position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider,"Callback", {@sliderCallBackFcn,handles, 1});               %%The first slider
        end
                
    else  % for grayscale images
                
        switch dim
            case 2
                set(hObject,"position",[100, 100, width*ratio+2*gap, height*ratio+4*gap+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+3*gap+textBoxHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, figInfo.height*ratio]);
            case 3
                set(hObject,"position",[100, 100, width*ratio+2*gap, height*ratio+5*gap+sliderHeight+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+4*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 3*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, figInfo.height*ratio]);
                
                maxFrm = size(imData, 3);
                textInit = strcat(num2str(currentFrm), "/",num2str(maxFrm),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                hSlider = uicontrol("style", "slider", "value", currentFrm,"Min",1, "Max",maxFrm, "SliderStep",[1/(maxFrm-1), 1/(maxFrm-1)]);
                set(hSlider, "position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider,"Callback", {@sliderCallBackFcn,handles, 1});               %%first slider
                
             case 4
                set(hObject,"position",[100, 100, width*ratio+2*gap, height*ratio+6*gap+sliderHeight*2+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+5*gap+textBoxHeight+2*sliderHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 4*gap+textBoxHeight+2*sliderHeight, figInfo.width*ratio, figInfo.height*ratio]);
                
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                textInit = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                hSlider = uicontrol("style", "slider", "value", currentFrm(1),"Min",1, "Max",maxFrm1, "SliderStep",[1/(maxFrm1-1), 1/(maxFrm1-1)]);
                set(hSlider, "position", [gap, 3*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider,"Callback", {@sliderCallBackFcn,handles, 1});               %%first slider 
                
                hSlider2 = uicontrol("style", "slider", "value", currentFrm(2),"Min",1, "Max",maxFrm2, "SliderStep",[1/(maxFrm2-1), 1/(maxFrm2-1)]);
                set(hSlider2, "position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider2,"Callback", {@sliderCallBackFcn,handles, 2});               %%second slider
             
            case 5
                set(hObject,"position",[100, 100, width*ratio+2*gap, height*ratio+7*gap+sliderHeight*3+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+6*gap+textBoxHeight+3*sliderHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 5*gap+textBoxHeight+3*sliderHeight, figInfo.width*ratio, figInfo.height*ratio]);
                
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                maxFrm3 = size(imData, 5);
                
                maxFrm = nan(1,4);
                if winInfo.isVirtualStack
                    maxFrm(1)=figInfo.sizeC;
                    maxFrm(2)=figInfo.sizeZ;
                    maxFrm(3)=figInfo.sizeT;
                    maxFrm(4)=figInfo.seriesCount;
                    maxFrm(maxFrm==1)=[];
                    maxFrm1 = maxFrm(1);
                    maxFrm2 = maxFrm(2);
                    maxFrm3 = maxFrm(3);
                end
                  
                textInit = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",dimensionOrder(5), num2str(currentFrm(3)), "/",num2str(maxFrm3),", ",num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                
                hSlider = uicontrol("style", "slider", "value", currentFrm(1),"Min",1, "Max",maxFrm1, "SliderStep",[1/(maxFrm1-1), 1/(maxFrm1-1)]);
                set(hSlider, "position", [gap, 4*gap+textBoxHeight+sliderHeight*2, figInfo.width*ratio, sliderHeight]);
                set(hSlider,"Callback", {@sliderCallBackFcn,handles, 1});               %%first slider 
                
                hSlider2 = uicontrol("style", "slider", "value", currentFrm(2),"Min",1, "Max",maxFrm2, "SliderStep",[1/(maxFrm2-1), 1/(maxFrm2-1)]);
                set(hSlider2, "position", [gap, 3*gap+textBoxHeight+sliderHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider2,"Callback", {@sliderCallBackFcn,handles, 2});               %%second slider                

                hSlider3 = uicontrol("style", "slider", "value", currentFrm(3),"Min",1, "Max",maxFrm3, "SliderStep",[1/(maxFrm3-1), 1/(maxFrm3-1)]);
                set(hSlider3, "position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider3,"Callback", {@sliderCallBackFcn,handles, 3});               %%third slider         
                
            case 6
                set(hObject,"position",[100, 100, width*ratio+2*gap, height*ratio+8*gap+sliderHeight*4+2*textBoxHeight], "name", windowName);
                set(hText, "position", [gap, figInfo.height*ratio+7*gap+textBoxHeight+4*sliderHeight, figInfo.width*ratio, textBoxHeight]);
                set(hAxes, "Position", [gap, 6*gap+textBoxHeight+4*sliderHeight, figInfo.width*ratio, figInfo.height*ratio]);
                
                maxFrm1 = size(imData, 3);
                maxFrm2 = size(imData, 4);
                maxFrm3 = size(imData, 5);
                maxFrm4 = size(imData, 6);
                
                textInit = strcat(dimensionOrder(3), num2str(currentFrm(1)), "/",num2str(maxFrm1),...
                    ", ",dimensionOrder(4), num2str(currentFrm(2)), "/",num2str(maxFrm2),...
                    ", ",dimensionOrder(5), num2str(currentFrm(3)), "/",num2str(maxFrm3),", ",...
                    ", ",dimensionOrder(6), num2str(currentFrm(4)), "/",num2str(maxFrm4),", ",...
                    num2str(figInfo.width),"*",num2str(figInfo.height), ", ", winInfo.imageType);
                
                hSlider = uicontrol("style", "slider", "value", currentFrm(1),"Min",1, "Max",maxFrm1, "SliderStep",[1/(maxFrm1-1), 1/(maxFrm1-1)]);
                set(hSlider, "position", [gap, 5*gap+textBoxHeight+sliderHeight*3, figInfo.width*ratio, sliderHeight]);
                set(hSlider,"Callback", {@sliderCallBackFcn,handles, 1});               %%first slider 
                
                hSlider2 = uicontrol("style", "slider", "value", currentFrm(2),"Min",1, "Max",maxFrm2, "SliderStep",[1/(maxFrm2-1), 1/(maxFrm2-1)]);
                set(hSlider2, "position", [gap, 4*gap+textBoxHeight+sliderHeight*2, figInfo.width*ratio, sliderHeight]);
                set(hSlider2,"Callback", {@sliderCallBackFcn,handles, 2});               %%second slider                

                hSlider3 = uicontrol("style", "slider", "value", currentFrm(3),"Min",1, "Max",maxFrm3, "SliderStep",[1/(maxFrm3-1), 1/(maxFrm3-1)]);
                set(hSlider3, "position", [gap, 3*gap++sliderHeight+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider3,"Callback", {@sliderCallBackFcn,handles, 3});               %%third slider   
                
                hSlider4 = uicontrol("style", "slider", "value", currentFrm(4),"Min",1, "Max",maxFrm4, "SliderStep",[1/(maxFrm4-1), 1/(maxFrm4-1)]);
                set(hSlider4, "position", [gap, 2*gap+textBoxHeight, figInfo.width*ratio, sliderHeight]);
                set(hSlider4,"Callback", {@sliderCallBackFcn,handles, 4});               %%forth slider                     
        end
   end

    set(hText, "string", textInit);
    set(hObject, "visible", "on");
    impixelinfo;
    
    setappdata(hObject,'figInfo',figInfo);
    setappdata(hObject,'winInfo',winInfo);
    setappdata(hObject,'imData',imData);
 
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
        case 'C'
            menuContrastCallBackFcn();
     end
end


function buttonCallbackFcn(hObject,eventdata, handles)
    winInfo.isVirtualStack = 0;
    winInfo.fileNames = [];
    winInfo.fileFolder = [];
    winInfo.windowName = [];
    winInfo.imageType = [];
    imData = [];
    
    hTemp = hObject.Parent;
    pop = findobj(hTemp, "Style","popupmenu");
    if length(string(pop.String))>1  %detect the situation of only one varible, need covert the name into a string first
        valName = pop.String{pop.Value};
    else
        valName = pop.String;
    end
    imData = evalin('base',valName);
    winInfo.windowName = valName;
    figInfo.width = size(imData,1);
    figInfo.height = size(imData,2);
    figInfo.series =1;
    figInfo.sizeT = 1;
    figInfo.sizeZ = 1;
    figInfo.sizeC = 1;
    figInfo.seriesCount =1;
    
    %need mark the order
    winInfo.currentFrm = 1;
    if length(size(imData))==3
        figInfo.sizeT = size(imData,3);
        winInfo.dimensionOrder = 'XYT';
        figInfo.sizeT = size(imData,3);
    end
    %need mark the order
    winInfo.imageType=class(imData);
    setappdata(hTemp, 'figInfo', figInfo);
    setappdata(hTemp, 'imData', imData);
    setappdata(hTemp, 'winInfo', winInfo);

    uiresume(hTemp);
end

function [out1, out2, out3] = getVaribleGUI()
        out1 = [];
        out2 = [];
        out3 = [];
        hTemp = figure('menubar', 'none', 'Position', [500 600 300 100],'NumberTitle','off','name', 'Choose a varible', 'Dockcontrols', 'off','Resize','off');
        set(hTemp, 'windowStyle','modal');
        pop = uicontrol(hTemp,'Style','popupmenu','Position', [70 50 60 20]);
        txt = uicontrol(hTemp, 'Style', 'text','String', 'Varibles', 'Position', [20 50 40 20] );
        button = uicontrol(hTemp, 'Style', 'pushButton','String', 'Ok', 'Position', [170 50 60 20]);
        set(button, 'Callback', @buttonCallbackFcn); %return the figInfo and imData to window hTemp
        vals = evalin('base', 'whos'); % get varible information in base workspace
        [valNames]={vals.name};
        valNames=string(valNames);
        pop.String = valNames;
        uiwait(hTemp);
        if ishandle(hTemp)
            out1 = getappdata(hTemp,'figInfo');
            out2 = getappdata(hTemp,'winInfo');
            out3 = getappdata(hTemp,'imData');
            delete(hTemp);
        end
end

function openFiugreFcn(hObject,eventdata, handles, type, isVirtualStack)

    winInfo.isVirtualStack = isVirtualStack;
    winInfo.fileNames = [];
    winInfo.fileFolder = [];
    winInfo.windowName = [];
    winInfo.imageType = [];
    imData = [];
    figInfo = [];
    switch type
        case 'file'
             [fileName, fileFolder, index] = uigetfile({"*.tif; *.tiff; *.bmp; *.jpg; *.png; *.czi; *nd2"; "*.*"}, "File Selector");

             if index
                winInfo.fileFolder = fileFolder;
                winInfo.windowName = fileName;
                winInfo.fileNames = cellstr(fileName);
                %imData = imread(fullfile(fileFolder, fileName));
                
                
                fid = fopen(fullfile(fileFolder, fileName));
                fseek(fid,0,'eof');
                fSize = ftell(fid);
                if fSize>1e10 && (~isVirtualStack) %if the file is too big and not open as virtual stack
                    hTemp = figure('menubar', 'none', 'Position', [500 600 300 100],'NumberTitle','off','name', 'Warning', 'Dockcontrols', 'off','Resize','off');
                    set(hTemp, 'windowStyle','modal');
                    uicontrol(hTemp, 'Style', 'text','String', 'The file is too big, do you want to load it as virtual stack?', 'Position', [50 50 200 40]);
                    button1 = uicontrol(hTemp, 'Style', 'pushButton','String', 'Yes', 'Position', [50 20 60 20]);
                    set(button1, 'Callback', 'hTemp = get(gcbo, "Parent"); setappdata(hTemp, "isVirtualStack", 1); uiresume(hTemp);'); %return the figInfo and imData to window hTemp
                    button2 = uicontrol(hTemp, 'Style', 'pushButton','String', 'No', 'Position', [190 20 60 20]);
                    set(button2, 'Callback', 'hTemp = get(gcbo, "Parent"); setappdata(hTemp, "isVirtualStack", 0); uiresume(hTemp);'); %return the figInfo and imData to window hTemp
                    uiwait(hTemp);
                    if ishandle(hTemp)
                        winInfo.isVirtualStack=getappdata(hTemp, 'isVirtualStack');
                        delete(hTemp);
                    end
                end
                
                
                [figInfo, imData, dimensionOrder] = bioFormatsParser(fullfile(fileFolder, fileName), winInfo.isVirtualStack);                
                winInfo.dimensionOrder = dimensionOrder;
                winInfo.imageType = class(imData);
                freedom = length(dimensionOrder)-2;
                
                if ~(contains(fileName, 'nd2')||contains(fileName, 'czi'))
                    temp = imfinfo(fullfile(fileFolder, fileName));
                    if temp(1).ColorType == "truecolor"
                        winInfo.imageType = 'RGB';
                        imData = uint8(imData);
                        freedom = length(dimensionOrder)-3;
                    end                    
                end
                
                if freedom == 0
                    freedom = 1;
                end
                winInfo.currentFrm = ones(1, freedom);
             end
        case  'folder'
              fileFolder = uigetdir();
              if fileFolder ~= 0
                winInfo.fileFolder = fileFolder;
                filesInfo = dir(fullfile(fileFolder,"*.tif"));
                winInfo.fileNames = {filesInfo.name};
                imData = imread(fullfile(fileFolder,winInfo.fileNames{1}));
                winInfo.imageType = class(imData);
                width = size(imData,2); %get width
                height = size(imData,1); %get height
                figInfo.width = width;
                figInfo.height = height;
                figInfo.sizeT = length(filesInfo);
                winInfo.dimensionOrder = 'XYT';
                fileFolderNameSplit = split(fileFolder, "\");
                winInfo.windowName = fileFolderNameSplit{end};
              end
        case  'varible'
              [figInfo, winInfo, imData] = getVaribleGUI;                   
        otherwise
            warning('unproper parameter for opening figures!');
    end

    if ~isempty(imData)
        hFig = figure("menubar", "none","NumberTitle","off",'CreateFcn',{@figureCreateFcn, blanks(0), figInfo, winInfo, imData},'DeleteFcn', @figureCloseFcn);
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
    winInfo = getappdata(activeWin, 'winInfo');
    uisave(data, winInfo.windowName);
end

function menuDuplicateCallBackFcn(hObject,eventdata, handles)
    activeWin = getActiveFigure();
    hNew = copyobj(activeWin,0,'legacy');
    
%     figData = getappdata(activeWin, 'figData');
%     currentFrm = getappdata(activeWin, 'currentFrm');
    winInfo = getappdata(hNew, 'winInfo');
    oldName = split(winInfo.windowName, ".");
    if length(oldName) == 1
        winInfo.windowName = strcat(oldName{1},'-copy');
    else
        winInfo.windowName = strcat(oldName{1:end-1},'-copy.',oldName{end});
    end
    
    setappdata(hNew,'winInfo',winInfo);

%     setappdata(hNew,'figData',figData);
%     setappdata(hNew,'currentFrm', currentFrm);
    set(hNew, "name", winInfo.windowName);
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

    