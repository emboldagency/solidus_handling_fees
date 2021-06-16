# frozen_string_literal: true

require 'spec_helper'

describe 'Checkout', js: true do
  let!(:usa) { create(:country, name: 'United States of America', states_required: true) }
  let!(:alabama) { create(:state, name: 'Alabama', abbr: 'AL', country: usa) }
  let!(:washington) { create(:state, name: 'Washington', abbr: 'WA', country: usa) }

  let!(:handling_calculator) { create(:calculator, type: Spree::Calculator::Shipping::FlexiRate, preferences: { first_item: 1.90, additional_item: 0.40 }) }
  let!(:shipping_calculator) { create(:calculator) }
  let!(:shipping_method) { create(:shipping_method, tax_category_id: 1, calculator: shipping_calculator) }
  let!(:stock_location) { create(:stock_location, country_id: stock_location_address.country.id, state_id: stock_location_address.state.id, address1: stock_location_address.address1, city: stock_location_address.city, zipcode: stock_location_address.zipcode, calculator: handling_calculator) }
  let!(:mug) { create(:product, name: 'RoR Mug', price: 10) }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let!(:store) { create(:store) }

  before do
    stock_location.stock_items.update_all(count_on_hand: 10)
  end

  context 'as admin user' do
    stub_authorization!

    it 'calculates and display handling for one item on payment step and allow full checkout' do
      add_to_cart('RoR Mug')
      click_button 'Checkout'

      fill_in 'order_email', with: 'test@example.com'
      click_button 'Continue'
      fill_in_address(alabama_address)
      click_button 'Save and Continue'
      click_button 'Save and Continue'
      click_button 'Save and Continue'
      expect(page).to have_content(/Handling:\s\$1.90/)
      expect(page).to have_content('$21.90')

      click_button 'Place Order'
      expect(current_path).to match(spree.order_path(Spree::Order.last))

      # Verify handling fee from backend
      visit spree.admin_path
      visit spree.edit_admin_order_path(Spree::Order.last)
      expect(page.find('fieldset#order-total')).to have_content(/Order Total\s\$21.90/)
      expect(page.find('.js-order-shipment-adjustments')).to have_content(/Handling:\s\$1.90/)

      expect(page.find('dl.additional-info')).to have_content("Total:\n$21.90")
      expect(page.find('dl.additional-info')).to have_content("Handling:\n$1.90")
    end
  end

  it 'calculates and display handling for multiple items on payment step and allow full checkout' do
    add_to_cart('RoR Mug')
    add_to_cart('RoR Mug')
    add_to_cart('RoR Mug')
    click_button 'Checkout'

    fill_in 'order_email', with: 'test@example.com'
    click_button 'Continue'
    fill_in_address(alabama_address)
    click_button 'Save and Continue'
    click_button 'Save and Continue'
    expect(page).to have_content(/Handling:\s\$2.70/)
    expect(page).to have_content(/Order Total:\s\$42.70/)

    click_on 'Save and Continue'
    click_on 'Place Order'
    expect(current_path).to match(spree.order_path(Spree::Order.last))
  end

  it 'updates the handling fee when cart contents change' do
    add_to_cart('RoR Mug')
    click_button 'Checkout'

    fill_in 'order_email', with: 'test@example.com'
    click_button 'Continue'
    fill_in_address(alabama_address)
    click_button 'Save and Continue'
    click_button 'Save and Continue'
    expect(page).to have_content(/Handling:\s\$1.90/)
    expect(page).to have_content(/Order Total:\s\$21.90/)

    add_to_cart('RoR Mug')
    click_button 'Checkout'
    click_button 'Save and Continue'
    click_button 'Save and Continue'
    expect(page).to have_content(/Handling:\s\$2.30/)
    expect(page).to have_content(/Order Total:\s\$32.30/)
  end

  def add_to_cart(item_name)
    visit spree.products_path
    click_link item_name
    click_button 'add-to-cart-button'
  end

  def fill_in_address(address)
    fieldname = 'order_bill_address_attributes'
    if SolidusSupport.combined_first_and_last_name_in_address?
      fill_in "#{fieldname}_name", with: address.name
    else
      fill_in "#{fieldname}_firstname", with: address.first_name
      fill_in "#{fieldname}_lastname", with: address.last_name
    end
    fill_in "#{fieldname}_address1", with: address.address1
    fill_in "#{fieldname}_city", with: address.city
    select address.country.name, from: "#{fieldname}_country_id"
    select address.state.name, from: "#{fieldname}_state_id"
    fill_in "#{fieldname}_zipcode", with: address.zipcode
    fill_in "#{fieldname}_phone", with: address.phone
  end

  def stock_location_address
    stock_location_address = build(
      :address,
      address1: '3121 W Government Way',
      city: 'Seattle',
      country: Spree::Country.where(name: 'United States of America').first,
      state: Spree::State.where(abbr: 'WA').first,
      zipcode: '98199-1402',
      phone: '(555) 5555-555'
    )
  end

  def alabama_address
    stock_location_address = build(
      :address,
      address1: '143 Swan Street',
      city: 'Montgomery',
      country: Spree::Country.where(name: 'United States of America').first,
      state: Spree::State.where(name: 'Alabama').first,
      zipcode: '36110',
      phone: '(555) 5555-555'
    )
  end
end
