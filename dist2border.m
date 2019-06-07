% generate distance to border map
function [img_dist] = dist2border(img)
    if size(img,3) > 1
        img = rgb2gray(img);
    end
    img_dist = (img == 0);
    img_dist(1:size(img,1), 1) = 1;
    img_dist(1:size(img,1), size(img,2)) = 1;
    img_dist(1, 1:size(img,2)) = 1;
    img_dist(size(img,1), 1:size(img,2)) = 1;
    img_dist = bwdist(img_dist, 'chessboard');
end