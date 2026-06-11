from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("SimpleJob").getOrCreate()
data = [1, 2, 3, 4, 5]
rdd = spark.sparkContext.parallelize(data)
sum = rdd.reduce(lambda x, y: x + y)
assert sum == 15
