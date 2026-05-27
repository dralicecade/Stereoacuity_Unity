% DropPatches
% drop loads of 'patch' into 'image' at lcations 'x' and 'y'
% deals with patches going "offimage"
%
% res=DropPatches(zeros(512,512),rand(8),128+Randi(256,[1 100]),128+Randi(256,[1 100]),1);
% Steven Dakin (s.dakin@ucl.ac.uk)
%
function res=DropPatches(im,patch,xvals,yvals,AddThem,contrasts)

xvals=round(xvals);
yvals=round(yvals);
if ~exist('AddThem')
    AddThem=1;
end
if ~exist('contrasts')
    contrasts=ones(1,length(xvals));
end


    res=im;
    [pX pY noPatches]=size(patch);

   [m n p]=size(im);
   minX=xvals-floor(pX/2);
   minY=yvals-floor(pY/2);
   maxX=xvals+ceil(pX/2)-1;
   maxY=yvals+ceil(pY/2)-1;

   minXclip=MaxMin(minX,1,m);
   minYclip=MaxMin(minY,1,n);
   maxXclip=MaxMin(maxX,1,m);
   maxYclip=MaxMin(maxY,1,n);
   offXlo=minXclip-minX;
   offXhi=maxX-maxXclip;
   offYlo=minYclip-minY;
   offYhi=maxY-maxYclip;
   cantDraw=(minX>(m-1))|(minY>(n-1));
   
if p~=3
    	for i=1:length(xvals)
        if ~cantDraw(i)%&(contrasts(i)>0)
            if i<=noPatches
                ThisPatch=patch(:,:,i);
            else
                ThisPatch=patch(:,:,1);
           end
%             if AddThem
%                 res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))=res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))+contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i));
%             else
%                 res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))=contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i));
% 
%             end
            
            
                                  switch AddThem
                            case 1, res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))=res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))+contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i));
                            case 0, res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))=contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i));
                           case -1, 
                               adjusted=res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i));
                               vals=All(ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i)));
                               goodVals=find(abs(vals)>0);
                               adjusted(goodVals)=vals(goodVals);
                                res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i))=adjusted;
                        end

            end
        end
else % its an RGB image
    
   	for i=1:length(xvals)
        if ~cantDraw(i)&(contrasts(i)>0)
            if i<=noPatches
                ThisPatch=patch(:,:,:,i);
            else
                ThisPatch=patch(:,:,:,1);
            end
                        switch AddThem
                            case 1, res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i),:)=res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i),:)+contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i),:);
                            case 0, res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i),:)=contrasts(i).*ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i),:);
                           case -1, 
                               adjusted=res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i),:);
                               target=find(All(ThisPatch(1+offXlo(i):pX-offXhi(i),1+offYlo(i):pY-offYhi(i),:)));
                               adjusted(target)=contrasts(i);
                                res(minXclip(i):maxXclip(i),minYclip(i):maxYclip(i),:)=adjusted;
                        end
        end
     end 
    
    
end
     