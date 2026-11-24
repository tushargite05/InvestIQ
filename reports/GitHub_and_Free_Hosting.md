# InvestIQ — Upload to GitHub + Free Hosting

**Student:** Sarthak Bhagawatkar

---

## Part 1 — Upload to GitHub

### A. Create GitHub repo
1. Go to https://github.com and sign in  
2. Click **New repository**  
3. Name: `InvestIQ` (or `InvestIQ-Portfolio-Analytics`)  
4. Public  
5. Do **not** add README (you already have one)  
6. Create repository  

### B. Upload from your Mac (Terminal)

```bash
cd ~/Desktop/InvestIQ

git init
git add .
git commit -m "Initial InvestIQ portfolio analytics and Shiny dashboard"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/InvestIQ.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

### C. Or upload with GitHub website
1. Create empty repo on GitHub  
2. Click **uploading an existing file**  
3. Drag the whole `InvestIQ` folder contents  
4. Commit  

### D. What to include
Include: `app/`, `scripts/`, `data/`, `output/`, `reports/`, `README.md`, `START_TO_END.md`

Already ignored by `.gitignore`: `.Rhistory`, `.RData`, virtualenvs, etc.

---

## Part 2 — Free hosting for the Shiny website

Best free option for R Shiny (recommended for college):

### Option 1 — shinyapps.io (easiest, free tier)

**Site:** https://www.shinyapps.io/

**Free plan limits (approx):**
- 1–5 apps (plan dependent)
- Limited active hours / month
- Enough for teacher demo + viva

#### Steps

1. Create free account at https://www.shinyapps.io  
2. In R / RStudio on your PC, install deploy tools:

```r
install.packages(c("rsconnect", "packrat"))
# or
install.packages("rsconnect")
```

3. Link account (shinyapps.io → Account → Tokens → Show → copy command), then run in R:

```r
rsconnect::setAccountInfo(
  name   = "YOUR_ACCOUNT_NAME",
  token  = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
```

4. Deploy from project:

```r
setwd("~/Desktop/InvestIQ")   # your path
rsconnect::deployApp(
  appDir = "app",
  appName = "InvestIQ",
  appTitle = "InvestIQ | Sarthak Bhagawatkar",
  appFiles = NULL  # will prompt; include app + needed data
)
```

**Important for InvestIQ:**  
Your app reads data from `../data/processed`. On shinyapps.io the working files must be available to the app.

**Recommended deploy layout fix before hosting:**

Either:
- Deploy from project root and set `appDir` properly, **or**
- Copy required CSVs into `app/data/` and update app paths for cloud (see below)

#### Easiest reliable method for students

1. Copy needed CSVs into `app/data/`:
   - from `data/processed/`
   - from `output/metrics/` and `output/tables/` as needed  
2. Point `app.R` to `file.path("data", ...)` when running on shinyapps  
3. Deploy only the `app/` folder with those CSVs inside  

After deploy, shinyapps gives a public URL like:

`https://YOURNAME.shinyapps.io/InvestIQ/`

Share that URL with your teacher.

---

### Option 2 — Hugging Face Spaces (free)

1. Create account: https://huggingface.co  
2. New Space → SDK: **Docker** (or Shiny if listed)  
3. Add Dockerfile that installs R + packages and runs Shiny  
4. Push code  

More flexible, but harder than shinyapps.io for beginners.

---

### Option 3 — Local demo only (no hosting)

If free hosting is blocked/slow for viva:

```bash
cd ~/Desktop/InvestIQ
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Show live on your laptop. Still keep GitHub for code submission.

---

## Part 3 — What to tell teacher

- **GitHub:** code + reproducible scripts + reports  
- **Live demo:** shinyapps.io URL (or local Run App)  
- **Note:** free hosting may sleep / have monthly hour limits  

Example line:

> Sir, source code is on GitHub, and the interactive dashboard is hosted on shinyapps.io free tier. It can also run locally with one R command.

---

## Part 4 — Quick decision

| Goal | Use |
|------|-----|
| Submit code | GitHub |
| Share clickable website | **shinyapps.io free** |
| Viva on your laptop | Local `shiny::runApp` |
| Advanced free cloud | Hugging Face Spaces |

**Recommended path for you:** GitHub + shinyapps.io.

---

*Sarthak Bhagawatkar — InvestIQ*
