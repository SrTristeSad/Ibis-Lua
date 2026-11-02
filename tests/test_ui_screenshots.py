"""Unit tests for structural Brush screenshot validation."""
import unittest
from PIL import Image

from tools.check_ui_screenshots import ScreenshotCheckError, check_brush_layout


class BrushLayoutCheckTests(unittest.TestCase):
    def test_accepts_light_left_dark_right(self):
        im = Image.new("RGB", (1024, 768), (45, 45, 45))
        # Draw the left panel white and the expected split remains dark.
        from PIL import ImageDraw
        draw = ImageDraw.Draw(im)
        draw.rectangle((172, 94, 461, 708), fill=(250, 250, 250))
        check_brush_layout(im)

    def test_rejects_uniform_panel(self):
        im = Image.new("RGB", (1024, 768), (60, 60, 60))
        with self.assertRaises(ScreenshotCheckError):
            check_brush_layout(im)

    def test_rejects_small_screenshots(self):
        im = Image.new("RGB", (200, 100), (255, 255, 255))
        with self.assertRaises(ScreenshotCheckError):
            check_brush_layout(im)


if __name__ == "__main__":
    unittest.main()
