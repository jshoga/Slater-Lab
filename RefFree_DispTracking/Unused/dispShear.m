%2019.05.09 Omar Banda

%This code should operate on the outputs of tracking.m to
%generate 2D displacement information for a given set of images of
%photo-patterned markers

%The input 'directory' is included to allow the function to be called
%repeatedly for automated analysis of many datasets.

% function dispShear(directory)
% if nargin == 1
%     cd(directory);
% end
tic
mkdir('Shear Mat Files')
filePath = cd;
set(0,'defaultfigurecolor',[1 1 1])
%Analyzing Trajectories from FIJI input or from Custom Code

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%Section 1.) Inputs and Sorting the Raw Data From Excel File
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

autoChk = 1; %1 for auto, otherwise 0
disp('1.1 Loading Images and Raw Data')
image = ImageData(autoChk);
image = DilateBinary(image,100);
raw = RawData(autoChk);
raw = rawPx2um(raw);
save('Shear Mat Files\DataRaw.mat','raw')
outputs = OutputSelector(autoChk);
disp(['done Loading Images and Raw Data '  num2str(toc) ' seconds'])
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%Section 2.) Building Shear Data from Raw Data
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

clear shear
disp(['Calculating Displacements and Tilt'])
shear = ShearData(raw,image);
%%
shear = globalTilt(shear,image,raw,filePath);
shear = localTilt(shear,filePath);
disp(['done Calculating Displacements and Tilt '  num2str(toc) ' seconds'])
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%Section 3.)Data Manipulations for Visualizations
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3.1 Binning for Quiver Plots and HeatMaps%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(['Binning Data'])
disp('3.1 Creating Color Map for Vector Plot Image Overlays')
[cm1,cm2,cmD,cmDS,colorMap,colorScheme] = createColorMap(shear,raw,outputs);
disp(['done Binning Data'  num2str(toc) ' seconds'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3.2 Data Filters and Cutoffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3.2 Persistence - The goal is to remove shear deformations that "occur"
% in less than 3 consecutive frames. Whether a shear deformation "occurs"
% will depend on whether the displacement is greater than some threshold.
disp('3.2 Thresholding Data Using a Displacement Magnitude-Based Cutoff')
shear = lTcutoff(shear);
disp(['done Thresholding Data Using a Displacement Magnitude-Based Cutoff'  num2str(toc) ' seconds'])
%%
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%4.)IMAGE OUTPUTS
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%%
disp('4.0 Creating Centroid and Vector Plot Overlay Image Outputs')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%4.1 Drawing Zero-State Displacement Fields on Black Background%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
if ismember(2,outputs) == 1
    folderName = strcat('Black Image_',colorScheme,' Quiver Overlays');
    mkdir(filePath,folderName)
    for f = 1:shear.numFrames        % number of z-slices
        blackOverlay = figure('Position',[0 0 1000 1000]);
        imshow(image.Black,[])
        hold on
        
        for i = 1:cmD
            quiver(shear.rawX(f,cm1(cm1(:,i,f)>0,i,f))/raw.dataKey(9,1),shear.rawY(f,cm1(cm1(:,i,f)>0,i,f))/raw.dataKey(9,1),shear.ltdX(f,cm1(cm1(:,i,f)>0,i,f))/raw.dataKey(9,1),shear.ltdY(f,cm1(cm1(:,i,f)>0,i,f))/raw.dataKey(9,1),...
                0,'color',[colorMap(i,1:3)]);
            hold on
        end
        hold off
        savefile = [filePath '\' folderName '\Black Background Overlay' colorScheme ' ' num2str(f) '.tif'];
        if ismember(6,outputs) == 1
            export_fig(blackOverlay,savefile,'-native');
        else
            export_fig(blackOverlay,savefile);
        end
        close
    end
end



%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%4.2 Plotting Centroids on a Black Background%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Notes: This section plots centroids (as in 5.3) on a black background for
%processing into heat maps in imageJ to view 3D information in a 2D image.

if ismember(4,outputs) == 1
    folderName = strcat( 'Centroid_',colorScheme,' Black Image Overlays');
    mkdir(filePath, folderName)
    for f = 1:shear.numFrames
        centroidsOnly = figure('Position',[0 0 1000 1000]);
        imshow(image.Black,[])
        hold on
        for i = 1:cmD
            
            xTemp = squeeze(shear.rawX(f,cm1(cm1(:,i,f)>0,i,f)))/raw.dataKey(9,1);
            
            yTemp = squeeze(shear.rawY(f,cm1(cm1(:,i,f)>0,i,f)))/raw.dataKey(9,1);
            
            plot(xTemp,yTemp,'.','MarkerSize',30,'Color',[colorMap(i,1:3)]);
            
            hold on
        end
        hold on
        hold off
        savefile = [filePath '\' folderName '\Centroids on Frame ' colorScheme ' ' num2str(f) '.tif'];
        if ismember(6,outputs) == 1
            export_fig(centroidsOnly,savefile,'-native');
        else
            export_fig(centroidsOnly,savefile);
        end
        close
    end
end

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%4.3 DEBUGGING:Plotting Corrected X,Y Coordinate Fields%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Notes: This sections is really helpful for debugging. It shows x0,y0 positions
% as well as current X,Y coordinates for each trajectory on each frame. It
% also plots the final displacement quiver field.

if ismember(3,outputs) == 1
    %%
    debugImage = figure('Position',[0 0 1000 1000]);
    imshow(image.Trans,[])
    hold on
    xTemp = squeeze(shear.rawX(1,:)/raw.dataKey(9,1));
    yTemp = squeeze(shear.rawY(1,:)/raw.dataKey(9,1));
    plot(xTemp,yTemp,'r.','MarkerSize',10);
    hold on
    if ismember(7,outputs) == 0
        for f = 1:shear.numFrames
            xTemp = squeeze(shear.rawX(f,:)/raw.dataKey(9,1));
            yTemp = squeeze(shear.rawY(f,:)/raw.dataKey(9,1));
            plot(xTemp,yTemp,'b.','MarkerSize',3);
            hold on
        end
    end
    hold on
    if ismember(8,outputs) == 0
        for i = 1:cmD
            quiver(shear.rawX1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.rawY1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdX(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdY(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),0,'color',[colorMap(i,1:3)]);
            hold on
        end
        
    end
    hold off
    savefile = [filePath '\Debug Image ' colorScheme '.tif'];
    if ismember(6,outputs) == 1
        export_fig(debugImage,savefile,'-native');
    else
        export_fig(debugImage,savefile);
    end
end
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%4.4 Plotting Transmitted Quiver Overlays v1%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ismember(5,outputs) == 0
    trajOverlay = figure('Position',[0 0 1000 1000]);
    imshow(image.Fluor,[])
    hold on
    for i = 1:cmD
        
        quiver(shear.rawX1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.rawY1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdX(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdY(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),0,'color',[colorMap(i,1:3)]);%(i^2)/((cmD/1.5)^2) also (i^1.3)/((cmD/2)^1.3) ...(i^2)/((cmD/1.5)^2)
        hold on
    end
    %quiver(shear.gtdXY(1,:),shear.mltdX(1,:),shear.mltdY(totalNumFrames,:),shear.ltdX(totalNumFrames,:),0,'g');
    hold off
    savefile = [filePath '\Fluorescent Overlay ' colorScheme '.tif'];
    if ismember(6,outputs) == 1
        export_fig(trajOverlay,savefile,'-native');
    else
        export_fig(trajOverlay,savefile);
    end
end

%%
if ismember(5,outputs) == 1
    transmittedOverlay = figure('Position',[0 0 1000 1000]);
    imshow(image.Trans,[])
    hold on
    for i = 1:cmD
        quiver(shear.rawX1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.rawY1(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdX(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),shear.ltLastdY(cm2(cm2(:,i)>0,i))/raw.dataKey(9,1),0,'color',[colorMap(i,1:3)]);%(i^1.3)/((cmD/2)^1.3)
        hold on
    end
    %quiver(shear.gtdXY(1,:),shear.mltdX(1,:),shear.mltdY(totalNumFrames,:),shear.ltdX(totalNumFrames,:),0,'g');
    hold off
    savefile = [filePath '\Transmitted Overlay ' colorScheme '.tif'];
    if ismember(6,outputs) == 1
        export_fig(transmittedOverlay,savefile,'-native');
    else
        export_fig(transmittedOverlay,savefile);
    end
end
disp('done Creating Centroid and Vector Plot Overlay Image Outputs')
%%
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%5.)Heat Scale Map of Shear
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%% Create Heat Map of Shear Deformations
disp('5.0 Creating Shear HeatMaps')

if ismember(15,outputs) == 1
    [imageHeatXY,vqXY,vqXYtotal,imageHeatNaN,imageHeatXYColor]=customHeatMap(shear,shear.ltLastdXY,image,raw.dataKey,outputs,filePath);
end
SE = strel('disk',30);
vqXYBinary = imdilate(vqXY ==0,SE);
BinaryFile = [filePath,'\HeatMaps\Shear\','Binary_Shear.tif'];
imwrite(vqXYBinary,BinaryFile);
%%
imageHeatXY2 = imresize(vqXY,[size(image.Area,1) size(image.Area,2)]);
imageHeatXY2(isnan(imageHeatXY2)) = 0;
%%
clear  imageHeatXYTotalScale imageHeatXYtotal2
if size(vqXYtotal,1) ~= 1
    for i = 1:size(vqXYtotal,3)
        
        imageHeatXYtotal2(:,:,i) = imresize(vqXYtotal(:,:,i),[size(image.Area,1) size(image.Area,2)]);
    end
else
    imageHeatXYtotal2 = 1;
end
imageHeatXYtotal2(isnan(imageHeatXYtotal2)) = 0;
disp(['done Creating Shear HeatMaps'  num2str(toc) ' seconds'])
%%
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%6.)Determining the Location of the Surface
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%%
[fitTiltPlaneMicrons,fitTiltPlanePixels] = tiltPlane(shear.noiseBook,raw.dataKey,image.Area);

%%
clear topSurface fitSurface
[topSurface ,fitSurface] = findSurface(shear,cm2,image.Area,image.Borders,raw.dataKey);
save('Shear Mat Files\Surface.mat','fitSurface')
%%
% figure
% %plot the filter pillars at the top frame that they reach
% scatter3(0,0,0)
% hold on
% scatter3(topSurface(:,3),topSurface(:,2),topSurface(:,4));
% plot(fitSurface{1})
% plot(fitSurface{2})
%  xlim([0 size(image.ROIstack,1)*raw.dataKey(9,1)])
%  ylim([0 size(image.ROIstack,2)*raw.dataKey(9,1)])
% plot(fitTiltPlanePixels)
% hold off
%%
% figure
% imshow(image.Area)
% hold on
% scatter(topSurface(:,2)/raw.dataKey(9,1),topSurface(:,3)/raw.dataKey(9,1),5,'r')
% hold off
%%
if ismember(16,outputs) == 1
    disp('Calculating Approximate Surface Deformations')
    %% Calculate Z-Displacement at Surface (Quick Method)
    clear cellSurface
    for i = 1:shear.numTraj
        shear.Top1(i) = feval(fitSurface{1},shear.rawY(shear.lastFrame(i),i),shear.rawX(shear.lastFrame(i),i));
        shear.Top2(i) = feval(fitSurface{2},shear.rawY(shear.lastFrame(i),i),shear.rawX(shear.lastFrame(i),i));
        shear.dTop1(i) = 0;
        shear.dTop2(i) = 0;
    end
    
    cellSurface = zeros(1,1);
    for i = 1:shear.numTraj
        %if it is under the cell
        if image.Area(ceil(shear.rawY1(i)),ceil(shear.rawX1(i)))==0 && image.Area(ceil(shear.lastY(i)),ceil(shear.lastX(i)))==0
            cellSurface = cat(1,cellSurface,i);
        end
    end
    %shift cells up 1 to get rid of initial zero
    cellSurface(1,:) = [];
    
    for i = 1:size(cellSurface,1)
        shear.dTop1(cellSurface(i,1)) = shear.lastFrame(cellSurface(i,1))-shear.Top1(cellSurface(i,1));
        shear.dTop2(cellSurface(i,1)) = shear.lastFrame(cellSurface(i,1))-shear.Top2(cellSurface(i,1));
    end
    
    
    interpSurface{1} = fit([(shear.rawY1(:) + shear.gtLastdY(:)),(shear.rawX1(:) + shear.gtLastdX(:))],(shear.Top1(:)+shear.dTop1(:)),'lowess','Span',.01);
    
    %% Calculate Z-Displacement at Surface (Quick Method 2)
    for i = 1:shear.numTraj
        shear.Top1(i) = feval(fitSurface{1},shear.rawY(shear.lastFrame(i),i),shear.rawX(shear.lastFrame(i),i));
        shear.Top2(i) = feval(fitSurface{2},shear.rawY(shear.lastFrame(i),i),shear.rawX(shear.lastFrame(i),i));
        shear.dTop1(i) = shear.lastFrame(i)-shear.Top1(i);
        shear.dTop2(i) = shear.lastFrame(i)-shear.Top2(i);
    end
    
    
    interpSurface{1} = fit([(shear.rawY1(:) + shear.gtLastdY(:)),(shear.rawX1(:) + shear.gtLastdX(:))],(shear.Top1(:)+shear.dTop1(:)),'lowess','Span',.005);
    
    %%
    % close all
    % figure
    % quiver3(shear.rawY1(:),shear.rawX1(:),shear.Top1(:),shear.gtLastdY(:),shear.gtLastdX(:),shear.dTop1(:))
    % hold on
    % plot3(0,0,0)
    % plot(interpSurface{1})
    % xlim([0 size(image.ROIstack,1)])
    % ylim([0 size(image.ROIstack,2)])
    % zlim([0 size(image.ROIstack,3)])
    % hold off
    
    [imageHeatZ,vqZ] = customHeatMapZ(shear,image.Black,raw.dataKey,outputs,filePath);
    
    %% Isolating Cell-Body Normal Forces
    %Filter Z-Deformation to accept only normal deformation within the cell's boundary
    imageHeatZScale = size(image.Area,1)/size(vqZ,1);
    imageHeatZ2 = imresize(vqZ,[size(image.Area,1) size(image.Area,2)]);
    imageHeatZ3 = double(imageHeatZ2) .* double(image.Area==0);
    imageHeatZ3(isnan(imageHeatZ3)) = 0;
end



%% Relate Cell Spread Area to Displacements
disp('Writing Area-Disp Relationship Stats')
clear imageAreaProps imageArea3
%shear(isnan(shear)) = 0;
imageArea3(:,:) = logical(image.Area==0);
imageAreaProps = regionprops(imageArea3,'centroid','Area','Eccentricity','Perimeter','MajorAxisLength','MinorAxisLength');
propsArea = sum(sum(image.Area==0));
propsSumDisp = sum(sum(shear.coltdXY(:,:)));
propsMeanDisp = mean(mean(shear.coltdXY(:,:)));
if propsArea > 0
    propsCircularity = ((sum(cat(1,imageAreaProps.Perimeter)))^2 )/(4*(pi*(sum(cat(1,imageAreaProps.Area)))));
    ratioArea = propsSumDisp/propsArea;
    ratioPerimeter = propsSumDisp/cat(1,imageAreaProps.Perimeter);
else
    clear imageAreaProps
    imageAreaProps = struct('centroid',0,'Area',0,'Eccentricity',0,'Perimeter',0,'MajorAxisLength',0,'MinorAxisLength',0);
    %     imageAreaProps.Perimeter =0;
    %     imageAreaProps.Area = 0;
    %     imageAreaProps(1,1).MajorAxisLength = 0;
    %     imageAreaProps(1,1).MinorAxisLength = 0;
    %     imageAreaProps(1,1).Eccentricity = 0;
    propsCircularity = 0;
    ratioArea = 0;
    ratioPerimeter = 0;
end


areaTxt = fopen('Area-Disp Relationship.txt','wt');
fprintf(areaTxt,strcat('Code Date:07/13/2017','\n'));

fprintf(areaTxt,strcat(num2str(sum(cat(1,imageAreaProps.Area))) , '\n'));
fprintf(areaTxt,strcat(num2str(propsSumDisp) , '\n'));
fprintf(areaTxt,strcat(num2str(propsMeanDisp) ,'\n'));
fprintf(areaTxt,strcat(num2str(sum(cat(1,imageAreaProps.Perimeter))) ,'\n'));
fprintf(areaTxt,strcat(num2str(propsCircularity) ,'\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).Eccentricity) ,'\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).MajorAxisLength) , '\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).MinorAxisLength) , '\n'));
fprintf(areaTxt,strcat(num2str(ratioArea) ,'\n'));
fprintf(areaTxt,strcat(num2str(ratioPerimeter) ,'\n'));
fprintf(areaTxt,strcat(num2str(sum(sum(imageHeatXY2))) , '\n'));
fprintf(areaTxt,strcat(num2str(sum(sum(sum(imageHeatXYtotal2)))) , '\n'));
%fprintf(areaTxt,strcat(num2str(sum(sum(imageHeatZ3))) , '\n'));
fprintf(areaTxt,strcat(num2str(max(max(imageHeatXY2))) , '\n'));
fprintf(areaTxt,strcat('\n'));
fprintf(areaTxt,strcat('Above is Without Text for Copy Paste','\n'));
fprintf(areaTxt,strcat('\n'));
fprintf(areaTxt,strcat(num2str(sum(cat(1,imageAreaProps.Area))) ,',    Cell Area in Sq. Pixels: ', '\n'));
fprintf(areaTxt,strcat(num2str(propsSumDisp) ,',   Sum of Pillar Displacements in Linear Pixels: ', '\n'));
fprintf(areaTxt,strcat(num2str(propsMeanDisp) ,',  Average Displacement in Linear Pixels: ', '\n'));
fprintf(areaTxt,strcat(num2str(sum(cat(1,imageAreaProps.Perimeter))) ,',   Perimeter: ', '\n'));
fprintf(areaTxt,strcat(num2str(propsCircularity) ,',   Circularity: ', '\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).Eccentricity) ,',   Eccentricity', '\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).MajorAxisLength) ,',   Major Axis of Ellipse', '\n'));
fprintf(areaTxt,strcat(num2str(imageAreaProps(1,1).MinorAxisLength) ,',   Minor Axis of Ellipse', '\n'));
fprintf(areaTxt,strcat(num2str(ratioArea) ,',  Area Ratio: ', '\n'));
fprintf(areaTxt,strcat(num2str(ratioPerimeter) ,',  Perimeter Ratio: ', '\n'));
fprintf(areaTxt,strcat(num2str(sum(sum(imageHeatXY2))) ,',  Sum of Interpolated XY Displacements in Linear Microns (Surface): ', '\n'));
fprintf(areaTxt,strcat(num2str(sum(sum(sum(imageHeatXYtotal2)))) ,',    Sum of Interpolated XY Displacements in Linear Microns (Stack): ', '\n'));
%fprintf(areaTxt,strcat(num2str(sum(sum(imageHeatZ3))) ,',   Sum of Interpolated Normal Displacements in Linear Microns (Cell Boundary): ', '\n'));
fprintf(areaTxt,strcat(num2str(max(max(imageHeatXY2))) ,',   Max of Interpolated XY Displacements in Linear Microns (Surface): ', '\n'));

fclose(areaTxt);
%% Create folder for profile views and save relevant data
disp('Saving Mat Variables')
filePath = cd;
folderName = 'Profile Data';
mkdir(filePath,folderName)
save('Profile Data\vqXY.mat','vqXY')
save('Profile Data\HeatMapXY.mat','imageHeatXYColor')
%%
save('Shear Mat Files\DataShear.mat','shear')
disp(['done Saving Mat Variables @' num2str(toc) 'seconds'])
%% Noise Histograms
clear le
mkdir('Histograms')
set(0,'defaultfigurecolor',[1 1 1])

%CHANGE FONT SIZES HERE
AxisFontSize = 28;
AxisTitleFontSize = 28;
LegendFontSize = 20;
colOptions{1,1} = 'white';
colOptions{2,1} = 'black';
colOptions{1,2} = 'black';
colOptions{2,2} = 'white';


for k = 1:size(colOptions,2)
    SigColor = [.1 .7 .7]; %[.9 .3 .3]
    fcolor = colOptions{1,k};
    bcolor = colOptions{2,k};
bins = [-400:20:400];
xdispdist = figure;
hold on
%histogram(shear.rawdX(:,:),50)
xStd = std2(shear.ltdX(:,shear.noCellTraj))*1000;
xVals = shear.ltdX(:,shear.noCellTraj);
xVals(xVals == 0) = NaN;
xStd = std(xVals(:),'omitnan')*1000;
histogram(shear.ltdX(:,shear.noCellTraj)*1000,bins,'FaceColor',fcolor,'EdgeColor',fcolor,'Normalization','probability')
histmax = max(histcounts(shear.ltdX(:,:)*1000,bins,'Normalization','probability'));
p1 = plot([xStd xStd],[0 .5],'color',[.7 .7 .7],'linestyle','--','linewidth',1);
plot([(xStd*-1) (xStd*-1)],[0 .5],'color',[.7 .7 .7],'linestyle','--','linewidth',1)
p2 = plot([xStd*2 xStd*2],[0 .5],'color',fcolor,'linestyle','--','linewidth',1);
plot([xStd*-2 xStd*-2],[0 .5],'color',fcolor,'linestyle','--','linewidth',1)
set(gca,'fontsize',AxisFontSize,'YMinorTick','on')
xt = 'X-Displacement (nm)';% input('enter the xaxis label','s');
yt = 'Probability'; %input('enter the yaxis label','s');
tt = 'Line-Profile Displacements';%input('enter the title','s');
le{1} = {'0'};
le2 = ['\color{' fcolor '}\sigma']; %input('enter the legend','s');
le3 = ['\color{' fcolor '}2*\sigma'];
label{1} = xlabel(xt);
label{2} = ylabel(yt);
%tl = title(tt);
text(xStd*2+20,.15,strcat('2\sigma= ',num2str(round(xStd*2,0)),'nm'),'color',fcolor,'fontsize',20)
text(xStd*2+20,.12,'Noise Cutoff','color',fcolor,'fontsize',20 )
ytickformat('%.2f')

axis([-400 400 0 .3])
ColorScheme(fcolor,bcolor,label,le,AxisFontSize,LegendFontSize,0,360)
leg = legend([p1 p2],le2,le3,'location','northwest');
leg.EdgeColor = fcolor;
leg.FontSize = LegendFontSize;
legend boxoff
title = ['\X-Displacement Histogram ' fcolor ' on ' bcolor];
savefile = [filePath '\Histograms' title];
export_fig(xdispdist,savefile,'-native');
end

for k = 1:size(colOptions,2)
    SigColor = [.1 .7 .7]; %[.9 .3 .3]
    fcolor = colOptions{1,k};
    bcolor = colOptions{2,k};
bins = [-400:20:400];
ydispdist = figure;
hold on
%histogram(shear.rawdX(:,:),50)
yStd = std2(shear.ltdY(:,shear.noCellTraj))*1000;
yVals = shear.ltdY(:,shear.noCellTraj);
yVals(yVals == 0) = NaN;
yStd = std(yVals(:),'omitnan')*1000;
histogram(shear.ltdY(:,shear.noCellTraj)*1000,bins,'FaceColor',fcolor,'EdgeColor',fcolor,'Normalization','probability')
histmax = max(histcounts(shear.ltdY(:,:)*1000,bins,'Normalization','probability'));
p1 = plot([yStd yStd],[0 .5],'color',[.7 .7 .7],'linestyle','--','linewidth',1);
plot([(yStd*-1) (yStd*-1)],[0 .5],'color',[.7 .7 .7],'linestyle','--','linewidth',1)
p2 = plot([yStd*2 yStd*2],[0 .5],'color',fcolor,'linestyle','--','linewidth',1);
plot([yStd*-2 yStd*-2],[0 .5],'color',fcolor,'linestyle','--','linewidth',1)
set(gca,'fontsize',AxisFontSize,'YMinorTick','on')
xt = 'Y-Displacement (nm)';% input('enter the xaxis label','s');
yt = 'Probability'; %input('enter the yaxis label','s');
tt = 'Line-Profile Displacements';%input('enter the title','s');
le{1} = {'0'};
le2 = ['\color{' fcolor '}\sigma']; %input('enter the legend','s');
le3 = ['\color{' fcolor '}2*\sigma'];
label{1} = xlabel(xt);
label{2} = ylabel(yt);

text(yStd*2+20,.15,strcat('2\sigma= ',num2str(round(yStd*2,0)),'nm'),'color',fcolor,'fontsize',20)
text(yStd*2+20,.12,'Noise Cutoff','color',fcolor,'fontsize',20 )
%tl = title(tt);
ytickformat('%.2f')
axis([-400 400 0 .3])
ColorScheme(fcolor,bcolor,label,le,AxisFontSize,LegendFontSize,0,360)
leg = legend([p1 p2],le2,le3,'location','northwest');
leg.EdgeColor = fcolor;
leg.FontSize = LegendFontSize;
legend boxoff
title = ['\Y-Displacement Histogram ' fcolor ' on ' bcolor];
savefile = [filePath '\Histograms' title];
export_fig(ydispdist,savefile,'-native');
end



for k = 1:size(colOptions,2)
    fcolor = colOptions{1,k};
    bcolor = colOptions{2,k};
SigColor = [.1 .7 .7]; %[.9 .3 .3]
bins = [-400:20:400];
filePath = cd;
xydispdist = figure;
hold on
%histogram(shear.rawdY(:,:),50)
xyStd = std2([shear.ltdXY(:,shear.noCellTraj) -1*shear.ltdXY(:,shear.noCellTraj)])*1000;
xyVals = squeeze(shear.ltdXY(:,shear.noCellTraj));
xyVals = cat(1,xyVals,-1*xyVals);
xyVals(xyVals == 0) = NaN;
xyStd = std(xyVals(:),'omitnan')*1000;
xyStd2 = 2*xyStd;
histogram(shear.ltdXY(:,shear.noCellTraj)*1000,bins ,'FaceColor', fcolor ,'Normalization','probability','EdgeColor',fcolor)
histmax = max(histcounts(shear.ltdXY(:,:)*1000,bins,'Normalization','probability'));
p1 = plot([xyStd xyStd],[0 .3],'color',[.7 .7 .7],'linestyle','--','linewidth',1);
p2 = plot([xyStd2 xyStd2],[0 .3],'color',fcolor,'linestyle','--','linewidth',1);
set(gca,'fontsize',AxisFontSize,'YMinorTick','on')
xt = 'XY-Displacement (nm)';% input('enter the xaxis label','s');
yt = 'Probability'; %input('enter the yaxis label','s');
tt = 'Line-Profile Displacements';%input('enter the title','s');
le{1} = {'0'};
le2 = ['\color{' fcolor '}\sigma']; %input('enter the legend','s');
le3 = ['\color{' fcolor '}2*\sigma'];
label{1} = xlabel(xt);
label{2} = ylabel(yt);
%tl = title(tt);

text(xyStd2+10,.15,strcat('2\sigma= ',num2str(round(xyStd2,0)),'nm'),'color',fcolor,'fontsize',20)
text(xyStd2+10,.12,'Noise Cutoff','color',fcolor,'fontsize',20 )
ytickformat('%.2f')
ColorScheme(fcolor,bcolor,label,le,AxisFontSize,LegendFontSize,0,360)
leg = legend([p1 p2],le2,le3,'location','best');
leg.EdgeColor = fcolor;
leg.FontSize = LegendFontSize;
legend boxoff
axis([0 400 0 .3])

title = ['\XY-Displacement Histogram' fcolor ' on ' bcolor];
savefile = [filePath '\Histograms' title];
export_fig(xydispdist,savefile,'-native');
end
save([filePath '\Shear Mat Files\ShearXYCutOff.mat'],'xyStd2')
%% Calculate Z-Displacement at Surface (Quick Method 2 in microns)

% %interpSurface{1} = fit([(shear.rawY1(:) + shear.gtLastdY(:)),(shear.rawX1(:) + shear.gtLastdX(:))],(shear.Top1(:)+shear.dTop1(:))*0.4,'lowess','Span',.01);
% interpSurface{1} = fit([(shear.rawY1(:) + shear.gtLastdY(:)),(shear.rawX1(:) + shear.gtLastdX(:))],(shear.Top2(:)+shear.dTop2(:))*0.4,'lowess','Span',.01);
%
% close all
% figure
% quiver3(shear.rawY1(:),shear.rawX1(:),shear.Top1(:)*0.4,shear.gtLastdY(:),shear.gtLastdX(:),shear.dTop1(:)*0.4,'r')
% hold on
% plot3(0,0,0)
% plot(interpSurface{1})
% xlim([0 size(image.ROIstack,1)])
% ylim([0 size(image.ROIstack,2)])
% zlim([0 size(image.ROIstack,3)]*0.4)
% hold off
%%

% figure
% hold on
% quiver3(shear.rawY1(:),shear.rawX1(:),shear.Top1(:),shear.gtLastdY(:),shear.gtLastdX(:),shear.dTop1(:))
% plot(interpSurface{2})
% plot3(0,0,0)

save([filePath '\Shear Mat Files\ShearImages.mat'],'image')

disp(['Trajectories Program has Completed Successfully at '  num2str(toc) ' seconds'])