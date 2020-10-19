# pan_aws
This is the CFT template to deploy sample application topology for inbound, east-west and outbound traffic. 

Traffic template: 
panw-aws-app-v3.0.template

Note: 
1. Upload app.zip to S3 bucket, the lambda function inside will create AGWe. 
2. Need to enter the AGW service configuration name from security VPC. 
3. Need to provide TGW Id.
4. Customers need to create a route in App attachment route table pointing to security attachment if they decide to protect east-west traffic. A concept of service insertion. 
