namespace :graphql do
  namespace :schema do
    desc "Dump the GraphQL schema SDL to schema.graphql (committed; frontend codegen reads it)"
    task dump: :environment do
      path = Rails.root.join("schema.graphql")
      File.write(path, ApiSchema.to_definition)
      puts "Wrote #{path}"
    end
  end
end
