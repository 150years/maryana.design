# Install

```sh
git clone git@github.com:150years/maryana.design
cd maryana.design
git clone git@github.com:150years/maryana.design _site
cd _site
git checkout gh-pages
cd ..
```
# Get updates from Repo

```sh
git fetch --all -p
git checkout main
git pull
git reset --hard origin/main

bundle exec jekyll serve
```

# Develop

## Аdd new photo
1. Download photo from photograther.
2. Create folder with name [abbriviatoin from project name]_[houseNo]. For example Botanica Forestique FQ17 → BF_FQ17.
3. Create 3 folder on local computer
   - 1 full - original photos from Photograther (If have Full and Web can use Web)
   - 2 small - resized 1200px by long side, resolution 240x240, quality 90%, name [abbriviatoin from project name]_[houseNo]-[running number]. For example Botanica Forestique FQ17 → BF_FQ17-01, BF_FQ17-02...
   - 3 selected - 10-15 photos for posting
4. Selct 1 photo from selcted or small for preview
  - Copy to selected
  - Crop with ratio 4x3
  - Save in selected folder with name 00.jpg or 00.jpeg, dimention 848x636px, resolution 240x240, quality 90%.
5. Open new Issue at repo and create branch from Issue. For example BF_FQ17.
6. Get updates from Repo to local machine (see above) and move to new branch.
7. Create new folder with next running number in assets/images/projects → Copy selected photos to new folder
8. Run script ```./add_project.sh```
9. Check on local machine if required restart server ```bundle exec jekyll serve```
10. Add/COmmit/Push changes to new branch
11. Compare and create PR && Merge PR in Github

# Build

```sh
./build.sh
```
