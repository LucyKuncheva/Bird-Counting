clear %clc, close all

% =========================================================================
% imds = imageDatastore('BirdClips', "IncludeSubfolders",true,...
%     "LabelSource","foldernames");
%
% % Create a data set
% Data = [];
% for i = 1:numel(imds.Files) % Read images using a for loop
%     im = rgb2gray(readimage(imds,i)); %#ok<*SAGROW>
%     Data = [Data;im(:)'];
% end
%
% Labels = grp2idx(imds.Labels); % Convert to numerical
%
% %%
% % Add negative examples--------------------------------------------------
%
% h = 40; w = 30; % height and width of the BB
%
% [~,~,P3] = xlsread("Overall_BB.csv");
%
% N = 2*size(Data,1);
%
% for i = 1:N
%     index_image = randi(size(P3,1));
%     imneg = rgb2gray(imread(P3{index_image,6}));
%     % Pick a random bounding box
%     r = randi(round(size(imneg,1)*0.25),round(size(imneg,1)-h));
%     c = randi(1,round(size(imneg,2)-w));
%     neg_im = imneg(r:r+h-1,c:c+w-1);
%     Data = [Data;neg_im(:)'];
%     Labels = [Labels;6];
% end
%
% %%
% to_remove = Labels == 2 | Labels == 5;
% Labels(to_remove) = [];
% Data(to_remove,:) = [];
%
% %%
% % Train LDC
% Data = double(Data);
% ldc = fitcdiscr(Data,Labels);
% y = ldc.predict(Data);
% fprintf('LDC resub accuracy = %.4f\n',mean(y==Labels))
%
% % LDC resub accuracy = 0.9451
%
%
% %%
% % PCA
% [coef, DataPCA30, ~, ~, ~, mu] = pca(Data,'NumComponents',30);
%
% ldcPCA30 = fitcdiscr(DataPCA30,Labels);
% yPCA30 = ldcPCA30.predict(DataPCA30);
% fprintf('LDC resub accuracy = %.4f\n',mean(yPCA30==Labels))
%
% save MATLAB_Data Data DataPCA30 Labels imds mu coef ldc ldcPCA30
% =========================================================================

addpath('MATLAB_Object_Detector_Example')

% Load the ground truth data
load('groundTruth_ClairesData_141121','gTruth');
gt = merge_labels(gTruth, {'GL','GN','RG','SC','UN'});
tt = cat(2,gt.DataSource.Source,gt.LabelData);

load MATLAB_Data

% PCA
Data = double(Data);
Labels(Labels<6) = 1;
Labels(Labels == 6) = 2;
[coef, DataPCA30, ~, ~, ~, mu] = pca(Data,'NumComponents',30);
%DataPCA30 = Data;

ldcPCA30 = fitcdiscr(DataPCA30,Labels);
yPCA30 = ldcPCA30.predict(DataPCA30);
fprintf('LDC resub accuracy = %.4f\n',mean(yPCA30==Labels))



im_folders = {'TL1_Images_001_completed-20211101T225032Z-001\TL1_Images_001_completed',...
    'TL1_Images_002_completed-20211101T225019Z-001\TL1_Images_002_completed',...
    'TL1_Images_003_completed-20211101T225000Z-001\TL1_Images_003_completed',...
    'TL1_Images_004_completed-20211101T224942Z-001\TL1_Images_004_completed',...
    'TL1_Images_005_completed-20211101T224919Z-001\TL1_Images_005_completed',...
    'TL1_Images_006_completed-20211101T224858Z-001\TL1_Images_006_completed'};


%% Work through an example ------------------------------------------------

flag_example = false;

if flag_example

    im = imread([im_folders{1},'/SOS_PUF_2021_Camera1_202105171628.jpg']);
    sz = size(im);
    res_image_RawData = detect_handcrafted(im,ldcPCA30,mu,coef);

    figure('Position',[100,100,sz(2)+100,sz(1)+100])
    imagesc(res_image_RawData), axis equal off

    figure('Position',[100,100,sz(2)+100,sz(1)+100])
    imshow(res_image_RawData > prctile(res_image_RawData(:),98))

    % Animated detections
    % Starting from the highest score

    % ff = figure('Position',[100,100,sz(2)+100,sz(1)+100]);
    % imshow(im)
    % hold on

    % figure(ff)
    % u = flipud(unique(res_image_RawData));
    % for i = 1:numel(u)/20
    %     [i1,i2] = find(res_image_RawData>= u(i));
    %     plot(i2,i1,'g.','MarkerSize',0.01)
    %     pause(0.01)
    % end

    % Impose the heat map on the image
    figure
    new_im = imfuse(im,res_image_RawData);
    imshow(new_im)

    centres = count_blobs(res_image_RawData,11.1);
    % Impose centres on the image
    figure
    imshow(im), hold on
    plot(centres(:,1),centres(:,2),'b.','MarkerSize',25)

end


%% Label all --------------------------------------------------------------
% Detect all
detect_flag = true;

if detect_flag
    imageFilename = tt.Var1;
    numImages = numel(imageFilename);
    fprintf('Total Number of Images = %i\n\n',numImages)
    [or_count, det_count] = deal(zeros(numImages,1));

    for i = 1 : numImages
        I = imread(imageFilename{i});
        res = detect_handcrafted(I,ldcPCA30,mu,coef);
        %weird_threshold = 11.1;
        thr_prob = 0.48*max(res(:));
        [centres,~] = count_blobs(res,thr_prob);
        or_count(i) = size(tt.Merged{i},1);
        det_count(i) = size(centres,1);
        fprintf('%3i  Original = %3i    Detected = %3i\n',i,or_count(i),...
            det_count(i))
    end

    save('Handcrafted_results_11')

else
    load('Handcrafted_results_11')
end
%%

figure, hold on, grid on, axis equal
plot(or_count,det_count,'k.')
xlabel('Original count of birds in image')
ylabel('Detected count of birds in image')
axis([0,45,0,45])
plot([0,45],[0,45],'k--')
title('Bird counting using handcrafted features')
cc = corrcoef(or_count,det_count);
fprintf('Correlation = %.4f\n',cc(1,2))


% =========================================================================
% -------------------------------------------------------------------------
function res_image = detect_handcrafted(im,cla,mu,coef)

h = 40; w = 30; % height and width of the BB

grey_image = rgb2gray(im);
sz = size(grey_image);

possible_x = 1:sz(2)-w;
possible_y = sz(1)*0.25:sz(1)-h;
res_image = zeros(sz);
res_counts = zeros(sz);

% Organise animation
% handle = plot([0,w,w,0,0],[0,0,h,h,0],'g-');

% Go through every possible location
for i = 1:5:numel(possible_y)
    % fprintf('Row %i\n', i)
    y = possible_y(i);
    for j = 1:5:numel(possible_x)
        x = possible_x(j);
        clip = grey_image(y:y+h-1,x:x+w-1);
        %clip = imresize(clip,[h,w]);

        % [yRawData,pp] = ldc.predict(double(clip(:)'));
        [~,pp] = cla.predict((double(clip(:))'-mu)*coef);

        res_image(y:y+h-1,x:x+w-1) = ...
            res_image(y:y+h-1,x:x+w-1) + pp(1);
        res_counts(y:y+h-1,x:x+w-1) = ...
            res_counts(y:y+h-1,x:x+w-1) + 1;

        % set(handle,'XData',[x,x+w,x+w,x,x],'YData',[y,y,y+h,y+h,y])
        % if yRawData ~= 6
        %     plot([x,x+w,x+w,x,x],[y,y,y+h,y+h,y],'y-')
        % end
        % drawnow
    end
end
res_image = res_image ./ res_counts;
end

% -------------------------------------------------------------------------
function [centres,mask] = count_blobs(im,thr)
% 'im' is a double array

if nargin == 1
    thr = 11.1;
end
bw = im > thr;
CC = bwconncomp(bw);
S = regionprops(CC,'Centroid');
if CC.NumObjects > 0
    for i = 1:CC.NumObjects
        centres(i,:) = S(i).Centroid;
    end
    mask = CC.PixelIdxList;
else
    centres = [];
    mask = [];
end
end