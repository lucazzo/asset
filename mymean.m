function [all_mvals, all_svals, groups] = mymean(all_vals, dim, indexes)

  all_mvals = [];
  all_svals = [];
  groups = [];

  if (nargin == 2)
    indexes = ones(size(all_vals, dim), 1);
  elseif (nargin == 1)
    dim = 1;
    indexes = ones(size(all_vals, 1), 1);
  end

  vals_size = size(all_vals);

  if (dim == 1 & vals_size(dim) == 1)
    dim = find(vals_size > 1, 1);

    if (isempty(dim))
      return;
    end
  elseif (dim > numel(vals_size) | vals_size(dim) == 1)
    return;
  end

  all_mvals = NaN(0, numel(all_vals)/vals_size(dim));
  all_svals = all_mvals;

  perm_dim = [1:length(vals_size)];
  perm_dim(dim) = 1;
  perm_dim(1) = dim;

  all_vals = permute(all_vals, perm_dim);
  all_vals = reshape(all_vals, vals_size(dim), []);
 
  if (numel(indexes) ~= vals_size(dim))
    return;
  end

  indexes = indexes(:);
  groups = unique(indexes).';
  ngroups = length(groups);

  for g = groups
    if (ngroups == 1)
      vals = all_vals;
    else
      vals = all_vals(indexes == g, :);
    end

    nans = isnan(vals);
    nelems = sum(~nans, 1);
    vals(nans) = 0;

    mvals = sum(vals, 1) ./ nelems;
    mvals(nelems == 0) = NaN;

    all_mvals = cat(1, all_mvals, mvals);

    if (nargout > 1)
      svals = bsxfun(@minus, vals, mvals).^2;
      svals(nans) = 0;
      svals = sqrt(sum(svals, 1) ./ (nelems - 1));
      svals(nelems == 0) = NaN;
      svals(nelems == 1) = 0;

      all_svals = cat(1, all_svals, svals);
    end
  end

  vals_size(dim) = ngroups;

  all_mvals = reshape(all_mvals, vals_size(perm_dim));
  all_mvals = ipermute(all_mvals, perm_dim);

  if (nargout > 1)
    all_svals = reshape(all_svals, vals_size(perm_dim));
    all_svals = ipermute(all_svals, perm_dim);
  end

  return;
end
