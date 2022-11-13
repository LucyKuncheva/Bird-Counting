function S = count_birds_penmon(im,P)

if nargin == 1
    strel_size = 20;
    crop_extension = 0.35;
else
    strel_size = P.strel_size; % strel size for detecting the island
    crop_extension = P.crop_extension; % proportion of the height of
    % the bounding box for
    % cropping the island _with_
    % birds left in
end

% Find the island
[x,y,w,h,mask,thr] = find_island(im,strel_size);

S.island_bb = [x,y,w,h]; % <<<
S.island_mask = mask; % <<<
S.island_threshold = thr; % <<<

if ~isempty(x) % island is found

    ext = crop_extension * h;
    to_crop = [x,y-ext,w,h+ext];
    cropped_image = imcrop(im,to_crop);
    S.to_crop = to_crop;
    S.cropped_image = cropped_image; % <<<

    % Find the top and the bottom edges of the image
    [top_edge, bottom_edge, my_u] = find_island_contour(im,mask);
    top_edge = top_edge - to_crop(2);
    bottom_edge = bottom_edge - to_crop(2);
    my_u = round(my_u - to_crop(1)); % index of top/bottom edge
    % with respect to the cropped image
    S.top_edge = top_edge; % <<<
    S.bottom_edge = bottom_edge; % <<<
    S.my_u = my_u; % <<<

    % Find the birds
    [bw_birds, Data, bthr] = find_birds(im,to_crop,mask,top_edge,my_u);
    S.bird_areas = Data{1}; % <<<
    S.bird_centroids = Data{2}; % <<<
    S.bird_circularities = Data{3}; % <<<
    S.bird_count = size(Data{2},1); % <<<
    S.bw_birds = bw_birds; % <<<
    S.birds_threshold = bthr; % <<<
else    
    [S.bird_areas, S.bird_centroids,S.bird_circularities, ...
        S.bird_count, S.my_u] = deal([]); % <<<
    [S.top_edge, S.bottom_edge,S.to_crop,S.cropped_image] ...
        = deal([]); % <<<
    [S.bw_birds, S.birds_threshold] = deal([]); % <<< 
end
