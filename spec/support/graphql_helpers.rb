module GraphqlHelpers
  def execute_query(query_string, variables: {}, context: {})
    ApiSchema.execute(query_string, variables: variables, context: context)
  end

  def auth_context(user)
    { current_user: user }
  end

  # Dig into the data hash of a result using a camelCase field path.
  def gql_data(result, *keys)
    keys.reduce(result["data"]) { |node, key| node&.fetch(key, nil) }
  end

  def gql_errors(result)
    result["errors"] || []
  end
end
