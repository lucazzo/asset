function mymovie = reconstruct_egg(mymovie, opts)

  if (nargin == 1 & ischar(mymovie))

    fname = mymovie;
    tmp = dir(fname); 

    for i=1:length(tmp)
      name = tmp(i).name
      load(name);

      mymovie = reconstruct_egg(mymovie, opts);
      save(mymovie.experiment, 'mymovie', 'opts');
    end
    
    return;
  end

  [nframes, imgsize] = size_data(mymovie.dic);
  mymovie = parse_metadata(mymovie, opts);
  real_z = mymovie.metadata.z_position;

  pts = cell(nframes, 1);
  all_coords = zeros(0,3);
  %goods = true(nframes, 1);
  sharpness = zeros(nframes, 1);
  all_edges = cell(nframes, 1);

  if (true)
  for i=1:nframes
    tmp_pts = mymovie.dic.eggshell(i).carth;
    if (~isempty(tmp_pts))
      npts = size(tmp_pts, 1);

      img = imnorm(double(load_data(mymovie.dic, i)));
      img = imadm(img, 0, false);
      edges = perpendicular_sampling(img, tmp_pts, opts);
      edges = max(edges(:, 55:75), [], 2);

      sharpness(i) = median(edges);

      tmp_pts = tmp_pts * opts.pixel_size;
      pts{i} = tmp_pts;

      all_edges{i} = edges;
    %else
    %  goods(i) = false;
    end
  end
  save('z_fit.mat', 'sharpness', 'all_edges', 'pts');
  else
    load ('z_fit.mat')
  end

  if (isempty(mymovie.metadata.plane_index))
    mymovie.metadata.plane_index = ones(1, nframes);
  end
  if (isempty(mymovie.metadata.frame_index))
    mymovie.metadata.frame_index = [1:nframes];
  end

  for i=1:length(pts)
    if (~isempty(pts{i}))
      if (~isempty(real_z))
        pts{i} = [pts{i} ones(size(pts{i}, 1), 1)*real_z(1, i) ones(size(all_edges{i}))*i all_edges{i}];
      else
        pts{i} = [pts{i} zeros(size(pts{i}, 1), 1) ones(size(all_edges{i}))*i all_edges{i}];
      end
    end
  end

  frames = mymovie.metadata.frame_index(1,:);
  time_points = unique(frames);
  ntimes = length(time_points);
  centers = NaN(3, ntimes);
  axes_length = NaN(3, ntimes);
  orient = NaN(1, ntimes);
  all_pts = cell(ntimes, 1);

  for i=1:ntimes
    currents = (frames == time_points(i));

    if (sum(currents) > 3)
      [centers(:, i), axes_length(:, i), orient(1, i), all_pts{i, 1}] = fit_absolute_ellipse(pts(currents));
    else
      centers(1:2, i) = mean(mymovie.dic.centers(:, currents) * opts.pixel_size, 2);
      axes_length(1:2, i) = mean(mymovie.dic.axes_length(:, currents) * opts.pixel_size, 2);
      orient(1, i) = mean(mymovie.dic.orientations(1, currents), 2);
      all_pts{i} = cat(1, pts{currents});
      centers(3,i) = mymean(all_pts{i}(:,3));
    end
  end

  if (any(~isnan(axes_length(3, :))))
    axes_length = mymean(axes_length, 2);
  else
    mid_plane = folded_distribution(axes_length, sharpness, 2);
    z_coefs = get_struct('z-correlation');
    z_size = z_coefs.bkg + z_coefs.long_axis * mid_plane(1) + z_coefs.short_axis * mid_plane(2);

    axes_length = [mid_plane(1:2,1); z_size];
  end

  orient = align_orientations(orient);
  centers(3,isnan(centers(3,:))) = 0;
  [axes_length, relative_z] = fit_relative_ellipse(all_pts, centers, axes_length, orient);

  centers = centers(:, frames);
  orient = orient(1, frames);
  relative_z = relative_position(pts, relative_z, centers, axes_length, orient);

  mymovie.metadata.center_3d = centers;
  mymovie.metadata.axes_length_3d = axes_length;
  mymovie.metadata.orientation_3d = orient;
  mymovie.metadata.relative_z = relative_z;
  
  return;
end

function [relative_z] = relative_position(pts, z, centers, axes_length, orient)

  nframes = length(pts);
  relative_z = NaN(1, nframes);

  for i=1:nframes
    if (isnan(z(i)) & ~isempty(pts{i}))

      ell_coords = carth2elliptic(pts{i}(:, 1:2), centers(1:2, i), axes_length(1:2), orient(i), 'radial');
      dist = mymean(ell_coords(:,2));
      z_pos = axes_length(3)*sqrt(1 - dist.^2);

      if (imag(z_pos))
        hold off;
        plot(pts{i}(:,1), pts{i}(:,2))
        hold on;
        draw_ellipse(centers(1:2, i), axes_length(1:2), orient(i));

        keyboard
      else
        relative_z(i) = z_pos;
      end
      %relative_z(i) = real(z_pos);  
    else
      relative_z(i) = z(i);
    end
  end

  return;
end

function [axes_length, relative_z, all_coords] = fit_relative_ellipse(pts, centers, axes_length, orient)

  all_coords = NaN(0, size(pts{1}, 2)+1);
  max_iter = 500;

  neggs = length(pts);
  for i=1:neggs
    all_coords = [all_coords; [realign(pts{i}(:,1:2), [0;0], centers(1:2, i), orient(i)) pts{i}(:,3)-centers(3,i) pts{i}(:,4:5) ones(size(pts{i}(:,4)))*i]];
  end

  indxs = unique(all_coords(:,6));
  tmp_z = NaN(1, neggs);
  npts = size(all_coords, 1);

  %%% TRY FULL FIT USING SHARPNESS AS WEIGHT FOR ERROR & PLANE ELIMINATION,
  %%% CAN PENALIZE FOR TOO FEW AND SUCH

  [axes_length, relative_z] = fit_full(all_coords, axes_length);

  return;

  for i=1:max_iter
    prev = indxs;

    [a, z, errs(1, i), p, indxs] = filter_frames(all_coords, axes_length, indxs);
    errs(1,i) = errs(1,i) + (1 - size(p,1)/npts);

    if ((i>1 & errs(i) > errs(i-1)) | (i>2 & (errs(i-2) - errs(i-1) > errs(i - 1) - errs(i))))
      break;
    else
      axes_length = a;
      relative_z = tmp_z;
      
      relative_z(indxs) = z;
    end

    if (isempty(indxs) | numel(indxs) == numel(prev))
      break;
    end

    all_coords = p;
  end
 
  return;
end

function [fit_axes, rel_z] = fit_full(all_coords, axes_length)

  %keyboard

  pts = all_coords(:,1:3);
  npts = size(pts, 1);
  frames = unique(all_coords(:,6));
  nframes = length(frames);
  indexes = all_coords(:,6);
  sharpness = imnorm(all_coords(:,5));
  %[indxs, i, j] = unique(all_coords(:, [4 6]), 'rows');
  %[tmp, k, l] = unique(indxs(:,2));
  %neggs = size(indxs, 1);
  %errs = ones(neggs, 1);

  all_errs = ones(nframes, 1);
  dist = NaN(nframes, 1);

  weights = NaN(size(sharpness));
  currents = false(npts, nframes);
  for i=1:nframes
    currents(:,i) = (indexes == frames(i));
    weights(currents(:,i)) = sharpness(currents(:,i)) / sum(sharpness(currents(:,i)));
  end

  z_coefs = get_struct('z-correlation');
  w = 1;

  %figure;hold on;

  %optims = optimset('Display', 'off');
  lbound = [0;0;0];
  ubound = [Inf(3,1)];
  optims = optimset('Display', 'off', 'Algorithm', 'levenberg-marquardt', 'TolFun', 1e-10, 'TolX', 1e-10);

  %bests = lsqcurvefit(@fit_z, p0, all_coords, zeros(neggs, 1), [], [], optims);
  p0 = sqrt(axes_length(1:2)*1.125);
  bests = lsqnonlin(@fit_z, p0, [], [], optims);

  bests = bests.^2;
  if (bests(1) < bests(2))
    [bests(1), bests(2)] = deal(bests(2), bests(1));
  end

  bests(3) = z_coefs.bkg + z_coefs.long_axis * bests(1) + z_coefs.short_axis * bests(2);

  fit_axes = bests(1:3);

  [errs, rel_z] = fit_z(sqrt(fit_axes));
  errs = errs(:);

  keyboard

  return;

  %function [z_err, z_pos] = fit_z(ax, pts)  
  function [z_err, z_pos] = fit_z(ax)  

    ax = ax.^2;

    if (ax(1) < ax(2))
      [ax(1), ax(2)] = deal(ax(2), ax(1));
    end

    z_pred = z_coefs.bkg + z_coefs.long_axis * ax(1) + z_coefs.short_axis * ax(2);
    ax(3) = z_pred;

    z_err = all_errs;
    z_pos = dist;
    z_std = dist;

    if (ax(3) < 0)
      z_err = 10;

      return;
    end

    ell_coords = carth2elliptic(pts(:, 1:2), [0;0], ax(1:2), 0, 'radial');
    for i=1:nframes
      z_dist = sum(ell_coords(currents(:,i), 2) .* weights(currents(:,i)) .* sign(pts(currents(:,i), 3) + 1e-10));

      if (z_dist > 1)
        z_err(i) = mean(sharpness(currents(:,i)));
      else
        z_err(i) = sum(abs(ell_coords(currents(:, i), 2) - z_dist) .* weights(currents(:,i)));
        z_std(i) = sqrt(sum(((ell_coords(currents(:,i), 2) - z_dist).^2) .* weights(currents(:,i))));
        z_pos(i) = ax(3)*sqrt(1 - z_dist^2) .* sign(z_dist);
      end

      %z_coef = sqrt(1 - (z_pos^2) / (ax(3)^2));
    end

    if (all(isnan(z_pos)))
      z_err = 10;

      return;
    end

    bads = (z_err > mean(z_err) + mymean(z_std));

    if (any(bads))
      z_pos(bads) = NaN;

      all_bads = ismember(indexes, frames(bads));

      z_err(bads) = z_err(bads) .* mymean(sharpness(all_bads), 1, indexes(all_bads));
    end

    %[mean(z_err), 2*(sum(isnan(z_pos))/nframes), mymean(abs(z_pos))/ax(3)]
    z_err = mean(z_err) + 2*(sum(isnan(z_pos))/nframes) + mymean(abs(z_pos))/ax(3);
    
    return;
  end
end


function [fit_axes, rel_z, err, all_coords, indxs] = filter_frames(all_coords, axes_length, indxs)

  neggs = length(indxs);

  all_coords(:,5) = imnorm(all_coords(:,5));
  val_thresh = graythresh(all_coords(:,5));

  goods = (all_coords(:,5) >= val_thresh);
  goods = filter_goods(goods, 15);

  for i=1:neggs
    current = (all_coords(:,6) == indxs(i));
    if ((sum(goods(current)) / sum(current)) < 0.25)
      goods(current) = false;
      indxs(i) = NaN;
    end
  end

  if (~any(goods))
    fit_axes = NaN(3,1);
    err = Inf;
    rel_z = [];
    all_coords = [];
    indxs = [];

    return;
  end

  indxs = indxs(isfinite(indxs));
  current = ismember(all_coords(:,6), indxs);

  all_coords = all_coords(current, :);
  goods = goods(current);

  [a, z, e] = estimate_z(all_coords(goods,:), axes_length);
  [m, s] = mymean(e);
  valids = (e < m + 2*s) & (~imag(z));

  if (~any(valids) | all(valids))
    fit_axes = a;
    err = mymean(e);
    rel_z = z;
    %all_coords = all_coords(goods, :);
    indxs = unique(all_coords(:, 6));

    return;
  end

  full_indxs = unique(all_coords(goods, [4 6]), 'rows');

  current = ismember(all_coords(:,6), full_indxs(valids, 2));
  all_coords = all_coords(current,:);
  goods = goods(current);

  [fit_axes, rel_z, e] = estimate_z(all_coords(goods, :), a);
  err = mymean(e);
  indxs = unique(all_coords(:, 6));

  return;
end

function [fit_axes, rel_z, errs] = estimate_z(all_coords, axes_length)

  %keyboard

  [indxs, i, j] = unique(all_coords(:, [4 6]), 'rows');
  [tmp, k, l] = unique(indxs(:,2));
  neggs = size(indxs, 1);
  errs = ones(neggs, 1);

  z_coefs = get_struct('z-correlation');

  %figure;hold on;

  p0 = axes_length(1:2);
  %optims = optimset('Display', 'off');
  lbound = [0;0;0];
  ubound = [Inf(3,1)];
  optims = optimset('Display', 'off', 'Algorithm', 'levenberg-marquardt', 'TolFun', 1e-10, 'TolX', 1e-10);

  bests = lsqcurvefit(@fit_z, p0, all_coords, zeros(neggs, 1), [], [], optims);
  %bests = lsqnonlin(@fit_z, p0, [], [], optims);
  bests(3) = z_coefs.bkg + z_coefs.long_axis * bests(1) + z_coefs.short_axis * bests(2);

  fit_axes = bests(1:3);

  [errs, rel_z] = fit_z(fit_axes);
  errs = errs(:);

  return;

  function [z_err, z_pos] = fit_z(ax, pts)  
  %function [z_err, z_pos] = fit_z(ax)  

    z_pred = z_coefs.bkg + z_coefs.long_axis * ax(1) + z_coefs.short_axis * ax(2);
    ax(3) = z_pred;

    z_err = errs;
    %ell_coords = carth2elliptic(pts(:, 1:2), [0;0], ax(1:2), 0, 'radial');
    %dist = mymean(ell_coords(:,2) .* sign(pts(:,3) + 1e-10), 1, pts(:,6));
    ell_coords = carth2elliptic(all_coords(:, 1:2), [0;0], ax(1:2), 0, 'radial');
    dist = mymean(ell_coords(:,2) .* sign(all_coords(:,3) + 1e-10), 1, all_coords(:,6));
    dist = dist(l);
    z_pos = ax(3)*sqrt(1 - dist.^2) .* sign(dist);
    imag_z = (imag(z_pos) ~= 0);
    
    %tmp_pts = [pts(:,1:2) pts(:,3) - z_pos(j) all_coords(:,4)];
    tmp_pts = [all_coords(:,1:2) all_coords(:,3) - z_pos(j) all_coords(:,4)];
    tmp_pts = tmp_pts(~imag_z(j),:);

    err = ellipse_distance_mex(tmp_pts, [0;0;0], ax, 0);
    
    z_err(imag_z) = dist(imag_z) ;
    z_err(~imag_z) = err + abs(z_pos(~imag_z)) / ax(3);
    %z_err(~imag_z) = (1 - dist(~imag_z));% + abs(z_pos(~imag_z)) / ax(3);
    %z_err(~imag_z) = err + abs(z_pos(~imag_z)) / ax(3);
    %z_err(imag_z) = dist(imag_z);
    %z_err(~imag_z) = err + abs(z_pos(~imag_z)) / ax(3);
    z_err = z_err + sum(abs(ax(ax < lbound))); % + sum(abs(ax - axes_length) ./ axes_length);
    
    %ratio = ax(2) / ax(1);
    %if (ratio > 1)
    %  z_err = z_err + ratio;
    %end

    z_pos(imag_z) = NaN;

    %z_pred = z_coefs.bkg + z_coefs.long_axis * ax(1) + z_coefs.short_axis * ax(2);

    %z_err = z_err + abs(z_pos) / ax(3) + abs(1 - (ax(3) / z_pred));

    %plot(z_err)
    
    return;
  end
end


function [center, axes_length, orient, all_coords] = fit_absolute_ellipse(pts)

  nframes = length(pts);
  max_iter = 500;

  all_coords = zeros(0,5);
  for i=1:nframes
    if (~isempty(pts{i}))
      all_coords = [all_coords; pts{i}];
    end
  end
  indxs = unique(all_coords(:,4));

  for i=1:max_iter
    prev = indxs;

    [c,a,o, errs(1, i), p, indxs] = filter_planes(all_coords, indxs);
    errs

    if ((i>1 & errs(i) > errs(i-1)) | (i>2 & (errs(i-2) - errs(i-1) > errs(i - 1) - errs(i))))
      break;
    elseif (isinf(errs(1)))
      center = c;
      axes_length = a;
      orient = o;

      break;
    else
      center = c;
      axes_length = a;
      orient = o;
    end

    if (isempty(indxs) | numel(indxs) == numel(prev))
      break;
    end

    all_coords = p;
  end
 
  return;
end

function [fit_center, fit_axes, orient, err, all_coords, indxs] = filter_planes(all_coords, indxs)

  neggs = length(indxs);

  all_coords(:,5) = imnorm(all_coords(:,5));
  val_thresh = graythresh(all_coords(:,5));

  goods = (all_coords(:,5) >= val_thresh);
  goods = filter_goods(goods, 15);

  for i=1:neggs
    current = (all_coords(:,4) == indxs(i));
    if ((sum(goods(current)) / sum(current)) < 0.25)
      goods(current) = false;
      indxs(i) = NaN;
    end
  end

  indxs = indxs(isfinite(indxs));
  current = ismember(all_coords(:,4), indxs);

  tmp = all_coords;

  all_coords = all_coords(current, :);
  goods = goods(current);

  [c,a,o,e] = estimate_axes(all_coords, goods);
  [m,s] = mymean(e);

  if (isnan(m))
    all_coords = tmp;
    indxs = unique(all_coords(:, 4));
    goods = true(size(all_coords, 1), 1);

    [c,a,o,e] = estimate_axes(all_coords, goods);
    [m,s] = mymean(e);

    if (isnan(m))
      [fit_center, fit_axes, orient] = deal(c,a,o);
      err = Inf;

      return;
    end
  end
  valids = (e < m + 2*s);


  current = ismember(all_coords(:,4), indxs(valids));
  all_coords = all_coords(current,:);
  goods = goods(current);

  [fit_center,fit_axes,orient,e] = estimate_axes(all_coords, goods);
  err = mymean(e);
  indxs = unique(all_coords(:, 4));

  return;
end

function [fit_center, fit_axes, orient, errs] = estimate_axes(all_coords, goods)

  neggs = length(unique(all_coords(goods, 4)));

  [c, a, orient] = fit_ellipse(all_coords(goods, 1:2));
  ell_coords = carth2elliptic(all_coords(:, 1:2), c, a, orient, 'radial');

  ell_coords(:,1) = ell_coords(:,1) - pi;
  [c2,a2,o2] = fit_ellipse(all_coords(:, 3), ell_coords(:, 2) .* sign(ell_coords(:, 1)));

  fit_axes = [a; a2(1)];
  fit_center = [c; c2(1)];

  p0 = [fit_center; fit_axes; orient];
  optims = optimset('Display', 'off', 'Algorithm', 'levenberg-marquardt');
  lbound = [0;0;-Inf;0;0;0;-2*pi];
  ubound = [Inf(6,1);2*pi];
  bests = lsqcurvefit(@fit_3d_ellipse, p0, all_coords(goods,:), zeros(neggs, 1), [], [], optims);

  fit_center = bests(1:3);
  fit_axes = bests(4:6);
  orient = bests(7);

  errs = ellipse_distance_mex(all_coords(goods,:), fit_center, fit_axes, orient);
  errs = errs(:);

  return;

  function iter_err = fit_3d_ellipse(p, pts)
    
    iter_err = ellipse_distance_mex(pts, p(1:3), p(4:6), p(7));
    iter_err = iter_err + sum(abs(p(p < lbound))) + sum(p(p > ubound));

    return;
  end
end

function goods = filter_goods(goods, thresh)

  [pos, lengths, vals] = boolean_domains(goods);
  rem = ((lengths < thresh) & ~vals);

  if (any(rem))
    for i=length(rem)-1:-1:2
      if (rem(i))
        lengths(i-1) = lengths(i-1) + lengths(i) + lengths(i+1);
      end
    end
  end

  keep = ~(rem | [false; rem(1:end-1)]);
  pos = pos(keep);
  lengths = lengths(keep);
  vals = vals(keep);

  rem = ((lengths < thresh) & vals);
  vals(rem) = false;
  goods(:) = false;

  for i=1:length(pos)
    if (vals(i))
      goods(pos(i):pos(i)+lengths(i)-1) = true;
    end
  end

  return;
end

function plot_3d_ellipse(pts, axes, orient)
  
  hold on;

  if (nargin == 3)
    centers = pts;

    nslices = 7;
    z_pos = [-nslices:nslices] * (axes(3)) / (nslices+1) ;
    z_coef = sqrt(1 - (z_pos.^2 / axes(3).^2));
    z_pos = z_pos + centers(3);

    for i=1:length(z_pos)
      [x, y] = draw_ellipse(centers(1:2), axes(1:2)*z_coef(i), orient);
      plot3(x,y,z_pos(i)*ones(size(x)), 'r');
    end
  elseif (nargin == 2)
    z_pos = axes;
    if (iscell(pts))
      for i=1:length(pts)
        plot3(pts{i}(:,1),pts{i}(:,2),ones(size(pts{i},1),1)*z_pos(i), 'k');
      end
    else
      indxs = unique(pts(:,4));
      for i=1:length(indxs)
        currents = (pts(:,4) == indxs(i));
        plot3(pts(currents,1),pts(currents,2),ones(sum(currents), 1)*z_pos(i), 'k');
      end
    end
  else
    if (iscell(pts))
      for i=1:length(pts)
        plot3(pts{i}(:,1),pts{i}(:,2),pts{i}(:,3), 'k');
      end
    else
      plot3(pts(:,1),pts(:,2),pts(:,3), 'k');
    end
  end

  hold off;

  return;
end
