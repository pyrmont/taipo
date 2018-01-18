# Taipo

Taipo is a simple library for checking the types of variables.

## Overview

When we deal with variables in our code, we have certain expectations about what those variables can and can’t do.

Taipo provides a simple way to make those expectations explicit. If an expectation isn’t met, Taipo can either raise an exception or return the problematic variables for us to handle.

## Installation

Run `gem install taipo` or add `gem 'taipo'` to your `Gemfile`.

## Usage

Taipo provides two methods that we can mix into our classes: `#check` and `#review`.

### #check

```
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

### #review

```
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

## Syntax

Type definitions are passed as Strings with a straightforward syntax.

The simplest case is to write the name of a class. For example, `’String’`. Taipo supports more complex type definitions should you need them. Here are some more examples.

```
'String'
'Array<String>'
'Hash<Symbol,String>'
'String|Float'
'Boolean|Array<String|Hash<Symbol,Point>|Array<String>>'
'Array(len: 5)'
'String(format: /woo/)'
'String(#size)'
'String(#size, #to_s)'
'Integer(min: 1, max: 10)'
'String(val: "This is a test.")'
'#to_s'
'#to_s|#to_i'
```

## Requirements

Taipo has been tested with Ruby version 2.4.2.

## Bugs

Found a bug? I’d love to know about it. The best way is to report them on GitHub. 

## Contributions

If you’re interested in contributing to Taipo, feel free to fork and submit a pull request.

## Colophon

Taipo began as an exercise to improve my programming skills. If you want something more comprehensive, consider some of the other options, such as [Contracts][1], [Rtype][2], [Rubype][3] or [Sig][4].

[1]: https://github.com/egonSchiele/contracts.ruby
[2]: https://github.com/sputnikgugja/rtype
[3]: https://github.com/gogotanaka/Rubype
[4]: https://github.com/janlelis/sig

# Licence

Taipo is released into the public domain. See LICENSE.md for more details.
