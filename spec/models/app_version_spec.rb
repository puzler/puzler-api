require "rails_helper"

RSpec.describe AppVersion, type: :model do
  # commit_sha / number are memoized on the class; clear between examples.
  before { reset_memo }
  after { reset_memo }

  def reset_memo
    [ :@commit_sha, :@number ].each do |ivar|
      described_class.remove_instance_variable(ivar) if described_class.instance_variable_defined?(ivar)
    end
  end

  describe ".register!" do
    it "registers the running commit once and is idempotent", :aggregate_failures do
      allow(described_class).to receive(:commit_sha).and_return("deadbeefcafe")
      expect { described_class.register! }.to change(described_class, :count).by(1)
      reset_memo
      allow(described_class).to receive(:commit_sha).and_return("deadbeefcafe")
      expect { described_class.register! }.not_to change(described_class, :count)
    end

    it "never raises when the table is unavailable" do
      allow(described_class).to receive(:commit_sha).and_return("deadbeefcafe")
      allow(described_class).to receive(:find_or_create_by!).and_raise(ActiveRecord::StatementInvalid)
      expect { described_class.register! }.not_to raise_error
    end
  end

  describe ".number" do
    it "assigns sequential numbers to distinct commits" do
      allow(described_class).to receive(:commit_sha).and_return("aaaa")
      first = described_class.number
      reset_memo
      allow(described_class).to receive(:commit_sha).and_return("bbbb")
      expect(described_class.number).to eq(first + 1)
    end
  end
end
