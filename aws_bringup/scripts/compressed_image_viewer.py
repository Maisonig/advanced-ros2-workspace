#!/usr/bin/env python3
"""
Subscribes to a compressed image topic and displays the image using OpenCV.
"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CompressedImage
import cv2
import numpy as np


class CompressedImageViewer(Node):
    def __init__(self):
        super().__init__('compressed_image_viewer')

        # Subscription to compressed image topic
        self.subscription = self.create_subscription(
            CompressedImage,
            '/brake_stz/image/compressed',
            self.image_callback,
            10
        )

        self.get_logger().info(f"Subscribed to /brake_stz/image/compressed")

        # Window name
        self.window_name = 'Compressed Image Viewer'

        # Create window
        cv2.namedWindow(self.window_name, cv2.WINDOW_NORMAL)

    def image_callback(self, msg: CompressedImage):
        """Callback function that decodes and displays the compressed image."""
        try:
            # Convert compressed image data to numpy array
            np_arr = np.frombuffer(msg.data, np.uint8)

            # Decode JPEG/PNG image to OpenCV format
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is None:
                self.get_logger().warn("Failed to decode image")
                return

            # Display the image
            cv2.imshow(self.window_name, frame)

            # Wait for a short period to allow the window to update
            # 1 ms is enough, 0 would block indefinitely
            cv2.waitKey(1)

        except Exception as e:
            self.get_logger().error(f"Error processing image: {e}")

    def destroy_node(self):
        """Override destroy_node to close OpenCV windows."""
        cv2.destroyAllWindows()
        super().destroy_node()


def main(args=None):
    rclpy.init(args=args)

    viewer = CompressedImageViewer()

    try:
        rclpy.spin(viewer)
    except KeyboardInterrupt:
        viewer.get_logger().info("Shutting down...")
    finally:
        viewer.destroy_node()
        rclpy.shutdown()
        cv2.destroyAllWindows()


if __name__ == '__main__':
    main()