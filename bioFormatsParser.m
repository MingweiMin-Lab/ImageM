function [bfReader, imData, dimentionOrder] = bioFormatsParser(filePath, isVirtualStack, varargin)
%varargin is the input of selcted range of images to display:
%[CMin, CMax; ZMin, ZMax; TMin, TMax; SMin, SMax]
    bfReader = BioformatsImage(filePath); 
    dimentionOrder = 'XY';
    W = bfReader.width;
    H = bfReader.height;
    sizeInfo = [W, H];
        
    C = bfReader.sizeC;
    CRange = [1, C];
    Z = bfReader.sizeZ;
    ZRange = [1, Z];
    T = bfReader.sizeT;
    TRange = [1, T];
    L = bfReader.seriesCount; % location
    LRange = [1, L];

    if nargin == 3
        range = varargin{1};
        CRange = range(1,:);
        ZRange = range(2,:);
        TRange = range(3,:);
        LRange = range(4,:);
    end
    
    
    if (CRange(2)-CRange(1))>0
        sizeInfo = [sizeInfo, C];
        dimentionOrder = [dimentionOrder, 'C'];
    end
    if (ZRange(2)-ZRange(1))>0
        sizeInfo = [sizeInfo, Z];
        dimentionOrder = [dimentionOrder, 'Z'];
    end
    if (TRange(2)-TRange(1))>0
        sizeInfo = [sizeInfo, T];
        dimentionOrder = [dimentionOrder, 'T'];
    end
    if (LRange(2)-LRange(1))>0
        sizeInfo = [sizeInfo, L];
        dimentionOrder = [dimentionOrder, 'L'];
    end    
    
    %imgOut = bfReader.getPlane(iZ, iC, iT, iS, ROI);
    if isVirtualStack
        imData = single(bfReader.getPlane([1, 1, 1, 1]));
    else
        imData = single(nan(H, W, CRange(2)-CRange(1)+1, ZRange(2)-ZRange(1)+1, TRange(2)-TRange(1)+1, LRange(2)-LRange(1)+1));
        for c = CRange(1):CRange(2)
            for z = ZRange(1):ZRange(2)
               for t = TRange(1):TRange(2)
                    for s = LRange(1):LRange(2)
                        imData(:,:,c-CRange(1)+1,z-ZRange(1)+1,t-TRange(1)+1,s-TRange(1)+1) = bfReader.getPlane([z, c, t, s]);
                    end
                end
            end
        end
        imData = squeeze(imData);
    end
end

