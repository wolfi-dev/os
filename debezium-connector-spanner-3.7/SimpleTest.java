/**
* Simple test to verify the Debezium Spanner Connector is properly installed and loadable.
* Tests class loading functionality by attempting to load a core connector class.
* Uses initialize=false to avoid triggering static initializers that require runtime deps.
*/
public class SimpleTest {
    public static void main(String[] args) {
        try {
            Class<?> cls = Class.forName("io.debezium.connector.spanner.SpannerStreamingChangeEventSource", false, ClassLoader.getSystemClassLoader());
            System.out.println("Successfully loaded class: " + cls.getName());
            System.exit(0);
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
 }
