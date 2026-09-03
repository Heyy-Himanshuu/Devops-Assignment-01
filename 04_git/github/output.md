# Task 4: Git & GitHub – Cherry-Pick

Goal: make several commits on a feature branch, then move **one** of them onto `main` without
merging the rest — and resolve the conflict that comes with it.

All output below is from the real run in this repository.

---

## 1. Create a feature branch and commit to it

```console
$ git branch
* main

$ git checkout -b cherry
Switched to a new branch 'cherry'

$ echo "Feature change 1" >> 04_git/feature.txt && git add . && git commit -m "Add feature change 1"
[cherry 57d9afe] Add feature change 1
 1 file changed, 1 insertion(+)
 create mode 100644 04_git/feature.txt

$ echo "Feature change 2" >> 04_git/feature.txt && git add . && git commit -m "Add feature change 2"
[cherry 4ac703f] Add feature change 2
 1 file changed, 1 insertion(+)

$ echo "Feature change 3" >> 04_git/feature.txt && git add . && git commit -m "Add feature change 3"
[cherry 1949b1e] Add feature change 3
 1 file changed, 1 insertion(+)

$ echo "Feature change 4" >> 04_git/feature.txt && git add . && git commit -m "Add feature change 4"
[cherry 42b8f11] Add feature change 4
 1 file changed, 1 insertion(+)
```

The fifth commit also **moves** the file into a new folder, so the commit contains a rename as well
as an edit:

```console
$ mkdir -p 04_git/github && git mv 04_git/feature.txt 04_git/github/feature.txt
$ echo "added to new folder" >> 04_git/github/feature.txt && git add . && git commit -m "Add feature change 5"
[cherry 2ec5a24] Add feature change 5
 1 file changed, 1 insertion(+)
 rename 04_git/{ => github}/feature.txt (77%)
```

```console
$ git log --oneline -6
2ec5a24 Add feature change 5
42b8f11 Add feature change 4
1949b1e Add feature change 3
4ac703f Add feature change 2
57d9afe Add feature change 1
864d7a5 Docker networking task done
```

---

## 2. Cherry-pick that one commit onto `main`

```console
$ git checkout main
Switched to branch 'main'

$ git cherry-pick 2ec5a24226121b81b76974cd1ee2706d6b4d99ad
CONFLICT (rename/delete): 04_git/feature.txt renamed to 04_git/github/feature.txt in 2ec5a24 (Add feature change 5), but deleted in HEAD.
CONFLICT (modify/delete): 04_git/github/feature.txt deleted in HEAD and modified in 2ec5a24 (Add feature change 5).  Version 2ec5a24 (Add feature change 5) of 04_git/github/feature.txt left in tree.
error: could not apply 2ec5a24... Add feature change 5
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
```

### Why it conflicts

`git cherry-pick` replays a commit's **diff**, not its content. Commit `2ec5a24` says *"take
`04_git/feature.txt`, move it to `04_git/github/`, and append a line."* On `main` that file has
never existed — commits 1–4 only live on `cherry`. Git cannot apply a rename to a file that is not
there, so it reports a **rename/delete** and **modify/delete** conflict and asks a human to decide.

Helpfully, it leaves the incoming version of the file in the working tree, so resolving is just a
matter of confirming that we want it:

```console
$ git status
You are currently cherry-picking commit 2ec5a24.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	deleted by us:   04_git/github/feature.txt
```

`deleted by us` = deleted on `main` (our side); modified by them (the commit being picked). Staging
the file resolves it in favour of the incoming version.

---

## 3. Resolve and finish

```console
$ git add 04_git/github/feature.txt

$ git -c core.editor=true cherry-pick --continue
[main 95ca179] Add feature change 5
 Date: Thu Sep 3 22:16:39 2026 +0530
 1 file changed, 5 insertions(+)
 create mode 100644 04_git/github/feature.txt
```

`-c core.editor=true` skips the commit-message editor and keeps the original message — without it,
`cherry-pick --continue` opens `$EDITOR` and fails in a non-interactive shell with
*"there was a problem with the editor 'vi'"*.

```console
$ git status
On branch main
nothing to commit, working tree clean

$ cat 04_git/github/feature.txt
Feature change 1
Feature change 2
Feature change 3
Feature change 4
added to new folder
```

All five lines arrive because the cherry-picked commit carried the **file** into a path that did not
exist on `main` — the resolution added it whole rather than as a one-line diff.

---

## 4. The resulting history

```console
$ git log --oneline --graph --all -9
* 95ca179 Add feature change 5
| * 2ec5a24 Add feature change 5
| * 42b8f11 Add feature change 4
| * 1949b1e Add feature change 3
| * 4ac703f Add feature change 2
| * 57d9afe Add feature change 1
|/
* 864d7a5 Docker networking task done
```

The key detail: **`95ca179` and `2ec5a24` are different commits** with the same message and the same
change. A cherry-pick copies a change and creates a *new* commit with a new SHA — it does not move
or share the original. `main` picked up commit 5 alone; commits 1–4 stayed on `cherry`.

---

## Summary

| Command | What it does |
| --- | --- |
| `git checkout -b <branch>` | Create a branch and switch to it |
| `git cherry-pick <sha>` | Replay one commit's diff onto the current branch |
| `git cherry-pick --continue` | Finish after conflicts are staged |
| `git cherry-pick --abort` | Undo everything, back to the pre-pick state |
| `git cherry-pick --skip` | Drop this commit and move on |
| `git cherry-pick -n <sha>` | Apply the change but do not commit yet |
| `git cherry-pick A..B` | Replay a range of commits |

**When to use it:** back-porting a bug fix to a release branch, or pulling one urgent commit out of
a feature branch that is not ready to merge. **When not to:** as a substitute for merging — repeated
cherry-picking leaves duplicate commits with different SHAs on both branches, which makes later
merges harder to reason about.

The `cherry` branch is kept in this repository so the two histories can be compared:

```bash
git log --oneline --graph --all
```
