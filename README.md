Crisp
=====
[![CI](https://github.com/rhysd/Crisp/workflows/CI/badge.svg?branch=master)](https://github.com/rhysd/Crisp/actions?query=workflow%3ACI)

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

1. [Install `crystal` command](https://crystal-lang.org/install/)
2. Run `shards install` for installing dependencies
3. Run `crystal build /path/to/Crisp/crisp.cr` to build an executable (add `--release` for the release build)
4. Put the built `crisp` executable in a `$PATH` directory

## Examples

Please see [mal test cases](https://github.com/rhysd/Crisp/tree/master/spec/crisp/mal_specs/tests) for now.

## Development Environment

- macOS or Linux
- Crystal 0.33.0 or later

## License

Distributed under [the MIT License](http://opensource.org/licenses/MIT).

```
Copyright (c) 2015 rhysd
```
