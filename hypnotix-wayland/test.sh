# GUI app: check the version got substituted and the module parses
grep -qF "$pkgver" /usr/lib/hypnotix/hypnotix.py
python -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' /usr/lib/hypnotix/hypnotix.py
