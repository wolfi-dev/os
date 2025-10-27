import java.awt.*;
import java.awt.event.*;

public class SimpleAWTApp {

    public SimpleAWTApp() {
        // Create a new frame
        Frame frame = new Frame("Simple AWT App");

        // Create a label
        Label label = new Label("Press the button");

        // Set label position
        label.setBounds(50, 100, 200, 30);

        // Create a button
        Button button = new Button("Click Me");

        // Set button position
        button.setBounds(50, 50, 80, 30);

        // Add button click event
        button.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                label.setText("Button was clicked!");
            }
        });

        // Add components to frame
        frame.add(button);
        frame.add(label);

        // Set frame layout, size, and visibility
        frame.setSize(300, 200);
        frame.setLayout(null); // use absolute positioning
        frame.setVisible(true);

        // Close operation
        frame.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                frame.dispose();
            }
        });
	System.exit(0);
    }

    public static void main(String[] args) {
        new SimpleAWTApp();
    }
}
