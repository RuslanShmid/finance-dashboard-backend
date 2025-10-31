# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = build_context
    result = FinanceDashboardBackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [ { message: e.message, backtrace: e.backtrace } ], data: {} }, status: 500
  end

  def build_context
    {
      current_user: current_user,
      token: extract_token_from_header
    }
  end

  def current_user
    @current_user ||= begin
      token = extract_token_from_header
      return nil unless token

      begin
        secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
        jwt_payload = JWT.decode(token, secret, true, algorithm: "HS256").first

        # Check if token is in denylist
        jti = jwt_payload["jti"]
        if jti && JwtDenylist.exists?(jti: jti)
          return nil
        end

        user_id = jwt_payload["sub"]
        User.find(user_id)
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        nil
      end
    end
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header.present?

    # Extract token from "Bearer <token>" format
    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end
end
