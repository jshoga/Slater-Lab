%% Put Surface, Normal, and Empty Detections together and interpolate
function [output] = interpFinal3D(directory)

if nargin ==1
    cd(directory);
end
close all

%%
load('3Ddata.mat')
% load('empties.mat')
%load('SurfaceData.mat')
% tic
% %Create the full Lists
% 
% 
% fullData = cat(1,m3.refSC,em3.refSC,dZerosXY(:,1:3));
% fullData(:,4:6) = cat(1,m3.refSC+m3.dispFilt,em3.refSC+em3.dispFilt,dZerosXY(:,1:3)+dZerosXY(:,4:6));
% fullData(isnan(fullData(:,1)),:) = [];
% 
% fullData2 = cat(1,m3.refSC,em3.refSC,dZerosZ(:,1:3));
% fullData2(:,4:6) = cat(1,m3.refSC+m3.dispFilt,em3.refSC+em3.dispFilt,dZerosZ(:,1:3)+dZerosZ(:,4:6));
% fullData2(isnan(fullData2(:,3)),:) = [];

%This data set will try to project values from the uppermost plane to the
%surface of the hydrogel.
fullData3 = m3.ref;
fullData3(:,4:6) = m3.ref+m3.disp;

%% Noise Cutoffs
xVals = shear.ltdX(:,shear.noCellTraj);
xVals(xVals == 0) = NaN;
xCO = std(xVals(:),'omitnan');

yVals = shear.ltdY(:,shear.noCellTraj);
yVals(xVals == 0) = NaN;
yCO = std(yVals(:),'omitnan');

zCO = m3.noiseCutoff/2;

%% Rigid Body Transform (Translation followed by Rotation)
% This part of the code should make the surface of the gel be at the Z=0
% plane

clear corner
corner(1,1:2) = [0,0];
corner(2,1:2) = [1,0];
corner(3,1:2) = [0,1];
corner(4,1:2) = [1,1];


corner(1,3) = feval(Surface2,[0,0]);
corner(2,3) = feval(Surface2,[1,0]);
corner(3,3) = feval(Surface2,[0,1]);
corner(4,3) = feval(Surface2,[1,1]);

translateZ = corner(1,3);
corner(:,3) = corner(:,3) - translateZ;
% Generate Angles
Ya = -atan(corner(2,3));
Xa = atan(corner(3,3));
Za = 0;
EulerA = zeros(4,4);
EulerA(1,1) = cos(Ya);
EulerA(1,2) = sin(Za)*sin(Ya);
EulerA(1,3) = sin(Ya) *cos(Za);
EulerA(2,1) = sin(Xa) *sin(Ya);
EulerA(2,2) = cos(Xa)*cos(Za)-cos(Ya)*sin(Xa)*sin(Za);
EulerA(2,3) = -cos(Xa)*sin(Za)-cos(Ya)*cos(Za)*sin(Xa);
EulerA(3,1) = -cos(Xa)*sin(Ya);
EulerA(3,2) = cos(Za)*sin(Xa)+cos(Xa)*cos(Ya)*sin(Za);
EulerA(3,3) = cos(Xa)*cos(Ya)*cos(Za)-sin(Xa)*sin(Za);
EulerA(4,4) = 1;

% Test Euler Proper Angles
corner2 = pointCloud(corner);
tform = affine3d(EulerA);
corner3 = pctransform(corner2,tform);

%% Translate and rotate all of the data
disp('Zeroing coordinates to Surface')
% [fD,fDp] = ZeroSurfacePlane(fullData,translateZ,tform);
% [fDz,fDzp] = ZeroSurfacePlane(fullData2,translateZ,tform);


%%


[fD3,fD3p,fD3d] = ZeroSurfacePlane(fullData3,translateZ,tform);
topPlane = find(planesLoc2 == min(planesLoc2));
fD3(plane.final(1:nnz(plane.final(:,topPlane)),topPlane),3) = 0;
for i = 1:size(plane.final,2)
    fD3(plane.final(1:nnz(plane.final(:,i)),i),4) = i;
    if i ~= topPlane
       fD3(plane.final(1:nnz(plane.final(:,i)),i),3) = (planesLoc2(1,i)*-1)+min(planesLoc2); 
    
end
end

fD3p = fD3(:,1:3)+fD3d;
fD3p(r.ND,:) =fD3(r.ND,1:3);
fD3d(r.ND,:) =0;
%scatter3(fD3p(:,1),fD3p(:,2),fD3p(:,3))
figure
hold on
for i = 1:max(fD3(:,4))
quiver3(fD3(fD3(:,4)==i,1),fD3(fD3(:,4)==i,2),fD3(fD3(:,4)==i,3),fD3d(fD3(:,4)==i,1),fD3d(fD3(:,4)==i,2),fD3d(fD3(:,4)==i,3))
end


fD3delete = unique(cat(1,find(isnan(fD3(:,1))),find(isnan(fD3(:,2))),find(isnan(fD3(:,3))),find(isnan(fD3d(:,1))),find(isnan(fD3d(:,2))),find(isnan(fD3d(:,3)))));
fD3(fD3delete,:) = [];
fD3p(fD3delete,:) = [];
fD3d(fD3delete,:) = [];

figure
quiver3(fD3(:,1),fD3(:,2),fD3(:,3),fD3d(:,1),fD3d(:,2),fD3d(:,3))
%% 2-D Interp for Shear displacements
clear vqXi vqYi vqZi vqXi2 vqYi2 vqZi2 fDf fDftemp
dm2 = 2.12;%raw.dataKey(9,1)*2;
[xq,yq] = meshgrid(raw.dataKey(9,1):dm2:size(image.Black,2)*raw.dataKey(9,1),raw.dataKey(9,1):dm2:size(image.Black,1)*raw.dataKey(9,1));

for i = 1:max(fD3(:,4))
    
    disp('Interpolating dXs')
    vqXi = griddata(fD3(fD3(:,4)==i,1),fD3(fD3(:,4)==i,2),fD3d(fD3(:,4)==i,1),xq,yq,'v4');
    vqXi(isnan(vqXi)) = 0;
    figure
    imshow(vqXi,[])
    vqXi2(:,:,i) = vqXi;
    
    disp('Interpolating dYs')
    vqYi = griddata(fD3(fD3(:,4)==i,1),fD3(fD3(:,4)==i,2),fD3d(fD3(:,4)==i,2),xq,yq,'v4');
    vqYi(isnan(vqYi)) = 0;
    figure
    imshow(vqYi,[])
    vqYi2(:,:,i) = vqYi;
    
    disp('Interpolating dZs')
    vqZi = griddata(fD3(fD3(:,4)==i,1),fD3(fD3(:,4)==i,2),fD3d(fD3(:,4)==i,3),xq,yq,'v4');
    vqZi(isnan(vqYi)) = 0;
    figure
    imshow(vqZi,[])
    vqZi2(:,:,i) = vqZi;
    zq = ones(size(xq))*max(fD3(fD3(:,4)==i,3));
    
    clear fDftemp
    fDftemp(:,1,i) = xq(:);
    fDftemp(:,2,i) = yq(:);
    fDftemp(:,3,i) = zq(:);
    fDftemp(:,4,i) = vqXi(:);
    fDftemp(:,5,i) = vqYi(:);
    fDftemp(:,6,i) = vqZi(:);
    
    if i == 1
        fDf(:,:) = fDftemp(:,:,1);
    else
        fDf = cat(1,fDf,fDftemp(:,:,i));
    end
    
end
disp('Done 2D interp')
%% Add Surface Data to lists
% zq = zeros(size(xq));
% clear fDftemp
%     fDftemp(:,1) = xq(:);
%     fDftemp(:,2) = yq(:);
%     fDftemp(:,3) = zq(:);
%     fDftemp(:,4) = vqXt(:);
%     fDftemp(:,5) = vqYt(:);
%     fDftemp(:,6) = vqZt(:);
% fDf = cat(1,fDftemp(:,:),fDf);

%% Filter out noisy data
% fDf(abs(fDf(:,4))<xCO,4) = 0;
% fDf(abs(fDf(:,5))<yCO,5) = 0;
% fDf(abs(fDf(:,6))<zCO,6) = 0;
% 
% fDf(abs(fDf(:,4))>xCO & abs(fDf(:,4))<xCO*2,:) = [];
% fDf(abs(fDf(:,5))>yCO & abs(fDf(:,5))<yCO*2,:) = [];
% fDf(abs(fDf(:,6))>zCO & abs(fDf(:,6))<zCO*2,:) = [];
%%
%save('3Ddata.mat')
%% Newer Interp scheme 10/31/2018 (Griddata Version)
tic
dm2 = 2.12;%raw.dataKey(9,1);
[xq,yq,zq] = meshgrid(min(fD3(:,1)):dm2:max(fD3(:,1)),min(fD3(:,2)):dm2:max(fD3(:,2)),min(fD3(:,3))+2:dm2:0);
disp('Interpolating dXs')
vqX = griddata(fDf(:,1),fDf(:,2),fDf(:,3),fDf(:,4),xq,yq,zq);
vqX(isnan(vqX)) = 0;
toc
disp('Interpolating dYs')
vqY = griddata(fDf(:,1),fDf(:,2),fDf(:,3),fDf(:,5),xq,yq,zq);
vqY(isnan(vqY)) = 0;
toc
disp('Interpolating dZs')
vqZ = griddata(fDf(:,1),fDf(:,2),fDf(:,3),fDf(:,6),xq,yq,zq);
vqZ(isnan(vqZ)) = 0;
toc
%% Newer Interp scheme 10/31/2018 (Scattered Interpolant Version)
% tic
% disp('Interpolating dXs')
% Fx = scatteredInterpolant(fD3(:,1),fD3(:,2),fD3(:,3),fD3d(:,1),'natural');
% u2 = Fx(xq,yq,zq);
% toc
% 
% disp('Interpolating dYs')
% Fy = scatteredInterpolant(fDf(:,1),fDf(:,2),fDf(:,3),fDf(:,5),xq,yq,zq);
% vqY(isnan(vqY)) = 0;
% toc
% disp('Interpolating dZs')
% Fz = scatteredInterpolant(fDf(:,1),fDf(:,2),fDf(:,3),fDf(:,6),xq,yq,zq);
% vqZ(isnan(vqZ)) = 0;
% toc
%%
  u{1}{1} = vqX * (1*10^-6);
  u{1}{2} = vqY * (1*10^-6);
  u{1}{3} = vqZ * (1*10^-6); 
 %%
%  u{1}{1} = vqX;
%  u{1}{2} = vqY;
%  u{1}{3} = vqZ;
%% 
save('Inputs2.mat','u')
%%
ShowStack(u{1}{1},0)
ShowStack(u{1}{2},0)
ShowStack(u{1}{3},0)
%%

dm3 = 2.12 * (1*10^-6);
  % From Example
  clear surface normals
sizeI = (size(u{1}{1}));

[surface{1}{1},surface{1}{2}] = meshgrid(dm3:dm3:sizeI(2)*dm3,dm3:dm3:sizeI(1)*dm3);
surface{1}{3} = (size(u{1}{1},3))*ones(size(surface{1}{1}))*dm3;

normals{1}{1} = zeros(size(surface{1}{1}));
normals{1}{2} = zeros(size(surface{1}{1}));
normals{1}{3} = ones(size(surface{1}{1}));


%%

model = 'linearelastic';
properties = [12000,.2];
%%
[surface, normals] = calculateSurfaceUi(surface(1), normals(1), u);
save('Inputs2.mat','u','surface','normals','model','properties','dm3')  

try
[Fij, Sij, Eij, Uhat, ti, tiPN] = fun3DTFM(u,dm3,surface,normals,model,properties);
save('TractionOutputs.mat','Fij', 'Sij', 'Eij','Uhat','ti','tiPN')
catch
    disp('Failed Traction Coversion Function!')
end
%%

mkdir('HeatMaps','Traction')
savepath = 'HeatMaps\Traction\';
figure
maxT = max(ti{1}{3}(:));
imshow(ti{1}{1},[])
[mapX] = Auxheatmap(size(image.Black,1),size(image.Black,2),ti{1}{1},'*blues','Xtractions',savepath,maxT);

figure
maxT = max(ti{1}{3}(:));
imshow(ti{1}{2},[])
[mapY] = Auxheatmap(size(image.Black,1),size(image.Black,2),ti{1}{2},'*blues','Ytractions',savepath,maxT);

figure
maxT = max(ti{1}{4}(:));
imshow(tiPN{1}{1},[])
[mapY] = Auxheatmap(size(image.Black,1),size(image.Black,2),tiPN{1}{1},'*spectral','ShearTractions',savepath,maxT);

figure
maxT = max(ti{1}{3}(:));
imshow(ti{1}{3},[])
[mapZ] = Auxheatmap(size(image.Black,1),size(image.Black,2),ti{1}{3},'*blues','Ztractions',savepath,maxT);

figure
maxT = max(ti{1}{4}(:));
imshow(tiPN{1}{2},[])
[mapZ] = Auxheatmap(size(image.Black,1),size(image.Black,2),tiPN{1}{2},'*spectral','NormalTractions',savepath,maxT);

figure
maxT = max(ti{1}{4}(:));
imshow(ti{1}{4},[])
[mapM] = Auxheatmap(size(image.Black,1),size(image.Black,2),ti{1}{4},'*spectral','MagnitudeTractions',savepath,maxT);

%%
figure
Uhat2 = sum(Uhat{1},3);
maxT = max(Uhat2(:));
imshow(ti{1}{4},[])
Uhat2(Uhat2<1) =0 ;
[mapM] = Auxheatmap(size(image.Black,1),size(image.Black,2),Uhat2,'*spectral','StrainEnergy',savepath,maxT);

figure
Uhat3(:,:) = Uhat{1}(:,:,end);
maxT = max(Uhat3(:));
imshow(Uhat3,[])
Uhat3(Uhat3<1) =0 ;
[mapM] = Auxheatmap(size(image.Black,1),size(image.Black,2),Uhat3,'*spectral','StrainEnergyTopOnly',savepath,maxT);
%%
sumShearOld = sum(abs(ti{1}{1}(:))) + sum(abs(ti{1}{2}(:)));
sumShear = sum(abs(tiPN{1}{1}(:)));
sumNormalOld = sum(abs(ti{1}{3}(:)));
sumNormal = sum(abs(tiPN{1}{2}(:)));
sumTotal = sum(ti{1}{4}(:));
NormalForce = (sumNormal*(dm3^2));
ShearForce = (sumShear*(dm3^2));
TotalForce = (sumTotal*(dm3^2));
U = sum(Uhat2(:));
Utop = sum(Uhat3(:));
output(1,1) = sumNormal;
output(1,2) = sumShear;
output(1,3) = sumTotal;
output(1,4) = NormalForce;
output(1,5) = ShearForce;
output(1,6) = TotalForce;
output(1,7) = U;
output(1,8) = Utop;
save('TractionStats.mat','sumShearOld','sumShear','sumNormalOld','sumNormal','U','Utop','NormalForce','ShearForce','TotalForce')

 end
%% Functions

function [fD4,fD4p,fD4d] = ZeroSurfacePlane(fullData,translateZ,tform)
% Translate Fulldata so that the corner falls on (0,0) then rotate
% Input (:,1:6) matrix where (:,1:3) are XYZ of reference positions and
% (:,4:6) are final measured positions

% Outputs are reference position, final position, delta position each are 
% (:,1:3)
fD2 = fullData(:,1:3);
fD2(:,3) = fD2(:,3)-translateZ;
fD2 = pointCloud(fD2(:,1:3));

fD2p(:,1:3) = fullData(:,4:6);
fD2p(:,3) = fD2p(:,3)-translateZ;
fD2p = pointCloud(fD2p(:,1:3));
%rotate
fD3 = pctransform(fD2,tform);
fD3p = pctransform(fD2p,tform);

fD4 = fD3.Location;
fD4p = fD3p.Location;
fD4d = fD4p - fD4;
end


