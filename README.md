aws-rest-server
=========

aws-rest-server is simple api server for AWS, generated by Sinatra.
We are assuming that aws-rest-server is used by client like iOS app.

## Getting Started

### Requirements
* AWS Account
* Ruby

### Quick start

```shell
git clone git@github.com:betahikaru/aws-rest-server.git
cd aws-rest-server
bundle install --path vendor/bundle
bundle exec rackup
```

Server will response json. Content-Type is "application/json".

Server has sample data. Show following command.

```shell
% curl -u user:changeme "http://localhost:9292/aws/iam/users?test=1"
{
    "Users": [
        {
            "UserName": "aws_user1",
            "Path": "/",
            "CreateDate": "2014-05-23T14:46:39Z",
            "UserId": "USER1XXXXXXXXXXXXXXXX",
            "Arn": "arn:aws:iam::123456789012:user/aws_user1"
        },
        ...
    ]
}
```

> All page needs BasicAuth. username is "user", passoword is "changeme" by default. If you want to change those, show #Authentication topic.

## Setting

First, copy ```.env.sample``` to ```.env```.
```shell
cp .env.sample .env
vi .env
```

### AWS API Setting
Set up region and restart server. aws-rest-server uses AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to run spec.
Edit ```.env```.

```shell
AWS_ACCESS_KEY_ID=<Your API Key encoded for URI>
AWS_SECRET_ACCESS_KEY=<Your API Key encoded for URI>
AWS_REGION=ap-northeast-1
```

### Basic Authentication Setting
aws-rest-server uses BasicAuth for all request.
Edit ```.env``` to set username and password.

```
BASIC_AUTH_USERNAME=<User name for BasicAuth>
BASIC_AUTH_PASSWORD=<Password for BasicAuth>
```

And, don't support OAuth and other one yet.

## Usage

### Use by cUrl
After setting, execute following command.

```shell
# Register IAM User's API Key and Secret Access Key. Those value saved Session.
curl -u user:changeme -d AWS_ACCESS_KEY_ID=<Your API Key encoded for URI> -d AWS_SECRET_ACCESS_KEY=<Your API Key encoded for URI> "http://localhost:9292/aws/setting"

# Get IAM User list
curl -u user:changeme "http://localhost:9292/aws/iam/users"
```

### End points
- Register IAM User's API Key and Secret Access Key for reading IAM Information.
  - POST ```/aws/setting```
    - parameter(required) : ```AWS_ACCESS_KEY_ID```
      - IAM User's API Key. Needs to encoded for URI. Required to have Managemented Policy called 'IAMReadonlyAccess'.
    - parameter(required) : ```AWS_SECRET_ACCESS_KEY```
      - IAM User's Secret Access Key. Needs to encoded for URI.
- List IAM Users.
  - GET ```/aws/iam/users```
  - GET ```/aws/iam/users?test=1```
- List IAM Groups of a User.
  - GET ```/aws/iam/users/:user_name/groups```
- List IAM Groups.
  - GET ```/aws/iam/groups```
  - GET ```/aws/iam/groups?test=1```
- List IAM Policies of User and Group.
  - GET ```/aws/iam/users/:user_name/policies```
  - GET ```/aws/iam/groups/:group_name/policies```
- IAM entity usage and IAM quotas.
  - GET ```/aws/iam/account_summary```
  - GET ```/aws/iam/account_summary?test=1```

## Licence
MIT
