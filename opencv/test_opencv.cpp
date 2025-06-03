#include <opencv2/opencv.hpp>
#include <iostream>

int main() {
    try {
        // Create a black 100x100 image with 3 channels (BGR)
        cv::Mat image = cv::Mat::zeros(100, 100, CV_8UC3);

        // Draw a white filled circle at the center
        cv::Point center(50, 50);
        int radius = 20;
        cv::Scalar color(255, 255, 255);  // White in BGR
        cv::circle(image, center, radius, color, -1);

        // Check if the center pixel is white
        cv::Vec3b center_pixel = image.at<cv::Vec3b>(center);
        if (center_pixel != cv::Vec3b(255, 255, 255)) {
            std::cerr << "ERROR: Circle not drawn correctly." << std::endl;
            return 1;
        }

        std::cout << "OpenCV test passed." << std::endl;
        return 0;

    } catch (const cv::Exception& e) {
        std::cerr << "OpenCV exception: " << e.what() << std::endl;
        return 2;
    } catch (...) {
        std::cerr << "Unknown exception." << std::endl;
        return 3;
    }
}

