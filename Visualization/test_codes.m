



% 2) plot ARKit VIO motion estimation results
figure;
h_ARKit = plot3(stateEsti_ARKit(1,:),stateEsti_ARKit(2,:),stateEsti_ARKit(3,:),'m','LineWidth',2); hold on; grid on;
scatter3(ARKitPoints(1,:), ARKitPoints(2,:), ARKitPoints(3,:), 40*ones(numPoints,1), (ARKitColors ./ 255).','.');
plot_inertial_frame(0.5); legend(h_ARKit,{'ARKit'}); axis equal; view(26, 73);
xlabel('x [m]','fontsize',10); ylabel('y [m]','fontsize',10); zlabel('z [m]','fontsize',10); hold off;

% figure options
f = FigureRotator(gca());







scatter3(X(:),Y(:),Z(:),S(:),C(:),'filled'), view(-60,60)




scatter3(X3DptsGlobal_k(1,:).' , X3DptsGlobal_k(2,:).' , X3DptsGlobal_k(3,:).' , 100*ones(numPts,1) , X3DptsColor_k.','.');