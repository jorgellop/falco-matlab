% Copyright 2018, by the California Institute of Technology. ALL RIGHTS
% RESERVED. United States Government Sponsorship acknowledged. Any
% commercial use must be negotiated with the Office of Technology Transfer
% at the California Institute of Technology.
% -------------------------------------------------------------------------
%
% Function for regularized linear least-squares control (EFC).
% -This function performs an empirical grid search over these parameters:
%  a) a scalar coefficient for the regularization matrix
%  b) a scalar gain for the final DM command.
%
% -This code is based on electric field conjugation (EFC) as described 
% by Give'on et al. SPIE 2011.
%
%
% REVISION HISTORY:
% - Modified on 2019-06-25 by A.J. Riggs to pass out tied actuator pairs. 
% - Modified on 2018-07-24 to use Erkin's latest controller strategy.
% - Modified on 2018-02-06 by A.J. Riggs to be parallelized with parfor.
%   Required calling a new function. 
% - Modified by A.J. Riggs on October 11, 2017 to allow easier mixing of
%   which DMs are used and to also do a grid search over the gain of the 
%   overall DM command. 
% - Modified from hcil_ctrl_checkMuEmp.m by A.J. Riggs on August 31, 2016
% - Created at Princeton on 19 Feb 2015 by A.J. Riggs

function [dDM,cvarOut] = falco_ctrl_grid_search_EFC(mp,cvar)

    %--STEPS:
    % Step 0: [Done at begging of WFSC loop function] For this iteration, remove un-used DMs from the controller by changing mp.dm_ind value. 
    % Step 1: If re-linearizing this iteration, empirically find the best regularization value.
    % Step 2: For this iteration in the schedule, replace the imaginary part of the regularization with the latest "optimal" regularization
    % Step 3: Compute the EFC command to use.
    
    %% Initializations   
    if cvar.Itr<mp.aux.ItrDump 
        vals_list = allcomb(linspace(0,3,7),mp.ctrl.dmfacVec).';
    else
        vals_list = allcomb(mp.ctrl.log10regVec,mp.ctrl.dmfacVec).'; %--dimensions: [2 x length(mp.ctrl.muVec)*length(mp.ctrl.dmfacVec) ]
    end
    if mp.aux.flagRegDM9 && cvar.Itr>=mp.aux.firstRegDM9Itr
        NvalsRegdm9 = 5;
        vals_list_dm9 = linspace(mp.aux.betadm9Min,mp.aux.betadm9Max,NvalsRegdm9);
    else
        NvalsRegdm9 = 1;
        vals_list_dm9 = vals_list;
    end
    Nvals = max(size(vals_list,2));
    if mp.aux.flagOmega==1
        NvalsOmega = 5;
        valsOmega_list = linspace(mp.aux.omegaMin,mp.aux.omegaMax,NvalsOmega);
    else
        valsOmega_list = [-inf];
    end
    NvalsOmega = numel(valsOmega_list);
    Inorm_list = zeros(Nvals,NvalsOmega,NvalsRegdm9);
    thput_list = zeros(Nvals,NvalsOmega,NvalsRegdm9);

    % Temporarily store computed DM commands so that the best one does not have to be re-computed
    if(any(mp.dm_ind==1)); dDM1V_store = zeros(mp.dm1.Nact,mp.dm1.Nact,Nvals,NvalsOmega,NvalsRegdm9); end
    if(any(mp.dm_ind==2)); dDM2V_store = zeros(mp.dm2.Nact,mp.dm2.Nact,Nvals,NvalsOmega,NvalsRegdm9); end
    if(any(mp.dm_ind==5)); dDM5V_store = zeros(mp.dm5.Nact,mp.dm5.Nact,Nvals,NvalsOmega,NvalsRegdm9); end
    if(any(mp.dm_ind==8)); dDM8V_store = zeros(mp.dm8.NactTotal,Nvals,NvalsOmega,NvalsRegdm9); end
    if(any(mp.dm_ind==9)); dDM9V_store = zeros(mp.dm9.NactTotal,Nvals,NvalsOmega,NvalsRegdm9); end

    %% Empirically find the regularization value giving the best contrast
    
    %--Loop over all the settings to check empirically
    if(mp.flagParfor) %--Parallelized
        parfor ni = 1:Nvals
            for nj = 1:NvalsOmega
            for nk = 1:NvalsRegdm9
            if mp.aux.flagRegDM9 && cvar.Itr>=mp.aux.firstRegDM9Itr
                IInk=nk;
            else
                IInk=nj;
            end
            [Inorm_list(ni,nj,nk),thput_list(ni,nj,nk),dDM_temp] = falco_ctrl_EFC_base(ni,vals_list,nj,valsOmega_list,IInk,vals_list_dm9,mp,cvar);
            if(any(mp.dm_ind==1)); dDM1V_store(:,:,ni,nj,nk) = dDM_temp.dDM1V; end
            if(any(mp.dm_ind==2)); dDM2V_store(:,:,ni,nj,nk) = dDM_temp.dDM2V; end
            if(any(mp.dm_ind==5)); dDM5V_store(:,:,ni,nj,nk) = dDM_temp.dDM5V; end
            if(any(mp.dm_ind==8)); dDM8V_store(:,ni,nj,nk) = dDM_temp.dDM8V; end
            if(any(mp.dm_ind==9)); dDM9V_store(:,ni,nj,nk) = dDM_temp.dDM9V; end
            end
            end
            %--Tied actuators
            if(any(mp.dm_ind==1)); dm1tied{ni} = dDM_temp.dm1tied; end
            if(any(mp.dm_ind==2)); dm2tied{ni} = dDM_temp.dm2tied; end
        end
    else %--Not Parallelized
        for ni = 1:Nvals
            for nj = 1:NvalsOmega
                for nk = 1:NvalsRegdm9
                if mp.aux.flagRegDM9 && cvar.Itr>=mp.aux.firstRegDM9Itr
                    IInk=nk;
                else
                    IInk=nj;
                end
                [Inorm_list(ni,nj,nk),thput_list(ni,nj,nk),dDM_temp] = falco_ctrl_EFC_base(ni,vals_list,nj,valsOmega_list,IInk,vals_list_dm9,mp,cvar);
                if(any(mp.dm_ind==1)); dDM1V_store(:,:,ni,nj,nk) = dDM_temp.dDM1V; end
                if(any(mp.dm_ind==2)); dDM2V_store(:,:,ni,nj,nk) = dDM_temp.dDM2V; end
                if(any(mp.dm_ind==5)); dDM5V_store(:,:,ni,nj,nk) = dDM_temp.dDM5V; end
                if(any(mp.dm_ind==8)); dDM8V_store(:,ni,nj,nk) = dDM_temp.dDM8V; end
                if(any(mp.dm_ind==9)); dDM9V_store(:,ni,nj,nk) = dDM_temp.dDM9V; end
                end
            end
            %--Tied actuators
            if(any(mp.dm_ind==1)); dm1tied{ni} = dDM_temp.dm1tied; end
            if(any(mp.dm_ind==2)); dm2tied{ni} = dDM_temp.dm2tied; end
        end
    end

    %--Print out results to the command line
    fprintf('Scaling factor:\t')
    for ni=1:Nvals;  fprintf('%.2f\t\t', vals_list(2,ni) );  end

    fprintf('\nlog10reg:\t');
    for ni=1:Nvals;  fprintf('%.1f\t\t',vals_list(1,ni));  end

    fprintf('\nInorm:  \t')
    for ni=1:Nvals;  fprintf('%.2e\t',Inorm_list(ni));  end
    fprintf('\n')

    %--Find the best scaling factor and Lagrange multiplier pair based on the best contrast.
    [cvarOut.cMin,indBest] = min(Inorm_list(:)./(thput_list(:).^2));
%     [cvarOut.cMin,indBest] = min(Inorm_list(:));
    [indBest,indBestOmega,indBestRegDM9] = ind2sub(size(Inorm_list),indBest);
    mp.aux.omega = valsOmega_list(indBestOmega);
%     indBest = indBest - 1; %JLlop
%     cvarOut.cMin = Inorm_list(indBest);
%     
%     if(any(mp.dm_ind==1)); dDM.dDM1V = dDM1V_store(:,:,indBest); end
%     if(any(mp.dm_ind==2)); dDM.dDM2V = dDM2V_store(:,:,indBest); end
%     if(any(mp.dm_ind==5)); dDM.dDM5V = dDM5V_store(:,:,indBest); end
%     if(any(mp.dm_ind==8)); dDM.dDM8V = dDM8V_store(:,indBest); end
%     if(any(mp.dm_ind==9)); dDM.dDM9V = dDM9V_store(:,indBest); end

    
    val = vals_list(1,indBest)-mp.aux.betaMinusOne;
    if ismember(val,vals_list)
        indBest=find(vals_list(1,:)==val);
    	cvarOut.log10regUsed = vals_list(1,indBest);
    	cvarOut.omegaUsed = mp.aux.omega;
    	cvarOut.regDM9Used = vals_list_dm9(indBestRegDM9);
        cvarOut.cMin = Inorm_list(indBest);
        dmfacBest = vals_list(2,indBest);
        if(any(mp.dm_ind==1)); dDM.dDM1V = dDM1V_store(:,:,indBest,indBestOmega,indBestRegDM9); end
        if(any(mp.dm_ind==2)); dDM.dDM2V = dDM2V_store(:,:,indBest,indBestOmega,indBestRegDM9); end
        if(any(mp.dm_ind==5)); dDM.dDM5V = dDM5V_store(:,:,indBest,indBestOmega,indBestRegDM9); end
        if(any(mp.dm_ind==8)); dDM.dDM8V = dDM8V_store(:,indBest,indBestOmega,indBestRegDM9); end
        if(any(mp.dm_ind==9)); dDM.dDM9V = dDM9V_store(:,indBest,indBestOmega,indBestRegDM9); end
    %--Tied actuators
    if(any(mp.dm_ind==1)); dDM.dm1tied = dm1tied{indBest}; end
    if(any(mp.dm_ind==2)); dDM.dm2tied = dm2tied{indBest}; end
    else
        % OUT OF DATE
        vals_listaux = [val;vals_list(2,indBest)];
        [Inorm,thput,dDM_temp] = falco_ctrl_EFC_base(1,vals_listaux,mp,cvar);
        cvarOut.log10regUsed = val;
        cvarOut.cMin = Inorm;
        dmfacBest = vals_list(2,indBest);
        if(any(mp.dm_ind==1)); dDM.dDM1V = dDM_temp.dDM1V; end
        if(any(mp.dm_ind==2)); dDM.dDM2V = dDM_temp.dDM2V; end
        if(any(mp.dm_ind==5)); dDM.dDM5V = dDM_temp.dDM5V; end
        if(any(mp.dm_ind==8)); dDM.dDM8V = dDM_temp.dDM8V; end
        if(any(mp.dm_ind==9)); dDM.dDM9V = dDM_temp.dDM9V; end
    end
    fprintf('Empirical grid search gives log10reg, = %.1f,\t dmfac = %.2f\t   gives %4.2e contrast.\n',cvarOut.log10regUsed, dmfacBest, cvarOut.cMin)

    if(mp.flagPlot)
        if(length(mp.ctrl.dmfacVec)==1)
            figure(499); semilogy(mp.ctrl.log10regVec,Inorm_list(:,indBestOmega,indBestRegDM9),'-bd','Linewidth',3)
            title('Line Search EFC','Fontsize',20,'Interpreter','Latex');
            xlabel('log10(regularization)','Fontsize',20,'Interpreter','Latex');
            ylabel('log10(Inorm)','Fontsize',20,'Interpreter','Latex');
            set(gca,'Fontsize',20); set(gcf,'Color',[1 1 1]); grid on;
            drawnow;
            if mp.aux.flagOmega
            figure(498); semilogy(valsOmega_list,Inorm_list(indBest,:,indBestRegDM9),'-bd','Linewidth',3)
            title('Line Search EFC','Fontsize',20,'Interpreter','Latex');
            xlabel('vals_list_omega','Fontsize',20,'Interpreter','Latex');
            ylabel('log10(Inorm)','Fontsize',20,'Interpreter','Latex');
            set(gca,'Fontsize',20); set(gcf,'Color',[1 1 1]); grid on;
            drawnow;
            end
            if mp.aux.flagRegDM9 && cvar.Itr>=mp.aux.firstRegDM9Itr
            figure(497); semilogy(vals_list_dm9,squeeze(Inorm_list(indBest,indBestOmega,:)),'-bd','Linewidth',3)
            title('Line Search EFC','Fontsize',20,'Interpreter','Latex');
            xlabel('vals_list_dm9','Fontsize',20,'Interpreter','Latex');
            ylabel('log10(Inorm)','Fontsize',20,'Interpreter','Latex');
            set(gca,'Fontsize',20); set(gcf,'Color',[1 1 1]); grid on;
            drawnow;
            end
        elseif(length(mp.ctrl.dmfacVec)>1)
            figure(499); imagesc(mp.ctrl.log10regVec,mp.ctrl.dmfacVec,reshape(log10(Inorm_list),[length(mp.ctrl.dmfacVec),length(mp.ctrl.log10regVec)])); 
            ch = colorbar; axis xy tight;
            title('Grid Search EFC','Fontsize',20,'Interpreter','Latex');
            xlabel('log10(regularization)','Fontsize',20,'Interpreter','Latex');
            ylabel('Proportional Gain','Fontsize',20,'Interpreter','Latex');
            ylabel(ch,'log10(Inorm)','Fontsize',20,'Interpreter','Latex');
            set(gca,'Fontsize',20); set(gcf,'Color',[1 1 1]);
            drawnow;
        end
    end
%%
end %--END OF FUNCTION