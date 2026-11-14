import org.telegram.ui.Components.cameraselect.CameraSelectGesture;

public final class CameraSelectGestureTest {
    private static int checks;
    private static CameraSelectGesture begin() {
        CameraSelectGesture g = new CameraSelectGesture();
        g.begin(100, 300, 0);
        return g;
    }
    private static void check(boolean result, String name) {
        checks++;
        if (!result) throw new AssertionError(name);
    }
    public static void main(String[] args) {
        CameraSelectGesture g = begin();
        g.move(100, 260, 20);
        check(g.getCandidate() == g.FRONT && !g.isRecording(), "fast short pull selects without recording");
        check(g.finish() == g.FRONT, "short release commits front");
        check(g.finish() == g.NONE, "release cannot commit twice");
        g = begin();
        g.move(100, 40, 5);
        check(g.getCandidate() == g.BACK && !g.isRecording(), "fast long pull selects back");
        for (int i = 0; i < 10000; i++) g.move(100, 40, i);
        check(!g.isRecording() && g.isActive(), "holding never starts recording");
        check(g.finish() == g.BACK, "long release commits back");
        g = begin();
        g.move(100, 260, 10);
        check(g.getCandidate() == g.FRONT, "front on upward slide");
        g.move(100, 40, 11);
        check(g.getCandidate() == g.BACK, "switch to back before release");
        g.move(100, 260, 12);
        check(g.getCandidate() == g.FRONT && g.finish() == g.FRONT, "reverse slide commits front");
        g = begin();
        g.move(100, 40, 1);
        g.move(100, 300, 2);
        check(g.hasDragged() && g.finish() == g.NONE, "return to button cancels without becoming tap");
        g = begin();
        g.move(100, 250, 1);
        g.move(20, 250, 2);
        g.move(100, 40, 3);
        check(g.isCancelled() && g.finish() == g.NONE, "left cancellation cannot start recording");
        g = begin();
        g.move(170, 180, 1);
        check(g.getCandidate() == g.NONE, "outside horizontal lane deselects");
        g.move(100, 250, 2);
        check(g.finish() == g.FRONT, "returning to lane restores selection");
        g = begin();
        g.move(100, 300 - CameraSelectGesture.BACK_PULL, 1);
        check(g.getCandidate() == g.BACK, "long threshold is distance based");
        g.cancel();
        check(g.finish() == g.NONE && !g.isRecording(), "system cancel cannot record");
        g.begin(100, 300, 20);
        g.move(100, 276, 21);
        check(g.finish() == g.FRONT, "new gesture resets cancellation");
        g = begin();
        check(!g.hasDragged() && g.finish() == g.NONE, "tap does not start video");
        g = begin();
        g.move(100, 291, 1);
        check(g.isRailVisible() && g.getCandidate() == g.NONE, "rail appears immediately after touch slop");
        g.move(100, 277, 2);
        check(g.finish() == g.NONE, "under threshold cancels");
        long start = System.nanoTime();
        for (int i = 0; i < 1000000; i++) {
            g.begin(100, 300, i);
            g.move(100, 260, i);
            g.move(100, 40, i);
            g.move(100, 260, i);
            if (g.isRecording() || g.finish() != g.FRONT) throw new AssertionError("stress invariant");
        }
        System.out.println(checks + " checks passed; 1,000,000 reversible gestures passed in "
                + ((System.nanoTime() - start) / 1000000) + " ms (JVM state model, not device UI timing)");
    }
}
