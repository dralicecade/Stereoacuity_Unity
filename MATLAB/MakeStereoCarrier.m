% MakeStereoCarrier
function [xValStore yValStore conStore SizeList patchIm]=MakeStereoCarrier(imSize,SizeList)

if ~exist('SizeList','var') || isempty(SizeList)
    SizeList=[ 32 16 8 4].*4.*(1/sqrt(2));%
end
if ~exist('imSize','var') || isempty(imSize)
    imSize=4096;%
end

m1=imSize; n1=m1;
DropRec=zeros(imSize,imSize);

multOff=3.3;
    for s=1:length(SizeList)
        [yvals xvals]=MakeDensePositionGrid(m1,n1,multOff*SizeList(s)/2.0,2,[],[],2.*1000,[],0,DropRec);
        xValStore{s}=xvals;
        yValStore{s}=yvals;
        NoEls = length(xvals);
%        patch1=MakeCosineWindow(SizeList(s),SizeList(s)/2.1,SizeList(s)/10);
%        res=DropPatches(res,patch1,xvals(1:NoEls),yvals(1:NoEls),1);
        if s<length(SizeList)
            ForbRad=multOff*SizeList(s+1)/2.1;
        else
            ForbRad=2;
        end
        patch2=MakeCosineWindow(3*SizeList(s),ForbRad,1);
        DropRec=DropPatches(DropRec,patch2,xvals(1:NoEls),yvals(1:NoEls),1);%1+0.*cons);
        DropRec=abs(DropRec)>0.01;
    end

patchIm=zeros(m1);
for s=1:length(SizeList)
    cons=0.75+0.25.*(1-2.*rand(1,length(xValStore{s})));
    conStore{s}=cons;
    patch1=MakeCosineWindow(3.5.*SizeList(s),SizeList(s)/2.1,SizeList(s)/10,0,0);
    patchIm=DropPatches(patchIm,patch1, xValStore{s}, yValStore{s},1,cons);
end
