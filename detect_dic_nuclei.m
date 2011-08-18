function detect_dic_nuclei(mymovie, opts)

  nuclei_size = 1;
  thresh = 0.75;
  area_thresh = 0.5;
  %thresh = [0.65:0.01:0.75];
  %morph_size = [1];

    filt_size = (nuclei_size / opts.pixel_size);
    if (mod(filt_size, 2) < 1)
      filt_size = ceil(filt_size);
    else
      filt_size = floor(filt_size);
    end
    filt = true(filt_size);

  [nframes, imgsize] = size_data(mymovie.dic);
  blank_img = false(imgsize);

  for i=1:nframes
    nimg = i;
    %nimg = randi(nframes, 1);
    %nimg = 89;

    %keyboard

    img = imnorm(double(load_data(mymovie.dic, nimg)));
    imshow(img);
    colormap('gray')
    saveas(gca, ['frame-' num2str(nimg) '-ref.png']);
    colormap('jet')

    %for n=nuclei_size
    %    for m=morph_size


    entr = imnorm(entropyfilt(img, filt));

    path = mymovie.dic.cortex(nimg).carth;
    mask = roipoly(blank_img, path(:,1), path(:,2));

    %entr(~mask) = NaN;
    %entr = imnorm(entr);
    %thresh = graythresh(entr) * t;
    entr(~mask) = 1;

    %  for t=thresh
    bw = (entr < thresh);
    %bw(~mask) = 0;
    %bw = imclose(bw, strel('disk', ceil(filt_size/m)));
    %stats = regionprops(bw, img, 'Area', 'Eccentricity', 'MeanIntensity', 'MajorAxisLength');

    orig_bw = bw;
    
    for a=area_thresh

    areas = round(pi * (a / opts.pixel_size)^2);

    bw = bwareaopen(orig_bw, areas);
    bw = imopen(bw, strel('disk', ceil(filt_size)));
    bw = imfill(bw, 'holes');

    l = bwlabel(bw, 8);
    l(l==0) = img(l==0);
    imagesc(l);
    %subplot(121);imshow(img);
    %subplot(122);imagesc(bwlabel(bw, 8));
    title(num2str(nimg));

    saveas(gca, ['frame-' num2str(nimg) '-' num2str(a) '.png']);

    end
%    end
%    end

    %keyboard
  end

  return;
end