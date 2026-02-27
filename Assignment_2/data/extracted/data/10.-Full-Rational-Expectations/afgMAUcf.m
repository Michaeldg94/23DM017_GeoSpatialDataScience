clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [68.68127943 0;0 0.003625];

model = recsmodel('mauCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [20 0.17];

smax = [70 0.50]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 70.07557;
for i=1:100;
    x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [43.31841707 0.184000593]; 
eH = [-15.3786538639071 0.573016291841583 -3.27689747623442 -0.361236556893836 0.290674204691484 -3.70457055022845 15.4139244724664 -5.58856998264404 8.79228924256251];
ePw = [0.02987656012675 0.0172950267354166 0.0277474955138333 0.21273700054 -0.0534737995861667 -0.0392424838798332 0.0538756600704999 0.0325042144807501 -0.0183056167532501];

shocks = zeros (1,2,9);
shocks(1,1,1:9) = eH(1,1:9);
shocks(1,2,1:9) = ePw(1,1:9);
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

Hmean = [40.07839285];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


