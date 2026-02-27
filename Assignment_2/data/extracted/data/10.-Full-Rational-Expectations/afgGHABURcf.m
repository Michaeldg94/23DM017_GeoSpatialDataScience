clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [160.076862 0 0; 0 538.8641421 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('ghaburCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [65 140 0.15];

smax = [125 250 0.45]; 

[interp,s] = recsinterpinit(5,smin,smax)

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 102.4635;
BeeI = 170.4942;
for i=1:125;
    x(i,3) = (s(i,1)/BeeC)^(1/epsilon);
    x(i,4) = (s(i,2)/BeeI)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [96.28995346 220.7535362 0.166119749];
eHc = [-10.1413287429311 -7.54063487772524 -10.4708220933721 -22.5046343593434 0.876339917002667 10.2917559744979 18.6998918298187 4.98022937777762 13.3242440588826];
eHi = [-8.92583790316021 16.6089324741199 6.45489602709625 -14.4790444526758 25.3099619260447 -23.1030573783528 13.7172344904307 -42.2818633780921 -5.83739468155713];
ePw = [0.0177629331156131 0.0151033501751564 0.0336481044863532 0.177077692890763 -0.0530192132309143 -0.0325713061533154 0.073676305420605 0.026101279192895 -0.0121502390877558];

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

Hmean = [93.80499454 0;0  188.2173634];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct