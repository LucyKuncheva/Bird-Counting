function [bw_birds, Data, thr]  = ...
    find_birds(im,to_crop,mask,top_edge,my_u)

% Block the island and crop
im = rgb2gray(im);
im(mask) = 255; %mean(im(:)); % Both work. An enesmble?
birds_grey = imcrop(im,to_crop);

thr = grey_threshold(imhist(birds_grey),0,31);

if thr < 50, thr = 65; end

bw_birds = imbinarize(birds_grey,thr/255);

cc = bwconncomp(1-bw_birds);
s = regionprops(cc,'Centroid','Area','Circularity');
Areas = [];
Centroids = [];
Circularities = [];
for k = 1:numel(s)
    Areas = [Areas;s(k).Area];
    Centroids = [Centroids;s(k).Centroid];
    Circularities = [Circularities; s(k).Circularity];
end
if ~isempty(Centroids)
    index_close = [];
    for k = 1:size(Centroids,1)
        where_bird = find(round(Centroids(k,1)) == my_u);
        if isempty(where_bird)
            index_close(k) = false;
        else
            above_island = Centroids(k,2) - top_edge(where_bird);
            index_close(k) = above_island < 0 & ...
                abs(above_island) < 30; % ** Possibly tuned?
        end
    end

    % Remove the "impossible" birds
    index = Circularities > 0.25 & Areas > 140 & ...
        Areas < 1800 & index_close(:);
    % ** Possibly tuned?
    
    Data = {Areas(index), Centroids(index,:), Circularities(index)};

else
    Data = {[],[],[]};
end


