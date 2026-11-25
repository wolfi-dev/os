import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.color.ColorSpace;
import java.awt.image.BufferedImage;
import java.awt.image.ColorConvertOp;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import javax.sound.sampled.AudioSystem;

// Checks that AWT runs headless and can draw text, write PNG and JPEG with
// ImageIO and convert colour spaces; any failure throws, so java exits non-zero.
public class HeadlessProbe {
    public static void main(String[] args) throws Exception {
        if (!GraphicsEnvironment.isHeadless()) {
            throw new IllegalStateException("expected a headless graphics environment");
        }
        BufferedImage img = new BufferedImage(100, 20, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        g.drawString("hello", 1, 15);
        int width = g.getFontMetrics().stringWidth("hello");
        if (width <= 0) {
            throw new IllegalStateException("text has no width");
        }
        for (String format : new String[] {"png", "jpg"}) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            if (!ImageIO.write(img, format, out) || out.size() == 0) {
                throw new IllegalStateException("ImageIO wrote no " + format);
            }
        }
        new ColorConvertOp(ColorSpace.getInstance(ColorSpace.CS_GRAY), null).filter(img, null);
        // Without libjsound the sound API reports no mixers instead of failing.
        System.out.println("headless ok: text " + width + "px, mixers " + AudioSystem.getMixerInfo().length);
    }
}
