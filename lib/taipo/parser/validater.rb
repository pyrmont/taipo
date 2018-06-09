require 'taipo/exceptions'
require 'taipo/parser/syntax_state'

module Taipo
  module Parser

    # A validater of Taipo type definitions
    #
    # Taipo's type definition syntax has four components: (1) names; (2)
    # collections; (3) constraints; and (4) sums.
    #
    # === Names
    #
    #   'String', 'Numeric', 'Foo::Bar'
    #
    # A name should be the name of a class or a module. A name can include a
    # namespace.
    #
    # The validater does not check whether the name represents a valid name in
    # the current context nor does it check whether the name complies with
    # Ruby's requirements for names.
    #
    # One special case is where the name is left blank. The validater will
    # accept this as valid. {Taipo::Parser} will implictly add the name
    # 'Object' when parsing the type definition. This allows a clean syntax for
    # duck types (discussed in further detail below).
    #
    # ==== Duck Types
    #
    #   '#to_s', '(#foo, #bar)'
    #
    # As noted above, duck types can be specified by using a blank name. Duck
    # types are really constraints (discussed in further detail below) on the
    # class +Object+. While normally constraints need to be enclosed in
    # parentheses, if there is a blank name and only one method constraint, the
    # parentheses can be omitted. For defining duck types that respond to
    # multiple methods, the parentheses are required.
    #
    # ==== Optional Types
    #
    #   'String?', 'Array<Integer?>', 'Symbol?|String?'
    #
    # It is possible to specify an 'optional' type by appending a question mark
    # to the name of the type. This shorthand functions similarly to defining a
    # sum type with +NilClass+ (the implementation of how optional types are
    # checked is slightly different, however; see {Taipo::TypeElement#match?}).
    # It is not possible to define an optional duck type. For that, either the
    # implicit +Object+ class should be specified (and then made optional), or a
    # sum type should be used.
    #
    # === Collections
    #
    #   'Array<Integer>', 'Hash<Symbol, String>', 'Array<Array<Float>>'
    #
    # A collection should be the type definiton for elements returned by
    # +Enumerator#each+ (the child type) called on the collecting object (the
    # parent type).
    #
    # A collection is demarcated by the angle brackets +<+ and +>+. These come
    # immediately after the name of the parent (ie. without a space). The type
    # definition for the child comes immediately after the opening angle
    # bracket.
    #
    # If +Enumerator#each+ returns multiple values (eg. such as with +Hash+),
    # the type definition for each value is delimited by a comma. It is optional
    # whether a space follows the comma.
    #
    # The type definition for a child element can contain all the components of
    # a type definition (ie. name, collection, constraint, sum) allowing for
    # collections that contain collections and so on.
    #
    # === Constraints
    #
    #   'Array(len: 5)', 'Integer(min: 0, max: 10)', 'String(format: /a{3}/)',
    #   'String(val: "Hello world!")', 'Foo(#bar)'
    #
    # A constraint should be a list of identifiers and values.
    #
    # A constraint is demarcated by parentheses (ie. +(+ and +)+). These come
    # immediately after the name or collection (ie. without a space). The first
    # identifier comes immediately after the opening parenthesis.
    #
    # An identifier and a value are separated by a colon (and an optional
    # space). Multiple identifier-value pairs are delimited by a comma. It is
    # optional whether a space follows the comma.
    #
    # The permitted identifiers and their values are as follows:
    # - +format+: takes a regular expression demarcated by +/+
    # - +len+: takes an integer
    # - +max+: takes an integer
    # - +min+: takes an integer
    # - +val+: takes a number or a string demarcated by +"+
    #
    # The validater does not check whether the identifiers and values are
    # acceptable, merely that they conform to the grammar.
    # {Taipo::Parser.parse} will raise an exception when it parses the
    # definition if the values are not acceptable for the relevant identifier.
    # Similarly, while the repetition of an identifier is technically invalid,
    # the exception will not be raised until {Taipo::Parser.parse} is called.
    #
    # One special case is where the identifier begins with a +#+. For this
    # identifier, no value is provided and the constraint instead results in
    # {Taipo::Check#check} and {Taipo::Check#review} checking whether the
    # given object returns true for +Object#respond_to?+ with the identifier as
    # the symbol.
    #
    # === Sums
    #
    #   'String|Float',
    #   'Boolean|Array<String|Hash<Symbol,Point>|Array<String>>',
    #   'Integer(max: 100)|Float(max: 100)'
    #
    # A sum is a combination of two or more type definitions.
    #
    # The sum comprises two or more type definitions, each separated by a bar
    # (ie. +|+).
    #
    # ==== Enums
    #
    #   ':foo|:bar', ':one|:two|:three'
    #
    # It's possible to approximate the enum idiom available in many languages
    # by creating a sum type consisting of Symbols. As a convenience, Taipo
    # parses these values as constraints on the Object class. In other words,
    # the +:foo|:bar+ is really +Object(val: :foo)|Object(val: :bar)+.
    #
    # @since 1.0.0
    module Validater

      # Check +str+ is a valid type definition
      #
      # @param str [String] a type definition
      #
      # @return [NilClass]
      #
      # @raise [::TypeError] if +str+ is not a String
      # @raise [Taipo::SyntaxError] if +str+ is not a valid type definition
      #
      # @since 1.0.0
      def self.validate(str)
        msg = "The argument to this method must be of type String."
        raise ::TypeError, msg unless str.is_a? String
        msg = "The string to be checked was empty."
        raise Taipo::SyntaxError, msg if str.empty?

        status_array = [ :bar, :lab, :rab, :lpr, :hsh, :cln, :cma, :spc_bar,
                         :spc_rab, :spc_rpr, :spc_cma, :spc_oth, :mth, :sym,
                         :nme, :end ]
        counter_array = [ [ :angle ], { angle: '>' } ]

        state = Taipo::Parser::SyntaxState.new(status_array, counter_array)
        state.prohibit_all except: [ :lpr, :hsh, :cln, :nme ]

        i = 0
        chars = str.chars

        while (i < chars.size)
          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
          case chars[i]
          when ')', '/', '"'
            raise Taipo::SyntaxError, msg
          when '|' # bar
            conditions = [ state.allowed?(:bar) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :lpr, :hsh, :cln, :spc_bar, :nme ]
          when '<' # lab
            conditions = [ state.allowed?(:lab) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :lpr, :hsh, :cln, :nme ]
            state.increment :angle
          when '>' # rab
            conditions = [ state.allowed?(:rab), state.inside?(:angle) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :bar, :rab, :lpr, :spc_rab, :end ]
            state.decrement :angle
          when '(' # lpr
            conditions = [ state.allowed?(:lpr) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            i = Taipo::Parser::Validater.validate_constraints(str, start: i+1)
            state.prohibit_all except: [ :bar, :rab, :spc_rpr, :end ]
          when '#' # hsh
            conditions = [ state.allowed?(:hsh) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :mth ]
          when ':' # cln
            if chars[i+1] == ':' && chars[i+2] != ':'
              conditions = [ state.allowed?(:nme) ]
              raise Taipo::SyntaxError, msg unless conditions.all?
              state.prohibit_all except: [ :nme ]
              i = i + 1
            else
              conditions = [ state.allowed?(:cln) ]
              raise Taipo::SyntaxError, msg unless conditions.all?
              state.prohibit_all except: [ :sym ]
            end
          when ',' # cma
            conditions = [ state.allowed?(:cma), state.inside?(:angle)]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :cln, :spc_cma, :nme ]
          when ' ' # spc
            conditions = [ state.allowed?(:spc_bar), state.allowed?(:spc_cma),
                           state.allowed?(:spc_oth) ]
            raise Taipo::SyntaxError, msg unless conditions.any?
            if state.allowed?(:spc_bar) || state.allowed?(:spc_cma)
              state.prohibit_all except: [ :hsh, :cln, :nme ]
            elsif state.allowed?(:spc_rab) || state.allowed?(:spc_rpr)
              state.prohibit_all except: [ :bar, :hsh, :cln, :nme ]
            elsif state.allowed?(:spc_oth)
              state.prohibit_all except: [ :bar ]
            end
          else # oth
            conditions = [ state.allowed?(:mth), state.allowed?(:sym),
                           state.allowed?(:nme) ]
            raise Taipo::SyntaxError, msg unless conditions.any?
            if state.allowed?(:mth)
              state.prohibit_all except: [ :bar, :rab, :cma, :spc_oth, :mth,
                                           :end ]
            elsif state.allowed?(:sym)
              state.prohibit_all except: [ :bar, :rab, :cma, :spc_oth, :sym,
                                           :end ]
            elsif state.allowed?(:nme)
              state.prohibit_all except: [ :bar, :lab, :rab, :lpr, :cma,
                                           :spc_oth, :nme, :end ]
            end
          end
          i += 1
        end

        msg_end = "The string '#{str}' ends with an illegal character."
        raise Taipo::SyntaxError, msg_end unless state.allowed?(:end)

        missing = state.unbalanced
        msg_bal = "The string '#{str}' is missing a '#{missing.first}'."
        raise Taipo::SyntaxError, msg_bal unless missing.size == 0
      end

      # Check +str+ is a valid set of constraints
      #
      # @param str [String] the type definition
      # @param start [Integer] the index within the type definition where this
      #   set of constraints begins
      #
      # @return [Integer] the index within the type definition where this set of
      #   set of constraints end
      #
      # @raise [Taipo::SyntaxError] if +str+ is not a valid set of constraints
      #
      # @since 1.4.0
      # @api private
      def self.validate_constraints(str, start: 0)
        status_array = [ :rpr, :hsh, :cln, :sls, :qut, :cma, :spc, :oth ]
        counter_array = [ [ :const ], { const: ":' or '#" } ]

        state = SyntaxState.new(status_array, counter_array)
        state.prohibit_all except: [ :hsh, :oth ]
        state.increment(:const)

        i = start
        chars = str.chars

        while (i < chars.size)
          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
          case chars[i]
          when '|', '<', '>', '('
            raise Taipo::SyntaxError, msg
          when ')' # rpr
            conditions = [ state.allowed?(:rpr) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            break # The constraints have ended.
          when '#' # hsh
            conditions = [ state.allowed?(:hsh) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :oth ]
            state.decrement :const
          when ':' # cln
            conditions = [ state.allowed?(:cln) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            if state.count(:const) == 0 # This is a symbol.
              state.prohibit_all except: [ :qut, :oth ]
            else
              state.prohibit_all except: [ :cln, :sls, :qut, :spc, :oth ]
              state.decrement :const
            end
          when '/' #sls
            conditions = [ state.allowed?(:sls), state.outside?(:const) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            i = Taipo::Parser::Validater.validate_regex(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when '"' #qut
            conditions = [ state.allowed?(:qut), state.outside?(:const) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            i = Taipo::Parser::Validater.validate_string(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when ',' # cma
            conditions = [ state.allowed?(:cma) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :spc, :oth ]
            state.increment :const
          when ' ' # spc
            conditions = [ state.allowed?(:spc) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :cln, :sls, :qut, :oth ]
          else # oth
            conditions = [ state.allowed?(:oth) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.allow_all except: [ :hsh, :spc ]
          end
          i += 1
        end

        msg = "The string '#{str}' is missing a ')'."
        raise Taipo::SyntaxError, msg if i == chars.size

        missing = state.unbalanced
        msg_bal = "The string '#{str}' is missing a '#{missing.first}'."
        raise Taipo::SyntaxError, msg_bal unless missing.size == 0

        i
      end

      # Check +str+ is a valid regular expression
      #
      # @param str [String] the type definition
      # @param start [Integer] the index within the type definition where this
      #   regex begins
      #
      # @return [Integer] the index within the type definition where this regex
      #   ends
      #
      # @raise [Taipo::SyntaxError] if +str+ is not a valid regular expression
      #
      # @since 1.0.0
      # @api private
      def self.validate_regex(str, start: 0)
        status_array = [ :bsl, :sls, :opt, :oth ]
        counter_array = [ [ :backslash ], { backslash: '/' } ]

        state = SyntaxState.new(status_array, counter_array)
        state.prohibit_all except: [ :bsl, :oth ]
        finish = start

        str[start, str.length-start].each_char.with_index(start) do |c, i|
          if state.active?(:backslash) # The preceding character was a backslash.
            state.decrement(:backslash)
            next # Any character after a backslash is allowed.
          end

          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"

          case c
          when 'i', 'o', 'x', 'm', 'u', 'e', 's', 'n'
            next # We're either in the regex or in the options that follow.
          when '/'
            raise Taipo::SyntaxError, msg unless state.allowed?(:sls)
            state.prohibit_all except: [ :opt ]
          when '\\'
            raise Taipo::SyntaxError, msg unless state.allowed?(:bsl)
            state.increment(:backslash)
          when ',', ')'
            next if state.allowed?(:oth)
            finish = i
            break # The string has ended.
          else
            raise Taipo::SyntaxError, msg unless state.allowed?(:oth)
            state.allow_all
          end
        end

        msg = "The string '#{str}' is missing a '/'."
        raise Taipo::SyntaxError, msg if finish == start

        finish - 1
      end

      # Check +str+ is a valid string
      #
      # @param str [String] the type definition
      # @param start [Integer] the index within the type definition where this
      #   string begins
      #
      # @return [Integer] the index within the type definition where this
      #   string ends
      #
      # @raise [Taipo::SyntaxError] if +str+ is not a valid string
      #
      # @since 1.0.0
      # @api private
      def self.validate_string(str, start: 0)
        status_array = [ :bsl, :qut, :oth ]
        counter_array = [ [ :backslash ], { backslash: '/' } ]

        state = SyntaxState.new(status_array, counter_array)
        state.prohibit_all except: [ :bsl, :oth ]
        finish = start

        str[start, str.length-start].each_char.with_index(start) do |c, i|
          if state.active?(:backslash) # The preceding character was a backslash.
            state.decrement :backslash
            next # Any character after a backslash is allowed.
          end

          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"

          case c
          when '"'
            raise Taipo::SyntaxError, msg unless state.allowed?(:qut)
            state.prohibit_all
          when '\\'
            raise Taipo::SyntaxError, msg unless state.allowed?(:bsl)
            state.increment :backslash
          when ',', ')'
            next if state.allowed?(:oth)
            finish = i
            break # The string has ended.
          else
            raise Taipo::SyntaxError, msg unless state.allowed?(:oth)
            state.allow_all
          end
        end

        msg = "The string '#{str}' is missing a '\"'."
        raise Taipo::SyntaxError, msg if finish == start

        finish - 1
      end
    end
  end
end
