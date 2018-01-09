require 'dromedary/entry/eg'

module Dromedary
  class Supplement

    attr_reader :xml, :egs, :todo

    def initialize(nokonode)
      return if nokonode == :empty
      @xml = nokonode.to_xml
      @egs = nokonode.at('EG').map{|eg| EG.new(eg)}
      @todo = nokonode.attr('todo')
    end

    def to_h
      {
        xml: xml,
        egs: egs.map(&:to_h)
      }
    end

    def self.from_h(h)
      obj = allocate
      obj.fill_from_hash(h)
      obj
    end

    def fill_from_hash(h)
      @xml = h[:xml]
      @egs = h[:egs].map{|x| EG.from_h(x)}
    end

  end
end

