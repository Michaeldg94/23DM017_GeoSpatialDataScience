clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [12.44546253 0 0; 0 1795.516965 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('cdimal.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [50 150 0.20];

smax = [80 305 0.55]; 

[interp,s] = recsinterpinit(5,smin,smax)

%interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
%[interp,x] = recsSolveREE(interp,model,s)

%interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 101.4192;
BeeI = 234.6796;
for i=1:125;
    x(i,3) = s(i,3) + 0.3935;
    x(i,4) = x(i,3) - 0.1029;
    x(i,5) = BeeC - s(i,1);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [60.46111128 230.4552237 0.203518126];
eHc = [3.17329271473682 4.28551810170993 3.6834953142989 -7.16673241483168 -0.0774647856537811 -0.495041546140804 -0.240539733526546 -3.16896907773872 -2.0329776391421];
eHi = [-63.1231925241498 -44.1008348260567 -35.7219108790908 -26.8740006384048 20.4854048787661 58.2739668278193 49.1246764008431 16.9053296504052 39.0121603037145];
ePw = [0.0447171252383333 0.0179765587416667 0.0202460203258334 0.263550427398333 -0.048624444575 -0.0614860167958332 0.0443112709549999 0.0460966206816667 -0.0230218451775001];

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

Hmean = [58.42169221 0;0  244.4368229];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct