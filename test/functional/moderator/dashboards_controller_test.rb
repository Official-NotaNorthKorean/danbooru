require 'test_helper'

module Moderator
  class DashboardsControllerTest < ActionDispatch::IntegrationTest
    context "The moderator dashboards controller" do
      setup do
        travel_to(1.month.ago) do
          @user = create(:gold_user)
        end
        @admin = create(:admin_user)
      end

      context "show action" do
        context "for mod actions" do
          setup do
            as(@admin) do
              @mod_action = create(:mod_action)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for user feedbacks" do
          setup do
            as(@user) do
              @feedback = create(:user_feedback)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for wiki pages" do
          setup do
            as(@user) do
              @wiki_page = create(:wiki_page)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for tags and uploads" do
          setup do
            as(@user) do
              @post = create(:post)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for notes" do
          setup do
            as(@user) do
              @post = create(:post)
              @note = create(:note, :post_id => @post.id)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for comments" do
          setup do
            @users = (0..5).map {create(:user)}

            as(@users[0]) do
              @comment = create(:comment)
            end

            @users.each do |user|
              create(:comment_vote, score: -1, comment: @comment, user: user)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for artists" do
          setup do
            as(@user) do
              @artist = create(:artist)
            end
          end

          should "render" do
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for flags" do
          should "render" do
            create(:post_flag)
            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end

        context "for appeals" do
          should "render" do
            @post = create(:post, is_deleted: true)
            @appeal = create(:post_appeal, post: @post)

            get_auth moderator_dashboard_path, @admin
            assert_response :success
          end
        end
      end
    end
  end
end
