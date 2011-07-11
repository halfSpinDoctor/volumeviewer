% FUNCTION [] = savefig(fname, epsflag)
%
% Save current figure to FigX.tif
%
% Inputs:
%    fname    - output file name
%    epsflag  - 0 = nomral image 1 = eps image output
%
% Samuel A. Hurley
% University of Wisconsin
% v1.0 10-Dec-2010
%
% Changelog
%
%  v1.0 - Basic saveas(gcf, '') implementation (Dec-2010)
%  v2.0 - based on myaa (anti-aliased figure generator)
%         added a flag for EPS

function [] = savefig(fname, epsflag)

if ~exist('epsflag', 'var')
  epsflag = 0;
end

%% Set default options and interpret arguments
self.K = [8 4];
self.figmode = 'figure';

%% Find out about the current DPI...
screen_DPI = get(0,'ScreenPixelsPerInch');

%% Capture current figure in high resolution
tempfile = 'myaa_temp_screendump.png';
self.source_fig = gcf;
current_paperpositionmode = get(self.source_fig,'PaperPositionMode');
current_inverthardcopy = get(self.source_fig,'InvertHardcopy');
set(self.source_fig,'PaperPositionMode','auto');
% set(self.source_fig,'InvertHardcopy','off');   % Keeps gray background.

if epsflag == 0
  print(self.source_fig,['-r',num2str(screen_DPI*self.K(1))], '-dpng', tempfile);

else
  disp('Export EPS at 1200 DPI');
  print(self.source_fig, '-r1200', '-deps2', fname);
  return;
end

set(self.source_fig,'InvertHardcopy',current_inverthardcopy);
set(self.source_fig,'PaperPositionMode',current_paperpositionmode);
self.raw_hires = imread(tempfile);
delete(tempfile);
    
%% Filter to remove aliasing
raw_lowres = single(imresize(self.raw_hires,1/self.K(2),'bilinear'))/256;

%% Write out resulting image
imwrite(raw_lowres, fname);

return;