% Copyright 2018-2020, by the California Institute of Technology. ALL RIGHTS
% RESERVED. United States Government Sponsorship acknowledged. Any
% commercial use must be negotiated with the Office of Technology Transfer
% at the California Institute of Technology.
% -------------------------------------------------------------------------
clear all;

%--Load true pupil (which isn't centered in its file)
pupil0 = imread('pupil_CGI-20200513_8k_binary_noF.png');
pupilFromFile = double(pupil0)/double(max(pupil0(:)));
Narray = size(pupilFromFile,1);

%--Generate pupil representation in FALCO
Nbeam = 2*4027.25;
centering = 'pixel';
changes.xShear = -0.5/Nbeam; 
changes.yShear = -52.85/Nbeam;
pupilFromFALCO = falco_gen_pupil_Roman_CGI_20200513(Nbeam, centering, changes);
pupilFromFALCO = pad_crop(pupilFromFALCO, Narray);

diff = pupilFromFile - pupilFromFALCO;
errorSum = sum(sum(abs(diff)));
fprintf('sum of mismatch = %.2f\n', errorSum)
fprintf('sum of underpadded pixels = %.2f\n', sum(diff(diff<-0.5)))
fprintf('sum of overpadded pixels  = %.2f\n', sum(diff(diff>0.5)))

figure(1); imagesc(pupilFromFile); axis xy equal tight; colorbar; drawnow;
figure(2); imagesc(pupilFromFALCO); axis xy equal tight; colorbar; drawnow;
figure(3); imagesc(diff, [-1 1]); axis xy equal tight; colorbar; colormap gray; drawnow;
figure(4); imagesc(-abs(diff), [-1 0]); axis xy equal tight; colorbar; colormap gray; drawnow;

%% Verify at lower res that the fit is still correct
dsfac = 16; % downsampling factor
NbeamDS = Nbeam/dsfac;
NarrayDS = Narray/dsfac;
pupilFromFileDS = falco_bin_downsample(pupilFromFile, dsfac);

shift = dsfac/2-0.5;
changes.xShear = -0.5/Nbeam - shift/Nbeam; 
changes.yShear = -52.85/Nbeam - shift/Nbeam;

pupilFromFALCODS = falco_gen_pupil_Roman_CGI_20200513(NbeamDS, centering, changes);
pupilFromFALCODS = pad_crop(pupilFromFALCODS, NarrayDS);

diff2 = pupilFromFileDS - pupilFromFALCODS;
errorSum2 = sum(sum(abs(diff2)));
fprintf('sum of mismatch at lower res = %.2f\n', errorSum2)

figure(11); imagesc(pupilFromFileDS); axis xy equal tight; colorbar; drawnow;
figure(12); imagesc(pupilFromFALCODS); axis xy equal tight; colorbar; drawnow;
figure(13); imagesc(pupilFromFileDS - pupilFromFALCODS, 0.1*[-1 1]); axis xy equal tight; colorbar; colormap gray; drawnow;

%% Verify at lower res that the fit is still correct
dsfac = 8; % downsampling factor
NbeamDS = Nbeam/dsfac;
NarrayDS = Narray/dsfac;
pupilFromFileDS = falco_bin_downsample(pupilFromFile, dsfac);

shift = dsfac/2-0.5;
changes.xShear = -0.5/Nbeam - shift/Nbeam; 
changes.yShear = -52.85/Nbeam - shift/Nbeam;

pupilFromFALCODS = falco_gen_pupil_Roman_CGI_20200513(NbeamDS, centering, changes);
pupilFromFALCODS = pad_crop(pupilFromFALCODS, NarrayDS);

diff3 = pupilFromFileDS - pupilFromFALCODS;
errorSum3 = sum(sum(abs(diff3)));
fprintf('sum of mismatch at lower res = %.2f\n', errorSum3)

figure(21); imagesc(pupilFromFileDS); axis xy equal tight; colorbar; drawnow;
figure(22); imagesc(pupilFromFALCODS); axis xy equal tight; colorbar; drawnow;
figure(23); imagesc(pupilFromFileDS - pupilFromFALCODS, 0.2*[-1 1]); axis xy equal tight; colorbar; colormap gray; drawnow;
