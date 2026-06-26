require "rails_helper"

RSpec.describe PresenceRegistry do
  describe PresenceRegistry::MemoryStore do
    subject(:store) { described_class.new }

    it "is not live with no connections" do
      expect(store.live?("1")).to be false
    end

    it "is live once a connection is added" do
      store.add("1", "a")
      expect(store.live?("1")).to be true
    end

    it "stays live while another connection remains" do
      store.add("1", "a")
      store.add("1", "b")
      store.remove("1", "a")
      expect(store.live?("1")).to be true
    end

    it "is not live once the last connection leaves" do
      store.add("1", "a")
      store.remove("1", "a")
      expect(store.live?("1")).to be false
    end

    it "isolates plays from one another" do
      store.add("1", "a")
      expect(store.live?("2")).to be false
    end

    it "clears all connections on reset" do
      store.add("1", "a")
      store.reset!
      expect(store.live?("1")).to be false
    end
  end

  describe PresenceRegistry::RedisStore do
    subject(:store) { described_class.new }

    # Minimal in-memory stand-in for the Redis SET commands RedisStore issues.
    let(:fake) do
      Class.new do
        def initialize
          @sets = Hash.new { |h, k| h[k] = [] }
        end

        def call(command, key, member = nil)
          case command
          when "SADD" then @sets[key] |= [ member ]
          when "SREM" then @sets[key].delete(member)
          when "SCARD" then @sets[key].size
          when "EXPIRE" then 1
          end
        end
      end.new
    end

    before do
      allow(Sidekiq).to receive(:redis).and_yield(fake)
      allow(fake).to receive(:call).and_call_original
    end

    it "is live while a connection is in the set" do
      store.add("9", "c1")
      expect(store.live?("9")).to be true
    end

    it "is not live once all connections are removed" do
      store.add("9", "c1")
      store.add("9", "c2")
      store.remove("9", "c1")
      store.remove("9", "c2")
      expect(store.live?("9")).to be false
    end

    it "refreshes the liveness TTL on add" do
      store.add("9", "c1")
      expect(fake).to have_received(:call).with("EXPIRE", "presence:play:9", PresenceRegistry::TTL_SECONDS)
    end
  end

  describe ".backend" do
    it "uses the in-memory store outside production" do
      expect(described_class.backend).to be_a(PresenceRegistry::MemoryStore)
    end
  end
end
