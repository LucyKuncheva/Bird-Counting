clear, clc, close all
%..........................................................................
%..........................................................................
%..........................................................................
% =========================================================================
% L Kuncheva 13/11/2022

[filename,user_cancelled] = imgetfile; % choose an image
if ~user_cancelled
    im = imread(filename);

    % Count the birds ----------------------------
    P.strel_size = 30; % parameter
    P.crop_extension = 0.45; % parameter
    S = count_birds_penmon(im,P);

    nn = 0; % number of birds in the image
    if ~isempty(S.island_mask)
        nn = S.bird_count;
    end %-----------------------------------------
    show_birds_image(S,im)

    title(sprintf('detected birds = %i', nn),'FontSize',12)
end


% =========================================================================
function show_birds_image(S,im) %#ok<*DEFNU>
figure('Units','N','Position',[0.02,0.5,0.9,0.55])
if ~isempty(S.island_mask)

    % Show the island with a mask
    [rp, gp, bp] = deal(zeros(size(im,1),size(im,2)));
    gp(S.island_mask) = 255;
    new_mask = cat(3,rp,gp,bp);
    new_im_to_show = uint8(double(im)*0.8 + new_mask*0.2);
    new_im_to_show = imcrop(new_im_to_show,S.to_crop);
    imshow(new_im_to_show)
    hold on

    plot(S.my_u,S.top_edge,'b-','linewidth',2)
    plot(S.my_u,S.bottom_edge,'y-','linewidth',2)

    C = S.bird_centroids;
    if ~isempty(C)
        plot(C(:,1),C(:,2),'g.','MarkerSize',20)
    end
else
    imshow(im)
end

end
