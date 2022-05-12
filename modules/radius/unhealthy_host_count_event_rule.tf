resource "aws_cloudwatch_event_rule" "unhealthy-host-count" {
  name        = "${var.prefix}-unhealthy-host-count"
  description = "Unhealthy host count metric"

  event_pattern = <<EOF
{
    "source": [
        "aws.ecs"
    ],
    "detail-type": [
        "ECS Task State Change"
    ],
    "detail": {
        "group": [
            "${aws_ecs_service.service.id}"
        ],
        "stoppedReason": [
            "Essential container in task exited"
        ]
    }
}
EOF
}
