# frozen_string_literal: true
class OrdersController < AuthenticatedController
  def count
    # order_count = ShopifyAPI::Order.count.body
    # ShopifyAPI::Logger.info("Retrieved order count: #{order_count["count"]}")
    
    all_shop_domains = Shop.all.pluck(:shopify_domain)
    shop = Shop.find_by(shopify_domain: all_shop_domains.first)

    product_count = ShopifyAPI::Product.count.body
    orders_count = ShopifyAPI::Order.count.body
    p "HHEEEEEERE"
    p product_count
    p orders_count
    # Make sure the shop exists and has an access_token
    if shop && shop.shopify_token
      session = ShopifyAPI::Auth::Session.new(
        shop: shop.shopify_domain,
        access_token: shop.shopify_token # Use the token specific to the shop
      )
      client = ShopifyAPI::Clients::Graphql::Admin.new(
        session: session
      )
      query = <<~QUERY
        query {
          orders(first: 10, query: "updated_at:>2019-12-01") {
            edges {
              node {
                id
              }
            }
          }
        }
      QUERY

      orders = ShopifyAPI::Order.all
      p orders

      response = client.query(query: query)
      p response

      json = {domains: all_shop_domains, response: response}
      render(json: json.to_json)
    end
  end
end
