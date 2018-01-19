[![Gem Version](https://badge.fury.io/rb/taipo.svg)](https://badge.fury.io/rb/taipo) [![Inline docs](http://inch-ci.org/github/pyrmont/taipo.svg?branch=master)](http://inch-ci.org/github/pyrmont/taipo)
[![Build Status](https://travis-ci.org/pyrmont/taipo.svg?branch=master)](https://travis-ci.org/pyrmont/taipo)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7b5dcb371ee422b27f0c/test_coverage)](https://codeclimate.com/github/pyrmont/taipo/test_coverage)

# Taipo

Taipo is a simple library for checking the types of variables.

[Full documentation][rd] is available at RubyDoc.

[rd]: http://www.rubydoc.info/gems/taipo/index

## Overview

When we deal with variables in our code, we have certain expectations about what those variables can and can’t do.

Taipo provides a simple way to make those expectations explicit. If an expectation isn’t met, Taipo can either raise an exception or return the problematic variables for us to handle.

## Installation

Run `gem install taipo` or add `gem 'taipo'` to your `Gemfile`.

## Usage

Taipo provides two methods in the `Taipo::Check` module that we can mix into our classes: `#check` and `#review`.

### #check

```ruby
require ‘taipo’

class Foo
  include Taipo::Check

  def double(val)
    check types, val: ‘Integer’
    val * 2
  end
end

foo = Foo.new
foo.double 5      #=> 10
foo.double ‘Oops’ #=> Taipo::TypeError
```

The method `#check` will raise an exception as soon as one of its arguments doesn’t match its type definition.

[More information about `#check`][rdc] is available in the documentation.

[rdc]: http://www.rubydoc.info/gems/taipo/Taipo/Check#check-instance_method

### #review

```ruby
require ‘taipo’

class Foo
  include Taipo::Check

  def add(x, y)
    errors = review types, x: ‘Integer’, y: ‘Integer’
    if errors.empty?
      x + y
    else
      ‘Oops’
    end
  end
end

foo = Foo.new
foo.add 4, 5      #=> 9
foo.add 2, ‘OK’   #=> ‘Oops’
```

The method `#review` will put the invalid arguments into an array and return that to the user. If there are no errors, the array is empty.

[More information about `#review`][rdr] is available in the documentation.

[rdr]: http://www.rubydoc.info/gems/taipo/Taipo/Check#review-instance_method

## Syntax

Type definitions are written as Strings. Type definitions can consist of (1) names, (2) collections, (3) constraints and (4) sums.

The information in this README is only meant as an introduction. [More information about the type definition syntax][rdv] is available in the documentation.

[rdv]: http://www.rubydoc.info/gems/taipo/Taipo/Parser/Validater

### Names

The simplest case is to write the name of a class. For example, `’String’`. Inherited class names can also be used.

```ruby
check types, a: 'String', b: 'Numeric'
```

#### Duck Types

It's possible to specify a duck type by writing the instance method (or methods) to which the object should respond.

```ruby
check types, a: '#to_s', b: '(#foo, #bar)'
```

### Collections

Taipo can also check whether a variable has a collection of elements of the specified child type. A child type can consist of the same components as any other type (ie. a name, collection, constraint, sum).

```ruby
check types, a: 'Array<Integer>', b: 'Hash<Symbol, String>', c: 'Array<Array<Float>>'
```

### Constraints

Constraints can be added to a type definition. Constraints consist of a list of one or more identifier-value pairs. Instance method names can also be in included.

```ruby
check types, a: 'Array(len: 5)', b: 'Integer(min: 0, max: 10)', c: 'String(format: /a{3}/)', d: 'String(val: "Hello world!")', e: 'Foo(#bar)'
```

### Sums

Type definitions can be combined to form sum types. Sum types consist of two or more type definitions.

```ruby
check types, a: 'String|Float', b: 'Boolean|Array<String|Hash<Symbol,Point>|Array<String>>', c: 'Integer(max: 100)|Float(max: 100)'
```

## Requirements

Taipo has been tested with Ruby version 2.4.2.

## Bugs

Found a bug? I’d love to know about it. The best way is to report them in the [Issues section][ghi] on GitHub.

[ghi]: https://github.com/pyrmont/taipo/issues

## Contributing

If you’re interested in contributing to Taipo, feel free to fork and submit a pull request.

## Colophon

Taipo began as, and remains primarily, an exercise to improve my programming skills. If Taipo has piqued your interest in adding type checks to Ruby, consider some of the other options, such as [Contracts][cnt], [Rtype][rty], [Rubype][rub] or [Sig][sig].

[cnt]: https://github.com/egonSchiele/contracts.ruby
[rty]: https://github.com/sputnikgugja/rtype
[rub]: https://github.com/gogotanaka/Rubype
[sig]: https://github.com/janlelis/sig

## Licence

Taipo is released into the public domain. See [LICENSE.md][lc] for more details.

[lc]: https://github.com/pyrmont/taipo/blob/master/LICENSE.md