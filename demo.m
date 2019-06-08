clear;
%% read pictures
% change directory here to test on different datasets 
directory = 'halfdome/';
files = dir(directory);
files = files(3:end);

%% shuffle
randIndex = randperm(numel(files));
files = files(randIndex);

%% preprocess
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
order_list = get_order_list(dataset)
panorama = mymosaic(dataset, order_list);
imshow(panorama);
imwrite(panorama,'panorama.png');
