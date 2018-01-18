module Taipo
  module Parser

    # A state machine
    #
    # @since 1.0.0
    # @api private
    class SyntaxState
 
      # Initialize a new state machine
      #
      # @param state_names [Array<Symbol>] an array of symbols designating the
      #   particular states to be used
      # @param counter_names_and_closers [Array<Array<Symbol>,Hash<Symbol,
      #   String>>] an array of two collections: an array of symbols
      #   designating the names the state machine will use for counting 
      #   brackets and a hash of closing characters used for each bracket (the
      #   key for each closing character should have the same name as the name
      #   used for the counter)
      #
      # @since 1.0.0
      # @api private
      #
      # @example
      #   status_array = [ :foo, :bar ]
      #   counter_array = [ [ :angle ], { angle: '>' } ]
      #   state = SyntaxState.new(status_array, counter_array)
      def initialize(state_names, counter_names_and_closers = nil)
        @status = Hash[state_names.map { |s| [s, :prohibited] }]
        if counter_names_and_closers.nil?
          @counter = Array.new
          @closers = Array.new
        else
          @counter = Hash[counter_names_and_closers[0].map { |c| [c, 0] }]
          @closers = counter_names_and_closers[1]
        end
      end

      # Check if the counter for the given +key+ has been incremented
      #
      # @param key [Symbol] the counter to check
      #
      # @return [Boolean] the result
      #
      # @since 1.0.0
      # @api private
      def active?(key)
        @counter[key] > 0
      end

      # Set the status for the given +key+ to be +:allowed+
      #
      # @param key [Symbol] the key to set
      #
      # @since 1.0.0
      # @api private
      def allow(key)
        @status[key] = :allowed
      end

      # Set all statuses to be +:allowed+ except those specified in the 
      # +except+ array
      #
      # @note Statuses which have been set to +:disabled+ will not be updated
      #
      # @param except [Array<Symbol>] keys not to update to +:allowed+ (will
      #   instead be set to +:prohibited+)
      #
      # @since 1.0.0
      # @api private
      def allow_all(except: [])
        set_all :allowed, except: { exceptions: except, status: :prohibited }
      end

      # Check if the given +key+ is allowed
      #
      # @param key [Symbol] the key to check
      #
      # @return [Boolean] the result
      #
      # @since 1.0.0
      # @api private  
      def allowed?(key)
        @status[key] == :allowed
      end

      # Get the count for the given +key+
      #
      # @param key [Symbol] the key for the counter
      #
      # @return [Integer] the count
      #
      # @since 1.0.0
      # @api private
      def count(key)
        @counter[key]
      end

      # Decrement the count for the given +key+ by 1
      #
      # @param key [Symbol] the key for the counter
      # 
      # @since 1.0.0
      # @api private
      def decrement(key)
        msg = 'Trying to reduce count below zero.'
        raise RangeError, msg if @counter[key] == 0
        @counter[key] -= 1
      end

      # Disable the status of the given +key+ (by setting it to +:disabled+)
      #
      # @param key [Symbol] the +key+ to disable
      #
      # @since 1.0.0
      # @api private
      def disable(key)
        @status[key] = :disabled
      end

      # Enable the status of the given +key+ (by setting it to +:prohibited+)
      #
      # @param key [Symbol] the +key+ to disable
      #
      # @since 1.0.0
      # @api private
      def enable(key)
        @status[key] = :prohibited
      end

      # Increment the counter for the given +key+ by 1
      #
      # @param key [Symbol] the key for the counter
      #
      # @since 1.0.0
      # @api private
      def increment(key)
        @counter[key] += 1
      end

      # Check if we are 'inside' a set of brackets (eg. a pair of parentheses)
      # for a given +key+
      #
      # @param key [Symbol] the key for the counter
      #
      # @return [Boolean] the result
      #
      # @since 1.0.0
      # @api private 
      def inside?(key)
        @counter[key] > 0
      end

      # Check if we are 'outside' a set of brackets (eg. a pair of parentheses)
      # for a given +key+
      #
      # @param key [Symbol] the key for the counter
      #
      # @return [Boolean] the result
      #
      # @since 1.0.0
      # @api private
      def outside?(key)
        @counter[key] == 0
      end

      # Set the status for the given +key+ to be +:prohibited+
      #
      # @param key [Symbol] the key to set
      #
      # @since 1.0.0
      # @api private
      def prohibit(key)
        @status[key] = :prohibited
      end

      # Set all statuses to be +:prohibited+ except those specified in the
      # +except+ array
      #
      # @note Statuses which have been set to +:disabled+ will not be updated
      #
      # @param except [Array<Symbol>] keys not to update to +:prohibited+ (will
      #   instead be set to +:allowed+)
      #
      # @since 1.0.0
      # @api private
      def prohibit_all(except: [])
        set_all :prohibited, except: { exceptions: except, status: :allowed }
      end

      # Check if the given +key+ is allowed
      #
      # @param key [Symbol] the key to check
      #
      # @since 1.0.0
      # @api private
      def prohibited?(key)
        @status[key] == :prohibited
      end

      # Set all statuses to be +status+ except those specified in the +except+
      # array
      #
      # @note Statuses which have been set to +:disabled+ will not be updated
      #
      # @param status [Symbol] the value for all statuses
      # @param except [Hash<Array<Symbol>, Symbol>] the exceptions
      # @option except [Array<Symbol>] :exceptions keys not to update to +status+
      # @option except [Symbol] :status the value for exceptions
      #
      # @since 1.0.0
      # @api private
      def set_all(status, except: {})
        @status.transform_values! { |v| v = status unless v == :disabled }
        except[:exceptions].each do |k|
          @status[k] = except[:status] unless @status[k] == :disabled
        end
      end

      # Get the names of the unbalanced brackets
      #
      # @return [Array<Symbol>] an array of the names of the unbalanced
      #   brackets
      #
      # @since 1.0.0
      # @api 
      def unbalanced()
        @counter.reduce(Array.new) do |memo, c|
          (c[1] == 0) ? memo : memo.push(@closers[c[0]])
        end
      end
    end
  end
end
