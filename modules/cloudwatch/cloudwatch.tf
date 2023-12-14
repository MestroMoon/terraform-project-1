module "rule_label" {
  source  = "cloudposse/label/null"
  version = "0.22.0" // requires Terraform >= 0.12.26

  id_length_limit = 64

  context = module.this.context
}

resource "aws_cloudwatch_event_rule" "evnt_rule" {
  name        = module.rule_label.id
  is_enabled  = var.cloudwatch_event_rule_is_enabled
  description = var.cloudwatch_event_rule_description != "" ? var.cloudwatch_event_rule_description : module.rule_label.id_full

  event_pattern = jsonencode(var.cloudwatch_event_rule_pattern)
}

resource "aws_cloudwatch_event_target" "evnt_target" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = var.cloudwatch_event_target_id
  arn       = var.cloudwatch_event_target_arn
}

resource "aws_cloudwatch_metric_alarm" "cpu_uti" {
  alarm_name                = "cpu_uti"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
}