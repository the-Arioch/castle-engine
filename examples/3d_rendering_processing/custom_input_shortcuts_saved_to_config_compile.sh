#!/bin/bash
set -eu

# Call this script from this directory,
# or from base castle_game_engine directory.
# Or just do "make examples" in base castle_game_engine directory.

# Allow calling this script from it's dir.
if [ -f custom_input_shortcuts_saved_to_config.lpr ]; then cd ../../; fi

# Find the build tool, use it to compile
if which tools/build-tool/castle-engine > /dev/null; then
  CASTLE_ENGINE="`which tools/build-tool/castle-engine`"
else
  CASTLE_ENGINE=castle-engine
fi

"${CASTLE_ENGINE}" simple-compile examples/3d_rendering_processing/custom_input_shortcuts_saved_to_config.lpr