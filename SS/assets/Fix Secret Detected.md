# Fixing a detected secret

Secret detection is a complicated problem, because of how entropy and these secrets work but if a tool is ran, and that tool looks at git history than a secret caught can't just be erased and committed again, we need to purge all git history containing that secret.

Deleting secret from git history procedure:

Ok we have a secret within a file in github

First thing we delete the secret and make whatever changes we want and commit them

The tool to use is [bfg](https://github.com/rtyley/bfg-repo-cleaner)

With this tool we can delete secrets in 2 ways

- Remove all references of that file within the repository except for the last commit with 

		bfg --delete-files YOUR-FILE-WITH-SENSITIVE-DATA

- Or remove certain text from git history with

		bfg --replace-text passwords.txt

This password file will replace all text found in git history with redacted text, a good example of a file like this [here](https://gist.github.com/w0rd-driven/60779ad557d9fd86331734f01c0f69f0)

The second option would be preferred as it does not purge the file from the repository

This needs to be followed by a 

	git push --all --force

All open branches need to be rebased (not merged) to this git history because a later merge with an older commit history will bring back the secret. 

Resources for this tutorial:
	- [Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
	- [Github tutorial on removing data from git history](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)