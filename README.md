Crisp
=====

[![Build Status](https://travis-ci.org/rhysd/Crisp.svg?branch=master)](https://travis-ci.org/rhysd/Crisp)

Crisp is one of Lisp dialect which is based on [mal](https://github.com/kanaka/mal) and implemented with [Crystal](https://github.com/manastech/crystal).
This project is a toy box for my dynamic language ideas.

![screenshot](https://raw.githubusercontent.com/rhysd/screenshots/master/Crisp/crisp.gif)

## So Many Tasks

- __Refactorings__
  - [ ] Make `is_a?` guards more elegant
  - [ ] Import test cases from Mal
  - [x] Add CI
  - [x] More OOP (`evaluator`, remove global variable, move states into object)
  - [x] Use standard `readline` implementation
  - [ ] Better lexer and parser
  - [ ] Add examples
  - [ ] More convenient REPL (e.g. completion)
- __New language features using Crystal's semantics__
  - [ ] Algebraic data type
  - ...

## Installation

1. Install `crystal` command ([instruction](http://crystal-lang.org/docs/installation/index.html))
2. `$ crystal run /path/to/Crisp/crisp.cr`

## Examples

Please see [mal test cases](https://github.com/rhysd/Crisp/tree/master/spec/crisp/mal_specs/tests) for now.

## Development Environment

- OS X
- Crystal 0.7.1 ~ 0.7.3 or 0.7.7 ~ 0.9.0

## License

Distributed under [the MIT License](http://opensource.org/licenses/MIT).

```
Copyright (c) 2015 rhysd
```

