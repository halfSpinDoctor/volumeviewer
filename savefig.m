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
% v2.2 26-Jan-2016
%
% Changelog:
%
%  v1.0 - Basic saveas(gcf, '') implementation (Dec-2010)
%  v2.0 - based on myaa (anti-aliased figure generator)
%         added a flag for EPS
%  v2.1 - Warning off to avoid EPS export errors.
%  v2.2 - Update header to include BSD licence (Jan-2016)



% Copyright (c) 2010-2016, Samuel A. Hurley (samuel.hurley@gmail.com)
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


function [] = savefig(fname, epsflag)

warning off; %#ok<WNOFF>

if ~exist('epsflag', 'var')
  epsflag = 0;
end

%% Set default options and interpret arguments
self.K = [8 4];
self.figmode = 'figure';

%% Find out about the current DPI...
screen_DPI = get(0,'ScreenPixelsPerInch');
disp(['Screen DPI: ' num2str(screen_DPI)]);

%% Capture current figure in high resolution
tempfile = 'myaa_temp_screendump.png';
self.source_fig = gcf;
current_paperpositionmode = get(self.source_fig,'PaperPositionMode');
current_inverthardcopy    = get(self.source_fig,'InvertHardcopy');
set(self.source_fig,'PaperPositionMode','auto');
% set(self.source_fig,'InvertHardcopy','off');   % Keeps gray background.

% Set font to Nimbus Sans L, for Linux/UNIX compat. -- done in Startup.m
% fontName = 'Nimbus Sans L';
% set(get(gcf,'CurrentAxes'),'FontName',fontName,'FontSize',12);

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

warning on; %#ok<WNON>
return;