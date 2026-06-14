require "rails_helper"

RSpec.describe "Root", type: :request do
  describe "GET /" do
    # commit_sha and number are memoized per process; clear them so each example
    # resolves the stubbed env fresh.
    before { reset_app_version! }
    after { reset_app_version! }

    def reset_app_version!
      [ :@commit_sha, :@number ].each do |ivar|
        AppVersion.remove_instance_variable(ivar) if AppVersion.instance_variable_defined?(ivar)
      end
    end

    def stub_render_commit(commit, branch)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("RENDER_GIT_COMMIT").and_return(commit)
      allow(ENV).to receive(:[]).with("RENDER_GIT_BRANCH").and_return(branch)
    end

    it "responds with a hello message and a version", :aggregate_failures do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("message" => "Hello There")
    end

    it "registers a new commit and returns its version number", :aggregate_failures do
      stub_render_commit("abc123def456", "main")
      expect { get "/" }.to change(AppVersion, :count).by(1)
      record = AppVersion.find_by!(commit: "abc123def456")
      expect(response.parsed_body.slice("version", "commit", "branch"))
        .to eq("version" => record.id, "commit" => "abc123def456", "branch" => "main")
    end

    it "reuses the version number for a commit it already knows", :aggregate_failures do
      existing = AppVersion.create!(commit: "abc123def456")
      stub_render_commit("abc123def456", "main")
      expect { get "/" }.not_to change(AppVersion, :count)
      expect(response.parsed_body["version"]).to eq(existing.id)
    end
  end
end
