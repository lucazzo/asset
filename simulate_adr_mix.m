function [all_x, t] = simulate_adr_mix(x0, opts)

  if (nargin == 1)
    if (isstruct(x0))
      opts = x0;
      x0 = [];
    else
      opts = get_struct('modeling');
      opts = load_parameters(opts, 'goehring.txt');
    end
  elseif (nargin == 0)
    opts = get_struct('modeling');
    opts = load_parameters(opts, 'goehring.txt');
    x0 = [];
  end

  if (isempty(x0))
    opts.nparticles = opts.nparticles - mod(opts.nparticles, 4);

    if (~isempty(opts.init_func) & isa(opts.init_func, 'function_handle'))
      x0 = opts.init_func(opts);
    else
      x0 = opts.init_params;
      x0 = repmat(x0, [opts.nparticles, 1]);
    end
  end

  all_params = [opts.diffusion_params; ...
                opts.reaction_params];

  flow = opts.advection_params;
  if (size(flow, 1) ~= size(x0, 1))
    [X, Y] = meshgrid([1:size(flow, 1)], 1+([0:size(x0, 1)-1]*(size(flow, 1)-1)/(size(x0, 1)-1)).');
    flow = bilinear_mex(flow, X, Y, [2 2]);
  end
  %flow(:) = pi;

  %x0 = ([1:opts.nparticles; 1:opts.nparticles].')/10;

  tmp = x0;
  tmp(1:2:end-1) = x0(1:opts.nparticles);
  tmp(2:2:end) = x0(opts.nparticles+1:end);
  x0 = tmp;

  [all_m, t] = simulate_model_mix(single(x0), single(all_params), single(opts.x_step), single(opts.tmax), single(opts.time_step), single(opts.output_rate), single(flow), single(opts.user_data), single(opts.max_iter));
  all_x = all_m;
  all_x(1:opts.nparticles, :) = all_m(1:2:end-1, :);
  all_x(opts.nparticles+1:end, :) = all_m(2:2:end, :);

  return;
end
