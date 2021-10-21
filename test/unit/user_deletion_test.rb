require 'test_helper'

class UserDeletionTest < ActiveSupport::TestCase
  setup do
    @request = mock
    @request.stubs(:remote_ip).returns("1.1.1.1")
    @request.stubs(:user_agent).returns("Firefox")
    @request.stubs(:session).returns(session_id: "1234")
  end

  context "an invalid user deletion" do
    context "for an invalid password" do
      should "fail" do
        @user = create(:user)
        @deletion = UserDeletion.new(@user, "wrongpassword", @request)
        @deletion.delete!
        assert_includes(@deletion.errors[:base], "Password is incorrect")
      end
    end

    context "for an admin" do
      should "fail" do
        @user = create(:admin_user)
        @deletion = UserDeletion.new(@user, "password", @request)
        @deletion.delete!
        assert_includes(@deletion.errors[:base], "Admins cannot delete their account")
      end
    end

    context "for a banned user" do
      should "fail" do
        @user = create(:banned_user)
        @deletion = UserDeletion.new(@user, "password", @request)
        @deletion.delete!
        assert_includes(@deletion.errors[:base], "You cannot delete your account if you are banned")
      end
    end
  end

  context "a valid user deletion" do
    setup do
      @user = create(:user, name: "foo", email_address: build(:email_address))
      @deletion = UserDeletion.new(@user, "password", @request)
    end

    should "blank out the email" do
      @deletion.delete!
      assert_nil(@user.reload.email_address)
    end

    should "rename the user" do
      @deletion.delete!
      assert_equal("user_#{@user.id}", @user.reload.name)
    end

    should "generate a user name change request" do
      assert_difference("UserNameChangeRequest.count") do
        @deletion.delete!
      end

      assert_equal("foo", UserNameChangeRequest.last.original_name)
      assert_equal("user_#{@user.id}", UserNameChangeRequest.last.desired_name)
    end

    should "reset the password" do
      @deletion.delete!
      assert_equal(false, @user.authenticate_password("password"))
    end

    should "remove any favorites" do
      @post = create(:post)
      Favorite.create!(post: @post, user: @user)

      perform_enqueued_jobs { @deletion.delete! }

      assert_equal(0, Favorite.count)
      assert_equal(0, @post.reload.fav_count)
    end
  end
end
