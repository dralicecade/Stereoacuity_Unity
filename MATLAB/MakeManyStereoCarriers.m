% MakeManyStereoCarriers
scalar=0.5;
NoCarriers=32;
imSize=scalar*4096;
SizeList=scalar.*[ 32 16 8].*4;%.*(1/sqrt(2));
for i=1:NoCarriers
    i
    [xValStore yValStore conStore SizeList patchIm]=MakeStereoCarrier(imSize,SizeList);
    xValStoreAll{i}=xValStore;
    yValStoreAll{i}=yValStore;
    conValStoreAll{i}=conStore;
    ishow(patchIm); shg; drawnow
end

save('/Users/sdak387/Uni of Auckland Dropbox/Dakinlab-Data/Binocular TAO/CarrierStuffSmall.mat','xValStoreAll','yValStoreAll','conValStoreAll','NoCarriers','imSize','SizeList')