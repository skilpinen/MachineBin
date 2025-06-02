#!/usr/bin/env bash

# ------------------------------------------------------------
# rstu_conda.sh
#
# Usage: rstu_conda.sh <conda_env_name>
#
#   1) Auto-detects your “conda base” via `conda info --base`.
#   2) Sources the proper activation hook.
#   3) Activates the requested env and finds the R binary with `which R`.
#   4) Exports RSTUDIO_WHICH_R.
#   5) Attempts to launch RStudio in two ways:
#       a) “rstudio” on your PATH (if available).
#       b) Directly calling the .app/Contents/MacOS/RStudio executable.
#   6) Leaves the env active long enough for RStudio to inherit it, then deactivates.
# ------------------------------------------------------------

set -e

# 1) Ensure the user passed “<env_name>”
if [ -z "$1" ]; then
  echo "Usage: rstu_conda.sh <conda_env_name>"
  exit 1
fi
ENV_NAME="$1"

# 2) Verify that “conda” is on $PATH
if ! command -v conda &>/dev/null; then
  echo "Error: ‘conda’ not found in \$PATH. Install Conda or add it to \$PATH."
  exit 1
fi

# 3) Ask Conda for its base directory
CONDA_BASE="$(conda info --base 2>/dev/null)"
if [ -z "$CONDA_BASE" ]; then
  echo "Error: Could not determine Conda base (conda info --base failed)."
  exit 1
fi

# 4) Source the activation hook
if [ -f "${CONDA_BASE}/etc/profile.d/conda.sh" ]; then
  source "${CONDA_BASE}/etc/profile.d/conda.sh"
elif [ -f "${CONDA_BASE}/bin/activate" ]; then
  source "${CONDA_BASE}/bin/activate"
else
  echo "Error: No activation script found under ${CONDA_BASE}."
  exit 1
fi

# 5) Activate the requested environment
if ! conda activate "$ENV_NAME" &>/dev/null; then
  echo "Error: Failed to activate Conda environment '$ENV_NAME'."
  exit 1
fi

# 6) Now that the env is active, find “R”
R_BIN="$(which R 2>/dev/null || true)"
if [ -z "$R_BIN" ] || [ ! -x "$R_BIN" ]; then
  echo "Error: R binary not found in environment '$ENV_NAME'."
  echo "       (Checked: which R → '$R_BIN')"
  conda deactivate
  exit 1
fi

# 7) Export RSTUDIO_WHICH_R
export RSTUDIO_WHICH_R="$R_BIN"

echo "-------------------------------"
echo "Using Conda base:  $CONDA_BASE"
echo "Activated env:      $ENV_NAME"
echo "Found R at:         $R_BIN"
echo "Setting RSTUDIO_WHICH_R to: $RSTUDIO_WHICH_R"
echo "-------------------------------"

# 8) Try launching RStudio in two possible ways:

LAUNCHED=false

# (a) If “rstudio” is on PATH (e.g. a conda-installed or CLI link), use that:
if command -v rstudio &>/dev/null; then
  echo "=> Launching via ‘rstudio’ command on PATH..."
  # Use “env … rstudio” so we’re 100% sure the variable is in its environment.
  env RSTUDIO_WHICH_R="$RSTUDIO_WHICH_R" rstudio &
  LAUNCHED=true
else
  # (b) Otherwise, try the “.app/Contents/MacOS/RStudio” executable directly:
  #     Common locations on macOS:
  SYS_RSTUDIO="/Applications/RStudio.app/Contents/MacOS/RStudio"
  USER_RSTUDIO="$HOME/Applications/RStudio.app/Contents/MacOS/RStudio"

  if [ -x "$SYS_RSTUDIO" ]; then
    echo "=> Launching /Applications/RStudio.app/Contents/MacOS/RStudio..."
    env RSTUDIO_WHICH_R="$RSTUDIO_WHICH_R" "$SYS_RSTUDIO" &
    LAUNCHED=true
  elif [ -x "$USER_RSTUDIO" ]; then
    echo "=> Launching ~/Applications/RStudio.app/Contents/MacOS/RStudio..."
    env RSTUDIO_WHICH_R="$RSTUDIO_WHICH_R" "$USER_RSTUDIO" &
    LAUNCHED=true
  fi
fi

if ! $LAUNCHED; then
  echo "Error: Could not find any RStudio executable to launch."
  echo "       Checked: ‘rstudio’ on PATH, /Applications/RStudio.app, and ~/Applications/RStudio.app"
  conda deactivate
  exit 1
fi

# 9) Give RStudio a moment to start up and pick up RSTUDIO_WHICH_R, then deactivate.
#    (Because we launched with “&”, the “env … rstudio” process already has the var.)
sleep 2
conda deactivate

exit 0
