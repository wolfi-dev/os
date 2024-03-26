import javax.management.RuntimeErrorException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;

public class RequestTest {
    public static void main(String[] args) throws Exception {
        // Remote connections can flake, so try a few times
        int attempt = 0;
        while (true) {
            URL url = new URL("http://example.org");
            HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
            if (urlConnection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                break;
            }

            Thread.sleep(5000); // 5 seconds in millis is 5000

            if (attempt++ >= 5) {
                throw new RuntimeException("Failed to check connection to example.org");
            }
        }

        System.out.println("Successfully connected to example.org");
    }
}
