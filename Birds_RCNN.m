clear, clc, close all

% https://uk.mathworks.com/help/vision/ref/rcnnobjectdetector.html
% Load pre-trained detector for the example.
load('Trained_CIFAR10NET.mat','cifar10Net')

%%
% Load the ground truth data
load('groundTruth_ClairesData_141121','gTruth');
gt = merge_labels(gTruth, {'GL','GN','RG','SC','UN'});
tt = cat(2,gt.DataSource.Source,gt.LabelData);

%%
% % Display one training image and the ground truth bounding boxes
% I = imread(tt.Var1{1});
% I = insertObjectAnnotation(I,'Rectangle',tt.Merged{1},'Bird',...
%     'LineWidth',1);
% figure
% imshow(I)

%%
% A trained detector is loaded from disk to save time when running the
% example. Set this flag to true to train the detector.
doTraining = false;

if doTraining
    
    % Set training options
    options = trainingOptions('sgdm', ...
        'MiniBatchSize', 128, ...
        'InitialLearnRate', 1e-3, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropFactor', 0.1, ...
        'LearnRateDropPeriod', 100, ...
        'MaxEpochs', 100, ...
        'Verbose', true);
    
    % Train an R-CNN object detector. This will take several minutes.    
    rcnn = trainRCNNObjectDetector(tt, cifar10Net, options, ...
    'NegativeOverlapRange', [0 0.3], 'PositiveOverlapRange',[0.5 1]);
else
    % Load pre-trained network for the example.
    load('Trained_Bird_RCNN_Detector.mat','rcnn')       
end

% %%
% 
I = imread(tt.Var1{1});
testImage = I;
% [bboxes,score,label] = detect(rcnn,I);%,'MiniBatchSize',128);
% 
% [score, idx] = sort(score);
% 
% bbox = bboxes(idx(1:min(10,numel(idx))), :);
% 
% for i = 1:size(bbox,1)
%     annotation = sprintf('Confidence = %.2f', score(i));
%     I = insertObjectAnnotation(I,'Rectangle',bbox(i,:),annotation,...
%     'LineWidth',1);
% end
% figure
% imshow(I)
% %%
featureMap = activations(rcnn.Network, testImage, 14);

% The softmax activations are stored in a 3-D array.
size(featureMap)

BirdMap = featureMap(:, :, 1);

% Resize stopSignMap for visualization
[height, width, ~] = size(testImage);
BirdMap = imresize(BirdMap, [height, width]);

% Visualise the feature map superimposed on the test image. 
featureMapOnImage = imfuse(testImage, BirdMap); 

figure
imshow(featureMapOnImage)

%%
% Detect all
detect_flag = false;

if detect_flag
    imageFilename = tt.Var1;
    numImages = numel(imageFilename);
    fprintf('Total Number of Images = %i\n\n',numImages)
    
    results = table('Size',[numImages 2],...
        'VariableTypes',{'cell','cell'},...
        'VariableNames',{'Boxes','Scores'});
    [or_count, det_count] = deal(zeros(numImages,1));
    for i = 1 : numImages
        I = imread(imageFilename{i});
        [bboxes, scores] = detect(rcnn,I);
        %     [bboxes, scores] = detect(rcnn,I,'MiniBatchSize',128,...
        %         'SelectStrongest',false);
        %     [bboxes, scores] = selectStrongestBbox(bboxes, scores,...
        %         'OverlapThreshold', 0.3);
        results.Boxes{i} = bboxes;
        results.Scores{i} = scores;
        or_count(i) = size(tt.Merged{i},1);
        det_count(i) = size(bboxes,1);
        fprintf('%3i  Original = %3i    Detected = %3i\n',i,or_count(i),...
            det_count(i))
    end
    
    blds = boxLabelDatastore(gt.LabelData);
    [ap, recall, precision] = evaluateDetectionPrecision(results, blds);
else
    load('RCNN_result_strongest_bb')
end
% Using the "Strongest" BB, AP is 0.20 - not enough!

%%

figure, hold on, grid on, axis equal
plot(or_count,det_count,'k.')
xlabel('Original count of birds in image')
ylabel('Detected count of birds in image')
axis([0,45,0,45])
plot([0,45],[0,45],'k--')
title('Bird counting using RCNN detector (overlap 0.5)')
text(5,35,sprintf('AP = %.4f',ap),'Color','r','FontWeight','bold')

fprintf('Average Precision = %.4f\n',ap)

%%
I = imread(tt.Var1{1});
I = insertObjectAnnotation(I,'Rectangle',results.Boxes{1},'Bird',...
    'LineWidth',1);

figure('pos',[50,50,size(I,2),size(I,1)]);
hold on, axes('pos',[0 0 1 1])
imshow(I)