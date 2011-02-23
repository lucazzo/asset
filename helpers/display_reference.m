function h = display_reference(varargin)
  
  [h, mymovie, fields, indexes, opts, fname, args, dv_inversion] = parse_inputs(varargin{:});
  
  new_draw = false;
  if (isempty(h))
    h = figure;
    
    handles = struct('cortex', [], ...
                     'ruffles', [], ...
                     'centrosomes', [], ...
                     'movie_index', 0, ...
                     'axes', 0, ...
                     'index', 0);

    new_draw = true;
  else
    handles = get(h, 'UserData');
  end
  
  for m=1:length(mymovie)
    if (~isfield(mymovie(m).(opts.segmentation_type), 'warpers') | isempty(mymovie(m).(opts.segmentation_type).warpers))
      mymovie(m) = carth2RECOS(mymovie(m));
    end
  end

  if (length(indexes) == 0 & new_draw)
    handles = draw_background(h, handles, get_struct('warper',1));
  else
    for indx = indexes
      for m=1:length(mymovie)
        if (handles.index ~= indx)
          handles.index = indx;

          if (length(indexes) == 1 | strncmp(args, 'animate', 7))
            handles.movie_index = 1;
          end
        end

        warper = mymovie(m).(opts.segmentation_type).warpers(indx);

        if (new_draw)
          handles = draw_background(h, handles, warper);

          new_draw = false;
        end

        for i=1:size(fields,1)
          pts = mymovie(m).(fields{i,1}).(fields{i,2})(indx).warped;

          if (length(indexes) == 1 | strncmp(args, 'animate', 7))
            handles = draw_element(handles, pts, fields{i,2});
          else
            handles = draw_element(handles, pts, fields{i,2}, indx / indexes(end));
          end
        end

        handles.movie_index = handles.movie_index + 1;
      end

      if (strncmp(args, 'animate', 7))
        refresh(h);
        drawnow;
        if (~isempty(fname))
          movie(indx) = getframe(h);
        end
      end
    end
  end

  set(h, 'UserData', handles);
  refresh(h);

  if (~isempty(fname))
    movie2avi(movie,fname,'FPS',6);
  end

  return;
end

function handles = draw_background(hfig, handles, warper)

  [eggx,eggy] = draw_ellipse(warper.reference.center, warper.reference.axes_length, warper.reference.orientation); 

  axex = [1 0 -1 0] * 1.1 * warper.reference.axes_length(1);
  axey = [0 1 0 -1] * 1.1 * warper.reference.axes_length(2);

  hax = axes;
  handles.axes = hax;

  set(hax, ...
    'FontSize',18, ...
    'NextPlot','add', ...
    'Visible','off', ...
    'Tag', 'axes',...
    'Parent',hfig, ...
    'Ylim', axey([4 2]), ...
    'Xlim', axex([3 1]), ...
    'DataAspectRatio',[1 1 1]);

  egghcs = line(eggx,eggy, ...
                'Color', [0 1 0], ...
                'HandleVisibility', 'callback', ...
                'EraseMode', 'none', ...
                'HitTest','off', ...
                'LineStyle','-', 'Marker','none', ...
                'LineWidth', 2, ...
                'Parent',hax, ...
                'SelectionHighlight','off', ...
                'Tag','Eggshell');

  line(axex([1 3]), axey([1 1]), ...
          'Color', 'k', ...
          'HandleVisibility', 'callback', ...
          'EraseMode', 'none', ...
          'HitTest','off', ...
          'LineStyle','-', 'Marker','none', ...
          'Parent',hax, ...
          'SelectionHighlight','off');

  line(axex([2 2]), axey([2 4]), ...
          'Color', 'k', ...
          'HandleVisibility', 'callback', ...
          'EraseMode', 'none', ...
          'HitTest','off', ...
          'LineStyle','-', 'Marker','none', ...
          'Parent',hax, ...
          'SelectionHighlight','off');

  text(axex + [2 0 -2 0], axey + [0 2 0 -2], {'0'; '\pi/2'; '\pi'; '3\pi/2'});

  return;
end

function handles = draw_element(handles, pts, name, scaling)

  if (nargin == 3)
    scaling = 1;
  end

  if (isempty(pts))
    pts = NaN(2);
  else
    %pts = pts(:,1:2);
    pts(:,2:2:end) = -pts(:,2:2:end);
  end

  if (handles.movie_index <= size(handles.(name), 2))
    nelems = size(handles.(name), 1);
    %if (nelems == 1)
      %set(handles.(name)(handles.movie_index),'XData', pts(:,1), 'YData', -pts(:,2));
    %else
      for i=1:nelems
        %set(handles.(name)(i,handles.movie_index),'XData', pts(i,1), 'YData', -pts(i,2));
        myplot(handles.(name)(i, handles.movie_index, :), pts);
      end
    %end
  else
    switch name
      case 'cortex'
        %h = line(pts(:,1),-pts(:,2), ...
        h = myplot(pts, ...
                'Color', [1 0.5 0] * scaling, ...
                'HandleVisibility', 'callback', ...
                'EraseMode', 'none', ...
                'HitTest','off', ...
                'LineStyle','-', 'Marker','none', ...
                'LineWidth', 2, ...
                'Parent',handles.axes, ...
                'SelectionHighlight','off', ...
                'Tag','Cortex');

      case 'ruffles'
        %h = line(pts(:,1),-pts(:,2), ...
        h = myplot(pts, ...
                'Color', [0.5 0 1] * scaling, ...
                'HandleVisibility', 'callback', ...
                'EraseMode', 'none', ...
                'HitTest','off', ...
                'LineStyle','none', 'Marker','*', ...
                'LineWidth', 1, ...
                'Parent',handles.axes, ...
                'SelectionHighlight','off', ...
                'Tag','Ruffles');
      case 'centrosomes'
        %h = line(pts(1,1),-pts(1,2), ...
        h(1,1,:) = myplot(pts(1,:), ...
                'Color', [0 0 1] * scaling, ...
                'HandleVisibility', 'callback', ...
                'EraseMode', 'none', ...
                'HitTest','off', ...
                'LineStyle','none', 'Marker','o', ...
                'LineWidth', 2, ...
                'Parent',handles.axes, ...
                'SelectionHighlight','off', ...
                'Tag','Centrosomes');

        %h(2,1) = line(pts(2,1),-pts(2,2), ...
        h(2,1,:) = myplot(pts(2,:), ...
                'Color', [1 0 0] * scaling, ...
                'HandleVisibility', 'callback', ...
                'EraseMode', 'none', ...
                'HitTest','off', ...
                'LineStyle','none', 'Marker','^', ...
                'LineWidth', 2, ...
                'Parent',handles.axes, ...
                'SelectionHighlight','off', ...
                'Tag','Centrosomes');
    end

    handles.(name) = [handles.(name) h];
  end

  return;
end

function [h, mymovie, fields, indx, opts, fname, args, dv_inversion] = parse_inputs(varargin)

  h = [];
  mymovie = [];
  indx = [];
  opts = get_struct('RECOS',1);
  fname = '';
  args = 'none';
  dv_inversion = false;
  fields = {(opts.segmentation_type), 'cortex'; (opts.segmentation_type), 'ruffles'; 'data', 'centrosomes'};

  if (nargin > 0)
    for i=1:length(varargin)
      type = get_type(varargin{i});
      switch type
        case 'char'
          if (findstr(varargin{i}, '.'))
            fname = varargin{i};
          else
            args = varargin{i};
          end
        case 'cell'
          fields = varargin{i};
        case 'num'
          if (all(ishandle(varargin{i})))
            h = varargin{i};
          else
            indx = varargin{i};
          end
        case 'struct'
          if (isfield(varargin{i}, 'experiment'))
            mymovie = varargin{i};
          else
            opts = varargin{i};
          end
      end
    end

    for i=size(fields,1):-1:1
      if (~isfield(mymovie(1), fields{i,1}) | ~isfield(mymovie(1).(fields{i,1}), fields{i,2}) | isempty(mymovie(1).(fields{i,1}).(fields{i,2})))
        fields(i,:) = [];
      end
    end

    if (isempty(indx))
      nframes = length(mymovie(1).(opts.segmentation_type).cortex);
      indx = [1:nframes];

    end
  end

  if (~isempty(fname))
    args = 'animate';
  end

  if (isfield(mymovie, 'data') & isfield(mymovie.data, 'inverted') & mymovie.data.inverted)
    dv_inversion = true;
  end

  return;
end
