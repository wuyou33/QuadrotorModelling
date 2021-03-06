close all
clear
clc
                %              1 2 3  4    5    6  7  8  9   10  11   12 13 14
                % State q = (  x y z phi theta psi dx dy dz zeta ksi  p  q  r );

q_0= zeros(14,1);
q_0(1,1)= 0;
q_0(2,1)= 0;
q_0(3,1)= 5;
q_0(6,1)= 0;

q_0(10,1)= 9.81; %to avoid singularities in feedback lin invertion

%m = 0.650;                  %[kg]
%Ix = 7.5e-3;                %[kg*m^2]
%Iy = 7.5e-3;                %[kg*m^2]
%Iz = 1.3e-2;                %[kg*m^2]
                                % arm length (from cm to rotor position)
%d = 0.23;                    %[m]

                                % taken from ---Exact Lin paper
m = 0.7;                  %[kg]
Ix = 1.2416;                %[kg*m^2]
Iy = 1.2416;                %[kg*m^2]
Iz = 1.2416;                %[kg*m^2]
                            % arm length (from cm to rotor position)
d = 0.255;                    %[m]


delta_t_des = 0.05;


v_0=0; %vel
v_f=0;
a_0=0; %acc
a_f=0;
j_0=0; %jerk
j_f=0;
s_0=0; %snap
s_f=0;
t_0=0; %time
t_f=5;

timeSim= t_f - t_0;

q_f= zeros(14,1);
q_f(1,1)= 0;
q_f(2,1)= 0;
q_f(3,1)= 100;
q_f(6,1)= 0;




xPlanner = SnapticPoly(q_0(1,1), v_0, a_0, j_0, s_0, q_f(1,1), v_f, a_f, j_f, s_f, t_0, t_f, delta_t_des);
yPlanner = SnapticPoly(q_0(2,1), v_0, a_0, j_0, s_0, q_f(2,1), v_f, a_f, j_f, s_f, t_0, t_f, delta_t_des);
zPlanner = SnapticPoly(q_0(3,1), v_0, a_0, j_0, s_0, q_f(3,1), v_f, a_f, j_f, s_f, t_0, t_f, delta_t_des);
psiPlanner = SnapticPoly(q_0(6,1), v_0, a_0, j_0, s_0, q_f(6,1), v_f, a_f, j_f, s_f, t_0, t_f, delta_t_des);

computeRealDeltaT(xPlanner);
delta_t = xPlanner.delta_t;

planners = [  xPlanner; yPlanner; zPlanner; psiPlanner ];

Igains= [0.0;0.0;0.0;0.0];
                                % taken from ---Exact Lin paper
PDgains = [ 60,0,0,0;
            150,0,0,0;
            150,0,0,0;
            40,0,0,0
          ];
gains= [ PDgains, Igains];


rotor = vrepQuadrotor( m , [Ix , Iy, Iz]' , d , delta_t, q_0);
rotor.vRepLoop(timeSim, planners, gains);
