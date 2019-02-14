require 'spec_helper'

describe 'Tax Rates', type: :feature do
  stub_authorization!

  before { create(:tax_rate, calculator: stub_model(Spree::Calculator)) }

  # Regression test for #1422
  it 'can create a new tax rate' do
    visit spree.admin_path
    find('#configurations-menu').click
    click_link 'Tax Rates'
    click_link 'New Tax Rate'
    fill_in 'Rate', with: '0.05'
    click_button 'Create'
    expect(page).to have_content('Tax Rate has been successfully created!')
  end
end
