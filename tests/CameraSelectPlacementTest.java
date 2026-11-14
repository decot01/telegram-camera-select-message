import org.telegram.ui.Components.cameraselect.CameraSelectGesture;
import org.telegram.ui.Components.cameraselect.CameraSelectPlacement;

public final class CameraSelectPlacementTest {
    public static void main(String[] args) {
        int checks = 0;
        for (float density : new float[]{1f, 1.5f, 2f, 2.625f, 2.75f, 3f, 3.5f, 4f}) {
            for (int barTop : new int[]{300, 650, 1000, 1400, 1800, 2400}) {
                int top = CameraSelectPlacement.top(density, barTop);
                int circleBottom = top + (int)Math.ceil(CameraSelectPlacement.FRONT_BOTTOM_DP * density);
                if (barTop - circleBottom != 80) throw new AssertionError("Gap is not 80 physical px");
                checks++;
                if (CameraSelectPlacement.top(density, barTop - 175) != top - 175) {
                    throw new AssertionError("Keyboard/bar movement not reflected in placement");
                }
                checks++;
                for (int parentOffset : new int[]{0, (int)Math.ceil(48*density), (int)Math.ceil(56*density)+24}) {
                    int laidOut = top + parentOffset;
                    int translation = CameraSelectPlacement.translation(top, laidOut);
                    int actualBottom = laidOut + translation
                            + (int)Math.ceil(CameraSelectPlacement.FRONT_BOTTOM_DP * density);
                    if (barTop - actualBottom != 80) {
                        throw new AssertionError("Action bar/insets swallowed spacing");
                    }
                    if (parentOffset > 0 && barTop - (laidOut
                            + (int)Math.ceil(CameraSelectPlacement.FRONT_BOTTOM_DP*density)) == 80) {
                        throw new AssertionError("Regression setup does not reproduce original bug");
                    }
                    checks++;
                }
                int desiredLeft = 150;
                int laidOutLeft = desiredLeft + 24;
                if (laidOutLeft + CameraSelectPlacement.translation(desiredLeft, laidOutLeft) != desiredLeft) {
                    throw new AssertionError("Horizontal system inset counted twice");
                }
                checks++;
                float down = barTop + 22f * density;
                float threshold = CameraSelectPlacement.backPull(density, down, top);
                float targetMidpoint = top + CameraSelectPlacement.TARGET_MIDPOINT_DP * density;
                if (Math.abs(down - threshold * density - targetMidpoint) > .01f) {
                    throw new AssertionError("Selection boundary not aligned with targets");
                }
                checks++;
                CameraSelectGesture g = new CameraSelectGesture();
                g.begin(100, down / density, 0);
                g.setBackPull(threshold);
                g.move(100, down / density - threshold - 1, 1);
                if (g.getCandidate() != CameraSelectGesture.BACK || g.isRecording()) {
                    throw new AssertionError("Dynamic long pull selection failed");
                }
                g.move(100, down / density - 32, 2);
                if (g.finish() != CameraSelectGesture.FRONT) throw new AssertionError("Reverse selection failed");
                checks++;
            }
        }
        System.out.println(checks + " placement/gesture checks passed across 8 densities and 6 bar positions");
    }
}
