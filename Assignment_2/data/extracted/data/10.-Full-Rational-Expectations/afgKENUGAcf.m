clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [85.86365271 0 0; 0 190.9777979 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('kenugaCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [55 50 0.095];

smax = [110 120 0.35]; 

[interp,s] = recsinterpinit(5,smin,smax)

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 79.05389;
BeeI = 72.09776;
for i=1:125;
    x(i,3) = s(i,3) + 0.1233;
    x(i,4) = x(i,3) - 0.2044;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [79.9541991 64.12447108 0.114894167];
eHc = [-2.41864167438018 3.93125414210881 11.0791567733462 0.317182730921843 -16.2086903308486 -16.0186559887163 7.42656368510337 3.08611640040071 6.11351806123297];
eHi = [-17.4005184508294 -11.9704273492269 -13.5144492782303 -14.7117102160836 12.9501253853058 12.372329497508 10.6677293062116 14.3465826779035 13.8010793491937];
ePw = [-0.0174925 0.00627166666666668 0.0462858333333333 0.049965 -0.0114908333333333 -0.0284875 0.093695 0.0270741666666667 0.0299375];
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

Hmean = [77.2620029 0;0  70.665212];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct