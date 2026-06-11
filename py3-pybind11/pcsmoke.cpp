#include <pybind11/pybind11.h>

PYBIND11_MODULE(pcsmoke, m) { m.attr("ok") = true; }
