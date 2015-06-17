require 'spec_helper'

module Spree
  describe OrderUpdater, type: :model do
    let(:order) { Spree::Order.create! }
    subject { Spree::OrderUpdater.new(order) }

    context "order totals" do
      before do
        2.times do
          create(:line_item, order: order, price: 10)
        end
      end

      it "updates payment totals" do
        create(:payment_with_refund, order: order)
        Spree::OrderUpdater.new(order).update_payment_total
        expect(order.payment_total).to eq(40.75)
      end

      it "update item total" do
        subject.update_item_total
        expect(order.item_total).to eq(20)
      end

      it "update shipment total" do
        create(:shipment, order: order, cost: 10)
        subject.update_shipment_total
        expect(order.shipment_total).to eq(10)
      end

      context 'with order promotion followed by line item addition' do
        let(:promotion) { Spree::Promotion.create!(name: "10% off") }
        let(:calculator) { Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        let(:promotion_action) do
          Promotion::Actions::CreateAdjustment.create!({
            calculator: calculator,
            promotion: promotion,
          })
        end

        before do
          subject.update

          order.create_adjustment!(
            source:     promotion_action,
            amount:     100,
            label:      'Test adjustment',
            adjustable: order
          )
          create(:line_item, order: order, price: 10) # in addition to the two already created
          # factory girls creation method does not register the line item in the already
          # cached collection Order#lineitems.
          order.reload
          subject.update
        end

        it "updates promotion total" do
          expect(order.promo_total).to eq(-3)
        end
      end

      it "update order adjustments" do
        # A line item will not have both additional and included tax,
        # so please just humour me for now.
        order.line_items.first!.update_columns(
          adjustment_total: 10.05,
          additional_tax_total: 0.05,
          included_tax_total: 0.05
        )
        subject.update_adjustment_total
        expect(order.adjustment_total).to eq(10.05)
        expect(order.additional_tax_total).to eq(0.05)
        expect(order.included_tax_total).to eq(0.05)
      end
    end

    context "updating shipment state" do
      before do
        allow(order).to receive_messages backordered?: false
        allow(order).to receive_message_chain(:shipments, :shipped, :count).and_return(0)
        allow(order).to receive_message_chain(:shipments, :ready, :count).and_return(0)
        allow(order).to receive_message_chain(:shipments, :pending, :count).and_return(0)
      end

      it "is backordered" do
        allow(order).to receive_messages backordered?: true
        subject.update_shipment_state

        expect(order.shipment_state).to eq('backorder')
      end

      it "is nil" do
        allow(order).to receive_message_chain(:shipments, :states).and_return([])
        allow(order).to receive_message_chain(:shipments, :count).and_return(0)

        subject.update_shipment_state
        expect(order.shipment_state).to be_nil
      end

      ["shipped", "ready", "pending"].each do |state|
        it "is #{state}" do
          allow(order).to receive_message_chain(:shipments, :states).and_return([state])
          subject.update_shipment_state
          expect(order.shipment_state).to eq(state.to_s)
        end
      end

      it "is partial" do
        allow(order).to receive_message_chain(:shipments, :states).and_return(["pending", "ready"])
        subject.update_shipment_state
        expect(order.shipment_state).to eq('partial')
      end
    end

    context "updating payment state" do
      let(:order) { Order.new }
      let(:subject) { order.updater }

      it "is failed if no valid payments" do
        allow(order).to receive_message_chain(:payments, :valid, :size).and_return(0)

        subject.update_payment_state
        expect(order.payment_state).to eq('failed')
      end

      context "payment total is greater than order total" do
        it "is credit_owed" do
          order.payment_total = 2
          order.total = 1

          expect {
            subject.update_payment_state
          }.to change { order.payment_state }.to 'credit_owed'
        end
      end

      context "order total is greater than payment total" do
        it "is balance_due" do
          order.payment_total = 1
          order.total = 2

          expect {
            subject.update_payment_state
          }.to change { order.payment_state }.to 'balance_due'
        end
      end

      context "order total equals payment total" do
        it "is paid" do
          order.payment_total = 30
          order.total = 30

          expect {
            subject.update_payment_state
          }.to change { order.payment_state }.to 'paid'
        end
      end

      context "order is canceled" do
        before do
          order.state = 'canceled'
        end

        context "and is still unpaid" do
          it "is void" do
            order.payment_total = 0
            order.total = 30
            expect {
              subject.update_payment_state
            }.to change { order.payment_state }.to 'void'
          end
        end

        context "and is paid" do
          it "is credit_owed" do
            order.payment_total = 30
            order.total = 30
            allow(order).to receive_message_chain(:payments, :valid, :size).and_return(1)
            allow(order).to receive_message_chain(:payments, :completed, :size).and_return(1)
            expect {
              subject.update_payment_state
            }.to change { order.payment_state }.to 'credit_owed'
          end
        end

        context "and the payment total is zero" do
          it "is void" do
            order.payment_total = 0
            order.total = 30
            allow(order).to receive_message_chain(:payments, :valid, :size).and_return(1)
            expect {
              subject.update_payment_state
            }.to change { order.payment_state }.to 'void'
          end
        end
      end
    end

    it "state change" do
      order.shipment_state = 'shipped'
      state_changes = double
      allow(order).to receive_messages state_changes: state_changes
      expect(state_changes).to receive(:create!).with(
        previous_state: nil,
        next_state: 'shipped',
        name: 'shipment',
        user_id: nil
      )

      order.state_changed('shipment')
    end

    it "updates payment state" do
      expect(subject).to receive(:update_payment_state)
      subject.update
    end

    it "updates shipment state" do
      expect(subject).to receive(:update_shipment_state)
      subject.update
    end

    it "doesnt update each shipment" do
      shipment = stub_model(Spree::Shipment)
      shipments = [shipment]
      allow(order).to receive_messages shipments: shipments
      allow(shipments).to receive_messages states: []
      allow(shipments).to receive_messages ready: []
      allow(shipments).to receive_messages pending: []
      allow(shipments).to receive_messages shipped: []

      allow(subject).to receive(:update_totals) # Otherwise this gets called and causes a scene
      expect(subject).not_to receive(:update_shipments).with(order)
      subject.update
    end

    it "refreshes shipment rates" do
      shipment = stub_model(Spree::Shipment, :order => order)
      shipments = [shipment]
      allow(order).to receive_messages :shipments => shipments

      expect(shipment).to receive(:refresh_rates)
      subject.update_shipments
    end

    it "updates the shipment amount" do
      shipment = stub_model(Spree::Shipment, :order => order)
      shipments = [shipment]
      allow(order).to receive_messages :shipments => shipments
    end

    describe "#persist_totals" do
      let!(:order) { super() }
      let(:updated_at) { Time.now }
      let(:validation_order) { mock_model(Spree::Order, valid?: true) }
      let(:totals) { attributes.merge(updated_at: updated_at) }

      let(:attributes) do
        {
          payment_state:        nil,
          shipment_state:       nil,
          item_count:           0,
          item_total:           0,
          adjustment_total:     0,
          included_tax_total:   0,
          additional_tax_total: 0,
          payment_total:        0,
          shipment_total:       0,
          promo_total:          0,
          total:                0
        }
      end

      before do
        allow(Time).to receive(:now).and_return(updated_at)
        allow(Spree::Order).to receive(:new).with(attributes).
          and_return(validation_order)
      end

      context 'when the columns are updated' do
        before do
          allow(order).to receive(:update_columns).and_return(true)
        end

        it 'persists the expected totals' do
          subject.persist_totals
          expect(order).to have_received(:update_columns).with(totals)
        end

        its(:persist_totals) { should be(true) }
      end

      context 'when the columns are not updated' do
        before do
          allow(order).to receive(:update_columns).and_return(false)
        end

        it 'persists the expected totals' do
          subject.persist_totals
          expect(order).to have_received(:update_columns).with(totals)
        end

        its(:persist_totals) { should be(false) }
      end

      context 'when the order is not valid' do
        before do
          allow(validation_order).to receive(:valid?).and_return(false)
        end

        it 'raises ActiveRecord::RecordInvalid' do
          expect { subject.persist_totals }
            .to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
