require 'taipo/exceptions'
require 'taipo/parser/syntax_state'

module Taipo
  module Parser
    
    # A validater of Taipo type definitions
    # @since 1.0.0
    module Validater

      # Check +str+ is a valid type definition
      #
      # @param str [String] a type definition
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

        status_array = [ :bar, :lab, :rab, :lpr, :rpr, :hsh, :cln, :sls, :qut,
                         :cma, :spc, :oth, :end ]
        counter_array = [ [ :angle, :paren, :const ],
                          { angle: '>', paren: ')', const: ":' or '#" } ]
        state = Taipo::Parser::SyntaxState.new(status_array, counter_array)

        i = 0
        chars = str.chars
        str_length = chars.size

        state.prohibit_all except: [ :hsh, :oth ]

        while (i < str_length)
          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
          case chars[i]
          when '|' # bar
            conditions = [ state.allowed?(:bar) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.enable :lab
            state.enable :lpr
            state.prohibit_all except: [ :hsh, :oth ]
          when '<' # lab
            conditions = [ state.allowed?(:lab) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :oth ]
            state.increment :angle
          when '>' # rab
            conditions = [ state.allowed?(:rab), state.inside?(:angle) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :bar, :rab, :lpr, :end ]
            state.decrement :angle
          when '(' # lpr
            conditions = [ state.allowed?(:lpr), state.outside?(:paren) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :oth ]
            state.increment :paren
            state.increment :const
          when ')' # rpr
            conditions = [ state.allowed?(:rpr), state.inside?(:paren) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :bar, :rab, :end ]
            state.decrement :paren
          when '#' # hsh
            conditions = [ state.allowed?(:hsh) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            if state.outside? :paren
              state.disable :lab
              state.disable :lpr
              state.prohibit_all except: [ :oth ]
            else
              state.prohibit_all except: [ :oth ]
              state.decrement :const
            end
          when ':' # cln
            conditions = [ state.allowed?(:cln), state.inside?(:paren) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :sls, :qut, :spc, :oth ]
            state.decrement :const
          when '/' #sls
            conditions = [ state.allowed?(:sls), state.inside?(:paren),
                           state.outside?(:const) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            i = Taipo::Parser::Validater.validate_regex(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when '"' #qut
            conditions = [ state.allowed?(:qut), state.inside?(:paren),
                           state.outside?(:const) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            i = Taipo::Parser::Validater.validate_string(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when ',' # cma
            conditions = [ state.allowed?(:cma),
                           state.inside?(:angle) || state.inside?(:paren) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :spc, :oth ]
            state.increment :const if state.inside?(:paren)
          when ' ' # spc
            conditions = [ state.allowed?(:spc) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :sls, :qut, :oth ]
          else # oth
            conditions = [ state.allowed?(:oth) ]
            raise Taipo::SyntaxError, msg unless conditions.all?
            state.allow_all except: [ :hsh, :spc ]
          end
          i += 1
        end
        msg_end = "The string '#{str}' ends with an illegal character."
        raise Taipo::SyntaxError, msg_end unless state.allowed?(:end)

        missing = state.unbalanced
        msg_bal = "The string '#{str}' is missing a '#{missing.first}'."
        raise Taipo::SyntaxError, msg_bal unless missing.size == 0
      end

      # Check +str+ is a valid regular expression
      #
      # @param str [String] a regular expression delimited by '/'
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
      # @param str [String] a string delimited by '"'
      # @param start [Integer] the index within the type definition where this
      #   string begins
      #
      # @return [Integer] the index within the type definition where this
      #   string ends
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
