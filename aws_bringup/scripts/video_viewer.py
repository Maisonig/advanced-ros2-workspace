#!/usr/bin/env python3
"""
Video Frame Navigator

Opens a video file and allows frame-by-frame navigation using arrow keys.
- Left/Right arrows: move forward/backward by 1 frame
- Up/Down arrows: move forward/backward by 10 frames
- Space: play/pause
- 'r': reset to first frame
- 'q' or ESC: quit
- 's': save current frame as image
"""

import cv2
import sys
import os


class VideoNavigator:
    def __init__(self, video_path):
        self.video_path = video_path

        # Open video
        self.cap = cv2.VideoCapture(video_path)
        if not self.cap.isOpened():
            print(f"[ERROR] Could not open video: {video_path}")
            sys.exit(1)

        # Get video properties
        self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
        self.fps = self.cap.get(cv2.CAP_PROP_FPS)
        self.width = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        # Current frame index
        self.current_frame_idx = 0
        self.is_playing = False

        # Read first frame
        self.current_frame = self.read_frame(0)

        print("=" * 50)
        print(f"Video: {os.path.basename(video_path)}")
        print(f"Frames: {self.total_frames}")
        print(f"FPS: {self.fps:.2f}")
        print(f"Resolution: {self.width}x{self.height}")
        print("=" * 50)
        print("Controls:")
        print("  ←/→   : Move 1 frame")
        print("  ↑/↓   : Move 10 frames")
        print("  SPACE : Play/Pause")
        print("  r     : Reset to first frame")
        print("  s     : Save current frame")
        print("  q/ESC : Quit")
        print("=" * 50)

        # Window setup
        self.window_name = "Video Navigator"
        cv2.namedWindow(self.window_name, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(self.window_name, 800, 600)

    def read_frame(self, idx):
        """Read frame at specific index."""
        if idx < 0 or idx >= self.total_frames:
            return None

        self.cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ret, frame = self.cap.read()
        if not ret:
            return None

        # Add frame info overlay
        self.add_overlay(frame, idx)
        return frame

    def add_overlay(self, frame, idx):
        """Add frame number and progress bar overlay."""
        # Frame number
        text = f"Frame: {idx + 1} / {self.total_frames}  ({idx / self.total_frames * 100:.1f}%)"
        cv2.putText(frame, text, (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

        # Progress bar
        bar_width = 200
        bar_height = 6
        bar_x = 10
        bar_y = 45
        progress = (idx + 1) / self.total_frames if self.total_frames > 0 else 0

        # Background
        cv2.rectangle(frame, (bar_x, bar_y), (bar_x + bar_width, bar_y + bar_height),
                      (100, 100, 100), -1)
        # Progress
        cv2.rectangle(frame, (bar_x, bar_y),
                      (bar_x + int(bar_width * progress), bar_y + bar_height),
                      (0, 200, 0), -1)

    def update_frame(self):
        """Read and display current frame."""
        frame = self.read_frame(self.current_frame_idx)
        if frame is None:
            return False

        # Show FPS if playing
        if self.is_playing:
            cv2.putText(frame, "▶ PLAYING", (frame.shape[1] - 150, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        else:
            cv2.putText(frame, "⏸ PAUSED", (frame.shape[1] - 150, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 200, 255), 2)

        self.current_frame = frame
        cv2.imshow(self.window_name, frame)
        return True

    def move_frame(self, delta):
        """Move by delta frames."""
        new_idx = self.current_frame_idx + delta
        new_idx = max(0, min(new_idx, self.total_frames - 1))

        if new_idx != self.current_frame_idx:
            self.current_frame_idx = new_idx
            self.update_frame()

    def play(self):
        """Toggle play/pause."""
        self.is_playing = not self.is_playing

        if self.is_playing:
            print("▶ Playing...")
        else:
            print("⏸ Paused")

    def save_frame(self):
        """Save current frame as image."""
        if self.current_frame is None:
            return

        # Create filename with frame number
        base_name = os.path.splitext(os.path.basename(self.video_path))[0]
        filename = f"{base_name}_frame_{self.current_frame_idx:06d}.png"

        # Remove overlay before saving
        frame_to_save = self.current_frame.copy()
        cv2.imwrite(filename, frame_to_save)
        print(f"Saved: {filename}")

    def run(self):
        """Main loop."""
        self.update_frame()

        while True:
            key = cv2.waitKey(30) & 0xFF

            # Quit
            if key == ord('q') or key == 27:  # ESC
                break

            # Arrow keys (OpenCV returns 255 for arrow keys, use -1 check)
            elif key == 255:
                # Get the actual key code from waitKey
                key = cv2.waitKey(1) & 0xFF

            # Right arrow (forward 1 frame)
            elif key == 83 or key == ord('l'):  # 'l' or right arrow
                self.move_frame(1)

            # Left arrow (back 1 frame)
            elif key == 81 or key == ord('h'):  # 'h' or left arrow
                self.move_frame(-1)

            # Down arrow (forward 10 frames)
            elif key == 84:
                self.move_frame(10)

            # Up arrow (back 10 frames)
            elif key == 82:
                self.move_frame(-10)

            # Space (play/pause)
            elif key == ord(' '):
                self.play()

            # 'r' reset to first frame
            elif key == ord('r'):
                self.current_frame_idx = 0
                self.update_frame()
                print("Reset to first frame")

            # 's' save frame
            elif key == ord('s'):
                self.save_frame()

            # If playing, auto-advance
            if self.is_playing:
                self.move_frame(1)

                # Stop at end
                if self.current_frame_idx >= self.total_frames - 1:
                    self.is_playing = False
                    print("⏸ End of video")

        self.cleanup()

    def cleanup(self):
        """Release resources."""
        self.cap.release()
        cv2.destroyAllWindows()
        print("Goodbye!")


def main():
    # Check arguments
    # if len(sys.argv) < 2:
    #     print("Usage: python video_navigator.py <video_file>")
    #     print("Example: python video_navigator.py recording.mp4")
    #     sys.exit(1)

    # video_path = sys.argv[1]

    video_path = '2_15-30min.mp4'

    if not os.path.exists(video_path):
        print(f"[ERROR] File not found: {video_path}")
        sys.exit(1)

    navigator = VideoNavigator(video_path)
    navigator.run()


if __name__ == '__main__':
    main()