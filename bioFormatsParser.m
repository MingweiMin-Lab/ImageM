function [bfReader, imData, dimentionOrder] = bioFormatsParser(filePath, isVirtualStack, varargin)
%varargin is the input of selcted range of images to display:
%{[CRange],[ZRange],[TRange],[SRange]}

    bfReader = BioformatsImage(filePath); 
    dimentionOrder = 'XY';
    W = bfReader.width;
    H = bfReader.height;
    sizeInfo = [W, H];
        
    C = bfReader.sizeC;
    CRange = 1:C;
    Z = bfReader.sizeZ;
    ZRange = 1:Z;
    T = bfReader.sizeT;
    TRange = 1:T;
    S = bfReader.seriesCount; % location
    SRange = 1:S;

    if nargin == 3
        range = varargin{1};
        CRange = range{1};
        ZRange = range{2};
        TRange = range{3};
        SRange = range{4};
        figInfo.width = W;
        figInfo.height = H;
        figInfo.filename = [];
        figInfo.series = 1;
        figInfo.seriesCount = length(SRange);
        figInfo.sizeZ = length(ZRange);
        figInfo.sizeC = length(CRange);
        figInfo.sizeT = length(TRange);
        figInfo.channelNames = bfReader.channelNames;
        figInfo.pxSize = bfReader.pxSize;
        figInfo.pxUnits = bfReader.pxUnits;
    end
    
    
    if length(CRange)>1
        sizeInfo = [sizeInfo, length(CRange)];
        dimentionOrder = [dimentionOrder, 'C'];
    end
    if length(ZRange)>1
        sizeInfo = [sizeInfo, length(ZRange)];
        dimentionOrder = [dimentionOrder, 'Z'];
    end
    if length(TRange)>1
        sizeInfo = [sizeInfo, length(TRange)];
        dimentionOrder = [dimentionOrder, 'T'];
    end
    if length(SRange)>1
        sizeInfo = [sizeInfo, length(SRange)];
        dimentionOrder = [dimentionOrder, 'S'];
    end    
    
    %imgOut = bfReader.getPlane(iZ, iC, iT, iS, ROI);
    if isVirtualStack
        imData = single(bfReader.getPlane([1, 1, 1, 1]));
    else
        imData = single(nan(H, W, length(CRange), length(ZRange), length(TRange), length(SRange)));
        for c = 1:length(CRange)
            for z = 1:length(ZRange)
               for t = 1:length(TRange)
                    for s = 1:length(SRange)
                        if ~contains(filePath, 'nd2')
                            imData(:,:,c,z,t,s) = bfReader.getPlane([ZRange(z), CRange(c), TRange(t), SRange(s)]);
                        else
                            imData(:,:,c,z,t,s) = bfReader.getXYplane(CRange(c), SRange(s), TRange(t));% for nd2 files, getXYplane(channel, XYloc, frame, varargin)
                        end
                    end
                end
            end
        end
        imData = squeeze(imData);
        if nargin == 3
            bfReader = figInfo;
        end
    end
end

