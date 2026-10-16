# gralha-bendquest

The proof-carrying rules kernel of BendQuest, a cooperative RPG: items,
equipment, stats, quests, health, maximum-health growth, the XP loop and
death/respawn, each rule stated as a law and proved. No unsafe or foreign
code. It is game-specific; it ships as an example of a verified game core
that a server (BendQuest's) runs as-is.

```python
import gralha-bendquest@0.1.0.0/game.bend as Game        # items, gear, stats, quests
import gralha-bendquest@0.1.0.0/numeric.bend as Numeric  # word/natural codecs
import gralha-bendquest@0.1.0.0/health.bend as Health    # health rules
import gralha-bendquest@0.1.0.0/growth.bend as Growth    # maximum-health growth
import gralha-bendquest@0.1.0.0/rewards.bend as Rewards  # the XP loop
import gralha-bendquest@0.1.0.0/vitals.bend as Vitals    # death and respawn
```

`kernel.bend` is the published entry: it only imports the six modules, so
`bend kernel.bend` checks the whole kernel and prints ALL PROOFS CHECK.
Names keep the game's `Bq.` prefix (`Game.Bq.Hero`), as BendQuest uses them.

`tests/health_check.bend` runs the health rules on sample values.

`bend kernel.bend --verdict` currently fails in `Bq.ops_respect_requirements`
with a mismatch between bend2's checker and the BendTT kernel, which bend
reports as its own bug, not the proof's.
