#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/features2d.hpp>
#include <opencv2/calib3d.hpp>
#include <iostream>
#include <cmath>

void testCore() {
    std::cout << "Testing core module..." << std::endl;

    // Test matrix addition with specific expected values
    cv::Mat mat1 = (cv::Mat_<int>(2, 2) << 1, 2, 3, 4);
    cv::Mat mat2 = (cv::Mat_<int>(2, 2) << 5, 6, 7, 8);
    cv::Mat result;
    cv::add(mat1, mat2, result);

    if (result.at<int>(0, 0) != 6 || result.at<int>(0, 1) != 8 ||
        result.at<int>(1, 0) != 10 || result.at<int>(1, 1) != 12) {
        std::cerr << "Core module test failed: matrix addition produced incorrect values" << std::endl;
        std::cerr << "Expected: [6, 8; 10, 12], Got: ["
                  << result.at<int>(0, 0) << ", " << result.at<int>(0, 1) << "; "
                  << result.at<int>(1, 0) << ", " << result.at<int>(1, 1) << "]" << std::endl;
        exit(1);
    }

    // Test matrix multiplication with exact expected values
    cv::Mat mat3 = (cv::Mat_<double>(2, 3) << 1, 2, 3, 4, 5, 6);
    cv::Mat mat4 = (cv::Mat_<double>(3, 2) << 7, 8, 9, 10, 11, 12);
    cv::Mat matMul = mat3 * mat4;

    // Expected result: [[58, 64], [139, 154]]
    double expected[2][2] = {{58, 64}, {139, 154}};
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            if (std::abs(matMul.at<double>(i, j) - expected[i][j]) > 1e-10) {
                std::cerr << "Core module test failed: matrix multiplication at (" << i << "," << j << ")" << std::endl;
                std::cerr << "Expected: " << expected[i][j] << ", Got: " << matMul.at<double>(i, j) << std::endl;
                exit(1);
            }
        }
    }

    // Test transpose
    cv::Mat mat5 = (cv::Mat_<int>(2, 3) << 1, 2, 3, 4, 5, 6);
    cv::Mat transposed = mat5.t();
    if (transposed.rows != 3 || transposed.cols != 2 ||
        transposed.at<int>(0, 0) != 1 || transposed.at<int>(0, 1) != 4 ||
        transposed.at<int>(1, 0) != 2 || transposed.at<int>(1, 1) != 5 ||
        transposed.at<int>(2, 0) != 3 || transposed.at<int>(2, 1) != 6) {
        std::cerr << "Core module test failed: matrix transpose" << std::endl;
        exit(1);
    }

    // Test norm calculation
    cv::Mat mat6 = (cv::Mat_<double>(1, 3) << 3, 4, 0);
    double norm = cv::norm(mat6);
    if (std::abs(norm - 5.0) > 1e-10) {
        std::cerr << "Core module test failed: norm calculation. Expected: 5.0, Got: " << norm << std::endl;
        exit(1);
    }

    std::cout << "Core module test passed!" << std::endl;
}

void testImgProc() {
    std::cout << "Testing imgproc module..." << std::endl;

    // Test threshold operation with exact expected result
    cv::Mat src = (cv::Mat_<uchar>(3, 3) <<
        50, 100, 150,
        200, 250, 30,
        80, 120, 180);
    cv::Mat thresholded;
    cv::threshold(src, thresholded, 127, 255, cv::THRESH_BINARY);

    // Values above 127 should be 255, below should be 0
    if (thresholded.at<uchar>(0, 0) != 0 || thresholded.at<uchar>(0, 1) != 0 ||
        thresholded.at<uchar>(0, 2) != 255 || thresholded.at<uchar>(1, 0) != 255 ||
        thresholded.at<uchar>(1, 1) != 255 || thresholded.at<uchar>(1, 2) != 0 ||
        thresholded.at<uchar>(2, 2) != 255) {
        std::cerr << "Imgproc test failed: threshold operation produced incorrect values" << std::endl;
        exit(1);
    }

    // Test Canny edge detection on a known pattern
    cv::Mat edgeImg = cv::Mat::zeros(100, 100, CV_8UC1);
    cv::rectangle(edgeImg, cv::Point(20, 20), cv::Point(80, 80), cv::Scalar(255), -1);
    cv::Mat edges;
    cv::Canny(edgeImg, edges, 50, 150);

    // Verify edges were actually detected - count non-zero pixels
    int edgePixels = cv::countNonZero(edges);
    if (edgePixels < 100) {  // Should detect rectangle edges
        std::cerr << "Imgproc test failed: Canny edge detection found too few edges: " << edgePixels << std::endl;
        exit(1);
    }

    // Verify edges are at the perimeter, not in solid regions
    // Check center of rectangle (should be no edge)
    if (edges.at<uchar>(50, 50) != 0) {
        std::cerr << "Imgproc test failed: Canny detected edge in solid region" << std::endl;
        exit(1);
    }

    // Test color conversion with known values
    cv::Mat bgr = (cv::Mat_<cv::Vec3b>(1, 1) << cv::Vec3b(255, 0, 0));  // Pure blue
    cv::Mat hsv;
    cv::cvtColor(bgr, hsv, cv::COLOR_BGR2HSV);

    // Pure blue should have hue around 120 (in OpenCV's 0-180 range)
    int hue = hsv.at<cv::Vec3b>(0, 0)[0];
    if (hue < 115 || hue > 125) {
        std::cerr << "Imgproc test failed: BGR to HSV conversion. Expected hue ~120, got: " << hue << std::endl;
        exit(1);
    }

    // Test morphological erosion with known kernel
    cv::Mat morphSrc = (cv::Mat_<uchar>(5, 5) <<
        0, 0, 0, 0, 0,
        0, 255, 255, 255, 0,
        0, 255, 255, 255, 0,
        0, 255, 255, 255, 0,
        0, 0, 0, 0, 0);
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));
    cv::Mat eroded;
    cv::erode(morphSrc, eroded, kernel);

    // After erosion, only center pixel should remain white
    if (eroded.at<uchar>(2, 2) != 255) {
        std::cerr << "Imgproc test failed: erosion - center should be white" << std::endl;
        exit(1);
    }
    if (eroded.at<uchar>(1, 1) != 0 || eroded.at<uchar>(1, 2) != 0 || eroded.at<uchar>(2, 1) != 0) {
        std::cerr << "Imgproc test failed: erosion - edges should be black" << std::endl;
        exit(1);
    }

    // Test resize with exact dimensions
    cv::Mat resizeSrc = cv::Mat::ones(100, 100, CV_8UC1);
    cv::Mat resized;
    cv::resize(resizeSrc, resized, cv::Size(50, 50));
    if (resized.rows != 50 || resized.cols != 50) {
        std::cerr << "Imgproc test failed: resize dimensions incorrect" << std::endl;
        exit(1);
    }

    std::cout << "Imgproc module test passed!" << std::endl;
}

void testFeatures2D() {
    std::cout << "Testing features2d module..." << std::endl;

    // Create a test image with distinct features at known locations
    cv::Mat img = cv::Mat::zeros(300, 300, CV_8UC1);

    // Create 4 distinct corner features
    cv::rectangle(img, cv::Point(50, 50), cv::Point(100, 100), cv::Scalar(255), -1);
    cv::rectangle(img, cv::Point(200, 50), cv::Point(250, 100), cv::Scalar(255), -1);
    cv::rectangle(img, cv::Point(50, 200), cv::Point(100, 250), cv::Scalar(255), -1);
    cv::rectangle(img, cv::Point(200, 200), cv::Point(250, 250), cv::Scalar(255), -1);

    // Test ORB detector
    cv::Ptr<cv::ORB> orb = cv::ORB::create();
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;

    orb->detectAndCompute(img, cv::noArray(), keypoints, descriptors);

    if (keypoints.size() < 4) {
        std::cerr << "Features2d test failed: expected at least 4 keypoints, found " << keypoints.size() << std::endl;
        exit(1);
    }

    if (descriptors.empty()) {
        std::cerr << "Features2d test failed: no descriptors computed" << std::endl;
        exit(1);
    }

    // Verify descriptors have correct dimensions (ORB uses 32-byte descriptors)
    if (descriptors.rows != (int)keypoints.size() || descriptors.cols != 32) {
        std::cerr << "Features2d test failed: descriptor dimensions incorrect. Expected "
                  << keypoints.size() << "x32, got " << descriptors.rows << "x" << descriptors.cols << std::endl;
        exit(1);
    }

    // Verify at least one keypoint is in each quadrant
    bool foundQ1 = false, foundQ2 = false, foundQ3 = false, foundQ4 = false;
    for (const auto& kp : keypoints) {
        if (kp.pt.x < 150 && kp.pt.y < 150) foundQ1 = true;
        if (kp.pt.x >= 150 && kp.pt.y < 150) foundQ2 = true;
        if (kp.pt.x < 150 && kp.pt.y >= 150) foundQ3 = true;
        if (kp.pt.x >= 150 && kp.pt.y >= 150) foundQ4 = true;
    }

    if (!foundQ1 || !foundQ2 || !foundQ3 || !foundQ4) {
        std::cerr << "Features2d test failed: keypoints not distributed as expected across quadrants" << std::endl;
        exit(1);
    }

    std::cout << "Features2d module test passed! (Detected " << keypoints.size() << " keypoints)" << std::endl;
}

void testCalib3D() {
    std::cout << "Testing calib3d module..." << std::endl;

    // Test homography with known transformation (pure translation)
    std::vector<cv::Point2f> srcPoints, dstPoints;

    float tx = 10.0f, ty = 15.0f;  // Known translation
    srcPoints.push_back(cv::Point2f(0, 0));
    srcPoints.push_back(cv::Point2f(100, 0));
    srcPoints.push_back(cv::Point2f(100, 100));
    srcPoints.push_back(cv::Point2f(0, 100));

    for (const auto& pt : srcPoints) {
        dstPoints.push_back(cv::Point2f(pt.x + tx, pt.y + ty));
    }

    cv::Mat homography = cv::findHomography(srcPoints, dstPoints);

    if (homography.empty() || homography.rows != 3 || homography.cols != 3) {
        std::cerr << "Calib3d test failed: homography has incorrect dimensions" << std::endl;
        exit(1);
    }

    // For pure translation, H should be approximately:
    // [1, 0, tx]
    // [0, 1, ty]
    // [0, 0, 1]
    double h00 = homography.at<double>(0, 0);
    double h11 = homography.at<double>(1, 1);
    double h22 = homography.at<double>(2, 2);
    double h02 = homography.at<double>(0, 2) / h22;  // Normalize by h22
    double h12 = homography.at<double>(1, 2) / h22;

    if (std::abs(h00 / h22 - 1.0) > 0.1 || std::abs(h11 / h22 - 1.0) > 0.1) {
        std::cerr << "Calib3d test failed: homography diagonal elements incorrect" << std::endl;
        exit(1);
    }

    if (std::abs(h02 - tx) > 2.0 || std::abs(h12 - ty) > 2.0) {
        std::cerr << "Calib3d test failed: translation components incorrect. Expected ("
                  << tx << ", " << ty << "), got (" << h02 << ", " << h12 << ")" << std::endl;
        exit(1);
    }

    // Verify the homography actually transforms points correctly
    std::vector<cv::Point2f> transformedPoints;
    cv::perspectiveTransform(srcPoints, transformedPoints, homography);

    for (size_t i = 0; i < srcPoints.size(); i++) {
        float dx = std::abs(transformedPoints[i].x - dstPoints[i].x);
        float dy = std::abs(transformedPoints[i].y - dstPoints[i].y);
        if (dx > 0.5 || dy > 0.5) {
            std::cerr << "Calib3d test failed: point transformation error too large at point " << i << std::endl;
            exit(1);
        }
    }

    std::cout << "Calib3d module test passed!" << std::endl;
}

void testDNN() {
    std::cout << "Testing dnn module..." << std::endl;

    // Test blob creation with specific known values
    cv::Mat img = cv::Mat::ones(10, 10, CV_8UC3) * 100;
    cv::Mat blob = cv::dnn::blobFromImage(img, 1.0/255.0, cv::Size(10, 10),
                                          cv::Scalar(0, 0, 0), false, false);

    if (blob.empty()) {
        std::cerr << "DNN test failed: blob creation" << std::endl;
        exit(1);
    }

    // Check blob dimensions (should be 4D: [1, 3, 10, 10])
    if (blob.dims != 4 || blob.size[0] != 1 || blob.size[1] != 3 ||
        blob.size[2] != 10 || blob.size[3] != 10) {
        std::cerr << "DNN test failed: blob dimensions incorrect" << std::endl;
        exit(1);
    }

    // Verify blob values are correctly scaled (100/255 ≈ 0.392)
    float* blobData = (float*)blob.data;
    float expectedValue = 100.0f / 255.0f;

    // Check a few sample values
    for (int i = 0; i < 10; i++) {
        if (std::abs(blobData[i] - expectedValue) > 0.01) {
            std::cerr << "DNN test failed: blob values incorrect. Expected ~"
                      << expectedValue << ", got " << blobData[i] << std::endl;
            exit(1);
        }
    }

    // Test blob with mean subtraction
    cv::Mat blob2 = cv::dnn::blobFromImage(img, 1.0, cv::Size(10, 10),
                                           cv::Scalar(50, 50, 50), false, false);
    float* blob2Data = (float*)blob2.data;
    float expectedValue2 = 100.0f - 50.0f;

    if (std::abs(blob2Data[0] - expectedValue2) > 0.1) {
        std::cerr << "DNN test failed: blob mean subtraction incorrect" << std::endl;
        exit(1);
    }

    std::cout << "DNN module test passed!" << std::endl;
}

void testML() {
    std::cout << "Testing ml module..." << std::endl;

    // Create simple training data with 3 clear clusters
    cv::Mat data(90, 2, CV_32F);

    // Cluster 1: around (0, 0)
    for (int i = 0; i < 30; i++) {
        data.at<float>(i, 0) = (rand() % 20) / 10.0f;
        data.at<float>(i, 1) = (rand() % 20) / 10.0f;
    }

    // Cluster 2: around (100, 100)
    for (int i = 30; i < 60; i++) {
        data.at<float>(i, 0) = 100 + (rand() % 20) / 10.0f;
        data.at<float>(i, 1) = 100 + (rand() % 20) / 10.0f;
    }

    // Cluster 3: around (100, 0)
    for (int i = 60; i < 90; i++) {
        data.at<float>(i, 0) = 100 + (rand() % 20) / 10.0f;
        data.at<float>(i, 1) = (rand() % 20) / 10.0f;
    }

    // Test k-means clustering
    cv::Mat labels, centers;
    int k = 3;
    double compactness = cv::kmeans(data, k, labels,
                                    cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 100, 0.1),
                                    5, cv::KMEANS_PP_CENTERS, centers);

    if (labels.empty() || centers.empty()) {
        std::cerr << "ML test failed: k-means clustering produced no results" << std::endl;
        exit(1);
    }

    if (centers.rows != k || centers.cols != 2) {
        std::cerr << "ML test failed: incorrect number of cluster centers" << std::endl;
        exit(1);
    }

    if (labels.rows != 90) {
        std::cerr << "ML test failed: incorrect number of labels" << std::endl;
        exit(1);
    }

    // Verify centers are roughly at expected positions
    bool foundNear0 = false, foundNear100_100 = false, foundNear100_0 = false;

    for (int i = 0; i < k; i++) {
        float cx = centers.at<float>(i, 0);
        float cy = centers.at<float>(i, 1);

        if (cx < 10 && cy < 10) foundNear0 = true;
        if (cx > 90 && cy > 90) foundNear100_100 = true;
        if (cx > 90 && cy < 10) foundNear100_0 = true;
    }

    if (!foundNear0 || !foundNear100_100 || !foundNear100_0) {
        std::cerr << "ML test failed: cluster centers not at expected positions" << std::endl;
        for (int i = 0; i < k; i++) {
            std::cerr << "  Center " << i << ": (" << centers.at<float>(i, 0)
                      << ", " << centers.at<float>(i, 1) << ")" << std::endl;
        }
        exit(1);
    }

    // Verify compactness is reasonable (not infinite or NaN)
    if (std::isnan(compactness) || std::isinf(compactness) || compactness < 0) {
        std::cerr << "ML test failed: invalid compactness value: " << compactness << std::endl;
        exit(1);
    }

    std::cout << "ML module test passed! (Compactness: " << compactness << ")" << std::endl;
}

int main() {
    std::cout << "Starting OpenCV functionality tests..." << std::endl;
    std::cout << "OpenCV version: " << CV_VERSION << std::endl;

    try {
        testCore();
        testImgProc();
        testFeatures2D();
        testCalib3D();
        testDNN();
        testML();

        std::cout << "\nAll OpenCV tests passed successfully!" << std::endl;
        return 0;
    } catch (const cv::Exception& e) {
        std::cerr << "OpenCV exception: " << e.what() << std::endl;
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "Standard exception: " << e.what() << std::endl;
        return 1;
    }
}
