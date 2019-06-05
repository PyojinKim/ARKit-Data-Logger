clc;
close all;
clear variables; %clear classes;
rand('state',0); % rand('state',sum(100*clock));
dbstop if error;


%% 1) parse ARKit camera pose data

% parsing ARKit camera pose data text file
textFileDir = 'ARKit_camera_pose.txt';
delimiter = ' ';
headerlinesIn = 0;
textARKitPoseData = importdata(textFileDir, delimiter, headerlinesIn);
ARKitPoseTime = textARKitPoseData(:,1).';
ARKitPoseTime = (ARKitPoseTime - ARKitPoseTime(1)) ./ 1000000000;


% ARKit camera pose with various 6-DoF camera pose representations
ARKitPose = textARKitPoseData(:,[2:13]);
numPose = size(ARKitPose,1);
T_gc_ARKit = cell(1,numPose);
stateEsti_ARKit = zeros(6,numPose);
R_gc_ARKit = zeros(3,3,numPose);
for k = 1:numPose
    
    % rigid body transformation matrix (4x4)
    T_gc_ARKit{k} = [reshape(ARKitPose(k,:).', 4, 3).'; [0, 0, 0, 1]];
    
    % state vector and rotation matrix
    R_gc_ARKit(:,:,k) = T_gc_ARKit{k}(1:3,1:3);
    stateEsti_ARKit(1:3,k) = T_gc_ARKit{k}(1:3,4);
    [yaw, pitch, roll] = dcm2angle(R_gc_ARKit(:,:,k));
    stateEsti_ARKit(4:6,k) = [roll; pitch; yaw];
end


%% 2) parse ARKit point cloud data

% parsing ARKit point cloud data text file
textFileDir = 'ARKit_point_cloud.txt';
delimiter = ' ';
headerlinesIn = 0;
textARKitPointData = importdata(textFileDir, delimiter, headerlinesIn);
ARKitPointTime = textARKitPointData(:,1).';
ARKitPointTime = (ARKitPointTime - ARKitPointTime(1)) ./ 1000000000;


% ARKit 3D point cloud
ARKitPoints = textARKitPointData(:,[3:5]).';
numPoints = size(ARKitPoints,2);


%% plot ARKit VIO results

% 1) play 3D trajectory of ARKit camera pose
figure(10);
for k = 1:numPose
    figure(10); cla;
    
    % draw moving trajectory
    p_gc_ARKit = stateEsti_ARKit(1:3,1:k);
    plot3(p_gc_ARKit(1,:), p_gc_ARKit(2,:), p_gc_ARKit(3,:), 'm', 'LineWidth', 2); hold on; grid on; axis equal;
    
    % draw camera body and frame
    plot_inertial_frame(0.5); view(47, 48);
    Rgc_ARKit_current = T_gc_ARKit{k}(1:3,1:3);
    pgc_ARKit_current = T_gc_ARKit{k}(1:3,4);
    plot_camera_ARKit_frame(Rgc_ARKit_current, pgc_ARKit_current, 0.5, 'm'); hold off;
    refresh; pause(0.01); k
end


% 2) plot ARKit VIO motion estimation results
figure;
h_ARKit = plot3(stateEsti_ARKit(1,:),stateEsti_ARKit(2,:),stateEsti_ARKit(3,:),'m','LineWidth',2); hold on; grid on;
scatter3(ARKitPoints(1,:), ARKitPoints(2,:), ARKitPoints(3,:),'k.');
plot_inertial_frame(0.5); legend(h_ARKit,{'ARKit'}); axis equal; view(26, 73);
xlabel('x [m]','fontsize',10); ylabel('y [m]','fontsize',10); zlabel('z [m]','fontsize',10); hold off;

% figure options
f = FigureRotator(gca());


% 3) plot roll/pitch/yaw of ARKit device orientation
figure;
subplot(3,1,1);
plot(ARKitPoseTime, stateEsti_ARKit(4,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(ARKitPoseTime) max(ARKitPoseTime) min(stateEsti_ARKit(4,:)) max(stateEsti_ARKit(4,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Roll [rad]','FontName','Times New Roman','FontSize',17);
subplot(3,1,2);
plot(ARKitPoseTime, stateEsti_ARKit(5,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(ARKitPoseTime) max(ARKitPoseTime) min(stateEsti_ARKit(5,:)) max(stateEsti_ARKit(5,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Pitch [rad]','FontName','Times New Roman','FontSize',17);
subplot(3,1,3);
plot(ARKitPoseTime, stateEsti_ARKit(6,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(ARKitPoseTime) max(ARKitPoseTime) min(stateEsti_ARKit(6,:)) max(stateEsti_ARKit(6,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Yaw [rad]','FontName','Times New Roman','FontSize',17);
set(gcf,'Units','pixels','Position',[100 200 1800 900]); % modify figure


