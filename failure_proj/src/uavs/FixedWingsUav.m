classdef FixedWingsUav < Uav
  properties
    h
    radius
    coords
    v_max
    v_min
    u_phi_max
    phi_bound
    primitives
  end

  methods( Static = true)
    function res = definePrimitives(self,v_max,v_min,u_phi_max,delta_t,delta_s)

      avg_v = (v_max - v_min)/2;

      % v
      knot1.pos = avg_v;
      knot1.vel = 0;
      knot1.acc = 0;
      knot1.time = 0;
      knot2.pos = avg_v;
      knot2.vel = 0;
      knot2.acc = 0;
      knot2.time = delta_s;
      knots_v = [ knot1 , knot2]

                                % u_phi
                                %straight
      knot3.pos = 0;
      knot3.vel = 0;
      knot3.acc = 0;
      knot3.time = 0;
      knot4.pos = 0;
      knot4.vel = 0;
      knot4.acc = 0;
      knot4.time = delta_s;
      knots_u_phi_straight = [ knot3 , knot4]

                                %curve_right

      knot5.pos = 0;
      knot5.vel = 0;
      knot5.acc = 0;
      knot5.time = 0;

      knot6.pos = -u_phi_max;
      knot6.vel = 0;
      knot6.acc = 0;
      knot6.time = delta_s/10;

      knot7.pos = -u_phi_max;
      knot7.vel = 0;
      knot7.acc = 0;
      knot7.time = 9*delta_s/10;

      knot8.pos = 0;
      knot8.vel = 0;
      knot8.acc = 0;
      knot8.time = delta_s;


      knots_u_phi_curve_right= [ knot5 , knot6, knots7 , knots8];


                                %curve_left
      knot9.pos = 0;
      knot9.vel = 0;
      knot9.acc = 0;
      knot9.time = 0;

      knot10.pos = u_phi_max;
      knot10.vel = 0;
      knot10.acc = 0;
      knot10.time = delta_s/10;

      knot11.pos = u_phi_max;
      knot11.vel = 0;
      knot11.acc = 0;
      knot11.time = 9*delta_s/10;

      knot12.pos = 0;
      knot12.vel = 0;
      knot12.acc = 0;
      knot12.time = delta_s;


      knots_u_phi_curve_left= [ knot5 , knot6, knots7 , knots8];




"TODO"



      p_straight = PolynomialKnotSequencer(knots_v,delta_t)

      p_straight = PolynomialKnotSequencer(knots_v,delta_t)



      knots_u_phi = [

      ]

      res.straight = p_straight.getReferences();
      res.curve_right= p_curve.getReferences();
      res.curve_left= p_straight.getReferences();

    end
  end
  methods
    function self = FixedWingsUav (q_0, h , color, clock, v_max, v_min, u_phi_max, radius, delta_s)
      self@Uav(q_0, color, clock )
      self.h= h;
      self.v_max = v_max;
      self.v_min= v_min;
      self.u_phi_max = u_phi_max;
      %self.primitives = [
      %%%                   v_max*0.65, 0;
      %                   v_max, u_phi_max;
      %                   v_max, -u_phi_max;
        %                 v_min, u_phi_max;
      %                   v_min, -u_phi_max;
      %];
      self.primitives = FixedWingsUav.definePrimitives(v_max, v_min, u_phi_max,clock.delta_t, delta_s)
      self.coords.x = q_0(1,1);
      self.coords.y = q_0(2,1);
      self.coords.z = 0;
      self.radius = radius;
      self.phi_bound=  0.7;   % 40 degrees
    end


    function q_dot= transitionModel( self, u)

      % q :  x  ,  y ,  psi  ,  phi

      v = u(1,1);
      u_phi = u(2,1);

      q3 = self.q(3,1);
      q4 = self.q(4,1);

      q_dot= [
              v* cos(q3);
              v* sin(q3);
              - self.g*tan(q4)/v;
              u_phi;
      ];
    end

    function  updateState(self, q_dot)
      new_t= self.clock.curr_t+self.clock.delta_t;
      for i= 1:size(self.q,1)
        integral = ode45( @(t, unused) q_dot(i,1) , [ self.clock.curr_t new_t], self.q(i,1));
        self.q(i,1)= deval( integral, new_t);
      end
      self.coords.x = self.q(1,1);
      self.coords.y = self.q(2,1);
    end

    function  data = doAction(self, primitives, stepNum)
      u = primitives(stepNum,:)';
      q_dot= transitionModel(self, u);
      updateState(self, q_dot);
      data.state= self.q;
    end




    function setUavState(self, conf, time)
      self.q = conf;
      self.coords.x = conf(1,1);
      self.coords.y = conf(2,1);
      self.clock.curr_t = time;
    end


    function res = generatePrimitives(self,node,delta_s)
      currConf = node.value.conf;
      currTime = node.value.time;
      precision = delta_s / self.clock.delta_t;
      res = {};
      for i = 1:size(self.primitives,1)
        setUavState(self,currConf,currTime );
        currInput = self.primitives(i,:)';
        middleData= zeros(size(self.q,1),precision);
        for j = 1:precision
          newQDot = transitionModel(self, currInput );
          updateState(self, newQDot);
          middleData(:,j) = self.q;
          tick(self.clock);
        end
        newConf = self.q;
        struct.conf = newConf;
        struct.pastInput = currInput;
        struct.time = self.clock.curr_t;
        struct.burned = false;
        struct.middleData= middleData;
        elem  = Node( struct );
        if abs(newConf(4,1)) <= self.phi_bound
          res = Node.addInTail(elem, res);
        else
          scatter3(newConf(1,1),newConf(2,1),0, 30 ,[0.8,0.2,0.2]);
        end
      end
    end



    function res = generateLongPrimitives(self,node,delta_s)
      currConf = node.value.conf;
      currTime = node.value.time;
      precision = delta_s / self.clock.delta_t;
      res = {};
      for i = 1:size(self.primitives,1)
        setUavState(self,currConf,currTime );
        middleData= zeros(size(self.q,1)+size(self.primitives,3),precision);
        for j = 1:precision
          currInput = self.primitives(i,j,:)';
          newQDot = transitionModel(self, currInput );
          updateState(self, newQDot);
          middleData(1:size(self.q,1),j) = self.q;
          middleData(size(self.q,1)+1:size(self.q,1)+size(self.primitives,3),j) = currInput;
          tick(self.clock);
        end
        newConf = self.q;
        struct.conf = newConf;
        struct.pastInput = currInput;
        struct.time = self.clock.curr_t;
        struct.burned = false;
        struct.middleData= middleData;
        elem  = Node( struct );
        if abs(newConf(4,1)) <= self.phi_bound
          res = Node.addInTail(elem, res);
        else
          scatter3(newConf(1,1),newConf(2,1),0, 30 ,[0.8,0.2,0.2]);
        end
      end
    end





    function draw(self)
      drawer = Drawer();
      scale = 20;

      vertices = [
                  - 1.0*scale, 1.6*scale, -0.2*scale ;
                  - 1.0*scale, -1.6*scale, -0.2*scale ;
                  3.5*scale, 0, -0.2*scale ;
                  0, 0 , 0.8*scale
      ];


      rotPsi= [
                  cos(self.q(3,1)) , -sin(self.q(3,1)), 0;
                  sin(self.q(3,1)) , cos(self.q(3,1)),  0;
                  0     ,     0     ,     1      ;
      ];

      transl = [ self.q(1,1);self.q(2,1);self.h];
      for i = 1:size(vertices,1)
        newVertex = rotPsi*vertices(i,:)';
        vertices(i,:)= (newVertex+transl)';
      end

      oppositeColor = 1 - self.color;

      d1= drawLine3D(drawer, vertices(1,:) , vertices(2,:), oppositeColor);
      d2= drawLine3D(drawer, vertices(2,:) , vertices(3,:), oppositeColor);
      d3= drawLine3D(drawer, vertices(3,:) , vertices(1,:), oppositeColor);
      d4= drawLine3D(drawer, vertices(1,:) , vertices(4,:), self.color);
      d5= drawLine3D(drawer, vertices(2,:) , vertices(4,:), self.color);
      d6= drawLine3D(drawer, vertices(3,:) , vertices(4,:), self.color);

      self.drawing= [ d1;d2;d3;d4;d5;d6];

      scatter3( self.q(1,1), self.q(2,1), self.h, 3 ,[0.8,0.2,0.2]);
    end

    function drawStatistics(self, data)

      figure('Name','State','pos',[10 10 1350 900])

      ax1 = subplot(2,2,1);
      plot(data(:,5),data(:,1));
      title(ax1,'x axis');

      ax2 = subplot(2,2,2);
      plot(data(:,5),data(:,2));
      title(ax2,'y axis');

      ax3 = subplot(2,2,3);
      plot(data(:,5),data(:,3));
      title(ax3,'psi');

      ax4 = subplot(2,2,4);
      plot(data(:,5),data(:,4));
      title(ax4,'phi');


      figure('Name','angle of approach (alfa) variation','pos',[10 10 1350 900])

      ax1 = subplot(2,2,1);
      plot(data(:,5),data(:,3));
      title(ax1,'alfa');

      ax2 = subplot(2,2,2);
      plot(data(:,5),data(:,6));
      title(ax2,'d_alfa');

      ax3 = subplot(2,2,3);
      plot(data(:,5),data(:,7));
      title(ax3,'dd_alfa');

      ax4 = subplot(2,2,4);
      plot(data(:,5),data(:,8));
      title(ax4,'ddd_alfa');



    end
  end
end
