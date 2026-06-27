require "uri"

# Sanitizes author-supplied rich text (TipTap HTML) for safe storage and
# display. Two passes:
#
#   1. Rails' HTML5 SafeListSanitizer enforces the tag/attribute allowlist and
#      strips scripts, event handlers (on*), styles, and unsafe URL protocols.
#   2. A Nokogiri post-pass tightens link/image policy beyond what an allowlist
#      can express: links get rel="nofollow noopener noreferrer" target="_blank"
#      and anything but http/https/mailto loses its href; images are dropped
#      unless their src points at one of our own hosts (so only blobs we served
#      from our upload mutation survive — no hotlinking, no data:/javascript:).
#
# The byte cap is a DoS guard applied before parsing.
class HtmlSanitizer
  class TooLarge < StandardError; end

  ALLOWED_TAGS = %w[p h1 h2 h3 strong em u s a ul ol li blockquote code pre img br hr].freeze
  ALLOWED_ATTRIBUTES = %w[href rel target src alt].freeze
  ALLOWED_LINK_SCHEMES = %w[http https mailto].freeze
  # Removed wholesale (element AND text content) before the allowlist pass — the
  # HTML5 sanitizer otherwise keeps a stripped <script>'s inert text behind.
  DANGEROUS_ELEMENTS = %w[script style template noscript iframe object embed].freeze
  MAX_BYTES = 100_000

  def self.sanitize(html, allowed_image_hosts:)
    new(allowed_image_hosts:).sanitize(html)
  end

  def initialize(allowed_image_hosts:)
    @allowed_image_hosts = Array(allowed_image_hosts).compact.map(&:downcase)
  end

  # Returns sanitized HTML (a plain String), or raises TooLarge for oversized input.
  def sanitize(html)
    return "" if html.blank?
    raise TooLarge, "Description is too large" if html.bytesize > MAX_BYTES

    cleaned = scrubber.sanitize(strip_dangerous_elements(html), tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
    post_process(cleaned)
  end

  private

  def scrubber
    @scrubber ||= Rails::HTML5::SafeListSanitizer.new
  end

  def strip_dangerous_elements(html)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css(*DANGEROUS_ELEMENTS).each(&:remove)
    fragment.to_html
  end

  def post_process(html)
    fragment = Nokogiri::HTML5.fragment(html)

    fragment.css("a").each do |link|
      if safe_link?(link["href"])
        link["rel"] = "nofollow noopener noreferrer"
        link["target"] = "_blank"
      else
        link.remove_attribute("href")
        link.remove_attribute("target")
      end
    end

    fragment.css("img").each { |img| img.remove unless safe_image?(img["src"]) }

    fragment.to_html
  end

  def safe_link?(href)
    href = href.to_s.strip
    return false if href.empty?

    ALLOWED_LINK_SCHEMES.include?(URI.parse(href).scheme&.downcase)
  rescue URI::InvalidURIError
    false
  end

  def safe_image?(src)
    src = src.to_s.strip
    return false if src.empty?

    uri = URI.parse(src)
    %w[http https].include?(uri.scheme&.downcase) && @allowed_image_hosts.include?(uri.host&.downcase)
  rescue URI::InvalidURIError
    false
  end
end
