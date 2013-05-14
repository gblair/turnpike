require 'digest/sha1'
require 'turnpike/base'

module Turnpike
  class UniqueQueue < Base
    ZPOP = <<-EOF
      local res = redis.call('zrange', KEYS[1], 0, KEYS[2] - 1)
      redis.pcall('zrem', KEYS[1], unpack(res))
      return res
    EOF

    ZPOP_SHA = Digest::SHA1.hexdigest(ZPOP)

    # Pop one or more items from the queue.
    #
    # n - Integer number of items to pop.
    #
    # Returns a String item, an Array of items, or nil if the queue is empty.
    def pop(n = 1)
      items = begin
        redis.evalsha(ZPOP_SHA, [name, n])
      rescue Redis::CommandError
        redis.eval(ZPOP, [name, n])
      end
      items.map! { |i| unpack(i) }

      n == 1 ? items.first : items
    end

    # Push items to the end of the queue.
    #
    # items - A splat Array of items.
    #
    # Returns the Integer size of the queue after the operation.
    def push(*items, score: Time.now.to_f)
      redis.multi do
        redis.zadd(name, items.reduce([]) { |ary, i| ary.push(score, pack(i)) })
        size
      end
    end

    alias << push

    # Returns the Integer size of the queue.
    def size
      redis.zcard(name)
    end

    # Push items to the front of the queue.
    #
    # items - A splat Array of items.
    #
    # Returns the Integer size of the queue after the operation.
    def unshift(*items)
      _, score = redis.zrange(name, 0, 0, with_scores: true).pop
      score ? push(*items, score: score - 1) : push(*items)
    end
  end
end