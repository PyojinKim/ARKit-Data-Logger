function plot_inertial_frame(magnitude)


% center point of inertial frame
X = 0;
Y = 0;
Z = 0;


% [X Y Z] axis end points of inertial frame
X_axis = [magnitude;0;0];
Y_axis = [0;magnitude;0];
Z_axis = [0;0;magnitude];


% draw inertial frame
line([X_axis(1) X],[X_axis(2) Y],[X_axis(3) Z],'Color','r','LineWidth',4)
line([Y_axis(1) X],[Y_axis(2) Y],[Y_axis(3) Z],'Color','g','LineWidth',4)
line([Z_axis(1) X],[Z_axis(2) Y],[Z_axis(3) Z],'Color','b','LineWidth',4)


end