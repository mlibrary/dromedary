module MiddleEnglishDictionary
  module Collection
    # An +Enumerable+ key-value store backed by a plain +Hash+.
    #
    # {HashArray} provides a minimal hash-like interface -- bracket access,
    # assignment, and key listing -- together with +Enumerable+ iteration over
    # values. It is used as the base class for {EntrySet} and
    # {ExternalDictionaryLinkSet}.
    #
    # An optional block passed to {#initialize} is evaluated in the context of
    # the new instance, allowing subclasses or callers to populate the store
    # at construction time.
    #
    # @example
    #   store = HashArray.new
    #   store["MED3366"] = some_entry
    #   store["MED3366"]  #=> some_entry
    #   store.keys        #=> ["MED3366"]
    #   store.map(&:id)   #=> ["MED3366"]
    class HashArray
      include Enumerable

      # @param blk [Proc, nil] optional block evaluated in instance context
      #   for initializing the store
      def initialize(&blk)
        @h = {}
        if blk
          instance_eval(&blk)
        end
        self # rubocop:disable Lint/Void
      end

      # @return [Array] all keys currently in the store
      def keys
        @h.keys
      end

      # Store +v+ under key +k+.
      #
      # @param k key
      # @param v value
      # @return [v]
      def []=(k, v)
        @h[k] = v
      end

      # Retrieve the value stored under key +k+.
      #
      # @param k key
      # @return [Object, nil] stored value, or +nil+ if absent
      def [](k)
        @h[k]
      end

      # Iterate over each value in insertion order.
      #
      # @yield [value] each stored value
      # @return [Enumerator] if no block is given
      def each
        return enum_for(:each) unless block_given?
        @h.values.each { |v| yield v }
      end

      # Iterate over each key-value pair in insertion order.
      #
      # @yield [pair] a two-element array +[key, value]+
      # @return [Enumerator] if no block is given
      def each_pair
        return enum_for(:each_pair) unless block_given?
        @h.each_pair { |k, v| yield [k, v] }
      end
    end
  end
end
