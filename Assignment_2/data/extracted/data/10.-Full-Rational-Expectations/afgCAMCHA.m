clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [128.5257403 0 0; 0 741.6248527 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('camcha.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [50 90 0.15];

smax = [90 200 0.45]; 

[interp,s] = recsinterpinit(5,smin,smax)

%interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
%[interp,x] = recsSolveREE(interp,model,s)

%interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 90.72067;
BeeI = 115.9312;
for i=1:125;
    x(i,3) = s(i,3)+0.426;
    x(i,4) = x(i,3) - 0.2193;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [54.72082926 137.4352057 0.157151329];
eHc = [-15.0168943427886 -11.5136524498511 -2.13289627840793 0.0337887842301967 2.04944297260081 13.6418794652855 14.2526178575343 8.08832225810818 7.36199309650267];
eHi = [-41.2964631836355 9.79771994646447 12.5315611873464 -10.296554849379 4.17768788094676 -6.27896399659991 -0.17265676874365 -30.3924107487434 60.2216384596251];
ePw = [0.0116004179443333 0.0140957795316667 0.0366645064868333 0.158554876936333 -0.053077738365 -0.0284232998008333 0.082961802721 0.0225358339596667 -0.0091702535005001];
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

Hmean = [71.48543062 0;0  135.7267636];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct