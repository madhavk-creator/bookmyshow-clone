require "test_helper"

class TheatresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @theatre = theatres(:one)
  end

  test "should get index" do
    get theatres_url, as: :json
    assert_response :success
  end

  test "should create theatres" do
    assert_difference("Theatre.count") do
      post theatres_url, params: { theatre: {} }, as: :json
    end

    assert_response :created
  end

  test "should shows theatres" do
    get theatre_url(@theatre), as: :json
    assert_response :success
  end

  test "should update theatres" do
    patch theatre_url(@theatre), params: { theatre: {} }, as: :json
    assert_response :success
  end

  test "should destroy theatres" do
    assert_difference("Theatre.count", -1) do
      delete theatre_url(@theatre), as: :json
    end

    assert_response :no_content
  end
end
