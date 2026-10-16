# gralha-bendquest: the proof-carrying rules kernel of BendQuest, a
# cooperative RPG. This file only gathers the package's modules; import
# each one directly:
#
#   import gralha-bendquest@0.1.0.0/game.bend as Game        # items, gear, stats, quests
#   import gralha-bendquest@0.1.0.0/numeric.bend as Numeric  # word/natural codecs
#   import gralha-bendquest@0.1.0.0/health.bend as Health    # health rules
#   import gralha-bendquest@0.1.0.0/growth.bend as Growth    # maximum-health growth
#   import gralha-bendquest@0.1.0.0/rewards.bend as Rewards  # the XP loop
#   import gralha-bendquest@0.1.0.0/vitals.bend as Vitals    # death and respawn
#
# Every def is safe and every law is proved: `bend kernel.bend` prints
# ALL PROOFS CHECK.
import Base
import ./game.bend as Game
import ./numeric.bend as Numeric
import ./health.bend as Health
import ./growth.bend as Growth
import ./rewards.bend as Rewards
import ./vitals.bend as Vitals
