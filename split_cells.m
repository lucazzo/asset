function all_pts = split_cells(mymovie, opts)

  [nframes, imgsize] = size_data(mymovie.dic);
  all_pts = cell(nframes, 4);

  %c = [3 6 7 8 19 26 31 35 45 60 63 67 69 70 75 78 81];
  %nframes = length(c);

  for n=1:nframes
    %nimg = randi(nframes, 1);
    nimg = n;
    %nimg = 23
    %nimg = c(n);

    angle_thresh = pi/20;

    img = imnorm(double(load_data(mymovie.dic,nimg)));

    max_ratio = 2;

    npixels = max(size(img));
    size10 = round(npixels/10);
    size75 = round(npixels/75);
    size150 = round(npixels/150);
    size100 = round(prod(size(img)) / 100);

    img = imadm_mex(img);

    thresh = graythresh(img);
    edg1 = (img > thresh*0.5*(max(img(:))) );

    edg1 = increase_canevas(edg1, size10);

    edg1 = imdilate(edg1, strel('disk', size150));
    edg1 = imfill(edg1, 'holes');
    edg1 = bwareaopen(edg1, size100);
    edg1 = imdilate(edg1, strel('disk', size75));
    edg1 = imfill(edg1, 'holes');
    edg1 = imerode(edg1, strel('disk', size75 + size150));

    edg1 = reduce_canevas(edg1, size10);

    if(~any(any(edg1)))
      beep;keyboard
      error('No embryo detected !!');
    end

    estim = bwboundaries(edg1, 8, 'noholes');
    %figure;imshow(img);
    %hold on;

    for i=1:length(estim)
      tmp_estim = estim{i};
      tmp_estim = tmp_estim(:,[2 1]);

      [pac, indxs] = impac(tmp_estim);

      imgsize = size(img);
      imgsize = imgsize([2 1]);
      borders = (any(tmp_estim == 2 | bsxfun(@eq, tmp_estim, imgsize-1), 2));
      border_indx = find(xor(borders, borders([2:end 1])));

      concaves = compute_concavity(pac, angle_thresh);

      [indxs, indx_indx] = sort([indxs; border_indx]);
      concaves = [concaves; true(size(border_indx))];
      concaves = concaves(indx_indx);

      ellipses = fit_segments(tmp_estim, indxs(concaves), borders, max_ratio);
      ratio = ellipses(:, 3) ./ ellipses(:, 4);

      ellipses = ellipses(ratio < max_ratio, :);

      %imshow(img);
      %hold on
      %myplot(tmp_estim);
      %scatter(tmp_estim(borders, 1), tmp_estim(borders, 2), 'g');
      %scatter(tmp_estim(indxs, 1), tmp_estim(indxs, 2), 'r');
      %scatter(tmp_estim(indxs(concaves), 1), tmp_estim(indxs(concaves), 2), 'y');

      %for j = 1:size(ellipses, 1)
      %  draw_ellipse(ellipses(j, 1:2), ellipses(j, 3:4), ellipses(j, 5));
      %end
      %title(num2str(nimg));
      %hold off

      if (i == 1)
        all_pts{n, 1} = ellipses;
        all_pts{n, 2} = tmp_estim;
        all_pts{n, 3} = indxs;
        all_pts{n, 4} = concaves;
      else
        all_pts{n, 1} = [all_pts{n, 1}; ellipses];
        all_pts{n, 2} = [all_pts{n, 2}; tmp_estim];
        all_pts{n, 3} = [all_pts{n, 3}; indxs];
        all_pts{n, 4} = [all_pts{n, 4}; concaves];
      end
    end

    %pause
    %keyboard
  end

  return;
end

function ellipses = fit_segments(pts, junctions, is_border, max_ratio)

  nsegments = length(junctions);
  ellipses = NaN(nsegments, 5);
  npts = size(pts, 1);
  segments = cell(nsegments, 1);
  scores = Inf(nsegments, 1);

  for i=1:nsegments

    if (i == nsegments)
      index = [junctions(i):npts 1:junctions(1)];
    else
      index = [junctions(i):junctions(i+1)];
    end
    tmp = pts(index, :);
    tmp_border = is_border(index);
    tmp = tmp(~tmp_border, :);

    segments{i} = tmp;

    if (isempty(tmp))
      continue;
    end

    [ellipse, dist, avg, stds] = fit_distance(tmp);
    if ((ellipse(3) / ellipse(4)) < 3*max_ratio)
      ellipses(i,:) = ellipse;
      scores(i) = avg;
    else
      segments{i} = [];
    end
  end

  %keyboard

  ellipses = combine_ellipses(segments, ellipses, scores, max_ratio);
  ellipses = ellipses(~any(isnan(ellipses), 2), :);

  return;
end

function ellipses = combine_ellipses(segments, ellipses, scores, max_ratio)
  
  nsegments = length(segments);
  improved = false;
  new_scores = scores;
  new_ellipses = ellipses;

  for i=1:nsegments
    if (isinf(scores(i)))
      continue
    end
    new_scores(:) = Inf;
    for j=i+1:nsegments
      if (isinf(scores(j)))
        continue
      end
      [ellipse, dist, avg, stds] = fit_distance([segments{i}; segments{j}]);
      %if (avg <= min(scores([i j])) + ((scores(i)+scores(j))/4))
      %  improved(i) = true;
      %  segments{i} = [segments{i}; segments{j}];
      %  segments{j} = [];
      %  scores(i) = avg;
      %  scores(j) = Inf;
      %  ellipses(j, :) = NaN;
      %  ellipses(i, :) = ellipse;
      %end
      new_scores(j) = avg;
      new_ellipses(j,:) = ellipse;
      %new_scores(j,i) = ellipse(3) / ellipse(4);
    end

    new_scores(new_scores > min(scores(i), scores) + ((scores(i)+scores)/5)) = Inf;
    new_scores(~((new_ellipses(:,3) ./ new_ellipses(:,4)) < max_ratio)) = Inf;
    [a, indx] = min(new_scores);
    if (~isinf(a))
        segments{i} = [segments{i}; segments{indx}];
        segments{indx} = [];
        scores(i) = avg;
        scores(indx) = Inf;
        ellipses(indx, :) = NaN;
        ellipses(i, :) = new_ellipses(indx,:);
        improved = true;
    end
  end

  if (improved)
    ellipses = combine_ellipses(segments, ellipses, scores, max_ratio);
  end

  return;
end

function [ellipse, dist, avg, stds] = fit_distance(pts)

  ellipse = NaN(1, 5);

  [c, a, o] = fit_ellipse(pts);
  ell_pts = carth2elliptic(pts, c, a, o);

  dist = abs(ell_pts(:,2) - 1);

  thresh = 4*std(dist);
  pts = pts(dist < thresh, :);

  if (isempty(pts))
    dist = [];
    avg = Inf;
    stds = Inf;

    return;
  end

  [c, a, o] = fit_ellipse(pts);
  ellipse = [c.' a.' o];
  ell_pts = carth2elliptic(pts, c, a, o);

  dist = abs(ell_pts(:,2) - 1);
  avg = mean(dist);
  stds = std(dist);

  return;
end

function conc = compute_concavity(pts, thresh)

  npts = size(pts, 1);
  conc = false(npts, 1);

  if (npts == 0)
    return;
  end

  pts = pts([end 1:end 1], :);

  for i=1:npts
    angle_prev = atan2(-(pts(i+1, 2) - pts(i, 2)), pts(i+1,1) - pts(i, 1));
    angle_next = atan2(-(pts(i+2, 2) - pts(i+1, 2)), pts(i+2,1) - pts(i+1, 1));
    angle = pi - (angle_next - angle_prev);

    if (angle > 2*pi)
      angle = angle - 2*pi;
    elseif (angle < 0)
      angle = angle + 2*pi;
    end

    interm = (pts(i+2, :) + pts(i, :)) / 2;
    greater_x = pts(1:end-1, 1) > interm(1, 1);

    indx = find(xor(greater_x(1:end-1), greater_x(2:end)));
    intersection = ((pts(indx+1, 2) - pts(indx, 2)) ./ (pts(indx+1, 1) - pts(indx, 1))) .* (interm(1, 1) - pts(indx, 1)) + pts(indx, 2);

    ninter = sum(intersection >= interm(1, 2), 1);

    if (mod(ninter, 2) == 0 & angle <= (pi - thresh) & angle >= thresh)
      conc(i) = true;
    end
  end

  if (sum(conc) == 1)
    indx = find(conc);
    half = round(npts/2);

    if (indx > half)
      conc(indx - half) = true;
    else
      conc(indx + half) = true;
    end
  end

  return;
end

%***********************************************************
function resized = increase_canevas(img, new_size)

  [h,w] = size(img);
  
  resized =  zeros(h+(2*new_size), w+(2*new_size));

  if (islogical(img))
    resized = logical(resized);
  end

  resized((new_size+1):(new_size+h),(new_size+1):(new_size+w)) = img;
  
  return;
end

%***********************************************************
function resized = reduce_canevas(img, new_size)

  [h,w] = size(img);
  
  resized =  img((new_size+1):(h-new_size), (new_size+1):(w-new_size));

  return;
end