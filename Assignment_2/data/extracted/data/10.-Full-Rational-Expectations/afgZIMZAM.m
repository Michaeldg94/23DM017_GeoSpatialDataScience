clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [841.6561741 0 0; 0 2771.952946 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('zimzam.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [35 70 0.12];

smax = [150 300 0.30]; 

[interp,s] = recsinterpinit(5,smin,smax)

%interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
%[interp,x] = recsSolveREE(interp,model,s)

%interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 105.4909;
BeeI = 105.4909;
for i=1:125;
    if s(i,1) < BeeC;
        x(i,3) = s(i,3) + 0.115;
    else
        x(i,3) = s(i,3) - 0.115;
    end;
    if s(i,2) < BeeI;
        x(i,4) = s(i,3) + 0.115+0.0807;
    else
        x(i,4) = (s(i,2)/BeeC)^(1/epsilon) + 0.05;
    end;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [83.56280226 106.2791299 0.143706768];
eHc = [47.90802576617 -12.9164795696394 31.7606071729769 -10.161065638717 -46.1341233896352 -30.6222749193135 6.25057289157431 27.3535586829425 -12.069126174892];
eHi = [-31.7881783106493 -64.9094613092174 -19.5266637199419 -27.6110011113892 -43.1633805682203 6.70799938058701 71.0799326786388 81.1093195090516 62.2492311737591];
ePw = [-0.0136010320483176 0.00780088449784161 0.063813200370607 0.0479755741607352 -0.0452850827431783 -0.0233127167468322 0.00382795845454759 0.108078194526022 -0.0242278676752766];
shocks = zeros (1,3,9);
shocks(1,1,1:9) = eHc(1,1:9);
shocks(1,2,1:9) = eHi(1,1:9);
shocks(1,3,1:9) = ePw(1,1:9);
shocks

%[ssim,xsim] = recsSimul(model,interp,s0,nper,shocks);
[ssim,xsim] = recsSimul(model,interp,s0,10,shocks,struct('simulmethod','solve'))

SPMX = zeros(10,8);
for i=1:10;
    for j=1:8;
        SPMX(i,j) = xsim(1,j,i);
    end;
end;
SPMX

Hmean = [84.93249708 0;0  140.4269276];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct