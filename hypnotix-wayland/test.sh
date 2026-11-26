# GUI app: check the version got substituted and the module compiles
grep -qF "$pkgver" /usr/lib/hypnotix/hypnotix.py
python -m py_compile /usr/lib/hypnotix/hypnotix.py
