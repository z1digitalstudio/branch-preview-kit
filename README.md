# branch-preview-kit

`branch-preview-kit` is a toolkit that facilitates the creation of "branch
previews". Branch previewing is a pattern of deploying the contents of a feature
branch so that they can be examined before merging. A branch preview deployment
has an unique url, is created when the pull request is opened, and is destroyed
when the pull request is merged.

`branch-preview-kit` is built with [Terraform][terraform].

## Prerequisites

* An [Amazon Web Services][aws] account, where the deployments will be created.
* A domain and an `AWS Route 53` hosted zone associated to it.
* Your project must be hosted on a GitHub repository.
* A [GitHub app][gh-app], to display the preview url in is respective pull
request.
* A CI runner supporting [Docker][docker] which will run `branch-preview-kit` on
each PR. At @z1digitalstudio we use [CicleCI][circleci].

## Bootstrapping

Before we can use the toolkit, we must bootstrap it. Bootstrapping will:

* create the S3 bucket used by Terraform to persist its state.
* create the DynamoDB table used by Terraform to lock its state.
* create the ACM wildcard certificate that will be used by all Cloudfront
distributions.

The bootstrapping may only be done once. If we want to use `branch-preview-kit`
across multiple projects, we can do so without having to bootstrap twice.

In order to run the bootstrap, generate an AWS access key with full privileges.
This access key is only temporary, and should be revoked after the bootstrapping
is finished.

Run:

```bash
$ docker run \
    -v "$(pwd):/out" \
    -e "AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx" \
    -e "AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
    -e "BASE_DOMAIN=example.com" \
    -e "BRANCH_PREVIEW_FQDN=branch-preview.example.com" \
    -e "TFSTATE_RESOURCES_NAME=tfstate.example.com" \
    -ti z1digitalstudio/branch-preview-kit bootstrap
```

### `bootstrap` variable reference

| name | description |
| ---- | ----------- |
| `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` | The AWS IAM credentials. |
| `BASE_DOMAIN` | The domain under which we will create the branch preview subdomain. It must have an associated Route 53 Hosted Zone. |
| `BRANCH_PREVIEW_FQDN` | The Fully Qualified Domain Name of the branch preview subdomain. Branch previews will in turn be served under a subdomain of this subdomain. (i.e: `feat-1.branch-preview.example.com`) |
| `TFSTATE_RESOURCES_NAME` | The name of the S3 bucket and DynamoDB table that will contain the Terraform state |

### `bootstrap` outputs

After running, the `bootstrap` command will create the following outputs in your
working directory:

* `acm_certificate_arn`: a text file containing the ARN of the created
certificate. You will need it each time you run `branch-preview-kit`.
* `terraform.tfstate`: a file containing the Terraform state of the bootstrapped
resources. In theory, they will never change, so this file will never be
necessary. However, in practice, an update of this toolkit might require you
to bootstrap again, in which case this file will be necessary. Therefore, it
would be wise to keep it safe. A good place to save it would be the created
Terraform state bucket.

## Deploying Single Page Applications

At the moment, `branch-preview-kit` can only deploy single page applications as
static websites.

The command `spa up` will:

* create an S3 bucket
* create a Cloudfront distribution pointing to that bucket, using the ACM
Wildcard Certificate generated in the Bootstrapping step.
* create the necessary Route 53 record pointing to the CF distribution.

In order to run the bootstrap, generate an AWS access key with enough privileges
to run this command. The necessary IAM Policy is described below in the [IAM
Policies](#iam-policies) section.

Run:

```bash
$ docker run \
    -v "$(pwd):/out" \
    -e "AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx" \
    -e "AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
    -e "AWS_CERT_ARN=arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000000" \
    -e "BASE_DOMAIN=example.com" \
    -e "BRANCH_PREVIEW_FQDN=branch-preview.example.com" \
    -e "BRANCH_PREVIEW_ID=feat-1" \
    -e "GITHUB_APP_ID=00000" \
    -e "GITHUB_APP_PRIVATE_KEY_BASE64=$(cat private-key.pem | base64 -w 0)" \
    -e "GITHUB_BRANCH=feat-1/add-new-feature" \
    -e "GITHUB_REPO=my-org/my-repo\
    -e "TFSTATE_RESOURCES_NAME=tfstate.example.com" \
    -ti z1digitalstudio/branch-preview-kit spa up
```

## `spa up` variable reference

This commands requires all variables from the `bootstrap` command. You can
consult them [here](#bootstrap-variable-reference). In addition, it requires:

| name | description |
| ---- | ----------- |
| `AWS_CERT_ARN` | The ARN of the AWS ACM certificate generated in the bootstrapping step. |
| `BRANCH_PREVIEW_ID` | An unique string identifying your feature. It is useful to issue tracker ids. **This ID must be globally unique across all projects**. |
| `BRANCH_PREVIEW_FQDN` | The Fully Qualified Domain Name of the branch preview subdomain. Branch previews will in turn be served under a subdomain of this subdomain. (i.e: `feat-1.branch-preview.example.com`) |
| `GITHUB_APP_ID` | The ID of the GitHub App that will be used to report the preview URL on the GitHub pull request. |
| `GITHUB_APP_PRIVATE_KEY_BASE64` | The private key of the GitHub App, as a base64 encoded string. |
| `GITHUB_BRANCH` | The head branch of the GitHub Pull Request. This is where the GitHub App will post its comments. If the PR doesn't exist, it will not post anything. |
| `GITHUB_REPO` | The GitHub repo of the project being built. |

### `spa up` outputs

After running, the `spa up` command will create the following outputs in your
working directory:

* `cloudfront_distribution_id`: the ID of the Cloudfront distribution. Useful
to invalidate the cache on subsequent feature updates.
* `s3_bucket_uri`: the uri of the S3 bucket, correctly prefixed (i.e:
`s3://feat-1.branch-preview.example.com.0000`). Useful to update the bucket on
subsequent feature updates.

## IAM Policies

### `spa up`

The following IAM Policy is needed to perform the `spa up` command:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"cloudfront:CreateDistribution",
				"cloudfront:GetDistribution",
				"cloudfront:ListTagsForResource",
				"cloudfront:TagResource",
				"route53:GetChange",
				"route53:ListHostedZones",
				"s3:CreateBucket",
				"s3:GetAccelerateConfiguration",
				"s3:GetAnalyticsConfiguration",
				"s3:GetBucketAcl",
				"s3:GetBucketCORS",
				"s3:GetBucketLocation",
				"s3:GetBucketLogging",
				"s3:GetBucketNotification",
				"s3:GetBucketObjectLockConfiguration",
				"s3:GetBucketPolicy",
				"s3:GetBucketPolicyStatus",
				"s3:GetBucketPublicAccessBlock",
				"s3:GetBucketRequestPayment",
				"s3:GetBucketTagging",
				"s3:GetBucketVersioning",
				"s3:GetBucketWebsite",
				"s3:GetEncryptionConfiguration",
				"s3:GetInventoryConfiguration",
				"s3:GetLifecycleConfiguration",
				"s3:GetReplicationConfiguration",
				"s3:ListBucket",
				"s3:PutAccelerateConfiguration",
				"s3:PutAnalyticsConfiguration",
				"s3:PutBucketCORS",
				"s3:PutBucketLogging",
				"s3:PutBucketNotification",
				"s3:PutBucketObjectLockConfiguration",
				"s3:PutBucketPolicy",
				"s3:PutBucketRequestPayment",
				"s3:PutBucketVersioning",
				"s3:PutBucketWebsite",
				"s3:PutEncryptionConfiguration",
				"s3:PutInventoryConfiguration",
				"s3:PutLifecycleConfiguration",
				"s3:PutMetricsConfiguration",
				"s3:PutReplicationConfiguration"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"route53:ChangeResourceRecordSets",
				"route53:GetHostedZone",
				"route53:ListResourceRecordSets",
				"route53:ListTagsForResource"
			],
			"Resource": "arn:aws:route53:::hostedzone/HOSTED_ZONE_ID"
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:GetObject"
			],
			"Resource": "arn:aws:s3:::TFSTATE_RESOURCES_NAME/*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"dynamodb:GetItem",
				"dynamodb:PutItem",
				"dynamodb:DeleteItem"
			],
			"Resource": "arn:aws:dynamodb:*:*:table/TFSTATE_RESOURCES_NAME"
		}
	]
}
```

Make sure to replace `HOSTED_ZONE_ID` and `TFSTATE_RESOURCES_NAME` with their
correct values.

### `spa down`

**In addition to the `spa up` policy**, the following IAM Policy is needed to perform the `spa down` command:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:DeleteDistribution",
                "cloudfront:UpdateDistribution",
                "s3:DeleteBucket",
                "s3:DeleteObject",
                "s3:ListBucketVersions",
                "s3:PutObject"
            ],
            "Resource": "*"
        }
    ]
}
```

[aws]: https://aws.amazon.com/
[circleci]: https://circleci.com/
[docker]: https://www.docker.com/
[gh-app]: https://developer.github.com/apps/
[terraform]: https://www.terraform.io/
