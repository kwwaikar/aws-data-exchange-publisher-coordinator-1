import boto3
import os
import logging

from datetime import datetime
from pyrearcadx.s3_helper import s3_select


def lambda_handler(event, context):
    """
    This function creates a new revision for the dataset and prepares input for the import job map
    """
    try:
        global log_level
        log_level = str(os.getenv('LOG_LEVEL')).upper()
        valid_log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
        if log_level not in valid_log_levels:
            log_level = 'ERROR'

        logging.getLogger().setLevel(log_level)
        
        logging.debug(f'{event=}')

        dataexchange = boto3.client(service_name='dataexchange')
        s3 = boto3.client(service_name='s3') 

        bucket = event['Bucket']
        key = event['Key']
        product_id = event['ProductId']
        dataset_id = event['DatasetId']
        revision_index = event['RevisionMapIndex']

        logging.debug(f"{bucket=}\n{key=}\n{product_id=}\n{dataset_id=}\n{revision_index=}")
        logging.info(f"Creating the input list to create a dataset revision with {revision_index=}")
        select_expression = f"""SELECT COUNT(*) FROM s3object[*].asset_list_nested[{revision_index}][*] r;"""
        num_jobs = s3_select(bucket, key, select_expression)
        job_map_input_list = list(range(num_jobs))

        num_revision_assets = 0
        for job_index in range(num_jobs):
            select_expression = f"""SELECT COUNT(*) FROM s3object[*].asset_list_nested[{revision_index}][{job_index}][*] r;"""
            num_job_assets = s3_select(bucket, key, select_expression)
            num_revision_assets += num_job_assets
        
        logging.debug(f'{dataset_id=}')
        revision = dataexchange.create_revision(DataSetId=dataset_id,
                                                Comment="from aws-data-exchange-publishing-workflow")
        revision_id = revision['Id']
        logging.info(f'{revision_id=}')

        metrics = {
                "Version": os.getenv('Version'),
                "TimeStamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f'),
                "ProductId": product_id,
                "DatasetId": dataset_id,
                "RevisionId": revision_id,
                "RevisionMapIndex": revision_index,
                "RevisionAssetCount": num_revision_assets,
                "RevisionJobCount": num_jobs,
                "JobMapInput": job_map_input_list
            }
        logging.info(f'Metrics:{metrics}')

    except Exception as e:
        logging.error(e)
        raise e

    return {
        "StatusCode": 200,
        "Message": f"New revision created with RevisionId: {revision_id} and input generated for {num_jobs} jobs",
        'Bucket': bucket,
        'Key': key,
        "ProductId": product_id,
        "DatasetId": dataset_id,
        "RevisionId": revision_id,
        "RevisionMapIndex": revision_index,
        "NumJobs": num_jobs,
        "NumRevisionAssets": num_revision_assets,
        "JobMapInput": job_map_input_list
    }
