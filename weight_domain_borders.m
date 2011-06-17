function weight = weight_domain_borders(img, params)

  alpha = params.alpha;
  beta = params.beta;
  gamma = params.gamma;
  delta = 1/params.delta;

  [nrows,npts] = size(img);
  img = imnorm(img, [], [], 'row');
  img = gaussian_mex(img, 0.6);

  derivatives = zeros(nrows, npts, npts);
  domain_size = zeros(nrows, npts, npts);
  domain_integral = zeros(nrows, npts, npts);
  weight = zeros(nrows, npts, npts);

  %line = img(40, :);

  %valids = ~isnan(line);
  %line(~valids) = 0;
  %dist = cumsum(valids);

  %domain_size = bsxfun(@minus, dist, dist.') + 1;
  %vals = cumsum(line);
  %domain_integral = bsxfun(@minus, vals, [0 vals(1:end-1)].');
  
  %domain = domain_integral ./ domain_size;
  %outside = (vals(end) - domain_integral) ./ (npts - domain_size);
  %domain_vals = beta * (1 - domain) + (1-beta)*outside;

  %valids_deriv = (valids & valids([2:end 1]));
  %dist = cumsum(valids_deriv);

  %derivatives = diff([line line(1)]) ./ diff([0 dist]);
  %derivatives = 1 ./ (1 + exp(-delta * derivatives));
  
  %left_deriv = gamma * (1-derivatives);
  %right_deriv = (1-gamma) * derivatives;
  %derivatives = bsxfun(@plus, left_deriv.', right_deriv);

  %weight = alpha * domain_vals + (1-alpha) * derivatives;
  %weight(domain_size <= 0) = Inf;
  %weight(isnan(weight)) = Inf;

  %figure;imagesc(weight);

  %keyboard

  valids = ~isnan(img);
  img(~valids) = 0;
  dist = cumsum(valids, 2);
  domain_size = bsxfun(@minus, reshape(dist, [nrows 1 npts]), dist) + 1;
  vals = cumsum(img, 2);
  domain_integral = bsxfun(@minus, reshape(vals, [nrows, 1, npts]), [zeros(nrows, 1) vals(:, 1:end-1)]);
  domain = domain_integral ./ domain_size;
  outside = bsxfun(@minus, vals(:, end), domain_integral) ./ (npts - domain_size);
  domain_value = beta .* (1-domain) + (1-beta).*outside;

  valids_deriv = (valids & valids(:, [2:end 1]));
  dist = cumsum(valids_deriv, 2);
  derivatives = bsxfun(@rdivide, diff([img img(:, 1)], [], 2), diff([zeros(nrows, 1) dist], [], 2));
  derivatives = 1 ./ (1 + exp(-delta * derivatives));

  left_deriv = gamma * (1-derivatives);
  right_deriv = (1-gamma) * derivatives;
  all_derivatives = bsxfun(@plus, left_deriv, reshape(right_deriv, [nrows, 1, npts]));

  %keyboard

  weight = (alpha * domain_value) + ((1-alpha) * all_derivatives);
  weight(domain_size <= 0) = Inf;
  weight(isnan(weight)) = Inf;

  %figure;imagesc(squeeze(weight(40,:,:)));

  %keyboard
  
  return;
  
  
  domain_prop = domain_size ./ (npts + 1 - domain_size);

  vals = cumsum(line);
  domain_integral = bsxfun(@minus, vals, vals.');
  
  relative_mean = ((vals(end) - domain_integral) ./ domain_integral) .* domain_prop;
  relative_mean(domain_prop <= 0) = Inf;
  relative_mean(isnan(relative_mean)) = Inf;

  pts = [1:npts];
  pts = pts(valids);
  smoothed = emdc(pts, line(valids));
  smoothed = sum(smoothed(2:end, :));
  derivatives = diff([smoothed smoothed(1)]) ./ diff([pts pts(1)+npts]);


  keyboard

  %sums = cumsum(img, 2);

  return;
end
