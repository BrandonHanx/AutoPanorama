function [img_b] = mymosaic(img_input, order_list)

    N = numel(img_input);
    fprintf('Image %d is selected as the initial image...\n',order_list(1));
    img_b = img_input{order_list(1)};
    
    % stitch images according to order_list
    for i = 2:1:N
        fprintf('Image %d is blending to the panorama...\n',order_list(i));
        img_i = img_input{order_list(i)};
        img_b = stitch(img_i, img_b);
    end
    fprintf('Done!\n');
end

% stitch img_i to img_b and return the mosaic all together
function [img_b] = stitch(img_i, img_b)

    [features_i, points_i] = get_features(img_i);
    [features_b, points_b] = get_features(img_b);

    pairs = matchFeatures(features_i, features_b);
    matchedBoxPoints = points_i(pairs(:, 1), :);
    matchedScenePoints = points_b(pairs(:, 2), :);

    x_i = matchedBoxPoints.Location(:,1);
    y_i = matchedBoxPoints.Location(:,2);
    x_b = matchedScenePoints.Location(:,1);
    y_b = matchedScenePoints.Location(:,2);

    % reject outliers     
    [H, ~] = ransac_est_homography(x_i, y_i, x_b, y_b, 10);

    img_b = map_pairs(H, img_i, img_b);

end