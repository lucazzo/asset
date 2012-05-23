function metropolis_hastings

  opts = get_struct('modeling');
  opts = load_parameters(opts, 'goehring.txt');

  x0 = opts.init_params;
  x0 = repmat(x0, [opts.nparticles, 1]);

  flow = opts.advection_params;
  if (size(flow, 1) ~= size(x0, 1))
    [X, Y] = meshgrid([1:size(flow, 1)], 1+([0:size(x0, 1)-1]*(size(flow, 1)-1)/(size(x0, 1)-1)).');
    flow = bilinear_mex(flow, X, Y, [2 2]);
  end

  ml_params = [opts.diffusion_params; ...
                opts.reaction_params(1:end-2, :)];

  [orig, orig_t] = simulate_model(x0, [ml_params; opts.reaction_params(end-1:end, :)], opts.x_step, opts.tmax, opts.time_step, opts.output_rate, flow, opts.user_data);
  orig = orig((end/2)+1:end, :);

  penalty = -((3*max(orig(:)))^2)*opts.nparticles/2;

  rescaling = 10.^(floor(log10(ml_params)));
  rescaling(ml_params == 0) = 1;
  ml_params = ml_params ./ rescaling;

  init_noise = 0.2;
  max_iter = 2000;
  ndiscard = 0;
  step_size = 0.1;
  size_params = size(ml_params);
  temp = (numel(orig)/2);

  uuid = now + cputime;
  RandStream.setDefaultStream(RandStream('mt19937ar','Seed',uuid));
  fid = fopen(['mcmc-' num2str(uuid) '.txt'], 'w');
  fprintf(fid, '0 (-1, 0) :');
  fprintf(fid, ' %f', ml_params);
  fprintf(fid, '\n');

  display(['Working ID ' num2str(uuid)]);

  %ml_params = ml_params + 0.1;
  ml_params = exp(log(ml_params) + init_noise*randn(size_params));
  best_score = likelihood(ml_params);
  fprintf(fid, '%e (0, 0) :', best_score);
  fprintf(fid, ' %f', ml_params);
  fprintf(fid, '\n');

  for i=1:max_iter
    new_params = exp(log(ml_params) + step_size*randn(size_params));
    new_score = likelihood(new_params);
    ratio = exp(new_score - best_score);
    rand_val = rand(1);

    if (rand_val <= ratio)
      ml_params = new_params;
      best_score = new_score;
    else
      ndiscard = ndiscard + 1;
    end

    fprintf(fid, '%e (%d, %d) :', new_score, i, ndiscard);
    fprintf(fid, ' %f', new_params);
    fprintf(fid, '\n');
  end

  fclose(fid);

  return;

  %function L = likelihood(params, stepping)
  function L = likelihood(params)

    %if (nargin == 1)
    %  stepping = 1;
    %end

    %[res, t] = simulate_model(x0, [params .* rescaling; opts.reaction_params(end-1:end, :)], opts.x_step, opts.tmax, opts.time_step / stepping, opts.output_rate, flow, opts.user_data);
    [res, t] = simulate_model(x0, [params .* rescaling; opts.reaction_params(end-1:end, :)], opts.x_step, opts.tmax, opts.time_step, opts.output_rate, flow, opts.user_data);
    res = res((end/2)+1:end, :);
    if (length(t) ~= length(orig_t))
      res = interp1q(t.', res.', orig_t.').';
    end

    L = sum(-((orig - res).^2) / 2);
    L(isnan(L)) = penalty;
    L = sum(L)/temp;
    %if (isnan(L))
    %  stepping = 2*stepping;
    %  if (stepping > 8)
    %    L = -Inf;
    %  else
    %    L = likelihood(params, stepping);
    %  end
    %end

    return;
  end
end
