require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'

# Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
Minitest::Reporters.use!

module TaipoTestHelper
  def self.create_types(type_defs)
    type_defs.reduce([]) do |types,type_def|
      res = type_def.reduce([]) do |memo_t,t|
              ct = (t[:child_type]) ? Taipo::TypeElement::ChildType.new(
                                        create_types(t[:child_type])) :
                                      nil
              csts = t[:constraints]&.split(', ')&.reduce([]) do |memo_c,c|
                       if c.include? ':'
                         pieces = c.split(': ')
                         cst = Taipo::TypeElement::Constraint.new(
                           name: pieces[0],
                           value: pieces[1])
                       else
                         cst = Taipo::TypeElement::Constraint.new(
                           name: nil,
                           value: c[1..-1])
                       end
                       memo_c.push cst
                     end
              memo_t.push Taipo::TypeElement.new(name: t[:class],
                                                     child_type: ct,
                                                     constraints: csts)
            end
      types.push res
    end
  end

  def self.prepare_for_comparison(str)
    str = self.remove_white_space str
    str = self.add_implicit_objects str
  end

  def self.add_implicit_objects(str)
    result = ''
    previous = ''
    paren = :outside
    const = :inactive
    str.each_char do |c|
      case c
      when '('
        paren = :inside
        c = 'Object(' if previous.empty? || previous == '|' || previous == '<'  
      when ')'
        paren = :outside
      when '#'
        if paren == :outside
          c = 'Object(' + c
          const = :active
        end
      when ':'
        if paren == :outside
          c = 'Object(val:' + c
          const = :active
        end
      when '|', '>'
        if const == :active
          c = ')' + c
          const = :inactive
        end
      end
      result += c
      previous = c
    end
    result = (const == :active) ? result + ')' : result
  end

  def self.remove_white_space(str)
    result = ''
    is_skip = false
    skips = [ '/', '"' ]
    closing_symbol = ''
    str.each_char do |c|
      if is_skip
        is_skip = false if c == closing_symbol
      else
        c = '' if c == ' '
        if skips.any? { |s| s == c }
          closing_symbol = c
          is_skip = true
        end
      end
      result += c
    end
    result
  end
end
