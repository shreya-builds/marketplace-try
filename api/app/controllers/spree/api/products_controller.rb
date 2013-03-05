module Spree
  module Api
    class ProductsController < Spree::Api::BaseController
      respond_to :json

      def index
        @products = product_scope.ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
        respond_with(@products)
      end

      def show
        @product = find_product(params[:id])
        respond_with(@product)
      end

      def new
      end

      def create
        authorize! :create, Product
        params[:product][:available_on] ||= Time.now
        @product = Product.new(params[:product])
        if @product.save
          respond_with(@product, :status => 201, :default_template => :show)
        else
          invalid_resource!(@product)
        end
      end

      def update
        authorize! :update, Product
        @product = find_product(params[:id])

				my_params = params[:product].except(:option_types,:variants,:product_properties,:taxon_ids,:count_on_hand,:permalink)

        if @product.update_attributes(my_params)
          respond_with(@product, :status => 200, :default_template => :show)
        else
          invalid_resource!(@product)
        end
      end

      def destroy
        authorize! :delete, Product
        @product = find_product(params[:id])
        @product.update_attribute(:deleted_at, Time.now)
        @product.variants_including_master.update_all(:deleted_at => Time.now)
        respond_with(@product, :status => 204)
      end
    end
  end
end
