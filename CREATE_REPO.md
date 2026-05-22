# Creating the GitHub repository

Repository name: **`wrf-hydro-coupled-lengau`**

## Option A — GitHub CLI (recommended)

```bash
cd wrf-lengau
gh auth login
gh repo create msovara/wrf-hydro-coupled-lengau --public --source=. --remote=origin --push
```

## Option B — Manual

1. Create repo at https://github.com/new  
   - Name: `wrf-hydro-coupled-lengau`  
   - Description: *Coupled WRF 4.7.1 + WRF-Hydro build for CHPC Lengau*  
   - Do **not** add README or license (already in this folder)

2. Push:

```bash
cd wrf-lengau
git init
git add README.md LICENSE docs/ examples/ *.sh *.py .gitignore
git commit -m "Add coupled WRF-Hydro GCC build scripts and user guide for Lengau"
git branch -M main
git remote add origin https://github.com/msovara/wrf-hydro-coupled-lengau.git
git push -u origin main
```

Use a GitHub Personal Access Token if prompted for a password.
