function [H, inlier_ind] = ransac_est_homography(x1, y1, x2, y2, thresh)
    N = numel(x1);
    max_inliers = zeros(N, 1);
    H = eye(3);
    ssd = @(x, y) sum((x-y).^2);
    for t = 1:1000
        inliers = zeros(N, 1);
        r_idx = randi([1, N], 4, 1);
        H_t = est_homography(x2(r_idx),y2(r_idx),x1(r_idx),y1(r_idx));
        for i = 1:N
            t_xy = H_t*[x1(i), y1(i), 1]';
            t_xy = t_xy/t_xy(end);

            if ssd([x2(i), y2(i), 1]', t_xy) < thresh
                inliers(i) = 1;
            end
        end
        if sum(inliers) > sum(max_inliers)
            max_inliers = inliers;
            H = H_t;
        end
    end
    inlier_ind = find(max_inliers);
end

% Compute the homography matrix from source(x,y) to destination(X,Y)
function H = est_homography(X,Y,x,y)
    A = zeros(length(x(:))*2,9);

    for i = 1:length(x(:))
     a = [x(i),y(i),1];
     b = [0 0 0];
     c = [X(i);Y(i)];
     d = -c*a;
     A((i-1)*2+1:(i-1)*2+2,1:9) = [[a b;b a] d];
    end

    [~, ~, V] = svd(A);
    h = V(:,9);
    H = reshape(h,3,3)';
end