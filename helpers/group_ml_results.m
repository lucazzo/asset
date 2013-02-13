function datas = group_ml_results(fnames, groups, filters)

  if (nargin == 1)
    groups = {};
    filters = {};
  elseif (nargin == 2)
    if (size(groups, 2) > 1)
      filters = groups;
      groups = {};
    else
      filters = {};
    end
  end

  ngroups = size(groups, 1);
  nfilters = size(filters, 1);

  [path, pattern, ext] = fileparts(fnames);
  file_pattern = [pattern ext];
  if (isempty(path))
    path = pwd;
  end

  files = dir(fnames);
  nfiles = length(files);
  datas = cell(nfiles, 2);
  nstored = 0;

  display('Parsing files...');

  for i=1:nfiles
    fname = [path filesep files(i).name];
    opt = load_parameters(get_struct('fitting'), fname);

    is_valid = true;
    for j=1:nfilters
      is_valid = is_valid && isfield(opt, filters{j, 1}) && numel(opt.(filters{j,1})) == numel(filters{j,2}) && all(opt.(filters{j,1})(:) == filters{j,2}(:));

      if (~is_valid)
        break;
      end
    end

    for j=1:ngroups
      is_valid = is_valid && isfield(opt, groups{j, 1});

      if (~is_valid)
        break;
      end
    end

    if (is_valid)
      found = false;
      for n=1:nstored
        ref = datas{n, 1}{1};
        all_same = true;
        for j=1:ngroups
          all_same = all_same && numel(ref.(groups{j})) == numel(opt.(groups{j})) && all(ref.(groups{j})(:) == opt.(groups{j})(:));
        end

        if (all_same)
          found = n;
          break;
        end
      end

      if (~found)
        found = nstored + 1;
        datas{found, 1} = {opt};
        datas{found, 2} = {fname};
        nstored = nstored + 1;
      else
        datas{found, 2} = [datas{found, 2}, fname];
      end

      display(files(i).name)
    end
  end

  display('Loading files...');

  for i=1:nstored
    files = datas{i, 2};
    for j=1:length(files)
      display(files{j});
      datas{i, 2}{j} = parse_ml_results(files{j}, Inf, true, 'none');
    end
  end

  datas = datas(1:nstored, :);

  return;
end
