# Requirements:
#   A realsense D400 series
#   Install realsense2 ros2 package (make sure you have this patch: https://github.com/IntelRealSense/realsense-ros/issues/2564#issuecomment-1336288238)
# Example:
#   $ ros2 launch rtabmap_examples realsense_d400.launch.py

import os

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch_ros.actions import Node, SetParameter
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource

def generate_launch_description():

    ld = LaunchDescription()

    rs_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([os.path.join(
            get_package_share_directory('realsense2_camera'), 'launch'),
            '/rs_launch.py']),
        launch_arguments={'align_depth.enable': 'true',
                          'rgb_camera.profile': '640x360x30'}.items(),
    )

    rtabmap_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([os.path.join(
            get_package_share_directory('rtabmap_launch'), 'launch'),
            '/rtabmap.launch.py']),
        launch_arguments={'database_path': '/home/harry/rtabmap.db',
                          'rgb_topic': '/camera/camera/color/image_raw',
                          'depth_topic': '/camera/camera/depth/image_rect_raw',
                          'frame_id': 'camera_color_optical_frame',
                          'camera_info_topic': '/camera/camera/color/camera_info',
                          'approx_sync': 'false',
                          'wait_imu_to_init': 'false'
                          }
        .items(),
    )

    ld.add_action(rs_launch)
    ld.add_action(rtabmap_launch)

    return ld