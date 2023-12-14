
locals {
  lambda_file = "lambda_function.zip"
}
module "ec2_creation" {
  source = "../modules/ec2"

}


resource "aws_iam_role" "lambda_execution_role" {
  name = "roleLambda"

  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  POLICY
}

resource "aws_lambda_function" "cpu_utilization_handler" {
  filename         = "lambda_function.zip"
  source_code_hash = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.id
}

resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
}

resource "aws_sns_topic_subscription" "my_sns_subscription" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "lambda"
  #endpoint  = aws_cloudwatch_event_rule.cpu_utilization_rule.arn
  endpoint = aws_lambda_function.cpu_utilization_handler.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cpu_utilization_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_updates.arn
}


resource "aws_iam_role" "cloudwatch_role" {
  name = "roleCloudwatch"

  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "cloudwatch.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  POLICY
}


resource "aws_iam_policy_attachment" "cloudwatch_policy_attachment" {
  name = "cloudwatch_policy_attachment"
  #policy_arn = data.aws_iam_policy_document.test.json
  policy_arn = "arn:aws:iam::aws:policy/AmazonCloudWatchEvidentlyFullAccess"
  roles      = [aws_iam_role.cloudwatch_role.name]
  #resources = [aws_cloudwatch_metric_alarm.cpu_utilization_alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "CPUUtilizationAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold" #"GreaterThanUpperThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # 5 minutes, adjust as needed
  statistic           = "Sum"
  threshold           = 40 # Adjust as needed
  # threshold_metric_id       = "e1"
  alarm_description         = "Alarm when CPU utilization exceeds 40%"
  treat_missing_data        = "missing"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = module.ec2_creation.ec2_id
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.user_updates.arn]
  #alarm_actions = [aws_lambda_function.cpu_utilization_handler.arn]
}

resource "aws_cloudwatch_event_rule" "cpu_utilization_rule" {
  name        = "CpuUtilizationRule"
  description = "Trigger Lambda when CPU exceeds 40%"

  event_pattern = <<PATTERN
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"]

}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cpu_utilization_rule.name
  target_id = aws_lambda_function.cpu_utilization_handler.id
  arn       = aws_lambda_function.cpu_utilization_handler.arn
}

data "aws_iam_policy_document" "test" {
  statement {
    sid    = "DevAccountAccess"
    effect = "Allow"
    actions = [
      "events:PutEvents",
      "sns:*"
    ]
    resources = [
      "*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

