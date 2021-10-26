require 'swagger_helper'

describe 'Shipping Methods API', swagger: true do
  include_context 'Platform API v2'

  resource_name = 'Shipping Method'
  options = {
    include_example: 'calculator,shipping_categories,shipping_rates,tax_category',
    filter_examples: [{ name: 'filter[name]', example: 'DHL Express' },
                      { name: 'filter[title_cont]', example: 'About Us' }]
  }

  let(:shipping_category) { create(:shipping_category) }
  let(:id) { create(:shipping_method).id }
  let(:records_list) { create_list(:shipping_method, 2) }

  let(:valid_create_param_value) do
    {
      name: 'DHL Express Domestic',
      display_on: 'both',
      shipping_category_ids: [shipping_category.id.to_s],
      admin_name: 'DHL Express- Zone A',
      code: 'DDD',
      calculator_attributes: {
        type: 'Spree::Calculator::Shipping::FlatRate'
      }
    }
  end

  let(:valid_update_param_value) do
    {
      name: 'FedEx Expedited',
      calculator_attributes: {
        type: 'Spree::Calculator::Shipping::FlatPercentItemTotal',
        preferred_flat_percent: 23
      }
    }
  end

  let(:invalid_param_value) do
    {
      name: ''
    }
  end

  include_examples 'CRUD examples', resource_name, options
end
