#!/bin/bash
function init_repo() {
    git init -q
    git config user.name "Test User"
    git config user.email "test@noncense.io"

    git status --short
}
#create a testing enviroment setup script
# running this script will create a few directories with a specific style of folder structure
# and file names in order to run tests on the accuracy of our product!
fake_file_system_name="fake_file_system"
fake_dir_abs_path="$(pwd)/tests/$fake_file_system_name"
set -e # exit if any errorrs occour

echo "Lets make some directories..."

# check were in correct directory
echo "About to create fake file system in $fake_dir_abs_path"
echo "This will abruptly overwrite anything in that dir..."
read -r -p "Continue (Y/n)" choice

if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
    echo "Exiting..."
    reurn 1
fi

echo "Working... "

# Delete any current fake repos to ensure clenliness
if [ -d "$fake_dir_abs_path" ]; then
    echo "removing current fake file system"
    rm -rf $fake_dir_abs_path
fi

mkdir -p $fake_dir_abs_path
cd $fake_dir_abs_path

echo "Now in $(pwd) ready to start creating some repo's"

# create a directory structure 4 directories so far..

#project alpha, clean and tidy
mkdir -p project_alpha/src/utils
mkdir -p project_alpha/repo_clean

#project beta, not staged
mkdir -p project_beta/docs
mkdir -p project_beta/repo_staged

#project gamma half way through a rebase
mkdir -p project_gamma/config/misc
mkdir -p project_gamma/repo_rebase

echo "directories created"

# lets add some bad actors to hopefully avoid : bad files simple have _BAD_ in the file name
touch BAD_marker_file.txt

touch project_alpha/BAD_marker_file.txt
touch project_alpha/src/utils/BAD_marker_file.txt

touch project_beta/BAD_marker_file.txt
touch project_beta/docs/BAD_marker_file.txt

touch project_gamma/BAD_marker_file.txt
touch project_gamma/config/BAD_marker_file.txt
touch project_gamma/config/misc/BAD_marker_file.txt

echo "Bad actors added to file system"
tree

##### Somthing to note, all git commit messages will start with ! sorry its my git setup to maintina concistatn messages, just ignore it!
##### i could add a function to remove my global git flows, but also meh. lets get the ball rolling

# STEP 1 : lets make a clean perfect repo with merged feature branches
repo_path="$fake_dir_abs_path/project_alpha/repo_clean"
echo "Moving to $repo_path"
cd $repo_path

init_repo

#create a mentally complicated .js project...
touch README.md
echo "# Clean repo" > README.md
touch app.js
echo "console.log('hello_world');" > app.js

#add initial commit
git add .
git commit -q -m "! Initial Commit"

echo "console.log('App v2.0');" >> app.js
git add app.js
git commit -q -m "! THIS APP IS MENTAL"

# Add feature/user-auth branch and merge it back (merged branch)
git checkout -q -b feature/user-auth
echo "// user auth module" > auth.js
git add auth.js
git commit -q -m "! Add user auth module"
git checkout -q main
git merge -q --no-ff feature/user-auth -m "! Merge feature/user-auth"

# Add feature/dark-mode branch and merge it back (another merged branch)
git checkout -q -b feature/dark-mode
echo "body { background: #1a1a1a; }" > theme.css
git add theme.css
git commit -q -m "! Add dark mode theme"
git checkout -q main
git merge -q --no-ff feature/dark-mode -m "! Merge feature/dark-mode"

git status --short
echo "repo_clean setup complete: 2 merged branches"

# STEP 2 : lets make a repo with some uncommited files and mixed branch health
repo_path="$fake_dir_abs_path/project_beta/repo_staged"
echo "Moving to $repo_path"
cd $repo_path

init_repo

touch README.md
echo "#staged repo" > README.md
touch main.py
echo "print('hello_world')" > main.py

#add a single commit
git add .
git commit -q  -m "! first commit of the worst python app"

echo "# ITS A TRAP... but who reads these anyway" > README.md
git add README.md
echo "repo with staging problem setup"

# Add an active WIP branch (not merged, recent commits)
git checkout -q -b wip/big-refactor
echo "# Refactor in progress" > REFACTOR.md
git add REFACTOR.md
git commit -q -m "! Start big refactor"
git checkout -q main

# Add a stale branch (last commit >90 days ago — use a backdated commit)
git checkout -q -b hotfix/old-login-crash
STALE_DATE="2025-11-01T12:00:00"
GIT_AUTHOR_DATE="$STALE_DATE" GIT_COMMITTER_DATE="$STALE_DATE" \
    git commit -q --allow-empty -m "! Attempted login fix (abandoned)"
git checkout -q main

echo "repo_staged setup complete: 1 active WIP branch, 1 stale branch"

# STEP 3 : lets also have ourself a repo thats half way through a rebase!
#
repo_path="$fake_dir_abs_path/project_gamma/repo_rebase"
echo "Moving to $repo_path"
cd $repo_path

init_repo

echo "// Main feature" > feature.txt
echo "#include <stdio.h>
int main() {
    printf(\"Hello\");
    return 0;
}" > main.c
git add .
git commit -q -m "! Initial C program"

# Create feature branch and commit
git checkout -q -b feature-branch
echo "// Feature addition" >> feature.txt
echo "#include <stdio.h>
int main() {
    printf(\"Hello World\");
    return 0;
}" > main.c
git add .
git commit -q -m "! Add feature"

# Switch back to main and create conflicting commit
git checkout -q main
echo "// Main update" >> feature.txt
echo "#include <stdio.h>
int main() {
    printf(\"Hello Main\");
    return 0;
}" > main.c
git add .
git commit -q -m "! Main update"

# Start rebase to create conflict state
git rebase feature-branch || true  # Allow it to fail

echo "✅ Rebase repo setup complete (in conflict state)"


# STEP 4 and beyond can come later!
#
# COMPLETION
#
# Output a summary and maybe a tree diagram to show what we have made!
