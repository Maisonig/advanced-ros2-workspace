#!/usr/bin/env python3
"""
Video Recorder with Frame Deduplication

Records video from a ROS topic for N seconds, saves it to MP4,
and skips frames that are identical to the previous one.
"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CompressedImage
import cv2
import numpy as np
import os
import time
from datetime import datetime
from cv_bridge import CvBridge


class VideoRecorder(Node):
    def __init__(self, duration=10, topic='/brake_stz/image/compressed', use_compressed=True):
        super().__init__('video_recorder')

        self.duration = duration
        self.topic = topic
        self.use_compressed = use_compressed
        self.recording = True

        # Frame storage
        self.prev_frame = None
        self.frames = []
        self.frame_count = 0
        self.skipped_count = 0

        # Subscriber
        if use_compressed:
            self.sub = self.create_subscription(
                CompressedImage,
                topic,
                self.compressed_callback,
                10
            )
        else:
            self.bridge = CvBridge()
            self.sub = self.create_subscription(
                Image,
                topic,
                self.image_callback,
                10
            )

        self.get_logger().info(f"Recording from {topic} for {duration} seconds...")
        self.get_logger().info("Duplicate frames will be skipped")

        # Timer to stop recording
        self.timer = self.create_timer(duration, self.stop_recording)

    def compressed_callback(self, msg: CompressedImage):
        """Callback for compressed images."""
        try:
            # Decode compressed image
            np_arr = np.frombuffer(msg.data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is None:
                self.get_logger().warn("Failed to decode image")
                return

            self.process_frame(frame)

        except Exception as e:
            self.get_logger().error(f"Error processing compressed image: {e}")

    def image_callback(self, msg: Image):
        """Callback for uncompressed images."""
        try:
            frame = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
            self.process_frame(frame)
        except Exception as e:
            self.get_logger().error(f"Error processing image: {e}")

    def process_frame(self, frame):
        """Process frame: check for duplicates and store."""
        if not self.recording:
            return

        self.frame_count += 1

        # Check if frame is identical to previous
        is_duplicate = False
        if self.prev_frame is not None:
            if frame.shape == self.prev_frame.shape:
                diff = cv2.absdiff(frame, self.prev_frame)
                if np.sum(diff) == 0:
                    is_duplicate = True

        if is_duplicate:
            self.skipped_count += 1
            return

        # Store frame
        self.frames.append(frame.copy())
        self.prev_frame = frame.copy()

    def stop_recording(self):
        """Stop recording and save video."""
        self.recording = False
        self.timer.cancel()

        total_frames = self.frame_count
        unique_frames = len(self.frames)
        duplicates = total_frames - unique_frames

        self.get_logger().info(f"Recording stopped!")
        self.get_logger().info(f"Total frames: {total_frames}")
        self.get_logger().info(f"Unique frames: {unique_frames}")
        self.get_logger().info(f"Skipped duplicates: {duplicates}")

        # Защита от деления на ноль
        if total_frames > 0:
            dedup_rate = (duplicates / total_frames) * 100
            self.get_logger().info(f"Dedup rate: {dedup_rate:.1f}%")
        else:
            self.get_logger().warn("No frames received!")

        # Save video
        if self.frames:
            self.save_video()
        else:
            self.get_logger().warn("No unique frames to save!")

        # Shutdown node
        rclpy.shutdown()

    def save_video(self):
        """Save collected frames to MP4 file."""
        if not self.frames:
            return

        # Get first frame dimensions
        h, w = self.frames[0].shape[:2]

        # Generate filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"recording_{timestamp}.mp4"

        # Create video writer
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(filename, fourcc, 30.0, (w, h))

        if not out.isOpened():
            self.get_logger().error(f"Failed to create video writer")
            return

        # Write all frames
        for frame in self.frames:
            out.write(frame)

        out.release()

        self.get_logger().info(f"Video saved: {filename}")
        self.get_logger().info(f"Total frames: {len(self.frames)}")
        self.get_logger().info(f"Duration: {len(self.frames) / 30.0:.2f} seconds")


def main(args=None):
    import sys

    rclpy.init(args=args)

    # Parse arguments
    duration = 900  # seconds
    topic = '/brake_stz/image/compressed'
    use_compressed = True

    if len(sys.argv) > 1:
        try:
            duration = float(sys.argv[1])
        except ValueError:
            pass

    if len(sys.argv) > 2:
        topic = sys.argv[2]

    # Проверка топика перед записью
    import time
    print("Waiting 2 seconds for topic check...")
    time.sleep(2)

    node = VideoRecorder(duration=duration, topic=topic, use_compressed=use_compressed)

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.get_logger().info("Interrupted by user")
        node.stop_recording()


if __name__ == '__main__':
    main()