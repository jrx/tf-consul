resource "aws_iam_role" "ec2_consul_discover_role" {
  name               = "consul-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "consul-policy" {
  name        = "consul-policy"
  description = "policy to discover the consul cluster nodes"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "consul-attach" {
  name       = "consul-attach"
  roles      = ["${aws_iam_role.ec2_consul_discover_role.name}"]
  policy_arn = aws_iam_policy.consul-policy.arn
}

resource "aws_iam_instance_profile" "consul_profile" {
  name = "consul_profile"
  role = aws_iam_role.ec2_consul_discover_role.name
}