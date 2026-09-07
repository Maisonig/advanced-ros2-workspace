import os

from launch.substitutions import PathJoinSubstitution
from launch_ros.actions import Node
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from ament_index_python.packages import get_package_share_directory
from launch.launch_description_sources import PythonLaunchDescriptionSource


def generate_launch_description():
    package_path = get_package_share_directory('gz_harmonic')
    pkg_ros_gz_sim = get_package_share_directory('ros_gz_sim')
    sim_world_name = 'living_room_bb'

    remapping_file = sim_world_name + '_remappings.yaml'
    sim_world_file = sim_world_name + '.sdf.xml'

    action_gz_sim_node = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_ros_gz_sim, 'launch', 'gz_sim.launch.py')),
        launch_arguments={'gz_args': PathJoinSubstitution([
            package_path,
            'world',
            sim_world_file
        ])}.items(),
    )

    action_gz_bridge_node = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        parameters=[{
            'config_file': os.path.join(package_path, 'config', remapping_file),
            'qos_overrides./tf_static.publisher.durability': 'transient_local',
        }],
        output='screen'
    )

    action_joint_converter_node = Node(
        package='ign_gazebo',
        executable='joint_converter.py',
        parameters=[os.path.join(package_path, 'config', 'bb_joint_converter.yaml')]
    )

    ld = LaunchDescription()
    ld.add_action(action_gz_sim_node)
    ld.add_action(action_gz_bridge_node)
    # ld.add_action(action_joint_converter_node)
    return ld
