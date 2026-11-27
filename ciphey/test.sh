# no --version flag, and the first-run wizard crashes without a tty: just check it runs
ciphey --help | grep -q "Usage: ciphey"
