# ARKit Data Logger #

This is a simple application to capture ARKit motion estimation (Visual-Inertial Odometry) results on iOS devices for offline use.
I want to play around with data from Apple's Visual-Inertial Odometry (VIO) solution with ARKit framework in Swift 5.0 for iPhone Xs.

![ARKit Data Logger](https://github.com/PyojinKim/ARKit-Data-Logger/blob/master/screenshot.png)

For more details, see the ARKit documentation [here](https://developer.apple.com/documentation/arkit).


## Usage Notes ##

The txt files are produced automatically after pressing Stop button.
This Xcode project is written under Xcode Version 10.2.1 (10E1001) for iOS 12.2.
It doesn't currently check for sensor availability before logging.


## Output Format ##

I have chosen the following output formats, but they are easy to modify if you find something else more convenient.

* ARKit 6-DoF Camera Pose (ARKit_camera_pose.txt): `timestamp, r_11, r_12, r_13, t_x, r_21, r_22, r_23, t_y, r_31, r_32, r_33, t_z \n`
* ARKit 3D Point Cloud (ARKit_point_cloud.txt): `timestamp, index, position_x, position_y, position_z \n`

Note that ARKit_camera_pose.txt contains a N x 12 table, where N is the number of frames of this sequence.
Row i represents the i'th pose of the camera coordinate system via a 3x4 transformation matrix similar to KITTI dataset pose format.
The matrices are stored in row aligned order (the first entries correspond to the first row), and take a point in the i'th coordinate system and project it into the first (=0th) coordinate system.
Hence, the translational part (3x1 vector of column 4) corresponds to the pose of the camera coordinate system in the i'th frame with respect to the first (=0th) frame.


## Offline Matlab Visualization ##

The ability to experiment with different algorithms to process the ARKit (VIO) motion estimation results is the reason that I created this project in the first place.
I have included an example script that you can use to parse and visualize the data that comes from ARKit Data Logger.
Look under the Visualization directory to check it out.
You can run the script by typing the following in your terminal:

    run main_script.m

Here's one of the figures produced by the Matlab script:

![Data visualization](https://github.com/PyojinKim/ARKit-Data-Logger/blob/master/data_visualization.png)
