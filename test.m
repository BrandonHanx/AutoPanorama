clear;
%% read and preprocess pictures
% change directory here to test on different datasets 
directory = 'building/';
files = dir(directory);
files = files(3:end);

% randIndex = randperm(numel(files));
% files = files(randIndex);

N = numel(files);
dataset = {};
cnt = 1;
for i = 1:N
    if files(i).name(1) ~= '.'
        im = imread(strcat(directory,files(i).name));
        im = double(imrotate(imresize(im, [480, 640]), 0))/255;
        dataset{cnt} = im;
%         imshow(im);
        drawnow;
        cnt = cnt + 1;
    end
end
% save('dataset2.mat', 'dataset');

%% load dataset and run
% img_m = mymosaic(dataset, 4);
% imshow(img_m);

level_matrix = get_level_matrix(dataset)