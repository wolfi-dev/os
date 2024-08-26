#include <iostream>
#include <double-conversion/double-conversion.h>

int main() {
    double_conversion::DoubleToStringConverter converter(
        double_conversion::DoubleToStringConverter::NO_FLAGS,
        "Infinity", "NaN", 'e', -6, 21, 6, 0);

    char buffer[128];
    double value = 12345.6789;
    double_conversion::StringBuilder builder(buffer, sizeof(buffer));
    converter.ToShortest(value, &builder);

    std::string result = builder.Finalize();
    std::cout << "Converted value: " << result << std::endl;

    return result == "12345.6789" ? 0 : 1;
}
