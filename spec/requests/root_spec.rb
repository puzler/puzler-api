require "rails_helper"

RSpec.describe "Root", type: :request do
  describe "GET /" do
    # commit is memoized per process; clear it so a stubbed env is re-read.
    after { AppVersion.remove_instance_variable(:@commit) if AppVersion.instance_variable_defined?(:@commit) }

    def stub_render_commit(commit, branch)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("RENDER_GIT_COMMIT").and_return(commit)
      allow(ENV).to receive(:[]).with("RENDER_GIT_BRANCH").and_return(branch)
      AppVersion.remove_instance_variable(:@commit) if AppVersion.instance_variable_defined?(:@commit)
    end

    it "responds with a hello message and a version", :aggregate_failures do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("message" => "Hello There")
      expect(response.parsed_body["version"]).to be_present
    end

    it "reports the deployed commit and branch from Render's env" do
      stub_render_commit("abc123def456", "main")
      get "/"
      expect(response.parsed_body.slice("commit", "version", "branch"))
        .to eq("commit" => "abc123def456", "version" => "abc123def", "branch" => "main")
    end
  end
end
