function out = ImClip(im, sz)
h = sz(1); w = sz(2);
out = im;
out = out(1:min(end,h), 1:min(end,w));
padH = h - size(out,1);
padW = w - size(out,2);
if padH > 0 || padW > 0
    out = padarray(out, [max(0,padH) max(0,padW)], 0, 'post');
end
end