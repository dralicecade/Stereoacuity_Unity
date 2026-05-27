% MakeStereoCarrier

function [xValStore yValStore SizeList patchIm]=MakeStereoCarrier(imSize)
imSize=4096;
m1=imSize; n1=m1;
res=zeros(imSize,imSize);
SizeList=[ 32 16 8 4].*4.*(1/sqrt(2));%
conIm=1-2.*zeros(m1);
DropRec=res;

multOff=3.3;
[X Y]=meshgrid([1:m1],[1:n1]);
KeepGoing=1;
MaxNoEls=320000000000000;
indList=[]; xAll=[]; yAll=[]; conList=[];
colIm=128+zeros(imSize,imSize,3);

while KeepGoing
    for s=1:length(SizeList)
        s
        [xvals yvals]=MakeDensePositionGrid(m1,n1,multOff*SizeList(s)/2.8,2,[],[],2.*1000,[],0,DropRec);
        xValStore{s}=xvals;
        yValStore{s}=yvals;

        PatchesPerSize(s)=length(xvals);
        xAll=[xAll(:)' xvals];
        yAll=[yAll(:)' yvals];
        indList=[indList(:)' s+0.*yvals];
        NoEls=min(MaxNoEls,length(xvals));
        patch1=MakeCosineWindow(SizeList(s),SizeList(s)/2.1,SizeList(s)/10);
        res=DropPatches(res,patch1,xvals(1:NoEls),yvals(1:NoEls),1);
        if s<length(SizeList)
            ForbRad=multOff*SizeList(s+1)/2.1;
        else
            ForbRad=10;
        end
        patch2=MakeCosineWindow(3*SizeList(s),ForbRad,1);
        DropRec=DropPatches(DropRec,patch2,xvals(1:NoEls),yvals(1:NoEls),1);%1+0.*cons);
        DropRec=abs(DropRec)>0.01;
    end
    KeepGoing=0;
end
% xAllStore{1}=xAll; yAllStore{1}=yAll; conListStore{1}=conList;
% xAll=xAllStore{1}; yAll=yAllStore{1}; conList=conListStore{1};
patchIm=zeros(m1);
for s=1:length(SizeList)
    patch1=MakeCosineWindow(3.5.*SizeList(1),SizeList(s)/2.1,SizeList(s)/10,0,0);
    patchIm=DropPatches(patchIm,patch1, xValStore{s}, yValStore{s},1);
end
