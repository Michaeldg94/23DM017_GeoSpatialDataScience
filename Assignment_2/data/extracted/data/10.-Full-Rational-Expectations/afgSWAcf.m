clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [181.2788951 0;0 0.003625];

model = recsmodel('swaCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [30 0.12];

smax = [71 0.32]; 

[interp,s] = recsinterpinit(4,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(16,4);
epsilon = -0.066;
Bee = 105.4909;
for i=1:16;
    x(i,3) = Bee - s(i,1);
    x(i,2) = s(i,2) + 0.01785;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [63.67419197 0.143706768]; 
eH = [5.60716339982707 10.8923851515468 3.44196474171748 -33.5287543856995 -4.57982443605481 -8.0152467966013 0.405601151742459 13.5363235638343 5.15268599320437];
ePw = [-0.0136010320483176 0.00780088449784161 0.063813200370607 0.0479755741607352 -0.0452850827431783 -0.0233127167468322 0.00382795845454759 0.108078194526022 -0.0242278676752766];
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

Hmean = [56.58649036];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


