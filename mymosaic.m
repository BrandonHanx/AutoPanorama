function [img_mosaic] = mymosaic(img_input, base_img_id)
    if size(img_input) == 1
        img_mosaic = img_input{1};
        return
    end

    % by default I use the second image as the starting point
    BASE_IMG = 2;
    if nargin > 1
        BASE_IMG = base_img_id;
    end

    img_b = img_input{BASE_IMG};

    % stitch images from BASE_IMG - 1 to 1 to img_b
    for i = BASE_IMG-1:-1:1
        img_i = img_input{i};
        img_b = stitch(img_i, img_b);
    end

    % stitch images from BASE_IMG + 1 to end to img_b
    for i = BASE_IMG+1:numel(img_input)
        img_i = img_input{i};
        img_b = stitch(img_i, img_b);
    end

    img_mosaic = img_b;
end

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

% stitch img_i to img_b and return the mosaic all together
function [img_b] = stitch(img_i, img_b)

    [boxFeatures, boxPoints] = get_features(img_i);
    [sceneFeatures, scenePoints] = get_features(img_b);

    boxPairs = matchFeatures(boxFeatures, sceneFeatures);
    matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
    matchedScenePoints = scenePoints(boxPairs(:, 2), :);

    x_i = matchedBoxPoints.Location(:,1);
    y_i = matchedBoxPoints.Location(:,2);
    x_b = matchedScenePoints.Location(:,1);
    y_b = matchedScenePoints.Location(:,2);

    % reject outliers     
    [H, inlier_ind] = ransac_est_homography(x_i, y_i, x_b, y_b, 10);

    img_b = map_pairs(H, img_i, img_b);

end
