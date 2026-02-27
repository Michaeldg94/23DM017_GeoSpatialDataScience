clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [137.1525115 0;0 0.003625];

model = recsmodel('lib.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [25 0.22];

smax = [50 0.65]; 

[interp,s] = recsinterpinit(4,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(16,4);
epsilon = -0.066;
Bee = 108.3292;
for i=1:16;
    x(i,3) = Bee - s(i,1);
    x(i,2) = 1;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [20.48509997 0.221889167]; 
eH = [-16.6981438047091 -8.50500171320365 -7.79493217396641 3.31377374441384 12.6280327719448 10.2662751476352 9.07299830947631 8.25808629360785 7.77804375936534];
ePw = [0.0578383333333333 0.0195141666666667 0.0137408333333334 0.305150833333333 -0.04686 -0.0745858333333332 0.0289975 0.0554316666666668 -0.0285100000000001];
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

Hmean = [38.80423231];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


