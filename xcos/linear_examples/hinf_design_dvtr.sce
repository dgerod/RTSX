// HINF_DESIGN_DVTR.SCE   perform H-inf design on servo robot joint   
// output disturbance attenuation on velocity loop
// tracking 
// Varodom Toochinda, January 2013
//
xdel(winsid());
ka1 = 0.5; ka2 = 1000; km1 = 0.1471; km2 = 0.26; ke = 0.1996; jm = 0.000156; bm = 0.001;  
kr = 1; tau = 0.0044; wn=2*%pi*30; z = 0.7; r2d = 180/%pi;
s=poly(0,'s');
// real plant
// real plant

pxv = syslin('c',ka1*ka2*km1*km2/(tau*s+1+ka2*km1));
pqxnum = (tau*s+1+ka2*km1)^2*((1-jm*wn^2)*s^2+2*z*wn*s+wn^2);
pqxden = (s+0.0001)*((jm*s+bm)*(tau*s+1+ka2*km1)^2+(tau*s+1)*km1*km2*ke)*(s^2+2*z*wn*s+wn^2);
pqx = syslin('c',r2d*pqxnum/pqxden);
Pqv = pqx*pxv;

pd = pqx;
// plant model obtained from experiment. Parameter errors are random within 10% of real
// values

ka1_a = ka1 + 0.1*ka1*(rand()-0.5);
ka2_a = ka2 + 0.1*ka2*(rand()-0.5);
km1_a = km1 + 0.1*km1*(rand()-0.5);
km2_a = km2 + 0.1*km2*(rand()-0.5);
ke_a = ke + 0.1*ke*(rand()-0.5);
jm_a = jm + 0.1*jm*(rand()-0.5);
bm_a = bm + 0.1*bm*(rand()-0.5);
tau_a = tau + 0.1*tau*(rand()-0.5);
wn_a = wn + 0.2*wn*(rand()-0.5);

pxv_a = syslin('c',ka1_a*ka2_a*km1_a*km2_a/(tau_a*s+1+ka2_a*km1_a));
pqxnum_a = (tau_a*s+1+ka2_a*km1_a)^2*((1-jm_a*wn_a^2)*s^2+2*z*wn_a*s+wn_a^2);
pqdotxden_a = ((jm_a*s+bm_a)*(tau_a*s+1+ka2_a*km1_a)^2+(tau_a*s+1)*km1_a*km2_a*ke_a)*(s^2+2*z*wn_a*s+wn_a^2);
pqxden_a = (s+0.001)*pqdotxden_a;
pqx_a = syslin('c',r2d*pqxnum_a/pqxden_a);

pqdotx_a = syslin('c',pqxnum_a/pqdotxden_a);
Pqdotv_a = pqdotx_a*pxv_a;  // t.f from input to velocity output
Pqv_a = pqx_a*pxv_a;        // t.f. from input to angle output

pdv=pqdotx_a;

// compute frequency responses
[frq,pqures]=repfreq(Pqv,0.01,1000);
[frq1,pqures_a]=repfreq(Pqv_a, frq);
frq=frq';
fsize = size(frq,1);
pqumag = zeros(fsize,1);
pquph = zeros(fsize,1);
pqumag_a = zeros(fsize,1);
pquph_a = zeros(fsize,1);

for k=1:fsize,
    [pqumag(k),pquph(k)]=polar(pqures(k));
    [pqumag_a(k),pquph_a(k)]=polar(pqures_a(k));    
end
pquph = pquph*180/%pi;
pquph_a = pquph_a*180/%pi;
figure(1);
subplot(211),plot2d("ln",frq,[20*log10(pqumag) 20*log10(abs(pqumag_a))]);
ylabel('Magnitude (dB)');
subplot(212),plot2d("ln",frq,[20*log10(abs(pquph)) 20*log10(abs(pquph_a))]);
ylabel('Phase (degree)');
xlabel('Frequency (Hz)');

// control design starts here
// performance weighting function on S
a=0.0000002; m=2; wb=300;
//w1_n=((1/m)*s+wb);
//w1_d=(s+wb*a);
w1_n=((1/m^(1/2))*s+wb)^2;
w1_d=(s+wb*a^(1/2))^2;
//w1_n=((1/m^(1/3))*s+wb)^3;
//w1_d=(s+wb*a^(1/3))^3;
w1 = syslin('c',w1_n,w1_d);

// weighting on KS
w2_d=2*(s/1000 + 1);
w2_n=s/300+1;
w2 = syslin('c',w2_n,w2_d);

// plot weighting functions
figure(2);
subplot(211), gainplot(1/w1);
gainplot(1/pdv);
ylabel('magnitude (dB)');
title('1/w1');
subplot(212), gainplot(1/w2);
ylabel('magnitude (dB)');
title('1/w2');

//return;
// form generalized plant
//N = [wp_n, wp_n*Pqunum_a; 0, wt_n*Pqunum_a; 1, Pqunum_a];
//D = [wp_d, wp_d*Pquden_a; 1, wt_d*Pquden_a; 1, Pquden_a];
//Pgen=syslin('c',N,D);
[Ap1,Bp1,Cp1,Dp1]=abcd(Pqdotv_a);
[Aw1,Bw1,Cw1,Dw1]=abcd(w1);
[Aw2,Bw2,Cw2,Dw2]=abcd(w2);

ap1_r=size(Ap1,1); ap1_c = size(Ap1,2);
aw1_r=size(Aw1,1); aw1_c = size(Aw1,2);
aw2_r=size(Aw2,1); aw2_c = size(Aw2,2);

bp1_r=size(Bp1,1);
bw1_r=size(Bw1,1);
bw2_r=size(Bw2,1);

cp1_c = size(Cp1,2);
cw1_c = size(Cw1,2);
cw2_c = size(Cw2,2);

Agp1 = [Ap1 zeros(ap1_r,aw1_c) zeros(ap1_r,aw2_c);
       Bw1*Cp1 Aw1 zeros(aw1_r,aw2_c);
     zeros(aw2_r,ap1_c) zeros(aw2_r,aw1_c) Aw2];
Bgp1 = [zeros(bp1_r,1) -Bp1;
        Bw1 zeros(bw1_r,1);
        zeros(bw2_r,1) Bw2];
Cgp1 = [Dw1*Cp1 Cw1 zeros(1,cw2_c);
        zeros(1,cp1_c) zeros(1,cw1_c) Cw2;
        Cp1 zeros(1,cw1_c) zeros(1,cw2_c)];
Dgp1 = [Dw1 0.001; 0 Dw2;1 0];
  // makes D12 full rank


Pgen1=syslin('c',Agp1,Bgp1,Cgp1,Dgp1);

// use h_inf function
//[Skv,ro]=h_inf(Pgen1, [1,1],0, 200000, 100);
//[Akv,Bkv,Ckv,Dkv]=abcd(Skv);

//use hinf function
[Akv,Bkv,Ckv,Dkv]=hinf(Agp1,Bgp1,Cgp1,Dgp1,1,1,50);
Skvf=syslin('c',Akv,Bkv,Ckv,Dkv);

// controller reduction
Skv = kreduced(Skvf,4);

// form closed-loop system and check stability

Lv_a = Skv*Pqdotv_a;
Sv_a=1/(1+Lv_a);
Tv_a = 1 - Sv_a;
//figure(3)
//gainplot(Sv_a);
//title('Sensitivity S(s)');
//figure(4)
//gainplot(Tv_a);
//title('Complementary sensitivity T(s)');
[Aclv_a,Bclv_a,Cclv_a,Dclv_a]=abcd(Tv_a);

// -------------now, design controller for position loop ----------------
Pint = syslin('c',r2d/(s+0.0001));  // replace integrator with LF pole
Pint = tf2ss(Pint);
P2 = Tv_a*Pint;
figure(5), bode(P2);
title('Plant with velocity control loop');

// performance weighting function on S
a=0.0002; m=4; wb=50;
wp_n=((1/m)*s+wb);
wp_d=(s+wb*a);
wp = syslin('c',wp_n,wp_d);
// weighting on T
wt_d=2*(s/1000 + 1);
wt_n=s/300+1;
wt = syslin('c',wt_n,wt_d);

// plot weighting functionsex
figure(6);
subplot(211), gainplot(1/wp);
ylabel('magnitude (dB)');
title('Weight on S');
subplot(212), gainplot(1/wt);
ylabel('magnitude (dB)');
title('Weight on T');

[Ap2,Bp2,Cp2,Dp2]=abcd(P2);
[Awp,Bwp,Cwp,Dwp]=abcd(wp);
[Awt,Bwt,Cwt,Dwt]=abcd(wt);

Agp2=[Ap2 zeros(size(Ap2,1),size(Awp,2)) zeros(size(Ap2,1),size(Awt,2));
    -Bwp*Cp2 Awp zeros(size(Awp,1),size(Awt,2));
    Bwt*Cp2 zeros(size(Awt,1),size(Awp,2)) Awt];
Bgp2 = [zeros(size(Bp2,1),size(Bwp,2)) Bp2; 
        Bwp zeros(size(Bwp,1),size(Bp2,2));
        zeros(size(Bwt,1),size(Bwp,2)) zeros(size(Bwt,1),size(Bp2,2))];
Cgp2 = [-Dwp*Cp2 Cwp zeros(size(Cwp,1),size(Cwt,2));
        zeros(size(Cwt,1),size(Cp2,2)) zeros(size(Cwt,1),size(Cwp,2)) Cwt;
        -Cp2 zeros(size(Cp2,1),size(Cwp,2)) zeros(size(Cp2,1),size(Cwt,2))];
Dgp2 = [Dwp 0.001; 0 Dwt;1 0];  // makes D12 full rank

Pgen2=syslin('c',Agp2,Bgp2,Cgp2,Dgp2);
//[Skf,ro]=h_inf(Pgen2, [1,1],0, 200000, 100);
[Akf,Bkf,Ckf,Dkf]=hinf(Agp2,Bgp2,Cgp2,Dgp2,1,1,100);
Skf=syslin('c',Akf,Bkf,Ckf,Dkf);
//Sk=kreduced(Skf);
Sk=Skf;
// form closed-loop system and check stability
L=Sk*Pqv;
S=1/(1+L); T = 1 -S;
[Acl,Bcl,Ccl,Dcl]=abcd(T);
figure(7)
gainplot(S);
figure(8)
gainplot(T);
L_a = Sk*Pqv_a;
S_a=1/(1+L_a);
T_a = 1 - S_a;
[Acl_a,Bcl_a,Ccl_a,Dcl_a]=abcd(T_a);
[Ak,Bk,Ck,Dk]=abcd(Sk);  // controller
