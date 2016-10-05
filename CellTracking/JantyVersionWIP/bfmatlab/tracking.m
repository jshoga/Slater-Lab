%% import image stack
% choose .czi image stack
[name,path] = uigetfile('*.czi');
filename = [path,name];
% read into matlab
czi = bfopen(filename);
% get image dimensions from first image in .czi file
[imgRows, imgCols] = size(czi{1}{1,1});
% get number of images (z-slices) from .czi file
noImgs = length(czi{1});
% column 1 in cell 1 contains all images, row index corresponds to position
% in z stack
images = zeros(imgRows,imgCols,noImgs);
for i = 1:noImgs
    images(:,:,i) = czi{1}{i,1};
end

%% read metadata
metadata = czi{1,2};
metadataKeys = metadata.keySet().iterator();
for i=1:metadata.size()
    keys{i} = metadataKeys.nextElement();
    values{i} = metadata.get(keys{i});
%     fprintf('%s = %s\n', key, value)
end
zz = [keys,values];
%% omar's preprocessing
close all
centroids2 = cell(noImgs,1);
d=3;
sig1 = 1/(1+sqrt(2))*d;
sig2 = sqrt(2) * sig1;
noiseRng = mean(prctile(images(:,:,noImgs),95));
[mVal,mIdx] = max(prctile(mean(images(:,:,:)),70));
refHistImage = images(:,:,mIdx);
LoG = fspecial('log',3,.25);
Lap = fspecial('laplacian');
% imadjust(ppImages, [noiseRng;max(max(max(images)))],[0,1];
for i = 1:noImgs
highIn = max(max(max(images(:,:,i))));
ppImages(:,:,i) = (imadjust(images(:,:,i)/65535,[noiseRng/65535 highIn/65535],[])*65535);
ppImages2(:,:,i) = (imgaussfilt(imadjust(images(:,:,i)/65535,[noiseRng/65535 highIn/65535],[])*65535,sig2)-imgaussfilt(imadjust(images(:,:,i)/65535,[noiseRng/65535 highIn/65535],[])*65535,sig1))*10;
ppImages3(:,:,i) = imfilter(ppImages2(:,:,i),Lap);
end
ppImages4 = (ppImages3>(prctile(ppImages3(ppImages3>0),25)));

for i = 1:noImgs
ppImages5(:,:,i) = bwareaopen(ppImages4(:,:,i),5);
    c = regionprops(ppImages5(:,:,i),'Centroid');
    centroids2{i} = cat(1,c.Centroid);
end



imshow(uint16(ppImages2(:,:,50)))
figure
imshow(uint16(ppImages(:,:,50)))
figure
imshow(uint16(ppImages3(:,:,50)))
figure
imshow((ppImages4(:,:,50)))
figure
imshow((ppImages5(:,:,50)))
%% edge detection
boundaries = cell(noImgs,1);
labeledBoundaries = cell(noImgs,1);
centroids = cell(noImgs,1);
for i = 1:noImgs
    % find edges using Canny filter (log filter almost works too)
    [bw,threshOut] = edge(images(:,:,i),'Canny',[0.1375,0.3]);
    % fill in gaps in detected edges by dilating features slightly
    se90 = strel('line',3,90);
    se0 = strel('line',3,0);
    % pack the image to make dilation operation more efficient - not 
    % necessary, but could speed up operations on large/many images
    % see: http://www.mathworks.com/help/images/ref/bwpack.html
    bwPacked = bwpack(bw);
    bwPackedDilate = imdilate(bwPacked,[se90,se0],'ispacked');
    bwDilate = bwunpack(bwPackedDilate);
    % fill in edge-detected areas so they are solid objects
    bwFill = imfill(bwDilate,'holes');
    % trace boundary of each object
    [boundaries{i},labeledBoundaries{i}] = bwboundaries(bwFill);
    % get centroid location of each object (in pixel units) 
    c = regionprops(bwFill,'Centroid');
    % concatenate all centroids into single matrix
    centroids{i} = cat(1,c.Centroid);
end

% %% surf test
% % extract features
% img1 = images(:,:,1);
% img2 = images(:,:,2);
% points1 = detectSURFFeatures(img1);
% points2 = detectSURFFeatures(img2);
% [features1, validPoints1] = extractFeatures(img1,points1);
% [features2, validPoints2] = extractFeatures(img2,points2);
% [indexPairs, matchMetric] = matchFeatures(features1,features2);
% matchedPoints1 = validPoints1(indexPairs(:,1));
% matchedPoints2 = validPoints2(indexPairs(:,2));
% showMatchedFeatures(img1,img2,matchedPoints1,matchedPoints2);

%% paper steps
% 1. define point spread function
%   a. empirically
%   b. analytically
% 2. focal adhesion detection
%   a. background subtraction
%   b. contrast limited adaptive histogram equalization
%   c. laplacian of gaussian filter
%   d. manual thresholding
% 3. dot detection
%   a. xy
%       i. threshold
%       ii. dot postion calculted via weighted centroid of grayscale values
%           in feature
%   b. z
%       i. spot detection function of Imaris
%       ii. fit a plane through all points, take difference between plane
%           and measured z coordinates = tilt correction
% 4. mesh generation (some other time)