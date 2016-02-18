export PYTHONUSERBASE=$HOME/.local/python
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Projects
export VIRTUALENVWRAPPER_SCRIPT=$PYTHONUSERBASE/bin/virtualenvwrapper.sh
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PATH=$PYTHONUSERBASE/bin:$PATH
source $PYTHONUSERBASE/bin/virtualenvwrapper_lazy.sh
source $PYTHONUSERBASE/bin/activate.sh
