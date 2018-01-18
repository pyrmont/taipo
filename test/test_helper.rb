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
                       pieces = c.split(': ')
                       cst = Taipo::TypeElement::Constraint.new(
                         name: pieces[0],
                         value: pieces[1])
                       memo_c.push cst
                     end
              memo_t.push Taipo::TypeElement.new(name: t[:class],
                                                     child_type: ct,
                                                     constraints: csts)
            end
      types.push res
    end
  end
end