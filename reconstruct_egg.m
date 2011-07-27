function mymovie = reconstruct_egg(mymovie, opts)

  [nframes, imgsize] = size_data(mymovie.dic);

  centers = mymovie.markers.centers;
  axes_length = mymovie.markers.axes_length;
  orientations = mymovie.markers.orientations;

  orientations = align_orientations(orientations);
  ratios = axes_length(1,:) ./ axes_length(2, :);

  target_ratio = median(ratios);
  new_axes = axes_length;
  new_axes(2, :) = sqrt(axes_length(1,:) .* axes_length(2,:) ./ target_ratio);
  new_axes(1, :) = new_axes(2, :) * target_ratio;

  mymovie = parse_metadata(mymovie, opts);

  [~, indx] = max(new_axes(1, :));
  equat_axes = new_axes(:, indx);

  z_pos = sqrt(equat_axes(2).^2 - new_axes(2, :).^2);
  real_z = mymovie.metadata.z_pos;
  npts = length(real_z);

  lower = [diff(real_z)~=0 0];

  x_pos = [0:npts-1];
  derivatives = (39*(real_z(:,5:end-2) - real_z(:,3:end-4)) + 12*(real_z(:,6:end-1) - real_z(:,2:end-5)) -5*(real_z(:, 7:end) - real_z(:, 1:end-6))) / 96;
  y_valids = (derivatives > 0 & ~isnan(derivatives));
  x_valids = logical([0 0 0 y_valids 0 0 0]);

  y_deriv = log(derivatives(y_valids));
  x_deriv = x_pos(x_valids).';

  expfunc = @(p,x)(p(1)*(1-exp(-p(2)*x)) + p(3));

  params = [x_deriv ones(size(x_deriv))] \ y_deriv(:);
  params = [-exp(params(2)) / params(1), -params(1), real_z(1)];

  valids = ~isnan(real_z) & lower;
  better_params = lsqcurvefit(expfunc,params,x_pos(valids), real_z(valids));
  relative_z = real_z - expfunc(better_params, x_pos);

  mymovie.metadata.z_rel = relative_z;

  figure;scatter(prod(new_axes), relative_z);
  figure;scatter(axes_length(1,:), relative_z);

  figure;plot(x_pos, real_z);
  hold on;plot(x_pos, expfunc(params, x_pos), 'r');
  plot(x_pos, expfunc(better_params, x_pos), 'g');

  figure;
  hold on;
  for i=1:nframes
    %plot3(x,y,z_pos(i)*ones(size(x)));
    %[x,y] = draw_ellipse(centers(:, i), axes_length(:, i), orientations(i));
    %plot3(x*opts.pixel_size,y*opts.pixel_size,mymovie.metadata.z_pos(i)*ones(size(x)), 'r');
    %[x,y] = draw_ellipse(centers(:, i), new_axes(:, i), orientations(i));
    %plot3(x*opts.pixel_size,y*opts.pixel_size,mymovie.metadata.z_pos(i)*ones(size(x)), 'b');
    plot3(mymovie.dic.eggshell(i).carth(:,1)*opts.pixel_size,mymovie.dic.eggshell(i).carth(:,2)*opts.pixel_size,mymovie.metadata.z_pos(i)*ones(size(mymovie.dic.eggshell(i).carth(:,1))), 'g');
  end
  axis('equal')


  figure;
  hold on;
  for i=1:nframes
    h1 = subplot(211);
  hold on;
    [x,y] = draw_ellipse([0;0], axes_length(:, i), 0);
    plot3(x*opts.pixel_size,y*opts.pixel_size,relative_z(i)*ones(size(x)), 'r');
    h2 = subplot(212);
  hold on;
    [x,y] = draw_ellipse([0;0], new_axes(:, i), 0);
    plot3(x*opts.pixel_size,y*opts.pixel_size,relative_z(i)*ones(size(x)), 'b');
  end
  axis(h1, 'equal')
  axis(h2, 'equal')
  %linkaxes([h1 h2])

  return;
  %keyboard
  
  figure;
  hold on;
  for i=1:nframes
    pts = mymovie.markers.eggshell(i).carth;
    mid_pts = project2midplane(pts, centers(:,i), equat_axes, orientations(i), z_pos(i));
    %[x,y] = draw_ellipse([0;0], new_axes(:, i), 0);
    plot3(mid_pts(:, 1), mid_pts(:,2),i*ones(size(mid_pts(:,1))));
    plot3(pts(:, 1), pts(:,2),i*ones(size(mid_pts(:,1))), 'r');
  end

  figure;
  hold on;
  for i=1:nframes
    [x,y] = draw_ellipse(centers(:, i), new_axes(:, i), orientations(i));
    pts = mymovie.markers.eggshell(i).carth;
    plot3(pts(:, 1), pts(:,2),z_pos(i)*ones(size(pts(:,1))), 'g');
    plot3(x,y,z_pos(i)*ones(size(x)));
  end

  return;
end