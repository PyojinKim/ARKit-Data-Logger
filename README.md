# ARKit-Data-Logger
iOS utility to save ARKit results (Visual-Inertial Odometry) to a series of text files for offline use.


## Usage Notes ##

The txt files are produced automatically after pressing Stop button.
This Xcode project is written under Xcode Version 10.2.1 (10E1001) for iOS 12.2.
It doesn't currently check for sensor availability before logging.


## Output Format ##




## Offline Matlab Visualization ##

The ability to experiment with different algorithms to process the ARKit (VIO) motion estimation results is the reason that I created this project in the first place.
I have included an example script that you can use to parse and visualize the data that comes from ARKit Data Logger.
Look under the Visualization directory to check it out.
You can run the script by typing the following in your terminal:

    run main_script.m

Here's one of the figures produced by the Matlab script:

![Data visualization](https://github.com/PyojinKim/ARKit-Data-Logger/blob/master/data_visualization.png)
