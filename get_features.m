function [features, points] = get_features(img)
    if ndims(img) == 3
        gray_img = rgb2gray(img);
    else 
        gray_img = img;
    end
    points = detectSURFFeatures(gray_img);        
    [features, points] = extractFeatures(gray_img, points);
end