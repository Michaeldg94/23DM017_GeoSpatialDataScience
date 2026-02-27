clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [466.1535147 0;0 0.003625];

model = recsmodel('et.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [100 0.095];

smax = [200 0.34]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 142.9779;
for i=1:100;
    x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [112.3606547 0.130893]; 
eH = [-28.729000439806 1.04229436763237 -5.07195357944016 -11.0970550127289 -4.93082846715816 3.12823425298657 8.79545120756487 29.1032580163898 37.282690753163];
ePw = [-0.015279164 0.009630849 0.055746383 0.077144944 -0.088145426 0.016735859 0.099200342 -0.010677295 0.008859134];

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

Hmean = [141.8837458];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


