import argparse
import importlib

from pyspark.sql import SparkSession


parser = argparse.ArgumentParser()
parser.add_argument('--job', type=str, required=True, help='the job name you want to select')
parser.add_argument("--job-args", action='append', type=str, help='the arguments of the job passed\
  one or multiple timesin form of --job-args="[key]=[value]" ')


args = parser.parse_args()

#transforming the job args into a dictionary
def get_kwargs(job_args):
  dic = {}
  for el in job_args:
    key, value = el.split('=')
    dic[key] = value
  return dic


spark = SparkSession \
        .builder \
        .master("yarn") \
        .appName('dataproc-python-demo') \
        .getOrCreate()

# importing the selected job module
job_module = importlib.import_module('jobs.%s' % args.job)
# calling the function analyze the job exposes
job_module.analyze(spark, **get_kwargs(args.job_args))
