function [gammas] = estimate_noise(img, filter_type)

  if (nargin == 1)
    filter_type = 'adm';
  end

  mfilter = 3;
  block_size = 21;
  middle = ((block_size-1)/2)+1;

  %minsize = estimate_sample_size(0.9, 0.075);
  minsize = estimate_sample_size(0.8, 0.1);
  nbins = numel(img) / (50*minsize);

  nelems = block_size^2;

  switch filter_type
    case 'adm'
      edge_map = imadm(img, 0, false);
  
      blocks = blockproc(cat(3,img,edge_map), [block_size block_size], @analyze_block);
    otherwise
      row = -ones(1, block_size);
      hfilter = zeros(block_size);
      hfilter(middle, :) = row;
      vfilter = hfilter.';
      pdfilter = diag(row);
      ndfilter = pdfilter.';
      ldfilter = hfilter;
      ldfilter(middle,middle:end) = 0;
      ldfilter(middle:end, middle) = -1;
      lufilter = hfilter;
      lufilter(middle,middle:end) = 0;
      lufilter(1:middle-1, middle) = -1;
      rdfilter = hfilter;
      rdfilter(middle,1:middle) = 0;
      rdfilter(middle+1:end, middle) = -1;
      rufilter = hfilter;
      rufilter(middle,1:middle) = 0;
      rufilter(1:middle-1, middle) = -1;

      filter = [hfilter(:) vfilter(:) pdfilter(:) ndfilter(:) ldfilter(:) lufilter(:) rdfilter(:) rufilter(:)];
      filter((middle-1)*block_size + middle, :) = (block_size - 1);

      blocks = blockproc(img, [block_size block_size], @analyze_block);
  end

  noisefree = median_mex(img, mfilter);
  noisy = img - noisefree;

  blocks = reshape(blocks, [], 3);

  blocks = sortrows(blocks);
  target_var = mean(blocks(1:3, 3));

  goods = (blocks(:,3) <= 3*target_var);
  blocks = blocks(goods, :);

  nblocks = min(size(blocks, 1), 20);
  gauss_noise = mean(blocks(1:nblocks, 2:3));

  noisefree = noisefree(:);
  noisy = noisy(:);
  edges = ([0:nbins].')*range(noisefree)/nbins + min(noisefree);
  edges(1) = edges(1) - 1e-6;
  edges(end) = edges(end) + 1e-6;

  [counts, map] = histc(noisefree, edges);
  nbins = length(counts);

  vars = NaN(nbins, 1);
  for i=1:nbins
    if (counts(i) > minsize)
      vars(i) = std(noisy(map==i))^2;
    end
  end

  goods = isfinite(vars);
  vars = vars(goods);
  edges = (edges(1:end-1) + edges(2:end)) / 2;
  edges = edges(goods);

  edges = edges - gauss_noise(1);
  vars = vars - gauss_noise(2)^2;

  X = [edges edges.^2];
  coefs = X \ vars;

  switch (sum(coefs < 0))
    case 0
      gammas = [gauss_noise coefs.'];
    case 1
      if (coefs(1) < 0)
        coefs = [edges.^2] \ vars;
        gammas = [gauss_noise 0 coefs];
      else
        coefs = [edges] \ vars;
        gammas = [gauss_noise coefs 0];
      end
    case 2
      gammas = [gauss_noise 0 0];
  end

  %figure;scatter(edges, vars);
  %hold on;
  %plot(edges, gammas(4)*edges.^2 + gammas(3)*edges, 'r')

  return;

  function res = analyze_block(block_struct)
    
    data = block_struct.data(:);

    if (numel(data) == nelems)
      homog = sum(abs(sum(bsxfun(@times, data, filter), 1)), 2);
      [means, stds] = mymean(data);

      res = cat(3, cat(3, homog, means), stds);

    elseif (numel(data) == 2*nelems)

      homog = sum(data((end/2)+1:end));
      [means, stds] = mymean(data(1:end/2));
      res = cat(3, cat(3, homog, means), stds);

    else
      res = cat(3, cat(3, Inf, Inf), Inf);
    end

    return;
  end
end
