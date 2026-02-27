clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0];

vars = [0.003625];

model = recsmodel('dji2cf.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [0 0.20];

smax = [40 0.65]; 

[interp,s] = recsinterpinit(4,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(16,4);
epsilon = -0.066;
Bee = 45.0233;
for i=1:16;
    x(i,3) = Bee;
    x(i,2) = s(i,2) + 0.05;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [0 0.221889167]; 
ePw = [0.0578383333333333 0.0195141666666667 0.0137408333333334 0.305150833333333 -0.04686 -0.0745858333333332 0.0289975 0.0554316666666668 -0.0285100000000001];
shocks = zeros (1,1,9);
shocks(1,1,1:9) = ePw(1,1:9);
shocks

%[ssim,xsim] = recsSimul(model,interp,s0,nper,shocks);
[ssim,xsim] = recsSimul(model,interp,s0,10,shocks,struct('simulmethod','solve'))

SPMX = zeros(10,4);
for i=1:10;
    for j=1:4;
        SPMX(i,j) = xsim(1,j,i);
    end;
end;
SPMX

Hmean = [0];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


