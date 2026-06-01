/**
* Simple test to verify the Debezium Spanner Connector is properly installed and loadable.
* Tests class loading functionality by attempting to load a core connector class.
*/
public class SimpleTest {
    public static void main(String[] args) {
        try {
            Class<?> cls = Class.forName("io.debezium.connector.spanner.SpannerStreamingChangeEventSource");
            System.out.println("Successfully loaded class");
            System.exit(0);
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
 }