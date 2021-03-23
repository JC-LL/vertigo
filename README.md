# vertigo
VHDL parser written in Ruby.

Vertigo is today able to parse a large subset of VHDL'93.

Vertigo aims at providing a managable tool for VHDL inspection and transformations.

A "tests" directory contains various VHDL files that can be parsed.
To run the test in this directory, run :
ruby run_test_parser.rb


![Alt text](running test)
<img src="./doc/run_test.svg">

## How to install ?
      gem install vertigo_vhdl

   Please note the name ! Not vertigo, but **vertigo_vhdl**

## How to build and install from github ?
    gem build vertigo.gemspec
    gem install vertigo_vhdl-x.y.z.gem --local


## Features :
  - VHDL parsing and pretty printer
  - Testbench generator
  - more to come !

## Contact the author !
  jean-christophe.le_lann@ensta-bretagne.fr
