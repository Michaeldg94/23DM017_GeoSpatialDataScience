clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [197.5867141 0 0; 0 2665.368074 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('mozmal.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [40 90 0.15];

smax = [100 290 0.45]; 

[interp,s] = recsinterpinit(5,smin,smax)

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 69.96438;
BeeI = 168.9825;
for i=1:125;
    if (s(i,1)/BeeC)^(1/epsilon)> s(i,3) + 0.2709;
        x(i,3) = s(i,3) + 0.2709;
    else
        x(i,3) = (s(i,1)/BeeC)^(1/epsilon);
    end;
    if (s(i,2)/BeeI)^(1/epsilon)> s(i,3) + 0.526;
        x(i,4) = s(i,3) + 0.526;
    else
        x(i,4) = (s(i,2)/BeeI)^(1/epsilon);
    end;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [63.09827881 162.0624478 0.15010428];
eHc = [-13.2207909739084 -21.1443340405551 0.61170575572261 6.36418620289193 8.14192516462224 5.94841772218984 4.54865292977378 27.744869892738 -14.1336132357321];
eHi = [-66.3464437693415 -99.5095591946001 1.93406264749342 40.9616093251306 -7.95382697645391 51.5186781247037 33.445587537746 45.0032506019861 33.1912833815911];
ePw = [0.0162217647028333 0.0110069179995 0.03170475736725 0.0656064664839167 0.126598358135417 -0.0873792973793333 0.0212883476334166 0.062688464612 0.02212340452075];
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

Hmean = [67.95929823 0;0  194.3070895];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct