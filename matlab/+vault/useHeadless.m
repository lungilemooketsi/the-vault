function useHeadless()
if exist('graphics_toolkit', 'file') == 2 || exist('graphics_toolkit', 'builtin') == 5
  try
    graphics_toolkit('gnuplot');
  catch
  end
end
end
