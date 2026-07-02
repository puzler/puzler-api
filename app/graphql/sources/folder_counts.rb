module Sources
  # Batches the per-folder puzzle/collection counts across a whole folder tree:
  # one grouped COUNT per model instead of two COUNTs per folder rendered.
  class FolderCounts < GraphQL::Dataloader::Source
    def initialize(model)
      @model = model
    end

    def fetch(folder_ids)
      counts = @model.where(folder_id: folder_ids).group(:folder_id).count
      folder_ids.map { |id| counts.fetch(id, 0) }
    end
  end
end
