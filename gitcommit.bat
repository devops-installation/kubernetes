git add .
set /p commitMsg="Enter commit message: "

git commit -m "%commitMsg%"
git push origin main
