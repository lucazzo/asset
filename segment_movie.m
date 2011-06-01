function [mymovie, updated] = segment_movie(mymovie, opts)

  updated = false;

  if (nargin < 2)
    opts = get_struct('ASSET', 1);
  end
      
  switch (opts.segmentation_type)
    case {'dic', 'all'}
      [nframes imgsize ] = size_data(mymovie.dic);
    case 'markers'
      if (isfield(mymovie, 'eggshell') & ~isempty(mymovie.eggshell))
        [nframes imgsize ] = size_data(mymovie.eggshell);
      else
        [nframes imgsize ] = size_data(mymovie.cortex);
      end
    otherwise
      error 'None of the expected field are present in ''mymovie''';
  end

  if (nargin < 2)
    opts.segmentation_parameters = set_image_size(opts.segmentation_parameters, imgsize);
  end

  if (~opts.recompute && strncmp(opts.do_ml, 'none', 4)) && ...
     (((strncmp(opts.segmentation_type, 'dic', 3) | strncmp(opts.segmentation_type, 'all', 3)) && ...
       (isfield(mymovie.dic, 'eggshell') && isfield(mymovie.dic, 'cortex')) && ...
       (length(mymovie.dic.eggshell) == nframes && length(mymovie.dic.cortex) == nframes)) ...
     || ...
     ((strncmp(opts.segmentation_type, 'markers', 7) | strncmp(opts.segmentation_type, 'all', 3)) && ...
       (isfield(mymovie.markers, 'eggshell') && isfield(mymovie.markers, 'cortex')) && ... 
       (length(mymovie.markers.eggshell) == nframes && length(mymovie.markers.cortex) == nframes)))

    return;
  end

  if (opts.verbosity > 0)
    hwait = waitbar(0,'Segmenting Frames','Name','ASSET');
  end

  switch (opts.parse_frames)
    case 'normal'
      frames = 1:nframes; 
    case 'random'
      frames = randperm(nframes);      
  end

  if (opts.max_frames > 1)
    max_frames = round(opts.max_frames);
  else
    max_frames = round(nframes*opts.max_frames);
  end

  if max_frames > nframes 
    max_frames = nframes;
  elseif max_frames < 1
    max_frames = 1;
  end

  frames = frames(1:max_frames);
  dic_opts = opts;
  dic_opts.segmentation_type = 'dic';
  %keyboard

  for i = 1:max_frames
    nframe = frames(i);

    if (strncmp(opts.segmentation_type, 'dic', 3) | strncmp(opts.segmentation_type, 'all', 3))
      mymovie = dp_dic(mymovie, opts.segmentation_parameters.dic, nframe, opts);

      updated = updated || any(mymovie.dic.update(:, nframe));
    end

    if (strncmp(opts.segmentation_type, 'markers', 7) | strncmp(opts.segmentation_type, 'all', 3))
      if (~isfield(mymovie, 'eggshell') | isempty(mymovie.eggshell))
        mymovie = dp_dic(mymovie, dic_opts.segmentation_parameters.dic, nframe, opts);

        if (any(mymovie.dic.update(:, nframe)))
          tmp_opts = dic_opts;
          tmp_opts.recompute = true;
          mymovie = duplicate_segmentation(mymovie, 'markers', tmp_opts, nframe);
          tmp_opts = opts;
          tmp_opts.recompute = true;
          mymovie = dp_markers(mymovie, tmp_opts.segmentation_parameters.markers, nframe, tmp_opts);
        end
      else
        mymovie = dp_markers(mymovie, opts.segmentation_parameters.markers, nframe, opts);
      end

      updated = updated || any(mymovie.markers.update(:, nframe));
    end
  
    if (opts.verbosity > 0)
      waitbar(i/max_frames,hwait);
    end
  end
  if (strncmp(opts.segmentation_type, 'dic', 3) | strncmp(opts.segmentation_type, 'all', 3))
    mymovie.dic = align_orientations(mymovie.dic);
  end
  if (strncmp(opts.segmentation_type, 'markers', 7) | strncmp(opts.segmentation_type, 'all', 3))
    mymovie.markers = align_orientations(mymovie.markers);
  end

  if (opts.verbosity > 0)
    close(hwait);
  end

  return;
end