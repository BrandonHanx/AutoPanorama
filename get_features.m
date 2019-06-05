function [features, points] = get_features(img)
    gray_img = rgb2gray(img);
    points = detectSURFFeatures(gray_img);        
    [features, points] = extractFeatures(gray_img, points);
end