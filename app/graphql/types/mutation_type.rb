# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :sign_in, mutation: Mutations::Users::SignIn
    field :sign_up, mutation: Mutations::Users::SignUp
    field :sign_out, mutation: Mutations::Users::SignOut
  end
end
