% MakeDensePositionGrid
%
function [xvals yvals hit]=MakeDensePositionGrid(m1,n1,minDistOrig,downSamp,xPreset,yPreset,maxRad,aSeed,wrapping,prehitImage)
%
% For an m1 X n1 image generates a set of random points, separated by
% a minimum distance of 'minDistOrig'. You can give it (a) an optional downsampling
% parameter ('downSamp') and (b) some optional preset points to avoid ("xPreset"
% and "yPreset"). these might be at the locations of e.g. contour elements in a path parsdigm.
% The optional downsampling speeds everything up by allowing the process to operate on a smaller
% physical grid, then upsizing the result (uncomment L90,91 to add a little x-y noise).
% maxRad (optional) will set a maximum radius from centre for dropping patches
% aSeed (optional) seed for random number generator (useful for regenerating stimuli)
% wrapping (optional) wraps positions around image-edge
% prehitImage (optional/exotic) you can feed a 'hit' image back in...
% e.g. [x1 y1]=MakeDensePositionGrid(256,256,16,2,[],[],100000000000,1,1); plot(x1,y1,'rx')
% 10/2005-21 s.dakin@auckland.ac.nz
if ~exist('prehitImage')
    prehitImage=zeros(m1,n1);
end

if ~exist('wrapping')
    wrapping=0;
end
if ~exist('aSeed')|isempty(aSeed)
    aSeed=sum(100*clock);
end
rand('state',aSeed);
randn('state',aSeed);

if ~exist('downSamp')
    downSamp=1;
end

if ~exist('maxRad')|isempty(maxRad)
    maxRad=0;
end

% scale key parameters by "downSamp"
minDist         = round(minDistOrig/downSamp);
m               = floor(m1/downSamp); n = floor(n1/downSamp);

% usually just zeros to start...
prehitImage     = imresize(prehitImage,[m n],'nearest');

% the x,y grid and distances from origin...
[X,Y]           = meshgrid([-minDist:minDist],[-minDist:minDist]);
d1              = ((X).^2+(Y).^2);
thePatch        = logical(d1(:)<(minDist^2));    % forbidden zone for each point
X=X(:); Y=Y(:)-1;                       % make these 1D for speed
if ~exist('xPreset') % points to avoid 
    xPreset = [];
    yPreset = [];
else
    xvals(1:length(xPreset)) = floor(xPreset/downSamp);
    yvals(1:length(yPreset)) = floor(yPreset/downSamp);
end

if wrapping
    hit             = prehitImage|zeros(m,n);
else % we need a larger image with a frame around it
    hit             = prehitImage|logical(PadIm(zeros(floor(m-2*minDist-2),floor(n-2*minDist-2)),[m n],1)); % places to avoid include edges
end

if maxRad>0
    [X1,Y1,D1,A1]   = MakeMesh(m,n);
   % [X1,Y1]         = meshgrid([-n/2:n/2-1],[-m/2:m/2-1]);
  %  D1              = sqrt(X.^2+Y.^2);
    noGoodLoc       = 1-(D1<(maxRad/downSamp));
    hit             = hit|noGoodLoc;
end
counter     = 1;                          % count each drop
validXY     = find(~hit);                 % all positions valid initially
ValidLength = length(validXY);        % number of possible positions

while ValidLength                       % i.e. while there are point's available
   thisXY=validXY(Randi(ValidLength)) ;        % grab a random xy position
    if (counter>length(xPreset))                % i.e. we are out of the preset range
        [xvals(counter) yvals(counter)]=ind2sub([m n],thisXY); % convert it to x and y
    end
    %  plot(xvals(1:end),yvals(1:end),'o'); drawnow;   shg
    %  xy1=X+xvals(counter)+m.*(Y+yvals(counter)) ;% make the right 2D range
    xy1             = (1+mod(X+xvals(counter)-1,m))+m.*(mod(Y+yvals(counter)-1,n)) ;% make the right 2D range
    hit(xy1)        = hit(xy1)|thePatch;                 % paste in the new forbidden location
  %   imshow(double(hit.*255)); drawnow;
    counter         = counter+1;                          % update the 'number of points' counter
    validXY         = find(~hit);                         % update the avilable positions
    ValidLength     = length(validXY);                % update how many of them are left
end
xvals   = downSamp.*xvals;%+Randi(downSamp,[1 length(xvals)])-1;
yvals   = downSamp.*yvals;%+Randi(downSamp,[1 length(xvals)])-1;

if (length(xPreset)>0)
    xvals(1:length(xPreset)) = xPreset;
    yvals(1:length(yPreset)) = yPreset;
end
%subplot(1,2,2); voronoi(xvals,yvals); axis([1 m1 1 n1]); drawnow % uncomment for a fun way to present