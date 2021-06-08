classdef FigureWindow < handle
    
    properties

    end
    
    methods %normal method         
        
    end %end of normal method
     
    
    methods(Static) %static method
        function figureCreateFcn(hObject,~, handles, figInfo, imData)
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
        end  %end of creatFigure function
        
        function figureCloseFcn(hObject,eventdata, handles)
    
           windows(windows==hObject)=[];
           delete(hObject);

        end %end of closeFigureFcn
    end %end of static method
    
end % end of class


