#!/bin/bash

set -o errexit -o nounset -o errtrace -o pipefail -x

# Test CREATE DATABASE
clickhouse-client --query "CREATE DATABASE IF NOT EXISTS test;"
# Test CREATE TABLE
clickhouse-client --query "CREATE TABLE IF NOT EXISTS test.sample (id UInt32, name String) ENGINE = MergeTree() ORDER BY id;"
# Test INSERT
clickhouse-client --query "INSERT INTO test.sample VALUES (1, 'test');"
# Test SELECT
clickhouse-client --query "SELECT * FROM test.sample" | grep -q "test"

# Test basic HTTP query
curl -s "http://localhost:8123/?query=SELECT%201" | grep -q "1"
# Test database creation via HTTP
curl -s -X POST "http://localhost:8123/?query=CREATE%20DATABASE%20IF%20NOT%20EXISTS%20http_test"

# Check access to system tables
clickhouse-client --query "SELECT * FROM system.databases WHERE name = 'system'" | grep -q "system"
clickhouse-client --query "SELECT * FROM system.tables WHERE database = 'system' LIMIT 1"

# Test data types handling
clickhouse-client --query "
    CREATE TABLE IF NOT EXISTS test.types (
    int8_col Int8,
    uint64_col UInt64,
    float_col Float64,
    string_col String,
    date_col Date
    ) ENGINE = MergeTree() ORDER BY int8_col"
clickhouse-client --query "
    INSERT INTO test.types VALUES
    (1, 18446744073709551615, 3.14159, 'test string', '2024-01-01')"
clickhouse-client --query "SELECT * FROM test.types" | grep -q "test string"

# Simple benchmark test with default options
clickhouse-benchmark --query "SELECT 1" --iterations 10
# Test with concurrency
clickhouse-benchmark --concurrency 2 --query "SELECT number FROM system.numbers LIMIT 10" --iterations 3
