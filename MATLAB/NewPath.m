function [xvals,yvals,ElementAngles,res,res2]=NewPath(m,CellSize,PathAngle,PathLen,PathStep,SmoothPath,PathRot,SpacingFactor,GaborLambda,GaborSD,GaborPhase,DownSamp,OrIm,Seed); %
%
% Code for making and drawing paths
% 
% Please cite "Reduced crowding and poor contour detection in schizophrenia are consistent with weak surround inhibition
% by Robol, Tibber, Anderson, Bobin, Carlin, Shergil & Dakin (2013) PloS one 8 (4), e60951
% example:
% [x1,y1,ElementAngles,res]=NewPath(512,32,(pi/180)*(15),9,32,0,0,1.7,14,14/(2*sqrt(2)),pi/2); ; ishow(res); %
if ~exist('DownSamp')
    DownSamp=1;
end

if ~exist('OrIm')
    OrIm=zeros(m);
else
    if ~isempty(OrIm)
        ishow(OrIm);
    else
        OrIm=zeros(m);
    end
end

if ~exist('Seed')
    Seed=floor(sum(100*clock));
end
rand('state',Seed); randn('state',Seed);

PathStep=floor(PathStep*sqrt(2));
% Initialise grid of random positions and orientations
KeepGoing=1;
while KeepGoing
    PixX    = zeros(1,PathLen);                 PixY    = zeros(1,PathLen);
    PixX(1) = PathStep + Randi(m-2*PathStep);   PixY(1) = PathStep + Randi(m-2*PathStep);
    PixHit((PixX(1)),(PixY(1))) = 1 ;
    ElementAngles(1)            = rand*2*pi;
    PathLoop=2; ValidPath=1;
    while (PathLoop<=PathLen) & ValidPath
        PixX(PathLoop)          = PixX(PathLoop-1) + floor(0.5*PathStep*cos(ElementAngles(PathLoop-1)));
        PixY(PathLoop)          = PixY(PathLoop-1) + floor(0.5*PathStep*sin(ElementAngles(PathLoop-1)));
        ElementAngles(PathLoop) = ElementAngles(PathLoop-1) + sign(1-(2*(1-SmoothPath)).*rand)*PathAngle;
        PixX(PathLoop)          = PixX(PathLoop) + floor(0.5*PathStep*cos(ElementAngles(PathLoop)));
        PixY(PathLoop)          = PixY(PathLoop) + floor(0.5*PathStep*sin(ElementAngles(PathLoop)));
        GoodElement             = ((PixX(PathLoop)>(PathStep))&(PixX(PathLoop)<(m-(PathStep)))&(PixY(PathLoop)>(PathStep))&(PixY(PathLoop)<(m-(PathStep))));
        if GoodElement
            KeepGoing=0; PathLoop=PathLoop+1;
        else
            ValidPath=0; KeepGoing=1;
        end
    end
    KeepGoing=(~GoodElement)|(sum(PixX>0)<PathLen);
end

% Make a set of positions with some minimum separation
[xvals yvals]                   = MakeDensePositionGrid(m,m,floor(PathStep/SpacingFactor),DownSamp,PixX,PixY,100000,Seed);
NoElements                      = length(xvals);
ElementAngles(end+1:NoElements) = rand(1,NoElements-PathLen).*(2*pi);

% use these params for the gabors - could be a functional call but this is faster
[X,Y]           = meshgrid(-CellSize/2:CellSize/2-1,-CellSize/2:CellSize/2-1);
sig1_squared    = 2*GaborSD*GaborSD;
lamb_mult       = (2.0*pi)/GaborLambda;
env             = exp(-(X.*X)/sig1_squared-(Y.*Y)/sig1_squared);
patch           = zeros(CellSize,CellSize,length(xvals));

% draw the gabors and save them in 'patch'. have some conditions if you want the path to be different
for i=1:length(xvals)
    if (i<=PathLen)
        ElementAngles(i)=ElementAngles(i)+0;%randn.*DegToRad(45);
    end
    ThisAng=pi-ElementAngles(i);
    Xt2 = X.*cos(PathRot+ThisAng) + Y.*sin(PathRot+ThisAng);
    if (i<=PathLen)    % first 'PathLen' elements are the path
        patch(:,:,i)=1.*env.*cos(Xt2.*lamb_mult+GaborPhase); %pi*mod(i,2))+
    else
        patch(:,:,i)=1.*env.*cos(Xt2.*lamb_mult+GaborPhase);
   end
end

% check the mutual distance stats
for i=1:length(xvals)
    for j=1:length(xvals)
        MutualD(i,j)=sqrt((xvals(i)-xvals(j))^2+(yvals(i)-yvals(j))^2);
    end
end

MutualD(MutualD==0)     = Inf;
minDist                 = min(MutualD);
MeanMinSep              = mean(minDist(PathLen+1:end));
MeanMinSep2             = mean(minDist(1:PathLen));

% draw the final result
res                     = DropPatches(zeros(m),patch,xvals,yvals);
res                     = rot90(res,1);
fprintf('Mean minimal separation is %3.3f pixels compared to a path sep of %3.3f\n',MeanMinSep,MeanMinSep2);