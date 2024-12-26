# frozen_string_literal: true

module Api
  module V1
    # Controller for QuoteCheckFeedbacks API
    class QuoteCheckFeedbacksController < BaseController
      before_action :authorize_request
      before_action :quote_check
      before_action :validation_error_details, if: -> { params[:validation_error_detail_id].present? }

      def create
        @quote_check_feedback = quote_check.feedbacks.create!(quote_check_feedback_params)

        render json: @quote_check_feedback.attributes.slice(
          "id", "quote_check_id", "validation_error_details_id", "is_helpful", "comment"
        ), status: :created
      end

      protected

      def quote_check
        @quote_check ||= QuoteCheck.find(params[:quote_check_id])
      end

      def quote_check_feedback_params
        raw_params = params.permit(:validation_error_details_id, :is_helpful, :comment)
        return raw_params unless defined?(@validation_error_details)

        raw_params.merge(validation_error_details_id: @validation_error_details.fetch("id"))
      end

      def validation_error_details
        # validation_error_detail_id is in singular in path params
        @validation_error_details ||= quote_check.validation_error_details.detect do |details|
          details.fetch("id") == params[:validation_error_detail_id]
        end || raise(ActiveRecord::RecordNotFound,
                     "Couldn't find ValidationErrorDetails with 'id'=#{params[:validation_error_detail_id]}")
      end
    end
  end
end
