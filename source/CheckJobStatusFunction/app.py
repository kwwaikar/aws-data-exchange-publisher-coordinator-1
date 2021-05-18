import boto3
import os
import logging
from datetime import datetime
import random

def lambda_handler(event, context):
    """This function checks and returns the import assets job status"""
    try:
        global log_level
        log_level = str(os.environ.get('LOG_LEVEL')).upper()
        valid_log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
        if log_level not in valid_log_levels:
            log_level = 'ERROR'

        logging.getLogger().setLevel(log_level)

        logging.debug('event={}'.format(event))

        dataexchange = boto3.client(service_name='dataexchange')
        s3 = boto3.client(service_name='s3') 

        product_id = event['ProductId']
        dataset_id = event['DatasetId']
        revision_id = event['RevisionId']
        job_id = event['JobId']
        
        job_response = dataexchange.get_job(JobId=job_id) 
        logging.debug('get job = {}'.format(job_response))

        job_status = job_response['State']

        metrics = {
            "Version" : os.getenv('Version'),
            "TimeStamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f'),
            "ProductId" : product_id,
            "DatasetId": dataset_id,
            "RevisionId": revision_id,
            "JobId": job_id,
            # "JobResponse": job_response,
            "JobStatus": job_status
        }
        logging.info('Metrics:{}'.format(metrics))


    except Exception as e:
       logging.error(e)
       raise e
    return {
        "StatusCode": 200,
        "ProductId" : product_id,
        "DatasetId": dataset_id,
        "RevisionId": revision_id,
        "JobId": job_id,
        # "JobResponse": job_response,
        "JobStatus": job_status
    }
