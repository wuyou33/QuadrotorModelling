close all
clear
clc

delta_t = 0.02;

x_0 = [ 10;10;0];
x_f = [ 40;25;0];

clock= Clock(delta_t);


%   fixed Wings
 % state       x      y     psi    phi
q_0 =  [x_0(1,1) ; x_0(2,1);  0 ;  0  ];

v_max = 10;
u_phi_max = 4;
radius = 1.5;

%agent = FixedWingsUav(q_0,20,[0.5,0.2,0.9], clock, v_max, u_phi_max, radius);



                                %  Unicycle
                                % state       x      y     psi    phi
q_0 =  [x_0(1,1) ; x_0(2,1);  0 ];

v_max = 10;
w_max = 4;
radius = 1.5;

agent = Unicycle(q_0,20,[0.5,0.2,0.9], clock, v_max,w_max, radius);


dimensions = [
              0 , 60;
              0 , 60;
              0, 40
];
env  = Env3D( dimensions, delta_t, agent, clock);

setMission(env, x_0, x_f );
obsNum = 20;
addObstacles(env, obsNum);

planner = RRTplanner(env);


%{
 normalized unit to perform path  generation, it is not the real delta_t
 it defines the magnitude of the displacement of the agent into the environment after each step
%}
delta_s = delta_t*10;
treeDrawing = true;
path = generatePathRRT(env, planner,delta_s,treeDrawing);

