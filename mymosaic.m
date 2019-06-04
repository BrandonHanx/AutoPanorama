function [img_mosaic] = mymosaic(img_input, base_img_id)
    if size(img_input) == 1
        img_mosaic = img_input{1};
    end

    % by default I use the second image as the starting point
    BASE_IMG = 2;
    if nargin > 1
        BASE_IMG = base_img_id;
    end

    img_b = img_input{BASE_IMG};

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
        hei_i = size(img_i,1);
        wid_i = size(img_i,2);
        hei_b = size(img_b,1);
        wid_b = size(img_b,2);

        boxImage = rgb2gray(img_i);
        sceneImage = rgb2gray(img_b);
        boxPoints = detectSURFFeatures(boxImage);
        scenePoints = detectSURFFeatures(sceneImage);
        
        [boxFeatures, boxPoints] = extractFeatures(boxImage, boxPoints);
        [sceneFeatures, scenePoints] = extractFeatures(sceneImage, scenePoints);
        
        boxPairs = matchFeatures(boxFeatures, sceneFeatures);
        
        matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
        matchedScenePoints = scenePoints(boxPairs(:, 2), :);
        
        x_i = matchedBoxPoints.Location(:,1);
        y_i = matchedBoxPoints.Location(:,2);
        x_b = matchedScenePoints.Location(:,1);
        y_b = matchedScenePoints.Location(:,2);
        

        % reject outliers     
        [H, inlier_ind] = ransac_est_homography(x_i, y_i, x_b, y_b, 10);

        % compute d2b
        img_i_dist = dist2border(img_i);
        img_b_dist = dist2border(img_b);

        % mapped coordinates of upperleft, upperright, bottomleft, bottomright
        % for img_i
        ul = H*[1 1 1]'; ul = ul/ul(end);
        ur = H*[wid_i, 1, 1]'; ur = ur/ur(end);
        bl = H*[1, hei_i, 1]'; bl = bl/bl(end);
        br = H*[wid_i, hei_i, 1]'; br = br/br(end);
        tic

        % find out how much padding we need to make
        pad_up = 0; % update pad_up and pad_left inorder to do an offset mapping 
        pad_left = 0;
        pad_down = 0;
        pad_right = 0;
        if max(br(1),ur(1)) > wid_b
            pad_right = round(max(br(1),ur(1))-wid_b+30);
            img_b = padarray(img_b, [0, pad_right], 'post');
        end
        if max(br(2), bl(2)) > hei_b
            pad_down = round(max(br(2), bl(2))-hei_b+30);
            img_b = padarray(img_b, [pad_down, 0], 'post');
        end
        if min(ul(1), bl(1)) <= 0 
            pad_left = round(-min(ul(1), bl(1))+30);
            img_b = padarray(img_b, [0, pad_left], 'pre');
        end
        if min(ul(2), ur(2)) <= 0
            pad_up = round(-min(ul(2), ur(2)) + 30);
            img_b = padarray(img_b, [pad_up, 0], 'pre');
        end
        H_inv = inv(H);


        % - Mapping coordinates from img_b to img_i to retrieve pixels
        % - Implemented distance to border blending
        % - Vecterized

        [y_b, x_b] = meshgrid(round(pad_up+min(ul(2), ur(2))):round(pad_up+max(bl(2), br(2))), ...
            round(pad_left+min(ul(1), bl(1))):round(pad_left+max(br(1),ur(1))));
        y_b = y_b(:); x_b = x_b(:);
        xy = H_inv*[x_b - pad_left, y_b - pad_up, ones(size(x_b,1),1)]';
        x_i = int64(xy(1,:)'./xy(3,:)'); y_i = int64(xy(2,:)'./xy(3,:)');

        % Blend img_b and img_i pixels according to dist to boundary
        % Only the coordinates that are possible to map to img_i are considerred.
        indices = x_i > 0 & x_i <= size(img_i, 2) & y_i > 0 & y_i <= size(img_i, 1) & y_b-pad_up > 0 & y_b - pad_up <= size(img_b_dist,1) & x_b - pad_left > 0 & x_b - pad_left <= size(img_b_dist,2);
        idx_i = (x_i(indices)-1)*size(img_i_dist,1) + y_i(indices);
        idx_b = (x_b(indices)-pad_left-1)*size(img_b_dist,1) + y_b(indices)-pad_up;
        p = img_i_dist(idx_i)./(img_i_dist(idx_i) + img_b_dist(idx_b));
        p(isnan(p)) = 0;
        % map rgb channels
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices)) = p.*img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices)) + ... 
            (1-p).*img_b((x_b(indices)-1)*size(img_b,1) + y_b(indices));
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices) + size(img_b,1)*size(img_b,2) ) = p.*img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices) + size(img_i,1)*size(img_i,2)) + ... 
            (1-p).*img_b((x_b(indices)-1)*size(img_b,1) + y_b(indices) + size(img_b,1)*size(img_b,2));
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices) + size(img_b,1)*size(img_b,2)*2 ) = p.*img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices) + size(img_i,1)*size(img_i,2)*2) + ... 
            (1-p).*img_b((x_b(indices)-1)*size(img_b,1) + y_b(indices) + size(img_b,1)*size(img_b,2)*2);

        % if it goes beyond border of img_b, just copy back the pixels from img_i
        indices = x_i > 0 & x_i <= size(img_i, 2) & y_i > 0 & y_i <= size(img_i, 1) & (y_b-pad_up <= 0 | y_b - pad_up > size(img_b_dist,1) | x_b - pad_left <= 0 | x_b - pad_left > size(img_b_dist,2));
        % rgb channels
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices)) = img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices));
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices) + size(img_b,1)*size(img_b,2) ) = img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices) + size(img_i,1)*size(img_i,2));
        img_b((x_b(indices)-1)*size(img_b,1)+y_b(indices) + size(img_b,1)*size(img_b,2)*2 ) = img_i((x_i(indices)-1)*size(img_i,1) + y_i(indices) + size(img_i,1)*size(img_i,2)*2);
    end

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



% function [panorama] = mymosaic2(img_input, base_img_id)
%     
%     if size(img_input) == 1
%         panorama = img_input{1};
%     end
% 
%     if base_img_id > 1
%         tempt = img_input{1};
%         img_input{1} = img_input{base_img_id};
%         img_input{base_img_id} = tempt;
%     end
% 
%     I = img_input{1};
%     
%     % Initialize features for I(1)
%     grayImage = rgb2gray(I);
%     points = detectSURFFeatures(grayImage);
%     [features, points] = extractFeatures(grayImage, points);
% 
%     % Initialize all the transforms to the identity matrix. Note that the
%     % projective transform is used here because the building images are fairly
%     % close to the camera. Had the scene been captured from a further distance,
%     % an affine transform would suffice.
%     numImages = numel(img_input);
%     tforms(numImages) = projective2d(eye(3));
% 
%     % Initialize variable to hold image sizes.
%     imageSize = zeros(numImages,2);
% 
%     % Iterate over remaining image pairs
%     for n = 2:numImages
% 
%         % Store points and features for I(n-1).
%         pointsPrevious = points;
%         featuresPrevious = features;
% 
%         % Read I(n).
%         I = img_input{n};
% 
%         % Convert image to grayscale.
%         grayImage = rgb2gray(I);
% 
%         % Save image size.
%         imageSize(n,:) = size(grayImage);
% 
%         % Detect and extract SURF features for I(n).
%         points = detectSURFFeatures(grayImage);
%         [features, points] = extractFeatures(grayImage, points);
% 
%         % Find correspondences between I(n) and I(n-1).
%         indexPairs = matchFeatures(features, featuresPrevious, 'Unique', true);
% 
%         matchedPoints = points(indexPairs(:,1), :);
%         matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);
% 
%         % Estimate the transformation between I(n) and I(n-1).
%         tforms(n) = estimateGeometricTransform(matchedPoints, matchedPointsPrev,...
%             'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
% 
%         % Compute T(n) * T(n-1) * ... * T(1)
%         tforms(n).T = tforms(n).T * tforms(n-1).T;
%     end
% 
%     % Compute the output limits  for each transform
%     for i = 1:numel(tforms)
%         [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);
%     end
% 
%     avgXLim = mean(xlim, 2);
%     [~, idx] = sort(avgXLim);
%     centerIdx = floor((numel(tforms)+1)/2);
%     centerImageIdx = idx(centerIdx);
%     Tinv = invert(tforms(centerImageIdx));
%     for i = 1:numel(tforms)
%         tforms(i).T = tforms(i).T * Tinv.T;
%     end
% 
%     for i = 1:numel(tforms)
%         [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);
%     end
% 
%     maxImageSize = max(imageSize);
% 
%     % Find the minimum and maximum output limits
%     xMin = min([1; xlim(:)]);
%     xMax = max([maxImageSize(2); xlim(:)]);
% 
%     yMin = min([1; ylim(:)]);
%     yMax = max([maxImageSize(1); ylim(:)]);
% 
%     % Width and height of panorama.
%     width  = round(xMax - xMin);
%     height = round(yMax - yMin);
% 
%     % Initialize the "empty" panorama.
%     panorama = zeros([height width 3], 'like', I);
% 
%     blender = vision.AlphaBlender('Operation', 'Binary mask', ...
%         'MaskSource', 'Input port');
% 
%     % Create a 2-D spatial reference object defining the size of the panorama.
%     xLimits = [xMin xMax];
%     yLimits = [yMin yMax];
%     panoramaView = imref2d([height width], xLimits, yLimits);
% 
%     % Create the panorama.
%     for i = 1:numImages
%         
%         I = img_input{i};
% 
%         % Transform I into the panorama.
%         warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
% 
%         % Generate a binary mask.
%         mask = imwarp(true(size(I,1),size(I,2)), tforms(i), 'OutputView', panoramaView);
% 
%         % Overlay the warpedImage onto the panorama.
%         panorama = step(blender, panorama, warpedImage, mask);
%     end
% 
% end