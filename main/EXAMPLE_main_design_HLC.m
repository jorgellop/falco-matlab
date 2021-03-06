% Copyright 2018-2021 by the California Institute of Technology. ALL RIGHTS
% RESERVED. United States Government Sponsorship acknowledged. Any
% commercial use must be negotiated with the Office of Technology Transfer
% at the California Institute of Technology.
% -------------------------------------------------------------------------
%
% Script to perform an example HLC design run. This is NOT an official 
% HLC design for the WFIRST CGI.

clear

%% Step 1: Define Necessary Paths on Your Computer System

%--Required packages are FALCO and PROPER. 
% Add FALCO to the MATLAB path with the command:  addpath(genpath(full_path_to_falco)); savepath;
% Add PROPER to the MATLAB path with the command:  addpath(full_path_to_proper); savepath;

%%--Output Data Directories (Comment these lines out to use defaults within falco-matlab/data/ directory.)
% mp.path.config = ; %--Location of config files and minimal output files. Default is [mp.path.falco filesep 'data' filesep 'brief' filesep]
% mp.path.ws = ; % (Mostly) complete workspace from end of trial. Default is [mp.path.falco filesep 'data' filesep 'ws' filesep];
% mp.flagSaveWS = false;  %--Whether to save out entire (large) workspace at the end of trial. Default is false


%% Step 2: Load default model parameters

EXAMPLE_defaults_design_HLC


%% Step 3: Overwrite default values as desired

%%--Special Computational Settings
mp.flagParfor = true; %--whether to use parfor for Jacobian calculation
mp.flagPlot = true;

%--Record Keeping
mp.SeriesNum = 1;
mp.TrialNum = 1;

% %--Force DM9 to be mirror symmetric about y-axis
% NactTotal = ceil_even(mp.dm9.actres*mp.F3.Rin*2)^2; %-NOTE: This will be different if influence function for DM9 is not '3x3'. Needs to be the same value as mp.dm9.NactTotal, which is calculated later.
% Nact = sqrt(NactTotal);
% LinIndMat = zeros(Nact); %--Matrix of the linear indices
% LinIndMat(:) = 1:NactTotal;
% FlippedLinIndMat = fliplr(LinIndMat);
% mp.dm9.tied = zeros(NactTotal/2,2);
% for jj=1:NactTotal/2
%     mp.dm9.tied(jj,1) = LinIndMat(jj);
%     mp.dm9.tied(jj,2) = FlippedLinIndMat(jj);
% end


%%--[OPTIONAL] Start from a previous FALCO trial's DM settings
% fn_prev = 'ws_Series0002_Trial0001_HLC_WFIRST20180103_2DM48_z1_IWA2.7_OWA10_6lams575nm_BW12.5_EFC_30its.mat';
% temp = load(fn_prev,'out');
% mp.dm1.V = temp.out.DM1V;
% mp.dm2.V = temp.out.DM2V;
% clear temp

% %--DEBUGGING ONLY: Monochromatic light
% mp.fracBW = 0.01;       %--fractional bandwidth of the whole bandpass (Delta lambda / lambda0)
% mp.Nsbp = 1;            %--Number of sub-bandpasses to divide the whole bandpass into for estimation and control
% mp.flagParfor = false; %--whether to use parfor for Jacobian calculation

% mp.Nsbp = 4;            %--Number of sub-bandpasses to divide the whole bandpass into for estimation and control


mp.ctrl.sched_mat = [...
    repmat([1, 1j, 129, 1, 1], [4,1]);...
    ];
[mp.Nitr, mp.relinItrVec, mp.gridSearchItrVec, mp.ctrl.log10regSchedIn, mp.dm_ind_sched] = falco_ctrl_EFC_schedule_generator(mp.ctrl.sched_mat);


%% Step 4: Generate the label associated with this trial

mp.runLabel = ['Series',num2str(mp.SeriesNum,'%04d'),'_Trial',num2str(mp.TrialNum,'%04d_'),...
    mp.coro,'_',mp.whichPupil,'_',num2str(numel(mp.dm_ind)),'DM',num2str(mp.dm1.Nact),'_z',num2str(mp.d_dm1_dm2),...
    '_IWA',num2str(mp.Fend.corr.Rin),'_OWA',num2str(mp.Fend.corr.Rout),...
    '_',num2str(mp.Nsbp),'lams',num2str(round(1e9*mp.lambda0)),'nm_BW',num2str(mp.fracBW*100),...
    '_',mp.controller];


%% Step 5: Perform the Wavefront Sensing and Control

mp.dm9.weight = 4; % Jacobian weight for the FPM dielectric. Smaller weight makes stroke larger by the inverse of this factor.

[mp, out] = falco_flesh_out_workspace(mp);

[mp, out] = falco_wfsc_loop(mp, out);

%%

mp.dm9.weight = 2; % Jacobian weight for the FPM dielectric. Smaller weight makes stroke larger by the inverse of this factor.

[mp, out] = falco_wfsc_loop(mp, out);

%%

mp.dm9.weight = 1; % Jacobian weight for the FPM dielectric. Smaller weight makes stroke larger by the inverse of this factor.

[mp, out] = falco_wfsc_loop(mp, out);

%%
mp.ctrl.sched_mat = [...
    repmat([1, 1j, 12, 1, 1], [10,1]);...
    ];
[mp.Nitr, mp.relinItrVec, mp.gridSearchItrVec, mp.ctrl.log10regSchedIn, mp.dm_ind_sched] = falco_ctrl_EFC_schedule_generator(mp.ctrl.sched_mat);

[mp, out] = falco_wfsc_loop(mp, out);
