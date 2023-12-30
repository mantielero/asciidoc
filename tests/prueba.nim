import synthesis

type Block = enum
  ## States of your automaton.
  ## The terminal state does not need to be defined
  BlockDocument
  BlockSection

type Event = enum
  ## Named events. They will be associated with a boolean expression.
  BlockSectionStart
  BlockSectionEnd


# Common configuration
# -------------------------------------------

# Create a "waterMachine" entry.
declareAutomaton(asciidoc, Block, Event)

# Optionally setup the "prologue". Extra state goes there, the variables are visible by all.
setPrologue(asciidoc):
  echo "Let's parse AsciiDoc\n"
  var txtLines: seq[string]

# Mandatory initial state. This must be one of the valid state of the state enum ("Phase" in our case)
setInitialState(asciidoc, BlockDocument)

# Terminal state is mandatory. It's a pseudo state and does not have to be part of the state enum.
setTerminalState(asciidoc, Exit)

# Optionally setup the "epilogue". Cleaning up what was setup in the prologue goes there.
setEpilogue(asciidoc):
  echo "All parsed"

# Events
# -------------------------------------------

implEvent(waterMachine, OutOfWater):
  tempFeed.len == 0

implEvent(waterMachine, Between0and100):
  0 < temp and temp < 100

implEvent(waterMachine, Below0):
  temp < 0

implEvent(waterMachine, Over100):
  100 < temp

# `onEntry` and `onExit` hooks
# -------------------------------------------
#
# Those are applied on each state entry, before conditions are checked
# and on each state exits. The only exceptions are "interrupt" behaviours.

onEntry(waterMachine, [Solid, Liquid, Gas]):
  let oldTemp = temp
  temp = tempFeed.pop()
  echo "Temperature: ", temp

# `behaviors`
# -------------------------------------------
#
# Interrupts are special triggers which ignores onEntry/onExit
#
# They allow the normal operations to make assumptions like
# a container not being empty or a value being available.
#
# They are also suitable to handle termination signals.

behavior(waterMachine):
  ini: [Solid, Liquid, Gas, Plasma]
  fin: Exit
  interrupt: OutOfWater
  transition:
    echo "Running out of steam ..."

# Conditional state change, depending on temperature.
behavior(waterMachine):
  ini: Solid
  fin: Liquid
  event: Between0and100
  transition:
    assert 0 <= temp and temp <= 100
    echo "Ice is melting into Water.\n"

behavior(waterMachine):
  ini: Liquid
  fin: Gas
  event: Over100
  transition:
    assert temp >= 100
    echo "Water is vaporizing into Vapor.\n"

#...

# Steady state, if no phase change was triggered, we stay in our current phase
behavior(waterMachine):
  steady: [Solid, Liquid, Gas]
  transition:
    # Note how we use the oldTemp that was declared in `onEntry`
    echo "Changing temperature from ", oldTemp, " to ", temp, " didn't change phase. How exciting!\n"

# `Synthesize`
# -------------------------------------------
# Synthesizing the automaton will transform the previous specification
# into a concrete procedure with a name, type and inputs of your choosing.
#
# Assertions are inserted to ensure the automaton
# stops if a state+event combination was not handled.
#
# You can pass "-d:debugSynthesis" to view the state machine generated
# at compile-time.
#
# The generated code can also be copy-pasted for debugging or for further refining.
synthesize(waterMachine):
  proc observeWater(tempFeed: var seq[float])

# Running the machine
# -------------------------------------------
import random, sequtils

echo "\n"
# Create 20 random temperature observations.
var obs = newSeqWith(20, rand(-50.0..150.0))
echo obs
echo "\n"
observeWater(obs)

# Output
# -------------------------------------------
# @[-3.460770047808822, 114.5693402308219, 16.66758940395412, 147.8992369379481, 38.74529893378966, -34.83679531473696, 68.73127270016445, -10.89306136942781, 55.17781700115015, 114.8825749296374, 86.88038583504948, 47.98729291960338, -40.94605405014646, 141.4807806383724, -19.78255259056119, -1.654260475969281, 37.0554825533913, 80.74588296425821, -7.707680239048244, 37.63170603752019]

# Welcome to the Steamy machine version 2000!
#
# Temperature: 37.63170603752019
# Changing temperature from 0.0 to 37.63170603752019 didn't change phase. How exciting!
#
# Temperature: -7.707680239048244
# Water is freezing into Ice.
#
# Temperature: 80.74588296425821
# Ice is melting into Water.
#
# Temperature: 37.0554825533913
# Changing temperature from 80.74588296425821 to 37.0554825533913 didn't change phase. How exciting!
#
# Temperature: -1.654260475969281
# Water is freezing into Ice.
#
# Temperature: -19.78255259056119
# Changing temperature from -1.654260475969281 to -19.78255259056119 didn't change phase. How exciting!
#
# Temperature: 141.4807806383724
# Ice is sublimating into Vapor.
# ...