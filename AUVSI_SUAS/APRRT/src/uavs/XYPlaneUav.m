classdef XYPlaneUav  < Uav
  properties
    h
    gains
    diffBlocks

  end

  methods


    function self = XYPlaneUav(q_0, h , color, clock, gains )

      self@Uav(q_0, color, clock )
      self.h= h;
      self.gains= gains;
      self.diffBlocks= {
                        DifferentiatorBlock(self.clock.delta_t,2);
                        DifferentiatorBlock(self.clock.delta_t,2);
      };

    end

    function q_dot= transitionModel( self, u)

      u_ksi = u(1,1);
      u_phi = u(2,1);

      q3 = self.q(3,1);
      q4 = self.q(4,1);
      q5 = self.q(5,1);
      q6 = self.q(6,1);

      q_dot= [
              q5* cos(q3);
              q5* sin(q3);
              - self.g*tan(q4)/q5;
              u_phi;
              q6;
              u_ksi;
      ];

    end

    function u = feedBackLin(self,v)
      %  v needs to be the third derivatives of the output, being rel deg 3 + 3 = 6
      q3 = self.q(3,1);
      q4 = self.q(4,1);
      q5 = self.q(5,1);
      q6 = self.q(6,1);
      grav = self.g;

      A =[
          (grav*tan(q4)*(q6*sin(q3) - grav*cos(q3)*tan(q4)))/q5;
          -(grav*tan(q4)*(q6*cos(q3) + grav*sin(q3)*tan(q4)))/q5
      ];
      B =[
          grav*sin(q3)*(tan(q4)^2 + 1), cos(q3)/self.I;
          -grav*cos(q3)*(tan(q4)^2 + 1), sin(q3)/self.I
      ];

      u = B\v - B\A ;
    end


    function v = controller(self,ref,stepNum)

      for i = 1:2
        diffBlock= self.diffBlocks{i};
        diffState= differentiate(diffBlock ,self.q(i,1));
        posErr = ref(i,1).positions(stepNum,1) - self.q(i,1);
        velErr = ref(i,1).velocities(stepNum,1) - diffState(1,1);
        accErr = ref(i,1).accelerations(stepNum,1) - diffState(2,1);
        v(i,1)= self.gains(i,1)*posErr + self.gains(i,2)*velErr+ self.gains(i,3)*accErr;
      end
     end


    function  data = doAction(self, ref, stepNum)

      v= controller(self,ref,stepNum);
      u= feedBackLin(self, v);

      q_dot= transitionModel(self, u);
      updateState(self, q_dot);

      data.state= self.q;
      data.v = v;
      data.u = u;
    end


    function draw(self)
      drawer = Drawer();
      scale = 1.8;

      vertices = [
                  - 1.0*scale, 1.6*scale, -0.2*scale ;
                  - 1.0*scale, -1.6*scale, -0.2*scale ;
                  3.5*scale, 0, -0.2*scale ;
                  0, 0 , 0.8*scale
      ];


      rotTheta = [
                  cos(self.q(3,1)) , -sin(self.q(3,1)), 0;
                  sin(self.q(3,1)) , cos(self.q(3,1)),  0;
                  0     ,     0     ,     1      ;
      ];

      transl = [ self.q(1,1);self.q(2,1);self.h];
      for i = 1:size(vertices,1)
        newVertex = rotTheta*vertices(i,:)';
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

      figure('Name','State')

      ax1 = subplot(2,3,1);
      plot(data(:,7),data(:,1));
      title(ax1,'x axis');

      ax2 = subplot(2,3,2);
      plot(data(:,7),data(:,2));
      title(ax2,'y axis');

      ax3 = subplot(2,3,3);
      plot(data(:,7),data(:,3));
      title(ax3,'psi');

      ax4 = subplot(2,3,4);
      plot(data(:,7),data(:,4));
      title(ax4,'phi');

      ax5 = subplot(2,3,5);
      plot(data(:,7),data(:,5));
      title(ax5,'v');

      ax6 = subplot(2,3,6);
      plot(data(:,7),data(:,6));
      title(ax6,'ksi');


      figure('Name','controller and feedbacklin outputs')

      ax1 = subplot(2,2,1);
      plot(data(:,7),data(:,8));
      title(ax1,'output controller x axis');

      ax2 = subplot(2,2,2);
      plot(data(:,7),data(:,9));
      title(ax2,'output controller y axis');

      ax3 = subplot(2,2,3);
      plot(data(:,7),data(:,10));
      title(ax3,'u1');

      ax4 = subplot(2,2,4);
      plot(data(:,7),data(:,11));
      title(ax4,'u2');


    end
  end
end
