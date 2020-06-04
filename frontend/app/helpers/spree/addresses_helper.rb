# https://github.com/spree-contrib/spree_address_book/blob/master/app/helpers/spree/addresses_helper.rb
module Spree
  module AddressesHelper
    def address_field(form, method, address_id = 'b', &handler)
      content_tag :div, id: [address_id, method].join, class: 'form-group checkout-content-inner-field has-float-label' do
        if handler
          yield
        else
          is_required = Spree::Address.required_fields.include?(method)
          method_name = I18n.t("activerecord.attributes.spree/address.#{method}")
          required = Spree.t(:required)
          form.text_field(method,
                          class: [is_required ? 'required' : nil, 'spree-flat-input'].compact,
                          required: is_required,
                          placeholder: is_required ? "#{method_name} #{required}" : method_name,
                          aria: { label: method_name }) +
            form.label(method_name, is_required ? "#{method_name} #{required}" : method_name, class: 'text-uppercase')
        end
      end
    end

    def address_zipcode(form, country, _address_id = 'b')
      country ||= Spree::Country.find(Spree::Config[:default_country_id])
      is_required = country.zipcode_required?
      required = Spree.t(:required)
        form.text_field(:zipcode,
                        class: [is_required ? 'required' : nil, 'spree-flat-input'].compact,
                        required: is_required,
                        placeholder: is_required ? "#{Spree.t(:zipcode).upcase} #{Spree.t(:required)}" : "#{Spree.t(:zipcode).upcase}",
                        aria: { label: :zipcode }) +
          form.label(:zipcode, is_required ? "#{Spree.t(:zipcode).upcase} #{Spree.t(:required)}" : "#{Spree.t(:zipcode).upcase}", class: 'text-uppercase')
    end

    def address_state(form, country, _address_id = 'b')
      country ||= Spree::Country.find(Spree::Config[:default_country_id])
      have_states = country.states.any?
      state_elements = [
        form.collection_select(:state_id, country.states.order(:name),
                              :id, :name,
                               { prompt: Spree.t(:state).upcase },
                               class: have_states ? 'required form-control spree-flat-select' : 'hidden form-control spree-flat-select',
                               aria: { label: Spree.t(:state) },
                               disabled: !have_states) +
          form.text_field(:state_name,
                          class: !have_states ? 'required spree-flat-input' : 'hidden spree-flat-input',
                          disabled: have_states,
                          placeholder: Spree.t(:state) + " #{Spree.t(:required)}") +
          form.label(Spree.t(:state).downcase,
                     raw(Spree.t(:state) + content_tag(:abbr, " #{Spree.t(:required)}")),
                     class: !have_states ? 'text-uppercase' : 'state-select-label text-uppercase') +
          image_tag('arrow.svg',
                    class: !have_states ? 'hidden position-absolute spree-flat-select-arrow' : 'position-absolute spree-flat-select-arrow')
      ].join.tr('"', "'").delete("\n")

      content_tag(:noscript, form.text_field(:state_name, class: 'required')) +
        javascript_tag("document.write(\"<span class='d-block position-relative'>#{state_elements.html_safe}</span>\");")
    end

    def user_available_addresses
      return unless try_spree_current_user

      try_spree_current_user.addresses.where(country: available_countries)
    end
  end
end
