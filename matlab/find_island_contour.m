function [top_edge, bottom_edge, my_u] = ...
    find_island_contour(im,mask)

[rows,columns] = ind2sub([size(im,1),size(im,2)],mask(:));
top_edge = [];
bottom_edge = [];
u = unique(columns);
my_u = u; %[];
for i = 1:numel(u)
    k1 = rows(columns == u(i));
    top_edge = [top_edge,min(k1)];
    bottom_edge = [bottom_edge, max(k1)];
end

ws = 151; % window size for smoothing % ** Possibly tuned?
po = 3; % polynomial order
if numel(top_edge) > ws
    top_edge = sgolayfilt(top_edge,po,ws);
    bottom_edge = sgolayfilt(bottom_edge,po,ws);
end
