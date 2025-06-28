import sys

from core.utils import set_emacs_var, get_emacs_var

cmd = get_emacs_var ("*my-eaf-command*")
print (f"cmd={cmd}")
ret = os.system (cmd)
print (f"ret={ret}")

set_emacs_var("*my-eaf-pycode-result*", ret)
