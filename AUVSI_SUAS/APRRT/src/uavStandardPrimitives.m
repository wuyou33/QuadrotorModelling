close all
clear
clc

t_0=0; %time
t_f=10;
totT = t_f - t_0;

delta_t = 1.0;

x_0 = [ 50;50;20];
x_f = [ 80;80;20];

clock= Clock(delta_t);

 % state       x      y     psi    phi
q_0 =  [x_0(1,1) ; x_0(2,1);  0 ;  0  ];

agent = FixedWingsUav(q_0,20,[0.5,0.2,0.9], clock);


dimensions = [
              0 , 100;
              0 , 100;
              0, 50
];
env  = Env3D( dimensions, delta_t, agent, clock);

setMission(env, x_0, x_f );

v_max = 10;
u_phi_max = 4;

primitives= [
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
             v_max , u_phi_max;
];


runPrimitives( env , primitives , totT)


                                %             v_max , 0;
%0 , u_phi_max;
%0 ,-u_phi_max;
%0 ,-u_phi_max;
%0 ,-u_phi_max;
%0 , u_phi_max;
%v_max , u_phi_max;
