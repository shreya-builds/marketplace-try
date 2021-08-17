require 'spec_helper'

class FakesController < ApplicationController
  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Store
  include Spree::Core::ControllerHelpers::Currency

  before_action :set_current_order
end

describe Spree::Core::ControllerHelpers::Store, type: :controller do
  controller(FakesController) {}

  describe '#current_store' do
    let!(:store) { create :store, default: true }
    let!(:store_2) { create :store, url: 'another.com' }

    context 'default store' do
      it 'returns current store' do
        expect(controller.current_store).to eq store
      end
    end

    context 'by domain' do
      before do
        controller.request.env['SERVER_NAME'] = 'another.com'
      end

      it 'returns current store' do
        expect(controller.current_store).to eq store_2
      end
    end

    context 'by subdomain' do
      let!(:store_3) { create :store, url: 'some.another.com' }

      before do
        controller.request.env['SERVER_NAME'] = 'some.another.com'
      end

      it 'returns current store' do
        expect(controller.current_store).to eq store_3
      end
    end
  end

  describe '#set_current_store' do
    let!(:store) { create :store, default: true }
    let!(:store_2) { create :store }

    context 'on an object that accepts multiple stores' do
      before { allow(controller).to receive(:current_store).and_return(store) }

      object = Spree::Product.new

      it 'object has only the current store set' do
        controller.set_current_store(object, Spree::Product)
        expect(object.stores).to contain_exactly(store)
        expect(object.stores).not_to contain_exactly(store_2)
      end
    end

    context 'on a object that accepts a single store' do
      before { allow(controller).to receive(:current_store).and_return(store) }

      object = Spree::Menu.new

      it 'object has the current store set' do
        controller.set_current_store(object, Spree::Menu)
        expect(object.store).to eql(store)
        expect(object.store).not_to eql(store_2)
      end
    end

    context 'when object is nil' do
      before { allow(controller).to receive(:current_store).and_return(store) }

      object = nil

      it 'returns nil' do
        expect(controller.set_current_store(object, Spree::Taxon)).to be_nil
      end
    end

    context 'when model_class is nil' do
      before { allow(controller).to receive(:current_store).and_return(store) }

      object = Spree::Menu.new

      it 'returns nil' do
        controller.set_current_store(object, nil)
        expect(object.store).to be_nil
        expect(controller.set_current_store(object, nil)).to be_nil
      end
    end
  end

  describe '#current_price_options' do
    subject(:current_price_options) { controller.current_price_options }

    context 'when there is a default tax zone' do
      let(:default_zone) { Spree::Zone.new }

      before do
        allow(Spree::Zone).to receive(:default_tax).and_return(default_zone)
      end

      context 'when there is no current order' do
        it 'returns the default tax zone' do
          expect(subject).to include(tax_zone: default_zone)
        end
      end

      context 'when there is a current order' do
        let(:other_zone) { Spree::Zone.new }
        let(:current_order) { Spree::Order.new }

        before do
          allow(current_order).to receive(:tax_zone).and_return(other_zone)
          allow(controller).to receive(:current_order).and_return(current_order)
          controller.instance_variable_set(:@current_order, current_order)
        end

        it { is_expected.to include(tax_zone: other_zone) }
      end
    end

    context 'when there is no default tax zone' do
      before do
        allow(Spree::Zone).to receive(:default_tax).and_return(nil)
      end

      context 'when there is no current order' do
        it 'return nil when asked for the current tax zone' do
          expect(current_price_options[:tax_zone]).to be_nil
        end
      end

      context 'when there is a current order' do
        let(:other_zone) { Spree::Zone.new }
        let(:current_order) { Spree::Order.new }

        before do
          allow(current_order).to receive(:tax_zone).and_return(other_zone)
          allow(controller).to receive(:current_order).and_return(current_order)
          controller.instance_variable_set(:@current_order, current_order)
        end

        it { is_expected.to include(tax_zone: other_zone) }
      end
    end
  end
end
