#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include <vector>

std::vector<int> doubled(const std::vector<int> &xs) {
  std::vector<int> out;
  out.reserve(xs.size());
  for (const int x : xs) {
    out.push_back(2 * x);
  }
  return out;
}

PYBIND11_MODULE(smoke, m) { m.def("doubled", &doubled); }
