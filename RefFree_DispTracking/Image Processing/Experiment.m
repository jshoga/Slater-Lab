

%The Experiment class object is intended to store relavent information
%about the specific data set to be analyzed for material deformation.
%Specifically, this class object will hold images and metadata and allow
%the user to process images all at once (e.g. in the event that one image
%is cropped during runtime, all related images should be cropped the same
%way)

%Omar Banda

classdef Experiment
    properties
        images
        metadata
        cellImg
        fluorImg
        masks
        centroids2d
        redo
        ppOptions
    end
    methods
        
        %FOR LOADING IMAGES INTO AN EXPERIMENT
        function obj = Experiment(stackFile,cellFile,fluorFile,metadata)
            % If a stackFile input argument is not supplied, ask the user
            % to select an image stack he/she would like to analyze
            if ~exist('stackFile','var') || isempty(stackFile)
                w = msgbox('Choose the image stack you''d like to analyze.');
                waitfor(w);
                % Use the images from the image stack you'd like to
                % analyze
                [obj.images,obj.metadata] = getImages;
                
                % OR
                % Get metadata from the original image stack since metadata
                % isn't saved when the image stacks are cropped to the
                % user-selected ROI
                %[~,obj.metadata] = getImages;
                % If a stackFile input argument is provided, use that as an
                % input for getImages without asking the user to select a file
                % manually
            else
                [obj.images,obj.metadata] = getImages(stackFile);
            end
            % If a cellFile input argument is not supplied, ask the user
            % to select the cell image he/she would like to use as an
            % overlay
            if ~exist('cellFile','var') || isempty(cellFile)
                w = questdlg('Create a companion TRANSMITTED image of the cells on this gel? If yes, select starting image',...
                    'Transmitted Image (Optional)','Yes','No','Yes');
                waitfor(w);
                if strcmp(w,'Yes') == 1
                    obj.cellImg = getImages;
                    obj.cellImg = imadjust(uint16(obj.cellImg));
                else
                    obj.cellImg = NaN;
                end
                % If a cellFile input argument is provided, use that as an
                % input for getImages without asking the user to select a file
                % manually
            else
                obj.cellImg = getImages(cellFile);
            end
            
            %Same as above, but for a fluorescent image
            if ~exist('fluorFile','var') || isempty(fluorFile)
                w = questdlg('Create a companion FLOURESCENT image of the cells on this gel? If yes, select starting image',...
                    'Fluorescent Image (Optional)','Yes','No','No');
                waitfor(w);
                if strcmp(w,'Yes') == 1
                    obj.fluorImg = getImages;
                    obj.fluorImg = uint16(obj.fluorImg);
                else
                    obj.fluorImg = NaN;
                end
            else
                obj.fluorImg = getImages(fluorFile);
            end
        end
        
        
        %FOR PRE-PREPROCESSING DATA FOR FINDING CENTERS
        function [ppOptions,roiMasks] = preprocess(obj,auto)
            % Process images and get centroid locations
            [roiMasks,ppOptions] = preprocess(obj.images,obj.metadata,auto);
        end
        
        %FOR TRUNCATING DATA BEFORE PREPROCESSING
        function [roiImgs,roiFluor,roiCell,roiBounds] = cropImgs(obj)
            % Use EditStack.m to crop the original image stack
            [roiImgs,~,roiBounds,~] = EditStack(obj.images,obj.images,1);
            
            %crop the transmitted image
            if isnan(obj.cellImg) == 0
                roiCell = imcrop(obj.cellImg,[roiBounds(1,1),roiBounds(1,2),roiBounds(1,3),roiBounds(1,4)]);
            else
                roiCell = NaN;
            end
            
            %Crop the fluorescent image
            if isnan(obj.fluorImg) == 0
                roiFluor = imcrop(obj.fluorImg,[roiBounds(1,1),roiBounds(1,2),roiBounds(1,3),roiBounds(1,4)]);
            else
                roiFluor = NaN;
            end
        end
        
        
        %FOR VIEWING PREPROCESSED MASKS AND TRUNCATING DATA
        function [roiImgs,roiMasks,roiCell,roiBounds,bkImg,redo] = cropImgs2(obj,auto)
            % Determine a scale factor for the resolution of outputs to
            % allow for high resolution overlays of displacement vectors
            % using the trajectories.m code. The new pixel size should be
            % 0.0825 microns
            scaleFactor = (obj.metadata.scalingX*1000000)/0.1625;
            
            % Use EditStack.m GUI function to select a region of interest
            % and return the bounds of the ROI, as well as the stack of
            % images and masks limited to the selected ROI
            if auto == 0
            [roiMasks,roiImgs,roiBounds,redoCheck] = EditStack(obj.masks,obj.images,1);
            else
                roiBounds = [1,1,size(obj.masks,2),size(obj.masks,1)];
                roiMasks = obj.masks;
                roiImgs = obj.images;
                redoCheck = 0;
            end
            
            disp('Saving Processed Images')
            if redoCheck == 1
                redo = 1;
                roiCell = 1;
                bkImg = 1;
            else
                redo = 0;
                % The ROI image stack is returned as a double, to ensure the
                % images are saved correctly, we convert from double to uint8
                % or uint16, depending on the data type of the original images
                if obj.metadata.colorDepth == 8
                    roiImgs = uint8(roiImgs);
                    dataScale = 255;
                elseif obj.metadata.colorDepth == 16
                    roiImgs = uint16(roiImgs);
                    dataScale = 65535;
                end
                
                % Here we save the ROI image stack
                noImgs = size(roiImgs,3);
                % The file path is set such that the ROI image stack will be
                % saved in the same folder as the original image stack, with
                % the same name as the original image stack, but with "roi"
                % appended to the end of the name
                roiFile = ...
                    [obj.metadata.filename,' ROI.tif']; %obj.metadata.filepath,
                maskFile = ...
                    [obj.metadata.filename,' Processed.tif']; %obj.metadata.filepath,
                % If a file already exists with the name we just specified
                % (i.e. if an ROI has been selected before), that file is
                % deleted. This is necessary because the file will not simply
                % be overwritten, because the imwrite function will just append
                % new images to the end of any previously exisiting ones. This
                % is how imwrite handles saving series of images in a single
                % tiff  file
                if exist(roiFile,'file')
                    delete(roiFile)
                end
                if exist(maskFile,'file')
                    delete(maskFile)
                end
                % Loop through each image in the ROI image stack, append the
                % current image (thisImg) to the end of the series, and save it
                % to the filepath specified in roiFile
                if ismember(6,obj.ppOptions{1}) == 1 || ismember(5,obj.ppOptions{1}) == 1
                    scaleCheck = .5;
                else
                    scaleCheck = 1;
                end
                for i = 1:noImgs
                    % We use imadjust so that the features of the images are
                    % visible after being saved
                    noiseRng = (double(mean(prctile(roiImgs(:,:,noImgs),50))))/dataScale;
                    highIn = (double(max(max(max(roiImgs(:,:,i))))))/dataScale;
                    thisImg = imgaussfilt(imadjust(roiImgs(:,:,i),[noiseRng,highIn],[]));
                    imwrite(imresize(thisImg,scaleFactor),roiFile,'WriteMode','append');
                    thisImg2 = uint16(roiMasks(:,:,i));
                    imwrite(thisImg2,maskFile,'WriteMode','append');
                    
                end
                
                % If it exists...
                % Save the ROI-cropped cell image with a similar file naming
                % convention to that used in saving the ROI stack.
                if isnan(obj.cellImg) == 0
                    roiCell = imcrop(obj.cellImg,[roiBounds(1,1),roiBounds(1,2),roiBounds(1,3),roiBounds(1,4)]);
                    cellFile = [obj.metadata.filename,' Transmitted Cell Image.tif']; %obj.metadata.filepath,
                    imwrite(imresize(roiCell,scaleFactor),cellFile,'tif');
                else
                    roiCell = 'No Input Selected';
                end
                
                % Save the ROI-cropped fluorescence image with a similar file
                % naming convention to that used in saving the ROI stack.
                if isnan(obj.fluorImg) == 0
                    roiFluor = imcrop(obj.fluorImg,[roiBounds(1,1),roiBounds(1,2),roiBounds(1,3),roiBounds(1,4)]);
                    fluorFile = [obj.metadata.filename,' Fluorescent Cell Image.tif']; %obj.metadata.filepath,
                    imwrite(imresize(roiFluor,scaleFactor),fluorFile,'tif');
                end
                
                % Save an ROI-sized black image with a similar file naming
                % convention to that used in saving the ROI stack. This image
                % is useful in the trajectories.m function for figure
                % generation purposes
                bkImg = uint16(zeros(roiBounds(4),roiBounds(3)));
                blackFile = [obj.metadata.filename,' Black.tif']; %obj.metadata.filepath,
                imwrite(bkImg,blackFile,'tif');
                
                % Save scaling information  
                autoChk = 1;
                raw = RawData(obj.metadata,autoChk);                
                save('Matlab Data Files\DataRaw.mat','raw')
            end
            disp('Done Saving Processed Images')
        end
    end
end