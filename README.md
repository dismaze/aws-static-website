# 🧘 Generic Static Website - AWS Hosted

A production-ready template for deploying modern static websites to AWS using Eleventy, Tailwind CSS, Terraform, and GitHub Actions.

[![Architecture AWS](archi.svg)](archi.svg)

## 📖 What This Is

A **light example version** showcasing best practices for:
- Hosting static websites on AWS S3 with CloudFront CDN
- Managing infrastructure as code with Terraform
- Automating deployments with GitHub Actions
- Building with Eleventy 3 + Tailwind CSS 4

The [Terraform backend](https://developer.hashicorp.com/terraform/language/backend/s3) setup is done locally once. Everything else is automated via GitHub Actions.

---

## 🚀 Quick Start

### Prerequisites

- AWS account with `aws configure` set up
- Terraform >= 1.0
- Node.js & npm (only useful to test the website locally on your computer)
- GitHub repository

### 1. IAM Setup (AWS Console)

1. Create IAM user: `website-deployer` (or other)

2. Edit `IAM/website-deployer.json` — replace bucket names with yours:
   ```json
   "Resource": [
       "arn:aws:s3:::my-terraform-state-bucket",      // ← For Terraform state storage (backend)
       "arn:aws:s3:::my-terraform-state-bucket/*",    // ← Same as above
       "arn:aws:s3:::my-website-bucket",              // ← Unique name for website content
       "arn:aws:s3:::my-website-bucket/*"             // ← Same as above
   ]
   ```
   
   - **`my-website-bucket`** — Unique S3 bucket name to host your website files
   - **`my-terraform-state-bucket`** — S3 bucket to store Terraform infrastructure state

3. Attach the edited policy as an Inline Policy to the user

4. Generate Access Keys (download the CSV)

### 2. Backend Setup (Local - One Time)

```bash
cd terraform/backend

# Edit terraform.tfvars
bucket_name = "my-terraform-state-bucket"

terraform init
terraform plan
terraform apply  # Confirm with 'yes'
```

### 3. Configure Backend for Main Terraform

Edit `terraform/main/providers.tf` to match your backend bucket:

```hcl
  backend "s3" {
    bucket = "my-terraform-state-bucket"    # ← Must match terraform/backend/terraform.tfvars, bucket_name
    key    = "terraform/terraform.tfstate"
    region = "eu-west-3"                    # ← Must match terraform/backend/terraform.tfvars, aws_region
  }
}
```

> ⚠️ The `bucket` value must be identical to the one you created in Step 2 (terraform/backend/terraform.tfvars)

### 4. Main Configuration (Local)

```bash
# Edit terraform/main/terraform.tfvars
aws_region    = "eu-west-3"
domain_name   = "mydomain.com"
bucket_name   = "my-website-bucket"
gallery_prefix = "img/gallery/"
```

> ⚠️ `bucket_name` must match what's in `IAM/website-deployer.json`

### 5. GitHub Secrets

Add to GitHub repo Settings → Secrets → Actions:
- `AWS_ACCESS_KEY_ID` — from the CSV
- `AWS_SECRET_ACCESS_KEY` — from the CSV

### 6. Deploy

```bash
git add .
git commit -m "Initial setup"
git push origin main
```

**What happens:**
- `terraform.yml` deploys infrastructure (if `terraform/main/` changed)
- `deploy.yml` builds and deploys website (every push)
- Website is live after ~5 minutes

---

## 📁 Project Structure

```
_src/                                    # Website source (Eleventy + Tailwind)
├── _includes/
│   ├── base.njk                        # Master HTML template
│   ├── header.html                     # Navigation component
│   └── footer.html                     # Footer component
├── js/
│   └── date.js                         # Client-side scripts
├── img/                                # Static images
│   └── gallery/                        # Gallery images (managed by Lambda)
├── index.html, page2.html, page3.html  # Content pages
└── styles.css                          # Global Tailwind directives

terraform/
├── backend/                            # Terraform state management (run locally)
│   ├── main.tf                         # S3 bucket + DynamoDB table for state
│   ├── variables.tf                    # Backend variables
│   ├── outputs.tf                      # Backend outputs
│   └── terraform.tfvars                # Configuration (create this)
│
├── main/                               # AWS infrastructure (auto-deployed via GitHub Actions)
│   ├── variables.tf                    # Input variables
│   ├── providers.tf                    # AWS provider config
│   ├── website.tf                      # S3, CloudFront, Route53, ACM
│   ├── gallery.tf                      # Lambda, S3 events, IAM roles
│   ├── outputs.tf                      # Outputs for GitHub Actions
│   ├── terraform.tfvars                # Configuration (create this)
│   └── lambda_function.zip             # Compiled Lambda code (for gallery)
│
└── data/                               # Data sources (retrieve outputs)
    └── main.tf                         # Queries Terraform state

IAM/
└── website-deployer.json               # IAM policy for GitHub Actions deployment user

.github/workflows/
├── terraform.yml                       # Workflow: Deploy AWS infrastructure
└── deploy.yml                          # Workflow: Build & deploy website

.gitignore                              # Prevents committing sensitive files
eleventy.config.js                      # Eleventy settings
package.json                            # Node.js dependencies (Eleventy, Tailwind)
tailwind.config.js                      # Tailwind settings
README.md                               # This file
```

---

## 📊 AWS Infrastructure Overview

### Core Services

| Service | Purpose | Key Resource |
|---------|---------|--------------|
| **S3** | Stores website files | `aws_s3_bucket.website` |
| **CloudFront** | Global CDN for fast delivery | `aws_cloudfront_distribution.website` |
| **Route53** | DNS management for domain | `aws_route53_zone.main` |
| **ACM** | Free SSL/TLS certificate for HTTPS | `aws_acm_certificate.main` |
| **Lambda** | Generates gallery manifest automatically | `aws_lambda_function.gallery_generator` |
| **DynamoDB** | Locks Terraform state (prevents conflicts) | `aws_dynamodb_table.terraform_locks` |
| **IAM** | User & permissions for GitHub Actions | `github-actions-bot` user |

### Gallery System

The gallery works as follows:

1. **Upload images** to `s3://bucket-name/img/gallery/`
2. **Lambda triggered** automatically by S3 event
3. **Lambda generates** `manifest.json` containing:
4. **Your JavaScript** fetches `manifest.json` and displays images in a gallery modal

> ⚠️ **Note:** The gallery JavaScript is **not provided** in this template. You must create your own JavaScript to:
> - Fetch `/img/gallery/manifest.json`
> - Parse the image list
> - Display images in your desired gallery interface (lightbox, carousel, modal, etc.)

### Data Flow

```
Developer pushes changes to GitHub
          ↓
GitHub Actions triggers workflows
          ↓
   terraform.yml          deploy.yml
   (Infrastructure)       (Website)
          ↓                    ↓
   Creates/updates        Builds website
   AWS resources          (Eleventy + Tailwind)
          ↓                    ↓
   S3, CloudFront      Uploads to S3
   Lambda, Route53     Invalidates CDN cache
          ↓                    ↓
          └────────────────────┘
                    ↓
            Website is live
            globally via CDN
```

### Security & Best Practices

- **S3 bucket is private** — Only CloudFront can access via Origin Access Control (OAC)
- **Terraform state isolated** — Stored in separate S3 bucket + DynamoDB locking
- **HTTPS enforced** — CloudFront + ACM certificate ensures encrypted traffic
- **IAM least privilege** — `website-deployer` has only required permissions
- **Cache strategy** — CloudFront caches files + deployment invalidates on changes

---

## 📝 How to Deploy Changes

### Update Website Content

```bash
# Edit website files in _src/
git add .
git commit -m "Update homepage"
git push origin main
```

**Result:** `deploy.yml` runs → website updated in ~1-2 minutes ✅

### Update Infrastructure

```bash
# Edit terraform/main/terraform.tfvars or .tf files
git add terraform/main/
git commit -m "Change AWS region"
git push origin main
```

**Result:** `terraform.yml` runs → infrastructure updated → website deployed ✅

---

## 🔄 How It Works

### Local Setup (One-time)
1. IAM user created
2. Terraform backend deployed (stores state in S3 + DynamoDB lock)
3. Main configuration files created

### Automatic Deployments
1. Push to GitHub main branch
2. GitHub Actions checks what changed
3. **If `terraform/main/` changed:** Run `terraform.yml` (infrastructure)
4. **Always:** Run `deploy.yml` (website)
5. Website is live globally

## 📊 Infrastructure

- **S3** — Website hosting (private, accessed via CloudFront)
- **CloudFront** — CDN for global delivery with caching
- **Route53** — DNS management for your domain
- **Lambda** — Gallery manifest generation (optional)
- **ACM** — Free SSL/TLS certificate for HTTPS
- **DynamoDB** — State locking for Terraform

---

## 🔐 Configuration Checklist

- [ ] IAM user `website-deployer` created
- [ ] `IAM/website-deployer.json` updated with your bucket names
- [ ] Policy attached to IAM user
- [ ] Access Keys generated and saved
- [ ] `terraform/backend/terraform.tfvars` edited + `terraform apply` run
- [ ] `terraform/main/providers.tf` edited
- [ ] `terraform/main/terraform.tfvars` edited
- [ ] GitHub Secrets added (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- [ ] First push to main triggers workflows
- [ ] Check GitHub Actions tab to monitor

---

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Access Denied" in GitHub Actions | Verify bucket names in IAM policy match terraform.tfvars |
| Bucket already exists | Change `bucket_name` in `terraform/main/terraform.tfvars` |
| Website not updating | Clear browser cache or check CloudFront invalidation in logs |
| Terraform state conflict | Ensure DynamoDB lock table exists in backend |

---

## 🔐 Security Best Practices

✅ **What we do right:**
- S3 bucket is private (only CloudFront can access)
- Terraform state in separate S3 bucket with DynamoDB locking
- IAM policy uses least privilege principle
- AWS credentials stored in GitHub Secrets (encrypted)
- HTTPS enforced via CloudFront + ACM

❌ **Never:**
- Commit AWS credentials to git
- Share Access Keys
- Make backend S3 bucket public
- Delete the DynamoDB lock table

---

## 💻 Local Development

```bash
# Install dependencies (Node.js must previously be installed)
npm install

# Start dev server (Eleventy + Tailwind watch)
npm start

# Build for production
npm run build
```

Output goes to `_site/` folder.

---

## 💰 Estimated Monthly Costs

- S3: ~$1
- CloudFront: Variable (based on traffic)
- Lambda: ~$0.20 (free tier covers most)
- Route53: $0.50
- ACM: Free
- DynamoDB: <$1

**Total:** $2-5/month for low traffic