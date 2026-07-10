# Crawler-readable share pages. The SPA can't serve per-page Open Graph tags,
# so share links point here: crawlers read the tags and unfurl a rich preview,
# humans are bounced straight to the app page. Private content 404s exactly
# like the GraphQL surface would (the share token is the secret for unlisted).
class SharesController < ApplicationController
  def collection
    collection = Collection.find_by(id: params[:id])
    return head :not_found unless collection&.viewable_by?(nil, share_token: params[:t])

    render html: share_page(collection).html_safe, content_type: "text/html" # rubocop:disable Rails/OutputSafety
  end

  private

  def share_page(collection)
    target = app_url(collection)
    tags = og_tags(collection, target).map { |name, value| %(<meta property="#{name}" content="#{h(value)}">) }
    <<~HTML
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>#{h(collection.title)} · Puzler</title>
        #{tags.join("\n  ")}
        <meta name="twitter:card" content="summary_large_image">
        <link rel="canonical" href="#{h(target)}">
        <meta http-equiv="refresh" content="0;url=#{h(target)}">
      </head>
      <body>
        <p>Continue to <a href="#{h(target)}">#{h(collection.title)}</a> on Puzler.</p>
      </body>
      </html>
    HTML
  end

  def og_tags(collection, target)
    tags = {
      "og:type" => "website",
      "og:site_name" => "Puzler",
      "og:title" => collection.title,
      "og:description" => collection.description.presence&.truncate(200) || "A puzzle collection on Puzler.",
      "og:url" => target
    }
    image = collection.og_image_url
    tags["og:image"] = image if image
    tags
  end

  def app_url(collection)
    base = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
    token = params[:t].present? ? "?t=#{ERB::Util.url_encode(params[:t])}" : ""
    "#{base}/collections/#{collection.id}#{token}"
  end

  def h(value)
    ERB::Util.html_escape(value)
  end
end
