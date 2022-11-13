function [x,y,w,h,mask,thr]  = find_island(im, strel_size)
gr1 = rgb2gray(im);
thr = grey_threshold(imhist(gr1, 256));
gr2 = histeq(gr1);
bwim1 = imbinarize(gr1,thr/255); % ** Possibly tuned?

bwim2 = imbinarize(gr2,0.2); % **

% se = strel('disk',strel_size, 0); % **

% 
k = strel_size;
eta = 0.85;
h = round(k*eta);
x = 1:2*k;
y = (-(x - k).^2 + k^2)./k^2*h;
se = zeros(h, 2*k);
ind = h:-1:1;
for i = 1:2*k
   se(ind < y(i), i) = 1; 
end

grey_combined = 0.5*bwim1+0.5*bwim2;%imclose(bwim,se);
%imshow(imbinarize(grey_combined))
%pause(0.1)
bw_combined = imclose(imbinarize(grey_combined),se);
% imshow(bw_combined)
% pause(0.3)
cc = bwconncomp(1-bw_combined);
s = regionprops(cc,'Centroid','Area','BoundingBox');

% % ----- Tuning help
% figure
% indim = uint8(zeros(size(bw_combined)));
% for i = 1:numel(s)
%     indim(cc.PixelIdxList{i}) = i;
% end
% cmap = rand(numel(s),3);
% imrgb = ind2rgb(indim,cmap);
% imshow(uint8((double(im)+255*double(imrgb))/2))
% title(numel(s))
% drawnow
% % -----

% Find the largest connected component closest to the middle of the image.
% That would be the island.
Centroids = [];
BBs = [];
Areas = [];

if ~isempty(s)
    for k = 1:numel(s)
        BBs = [BBs;s(k).BoundingBox];
        Areas = [Areas;s(k).Area];
        Centroids = [Centroids;s(k).Centroid];
    end
    [SortedA,index] = sort(Areas,'descend');
    mid_image = [size(im,2)/2,size(im,1)/2];


    SortedC = Centroids(index,:);
    z = abs(SortedC(:,2)-mid_image(2));
    idx = find(z < 0.35*size(im,1));

    if isempty(idx) || SortedA(idx(1)) > ...
            size(im,1)*size(im,2)*.3
        % no island found
        disp('No island!')
        [x,y,w,h,mask] = deal([]);
    else
        z = BBs(index(idx(1)),:);
        x = z(1); y = z(2); w = z(3); h = z(4);
        mask = cc.PixelIdxList{index(idx(1))};
    end

    % % ----- Tuning help
    %     % -----
    %     figure
    %     indim = uint8(zeros(size(bw_combined)));
    %     indim(mask) = 1;
    %     cmap = [0,0,0;0,0,1];
    %     imrgb = ind2rgb(indim,cmap);
    %     imshow(uint8((double(im)+255*double(imrgb))/2))
    %     title(numel(s))
    %     % -----

else
    disp('No island!')
    [x,y,w,h,mask] = deal([]);
end

