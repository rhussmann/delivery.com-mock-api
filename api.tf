# Configure the AWS Provider
provider "aws" {
    region = "${var.region}"
}

resource "aws_api_gateway_rest_api" "MockDeliveryDotCom" {
  name = "MockDeliveryDotCom"
  description = <<EOF
Since we can't currently get access, this is a mock of the delivery.com API.
EOF
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  parent_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.root_resource_id}"
  path_part = "api"
}

resource "aws_api_gateway_resource" "merchant" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  parent_id = "${aws_api_gateway_resource.api.id}"
  path_part = "merchant"
}

resource "aws_api_gateway_resource" "search" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  parent_id = "${aws_api_gateway_resource.merchant.id}"
  path_part = "search"
}

resource "aws_api_gateway_resource" "DeliverySearch" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  parent_id = "${aws_api_gateway_resource.search.id}"
  path_part = "{method}"
}

resource "aws_api_gateway_method" "DeliverySearchGet" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  resource_id = "${aws_api_gateway_resource.DeliverySearch.id}"
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.address" = true
    "method.request.querystring.latitude" = true
    "method.request.querystring.longitude" = true
    "method.request.querystring.access_token" = true
    "method.request.querystring.merchant_type" = true
  }
}

resource "aws_api_gateway_integration" "DeliverySearchGetIntegration" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  resource_id = "${aws_api_gateway_resource.DeliverySearch.id}"
  http_method = "${aws_api_gateway_method.DeliverySearchGet.http_method}"
  integration_http_method  = "${aws_api_gateway_method.DeliverySearchGet.http_method}"
  type = "MOCK"
  request_templates = {
    "application/json" = "${file("templates/integrationRequest.vtl")}"
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  resource_id = "${aws_api_gateway_resource.DeliverySearch.id}"
  http_method = "${aws_api_gateway_method.DeliverySearchGet.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "DeliverySearchGetIntegrationResponse" {
  depends_on = ["aws_api_gateway_integration.DeliverySearchGetIntegration"]
  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  resource_id = "${aws_api_gateway_resource.DeliverySearch.id}"
  http_method = "${aws_api_gateway_method.DeliverySearchGet.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  response_templates = {
    "application/json" = "${file("templates/integrationResponse.vtl")}"
  }
}

resource "aws_api_gateway_deployment" "MyDemoDeployment" {
  depends_on = ["aws_api_gateway_integration.DeliverySearchGetIntegration"]

  rest_api_id = "${aws_api_gateway_rest_api.MockDeliveryDotCom.id}"
  stage_name = "test"
}
