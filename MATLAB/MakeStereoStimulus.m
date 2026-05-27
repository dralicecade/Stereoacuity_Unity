% MakeStereoStimulus
% ishow(MakeStereoStimulus(4096,-12,2,1,0))
function [colIm]=MakeStereoStimulus(imSize,OffX,symbolType,whichSymbol,carrierType,usePregen)
if ~exist('imSize','var') || isempty(imSize)
    imSize=4096;
end
if ~exist('symbolType','var') || isempty(symbolType) || symbolType>2
    symbolType=1; %TAO
end
if ~exist('carrierType','var') || isempty(carrierType) || ~ismember(carrierType,[1 2])
    carrierType=1; %blobs
end
if ~exist('usePregen','var') || isempty(usePregen)
    usePregen=1; % use a pregen carrier
end
% if ~exist('stereoType')
%     stereoType=1; % use RG, type 2 is separate images
% end

if ~exist('OffX','var') || isempty(OffX)
    OffX = -12;
end

switch symbolType
    case 1, Names={'Butterfly_Sil_Pad.tif' 'Car_Sil_Pad.tif' 'Duck_Sil_Pad.tif' 'Flower_Sil_Pad.tif' 'Heart_Sil_Pad.tif' 'House_Sil_Pad.tif' 'Moon_Sil_Pad.tif' 'Rabbit_Sil_Pad.tif' 'Rocket_Sil_Pad.tif' 'Tree_Sil_Pad.tif'};
    case 2, Names={'Hand_RD_Pad.tif' 'House_RD_Pad.tif' 'Car_RD_Pad.tif' 'Square_RD_Pad.tif' 'Truck_RD_Pad.tif' 'Circle_RD_Pad.tif' 'Elephant_RD_Pad.tif' 'Heart_RD_Pad.tif' 'Duck_RD_Pad.tif' 'Star_RD_Pad.tif' 'Tree_RD_Pad.tif' };
end
if ~exist('whichSymbol','var') || isempty(whichSymbol)
    whichSymbol = randi(length(Names));
end



baseName=Names{whichSymbol};
im=1-imresize(double(imread(baseName))./255,[1900 1900],'nearest');
im0a=double(imresize(PadIm(im,[2000 2000],0),[imSize imSize],'nearest')>0.5);
%sum(All(im0a))./imSize^2
SizeList=[ 32 16 8].*4;%
colIm=128+zeros(imSize,imSize,3);
if carrierType==1 % blobs
    OffX=-OffX;
    if usePregen
        if imSize==4096;
        load('CarrierStuff.mat');
        elseif imSize==2048;
               load('CarrierStuffSmall.mat');

        end

   
    whichCarrier=randi(NoCarriers);
        xValStore=xValStoreAll{whichCarrier};
        yValStore=yValStoreAll{whichCarrier};
        conStore=conValStoreAll{whichCarrier};
    else
        [xValStore yValStore conStore SizeList patchIm]=MakeStereoCarrier(imSize,SizeList);
    end
    xAll=xValStore; yAll=yValStore; conList=conStore;
    imR=zeros(imSize,imSize);
    imG=zeros(imSize,imSize);
    roundOffX=round(OffX);
    frcOffX=(OffX)-roundOffX;
    ForeShftR=(circshift(im0a',-roundOffX)'); %ImShift(im0a,roundOffX,0);
    ForeShftL=(circshift(im0a',roundOffX)'); %ImShift(im0a,-roundOffX,0);
    BackShftR=1-ForeShftR;
    BackShftL=1-ForeShftL;
    for s=1:length(SizeList)
thisOff=roundOffX;
        xvals = xAll{s};
        yvals = yAll{s};

        % Classify patches using the unshifted symbol mask
        inds = xvals + (yvals-1).*imSize;
        inShape  = find(im0a(inds));
        outShape = find(~im0a(inds));

        NewCons = sign(randn(1,length(conList{s})));
        NewCons = 0.75.*NewCons + 0.25.*(1-2.*rand(1,length(NewCons)));

        patch1Pos = MakeCosineWindow(round(1.5.*SizeList(s)), ...
            SizeList(s)/2.1, SizeList(s)/10, frcOffX, 0);

        patch1Neg = MakeCosineWindow(round(1.5.*SizeList(s)), ...
            SizeList(s)/2.1, SizeList(s)/10, -frcOffX, 0);

        mult1 = 1;

        % Right/red image: foreground shifted one way, background the other
        tmpCons = NewCons(inShape);
        x1 = xvals(inShape);
        y1 = yvals(inShape) + thisOff;
        goodVals = (x1>0) & (y1>0) & (x1<=imSize) & (y1<=imSize);
        imR = DropPatchesWeird(imR,patch1Pos, ...
            x1(goodVals), y1(goodVals), 1, mult1.*tmpCons(goodVals));

        tmpCons = NewCons(outShape);
        x1 = xvals(outShape);
        y1 = yvals(outShape) - thisOff;
        goodVals = (x1>0) & (y1>0) & (x1<=imSize) & (y1<=imSize);
        imR = DropPatchesWeird(imR,patch1Neg, ...
            x1(goodVals), y1(goodVals), 1, (1/mult1).*tmpCons(goodVals));

        % Left/green image: opposite shifts
        tmpCons = NewCons(inShape);
        x1 = xvals(inShape);
        y1 = yvals(inShape) - thisOff;
        goodVals = (x1>0) & (y1>0) & (x1<=imSize) & (y1<=imSize);
        imG = DropPatchesWeird(imG,patch1Neg, ...
            x1(goodVals), y1(goodVals), 1, mult1.*tmpCons(goodVals));

        tmpCons = NewCons(outShape);
        x1 = xvals(outShape);
        y1 = yvals(outShape) + thisOff;
        goodVals = (x1>0) & (y1>0) & (x1<=imSize) & (y1<=imSize);
        imG = DropPatchesWeird(imG,patch1Pos, ...
            x1(goodVals), y1(goodVals), 1, (1/mult1).*tmpCons(goodVals));


        %
        % thisOff=roundOffX;
        %
        % xvals=xAll{s};
        % yvals=yAll{s};
        % inds=xvals+(yvals-1).*imSize;
        % inShapeR=find(ForeShftR(inds));
        % outShapeR=find(BackShftR(inds));
        % inShapeL=find(ForeShftL(inds));
        % outShapeL=find(BackShftL(inds));
        % NewCons=sign(randn(1,length(conList{s})));
        % NewCons=0.75.*NewCons+0.25.*(1-2.*rand(1,length(NewCons)));
        %
        % patch1Pos   = MakeCosineWindow(round(1.5.*SizeList(s)),SizeList(s)/2.1,SizeList(s)/10,frcOffX,0);
        % patch1Neg   = MakeCosineWindow(round(1.5.*SizeList(s)),SizeList(s)/2.1,SizeList(s)/10,-frcOffX,0);
        % mult1=1;
        % tmpCons = NewCons(inShapeR);
        % x1=xvals(inShapeR); y1=yvals(inShapeR)+thisOff; goodVals=find((x1>0)&(y1>0)&(x1<=imSize)&(y1<=imSize));
        % imR         = DropPatchesWeird(imR,patch1Pos,x1(goodVals),y1(goodVals),1,mult1.*tmpCons(goodVals));
        % tmpCons = NewCons(outShapeL);
        % x1=xvals(outShapeL); y1=yvals(outShapeL)-thisOff; goodVals=find((x1>0)&(y1>0)&(x1<=imSize)&(y1<=imSize));
        % imR         = DropPatchesWeird(imR,patch1Neg,x1(goodVals),y1(goodVals),1,1/mult1.*tmpCons(goodVals));
        % tmpCons = NewCons(inShapeL);
        %
        % x1=xvals(inShapeL); y1=yvals(inShapeL)-thisOff; goodVals=find((x1>0)&(y1>0)&(x1<=imSize)&(y1<=imSize));
        % imG         = DropPatchesWeird(imG,patch1Neg,x1(goodVals),y1(goodVals),1,mult1.*tmpCons(goodVals));
        % tmpCons = NewCons(outShapeR);
        % x1=xvals(outShapeR); y1=yvals(outShapeR)+thisOff; goodVals=find((x1>0)&(y1>0)&(x1<=imSize)&(y1<=imSize));
        % imG         = DropPatchesWeird(imG,patch1Pos,x1(goodVals),y1(goodVals),1,1/mult1.*tmpCons(goodVals));
    end

else % pixel carrier
    samp=16;
    carrier=double(imresize(rand(imSize./samp,imSize./samp),[imSize imSize],'nearest')>0.5);
    back1=ImShift(carrier,-OffX/2,0);
    fore1=ImShift(carrier,OffX/2,0);
    imR=fore1.*im0a+(1-im0a).*back1;
    imG=back1.*im0a+(1-im0a).*fore1;
end
colIm(:,:,1)=128+127.*imR;
colIm(:,:,2)=128+127.*imG;
%ishow(double(colIm./255)); drawnow