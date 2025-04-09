bundle exec jekyll build
cd _site
git add -A
git commit -m "$(date)"
git push
cd ..
