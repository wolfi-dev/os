from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg

def main():
    # Initialize Spark session
    spark = SparkSession.builder \
        .appName("ExampleSparkJob") \
        .getOrCreate()

    # Read CSV file into DataFrame
    input_path = "./salaries.csv"
    df = spark.read.option("header", "true").csv(input_path)

    # Convert numeric columns to proper types
    df = df.withColumn("age", col("age").cast("int")) \
           .withColumn("salary", col("salary").cast("double"))

    # Perform simple aggregation
    avg_salary_by_age = df.groupBy("age").agg(avg("salary").alias("average_salary"))

    # Show results
    avg_salary_by_age.show()

    # Write results to output CSV
    output_path = "data/output.csv"
    avg_salary_by_age.write.mode("overwrite").csv(output_path, header=True)

    # Stop Spark session
    spark.stop()

if __name__ == "__main__":
    main()
