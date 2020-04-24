require 'turnpike/queue'
require 'turnpike/unique_queue'

module Turnpike
  class << self
    attr_accessor :namespace

    def call(name = 'default', unique: false, redis: nil)
      (unique ? UniqueQueue : Queue).new(name, redis: redis)
    end
    alias [] call
  end

  @namespace = 'turnpike'
end
