require 'spec_helper'

describe "actions/edit" do
  before(:each) do
    @action = assign(:action, stub_model(Action,
      :title => "MyString",
      :short_desc => "MyString",
      :target => nil
    ))
  end

  it "renders the edit action form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", action_path(@action), "post" do
      assert_select "input#action_title[name=?]", "action[title]"
      assert_select "input#action_short_desc[name=?]", "action[short_desc]"
      assert_select "input#action_target[name=?]", "action[target]"
    end
  end
end
