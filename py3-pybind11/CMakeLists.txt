cmake_minimum_required(VERSION 3.18)
project(smoke LANGUAGES CXX)

find_package(pybind11 CONFIG REQUIRED)
pybind11_add_module(smoke smoke.cpp)
