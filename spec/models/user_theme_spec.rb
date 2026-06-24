require "rails_helper"

RSpec.describe UserTheme, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:user_theme)).to be_valid
  end

  it "requires a name" do
    expect(build(:user_theme, name: "")).not_to be_valid
  end

  it "only allows known base preset ids", :aggregate_failures do
    expect(build(:user_theme, base_preset_id: "neon")).not_to be_valid
    expect(build(:user_theme, base_preset_id: "dark")).to be_valid
  end

  it "scopes uid uniqueness to the user", :aggregate_failures do
    theme = create(:user_theme)
    expect(build(:user_theme, user: theme.user, uid: theme.uid)).not_to be_valid
    # the same uid under a different user is fine
    expect(build(:user_theme, uid: theme.uid)).to be_valid
  end

  it "rejects non-object appearance / constraints", :aggregate_failures do
    expect(build(:user_theme, appearance: [])).not_to be_valid
    expect(build(:user_theme, constraints: "x")).not_to be_valid
  end

  it "is destroyed along with its user" do
    theme = create(:user_theme)
    expect { theme.user.destroy }.to change(described_class, :count).by(-1)
  end
end
