class TagDailyOrdersWorker
  include Sidekiq::Worker

  def perform(*args)
    # Do something later
    Shop.all.each do |shop|
      next unless shop&.shopify_token

      client = create_session(shop)
      shop_daily_orders = get_daily_orders(client).body.dig("data","orders","edges")
      if shop_daily_orders.any?
        shop_daily_orders.each { |order| tag_order(order.dig('node', 'id'), client) }
      end
    end
  end

  private 

  def get_daily_orders(client)
    query = <<~QUERY
      query {
        orders(first: 100, query: "created_at:>#{(Date.today - 1.day).strftime('%Y-%m-%d')}") {
          edges {
            node {
              id
            }
          }
        }
      }
    QUERY
    client.query(query: query)
  end

  def tag_order(order_id, client)
    query = <<~QUERY
      mutation addTags($id: ID!, $tags: [String!]!)
        tagsAdd(id: $id, tags: $tags) {
          node {
            id
          }
          userErrors {
            message
          }
        }
      }
    QUERY
    variables = {id: order_id, tags: [(Date.today - 1.day).strftime('%Y-%m-%d')]}
    client.query(query: query, variables: variables)
  end

  def create_session(shop)
    session = ShopifyAPI::Auth::Session.new(
      shop: shop.shopify_domain,
      access_token: shop.shopify_token # Use the token specific to the shop
    )
    ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end
end