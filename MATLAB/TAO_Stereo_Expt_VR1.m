% TAO_Stereo_Expt_VR1
clear all
screenid = max(Screen('Screens'));%was 2

KbName('UnifyKeyNames');
escapeKey       = KbName('ESCAPE');
backKey         = KbName('DELETE');
repeatKey       = KbName('SPACE');
LeftArrow       = KbName('LeftArrow');
RightArrow      = KbName('RightArrow');
ReturnKey       = KbName('Return');
SymbolName      = {'LanC' 'TAO' 'RANDOT'};
ProcedureNames  = {'QUEST' };

% Machine spocific
PixPerCm         = 65; % LG 4k home monitor. 58 = macbook
ViewingDistance  = 80; % cm
PixPerDeg        = round(PixPerCm/(2*atan2d(0.5,ViewingDistance)));%
PatchDiameterPix = round(PixPerDeg*3.5);

baseRandState       = rng('default');
rng(baseRandState);
WhichProcedure      = 1;%DefInput('Which procedure? (1=QUEST)',1);
ParticipantName     = DefInput('Participant name','Test');
WhichSymbol         = 2;%DefInput('Which symbol? (1=C,2=TAO,3=RANDOT)',3);
carrierType= 1; %DefInput('Which carrier? (1=disks,2=noise)',2);
GlobalScaling = 1; %DefInput('GlobalScaling?',1);
if carrierType==1
    usePregen=1;
else
    usePregen=0;
end
NoSymbolList        = [8 10 11];
NoSymbols           = NoSymbolList(WhichSymbol);
NoInterleaved=NoSymbols;

NoInterleaved=1;


if WhichProcedure==1 %% QUEST
    tGuess=-1+zeros(1,NoInterleaved);
    tGuess=DefInput('Estimate threshold (e.g. -1): ',tGuess);
    tGuessSd=tGuess+2;
    tGuessSd=DefInput('Estimate the standard deviation of your guess, above, (e.g. 2): ',tGuessSd);
    NoTrialsPerCondition=DefInput('#trials per interleaved condition',5);
    NoTrials=NoTrialsPerCondition*NoInterleaved;

    pThreshold=1/NoSymbols+(1-1/NoSymbols)/2; % 55% or 56.25% for 10AFC and 8AFC
    beta=3.5;delta=0.01;gamma=0.5;
    for i=1:NoInterleaved
        q(i)=QuestCreate(tGuess(i),tGuessSd(i),pThreshold,beta,delta,gamma);
        q(i).normalizePdf=1;
    end
    minStimTime=2;
    minimumTime=0.0;
    feedback=1;
    WhichInterList=Shuffle(All(repmat([1:NoInterleaved],[1 NoTrialsPerCondition])));
    TrialsCount         = ones(1,NoInterleaved);
    ResponseRecord      = zeros(NoInterleaved,NoTrialsPerCondition);
    CorrectRecord      = zeros(NoInterleaved,NoTrialsPerCondition);
    StimulusIDRecord      = zeros(NoInterleaved,NoTrialsPerCondition);
    TimeRecord      = zeros(NoInterleaved,NoTrialsPerCondition);

end
carrierTypeName={'Disk' 'Noise'};;
RootDir             = PathToMe;
DataFileName         = sprintf('%sStereo_Data%c%s_%s_%s_%s_%s.mat',RootDir,filesep,ParticipantName,SymbolName{WhichSymbol},carrierTypeName{carrierType},ProcedureNames{WhichProcedure},MyDate);
fprintf(1,'Data will be written to %s\n',DataFileName);

if WhichSymbol==1 % Landolt C
    NoSymbols   = 8;
    rotAngs     = 360-[0:45:315];
    [x y d a]=MakeMesh(1024,1024);
    ring=(d<512)&(d>512-(1024/5));
    BaseIm      = 1+254.*(1-((ring-((abs(y)<(1024/10))&(x>0)))>0))   ;%imread('Landolt_C_R.tif');
    for j=1:NoSymbols
        StimIm(:,:,j)=255-ImClip(imrotate(255-BaseIm,rotAngs(j)),[1024 1024]);
    end
    respKeys=';.,mkiop';
    respKeyCodes=[186 190 188 77 75 73 79 80]
elseif WhichSymbol==2 % TAO
    NoSymbols   = 10;
    SymNames    = {'Butterfly' 'Car' 'Duck' 'Flower' 'Heart' 'House' 'Moon' 'Rabbit' 'Rocket' 'Tree'};
    SymNames={'Butterfly_Sil_Pad.tif' 'Car_Sil_Pad.tif' 'Duck_Sil_Pad.tif' 'Flower_Sil_Pad.tif' 'Heart_Sil_Pad.tif' 'House_Sil_Pad.tif' 'Moon_Sil_Pad.tif' 'Rabbit_Sil_Pad.tif' 'Rocket_Sil_Pad.tif' 'Tree_Sil_Pad.tif'};
    SYmKeys='';
    for j=1:NoSymbols
        StimIm(:,:,j)=imread(SymNames{j});
    end
    respKeys='tyufghjvbn';
    respKeyCodes=respKeys-32;
elseif WhichSymbol==3 % randdot
    NoSymbols   = 11;
    SymNames={'Hand_RD_Pad.tif' 'House_RD_Pad.tif' 'Car_RD_Pad.tif' 'Square_RD_Pad.tif' 'Truck_RD_Pad.tif' 'Circle_RD_Pad.tif' 'Elephant_RD_Pad.tif' 'Heart_RD_Pad.tif' 'Duck_RD_Pad.tif' 'Star_RD_Pad.tif' 'Tree_RD_Pad.tif' };

    for j=1:NoSymbols
        StimIm(:,:,j)=imread(sprintf('%s',SymNames{j}));
    end
    respKeys='1234qwerasd';
    respKeyCodes=[49 50 51 52 81 87 69 82 65 83 68];
end

for j=1:NoSymbols
    imPatch(:,:,j)=imresize(StimIm(:,:,j),[192 192],'bilinear');
end
% init graphics
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
Screen('PrepareConfiguration');PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win winRect] = PsychImaging('OpenWindow', screenid, 255,[]);%[0 0 1600 1600]);%[0 0 1280 1280]);%[ 0 0 1200 1200]);
cX=winRect(3)/2;
cY=winRect(4)/2;

% make response screen image
PatchAngs       =  (linspace(0,2*pi,NoSymbols+1));  PatchAngs=PatchAngs(1:end-1);
PatchPosX       = cX+round(600.*cos(PatchAngs));
PatchPosY       = cY+round(600.*sin(PatchAngs));
backIm=200+zeros(winRect(4),winRect(3));
[x y d a]=MakeMesh(winRect(4),winRect(3));
disk= 200+55.*(d<PatchDiameterPix/2);
RespIm          = 128-127.*((255-DropPatches(disk,imPatch,PatchPosX,PatchPosY,0))./255);

respTex= Screen('MakeTexture', win, RespIm);
graphics            = 0;
GuessRate           = 1/NoSymbols;



%if WhichProcedure==1 % ISO
%end
TrialLoop   = 1;
NoQuit      = 1;
keepRunning = 1;
NoRepeat=1;
BackGrey=128;
Screen('FillRect', win,BackGrey,winRect );
Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));
Screen('DrawText',win,sprintf('Push a button to begin'),32,32,192);
vbl = Screen('Flip', win);
Screen('FillRect', win,BackGrey,winRect );
Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));

Screen('DrawText',win,sprintf('Push a button to begin'),32,32,192);
vbl = Screen('Flip', win);
GetChar

while keepRunning % MAIN TRIAL LOOP
    if NoRepeat
        randState(TrialLoop)    = rng; % set random seed
        rng(randState(TrialLoop));
        ThisInter=WhichInterList(TrialLoop);

        if WhichProcedure==1 % QUEST
            ThisSymbol      = Randi(NoSymbols); %ThisInter;%
            tTest=QuestQuantile(q(ThisInter));	% Recommended by Pelli (1987), and still our favorite.
            StimSizesDeg        = (10.^tTest).*(5/60);
            StimOffsetPix = 8.*10^tTest;
            pixSize        = round(StimSizesDeg*PixPerDeg);
        end
        %    ThisStim= imresize(StimIm(:,:,ThisSymbol),[pixSize pixSize],'bilinear');

        imSize=4096/2; OffXpixel=StimOffsetPix;  % usePregen=0; %carrierType=1;
    end
    tic
    [ThisStim]=MakeStereoStimulus(imSize,2*OffXpixel,WhichSymbol-1,ThisSymbol,carrierType,usePregen);
    %ThisStim=imresize(ThisStim,[2048 2048],'bilinear');

    size(ThisStim)

    figure;
    imshow(ThisStim(:,:,1),[]);
    title('Left eye');
    
    figure;
    imshow(ThisStim(:,:,2),[]);
    title('Right eye');

    imwrite(uint8(ThisStim),sprintf('%sStereo_Data%cPassedImage.tiff',RootDir,filesep));
    imwrite(uint8(ThisStim(:,:,1)),sprintf('%sStereo_Data%cPassedImageL.tiff',RootDir,filesep));
    imwrite(uint8(ThisStim(:,:,2)),sprintf('%sStereo_Data%cPassedImageR.tiff',RootDir,filesep));
toc

    ThisStim=(ThisStim-128).*127/250+128;




    Screen('FillRect', win,BackGrey,winRect );
    Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));
    imTex           = Screen('MakeTexture', win,ThisStim);%squeeze(StimFinal(:,:,ThisSymbol,ThisInter)));
    destRectforStim=[0 0 2048 2048].*GlobalScaling;
    Screen('DrawTexture', win, imTex, [],CenterRect(destRectforStim,winRect));
    vbl = Screen('Flip', win);
    pause(minStimTime)
    Screen('FillRect', win,BackGrey,winRect );
    Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));    Screen('DrawTexture', win, respTex, [],[]);
    Screen('FillRect', win,BackGrey,winRect );
    Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));    Screen('DrawTexture', win, respTex, [],[]);
    Screen('DrawText',win,sprintf('T%d',TrialLoop),32,32,192);
    vbl = Screen('Flip', win);
    clear imTex
    % while KbCheck; end % Wait until all keys are released.
    keepPolling=1; keyHit=0; NoRepeat=1; GoBack=0; whichPatch=1;whichResp=[]; OvalCol=[210 210 210];
    tic

    while keepPolling % keyboard loop
        [ keyIsDown, seconds, keyCodeSeq ] = KbCheck;
        if keyIsDown
            keyCode = First(find(keyCodeSeq, 1));
            ReponseKeyName= KbName(keyCode);
            whichResp=find(keyCode==respKeyCodes);
            if WhichSymbol==1 & ~isempty(whichResp) % Landolt C
                whichPatch=whichResp; keyCode=ReturnKey;
            elseif WhichSymbol==2 & ~isempty(whichResp) % TAO
                whichPatch=whichResp; keyCode=ReturnKey;
            elseif WhichSymbol==3 & ~isempty(whichResp) % RANDDOT
                whichPatch=whichResp; keyCode=ReturnKey;
            end;

            switch keyCode
                case escapeKey,     keepRunning = 0;
                case ReturnKey,     whichResp   = MaxMin(floor(whichPatch)-1,0,NoSymbols-1)+1; timetoRespond=toc;
                    if ~feedback
                        OvalCol=[128 128 210];
                    else
                        OvalCol=[128+82.*(whichResp~=ThisSymbol) 128+82.*(whichResp==ThisSymbol) 128];
                    end
                case repeatKey,     NoRepeat    = 0;
                case LeftArrow,     whichPatch  = mod(whichPatch-1-0.1,NoSymbols)+1; whichPatch  = MaxMin((whichPatch),1,NoSymbols+0.9);
                case RightArrow,    whichPatch  = mod(whichPatch-1+0.1,NoSymbols)+1; whichPatch  = MaxMin((whichPatch),1,NoSymbols+0.9);
                case backKey,       GoBack      = 1;
            end
            keyHit=(~isempty(whichResp))|(keepRunning==0)|(NoRepeat==0)|(GoBack==1);
        end
        keepPolling=(toc<minimumTime)|~keyHit;
        Screen('FillRect', win,BackGrey,winRect );
        Screen('FillOval', win,[255 255 255], CenterRectOnPoint([0 0 PatchDiameterPix PatchDiameterPix],cX,cY));    Screen('DrawTexture', win, respTex, [],[]);

        Screen('DrawTexture', win, respTex, [],[]);
        if ~isempty(whichPatch)
            Screen('FrameOval', win,OvalCol, CenterRectOnPoint([0 0 192 192].*1.8,PatchPosX(floor(whichPatch)),PatchPosY(floor(whichPatch))),24);
        end
        Screen('DrawText',win,sprintf('T%d',TrialLoop),32,32,192);
        vbl = Screen('Flip', win);
    end
    pause(0.05)
    if keepRunning&NoRepeat&~GoBack
        if WhichProcedure==1 % QUEST
            TimeRecord(ThisInter,TrialsCount(ThisInter)) = timetoRespond;
            ResponseRecord(ThisInter,TrialsCount(ThisInter)) = whichResp;
            CorrectRecord(ThisInter,TrialsCount(ThisInter)) = (whichResp==ThisSymbol);
            fprintf(1,'[%d] QUEST %dAFC T%s L%d LogMAR %3.1f\tSym %d Resp%d corr %d\n',ThisInter,NoSymbols,DigitToString(TrialLoop,4),TrialsCount(ThisInter),tTest,ThisSymbol,whichResp,(whichResp==ThisSymbol));
            q(ThisInter)=QuestUpdate(q(ThisInter),tTest,(whichResp==ThisSymbol)); % Add the new datum (actual test intensity and observer response) to the database.
            save(DataFileName,'baseRandState','randState','q','PixPerDeg','PixPerCm','ViewingDistance','ParticipantName',...
                'DataFileName','WhichSymbol','ResponseRecord','TrialsCount','ResponseRecord','WhichSymbol','TrialLoop','CorrectRecord' ,'WhichInterList','carrierType' , 'GlobalScaling')
        end
        keepRunning = (TrialLoop < NoTrials);
        TrialsCount(ThisInter)=TrialsCount(ThisInter)+1;
        TrialLoop=TrialLoop+1;
    end
    if GoBack
        TrialLoop=MaxMin(TrialLoop-1,1,NoTrials);
    end
end
sca;
%%
figure(1)
if WhichProcedure==1 % QUEST
    for i=1:NoInterleaved

        % Ask Quest for the final estimate of threshold.
        t(i)=QuestMean(q(i));		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.

        thresholdPixels=(destRectforStim(3)./imSize).*2*8.*10^t(i);
        sd=QuestSd(q(i));
        fprintf('Final threshold estimate (t; mean+-sd) is %.2f +- %.2f\n',t,sd);
        fprintf('Final threshold estimate (pix; mean) is %.2f \n',thresholdPixels);
        fprintf('Final threshold estimate (arc min; mean+) is %.2f min = %3.2fsec \n',60*thresholdPixels/PixPerDeg,60*60*thresholdPixels/PixPerDeg);

        subplot(3,4,i); plot([1:NoTrialsPerCondition],q(i).intensity(1:NoTrialsPerCondition),'o-');
        axis([0 NoTrialsPerCondition+1 -3 2])
        hold on
        plot([1 NoTrialsPerCondition],[1 1].*t(i),'k--')
        hold off
        shg
    end
end
figure(2)
bar((60*60/PixPerDeg)    .*(destRectforStim(3)./imSize).*2*8.*10.^t)
xticklabels(SymNames)
