module Sources
  # Generic batch-loader for ActiveRecord records by primary key, so resolvers
  # can fetch an associated record without an N+1. Usage:
  #   context.dataloader.with(Sources::Record, Puzzle).load(id)
  class Record < GraphQL::Dataloader::Source
    def initialize(model)
      @model = model
    end

    def fetch(ids)
      by_id = @model.where(id: ids).index_by(&:id)
      ids.map { |id| by_id[id] }
    end
  end
end
