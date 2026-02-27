clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [62.96124333 0;0 0.003625];

model = recsmodel('namCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [20 0.12];

smax = [40 0.32]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 48.77166;
for i=1:100;
    x(i,3) = Bee - s(i,1);
    x(i,2) = s(i,2) + 0.06825;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [14.58230388 0.143706768]; 
eH = [-12.0978010311477 -6.10637384896115 3.44561203897879 0.488372187469846 1.32930271991468 0.544938529906425 3.63425174909558 7.62367444553673 12.7521166865598];
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

Hmean = [26.19639736];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


