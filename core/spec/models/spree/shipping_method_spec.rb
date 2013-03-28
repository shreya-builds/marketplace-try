require 'spec_helper'

describe Spree::ShippingMethod do
  context 'factory' do
    let(:shipping_method){ create :shipping_method }

    it "should set calculable correctly" do
      shipping_method.calculator.calculable.should == shipping_method
    end
  end

  context 'available?' do
    before do
      @shipping_method = create(:shipping_method)
      variant = create(:variant, :product => create(:product))
      @order = create(:order, :line_items => [create(:line_item, :variant => variant)])
    end

    context "when the calculator is not available" do
      before { @shipping_method.calculator.stub(:available? => false) }

      it "should be false" do
        @shipping_method.available?(@order).should be_false
      end
    end

    context "when the calculator is available" do
      before { @shipping_method.calculator.stub(:available? => true) }

      it "should be true" do
        @shipping_method.available?(@order).should be_true
      end
    end

    context "when the shipping method's calculator is available" do
      it "should be available for the order" do
        @shipping_method.available?(@order).should be_true
      end
    end
  end

  context 'available_to_order?' do
    before do
      @shipping_method = create(:shipping_method)
      @shipping_method.zone.stub(:include? => true)
      @shipping_method.stub(:available? => true)
      variant = create(:variant, :product => create(:product))
      @order = create(:order, :line_items => [create(:line_item, :variant => variant)])
    end

    context "when availability_check is false" do
      before { @shipping_method.stub(:available? => false) }

      it "should be false" do
        @shipping_method.available_to_order?(@order).should be_false
      end
    end

    context "when zone_check is false" do
      before { @shipping_method.zone.stub(:include? => false) }

      it "should be false" do
        @shipping_method.available_to_order?(@order).should be_false
      end
    end

    context "when category_check is false" do
      before { @shipping_method.stub(:category_match? => false) }

      it "should be false" do
        @shipping_method.available_to_order?(@order).should be_false
      end
    end

    context "when currency_check is false" do
      before { @shipping_method.stub(:currency_match? => false) }

      it "should be false" do
        @shipping_method.available_to_order?(@order).should be_false
      end
    end

    context "when all checks are true" do
      it "should be true" do
        @shipping_method.available_to_order?(@order).should be_true
      end
    end
  end

  context "#category_match?" do
    context "when no category is specified" do
      before do
        @shipping_method = create(:shipping_method)
      end

      it "should return true" do
        @shipping_method.category_match?(create(:order)).should be_true
      end
    end

    context "when a category is specified" do
      before { @shipping_method = create(:shipping_method_with_category) }

      context "when all products match" do
        before do
          variant = create(:variant, :product => create(:product, :shipping_category => @shipping_method.shipping_category))
          @order = create(:order, :line_items => [create(:line_item, :variant => variant)])
        end

        context "when rule is every match" do
          before { @shipping_method.match_all = true }

          it "should return true" do
            @shipping_method.category_match?(@order).should be_true
          end
        end

        context "when rule is at least one match" do
          before { @shipping_method.match_one = true }

          it "should return true" do
            @shipping_method.category_match?(@order).should be_true
          end
        end

        context "when rule is none match" do
          before { @shipping_method.match_none = true }

          it "should return false" do
            @shipping_method.category_match?(@order).should be_false
          end
        end
      end

      context "when no products match" do
        before do
          variant = create(:variant, :product => create(:product, :shipping_category => create(:shipping_category)))
          @order = create(:order, :line_items => [create(:line_item, :variant => variant)])
        end

        context "when rule is every match" do
          before { @shipping_method.match_all = true }

          it "should return false" do
            @shipping_method.category_match?(@order).should be_false
          end
        end

        context "when rule is at least one match" do
          before { @shipping_method.match_one = true }

          it "should return false" do
            @shipping_method.category_match?(@order).should be_false
          end
        end

        context "when rule is none match" do
          before { @shipping_method.match_none = true }

          it "should return true" do
            @shipping_method.category_match?(@order).should be_true
          end
        end
      end

      context "when some products match" do
        before do
          variant1 = create(:variant, :product => create(:product, :shipping_category => @shipping_method.shipping_category))
          variant2 = create(:variant, :product => create(:product, :shipping_category => create(:shipping_category)))
          @order = create(:order, :line_items => [create(:line_item, :variant => variant1), create(:line_item, :variant => variant2)])
        end

        context "when rule is every match" do
          before { @shipping_method.match_all = true }

          it "should return false" do
            @shipping_method.category_match?(@order).should be_false
          end
        end

        context "when rule is at least one match" do
          before { @shipping_method.match_one = true }

          it "should return true" do
            @shipping_method.category_match?(@order).should be_true
          end
        end

        context "when rule is none match" do
          before { @shipping_method.match_none = true }

          it "should return false" do
            @shipping_method.category_match?(@order).should be_false
          end
        end
      end
    end
  end

  context "#build_tracking_url" do
    context "when a tracking_url is specified" do
      let(:shipping_method) { create(:shipping_method, :tracking_url => "http://www.ups.com?tracking?n=:tracking") }

      specify { shipping_method.build_tracking_url("1Z12345").should == "http://www.ups.com?tracking?n=1Z12345" }
      specify { shipping_method.build_tracking_url("").should  be_nil }
      specify { shipping_method.build_tracking_url(nil).should be_nil }
    end

    context "when a tracking_url is not specified" do
      let(:shipping_method) { create(:shipping_method, :tracking_url => nil) }

      specify { shipping_method.build_tracking_url("1Z12345").should be_nil }
    end
  end
end
