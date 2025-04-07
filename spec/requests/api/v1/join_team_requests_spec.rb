# spec/requests/api/v1/join_team_requests_spec.rb

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/join_team_requests', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end
  let(:instructor_user) do
    User.create!(
      name: "instructor_user",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor User",
      email: "instructor@example.com",
      mru_directory_path: "/home/instructor"
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: "Sample Assignment",
      directory_path: "sample_assign",
      instructor_id: instructor_user.id  # Must pass an instructor
    )
  end
  let(:admin_user) do
    User.create!(
      name: "admin_user",
      password_digest: "password",
      role_id: @roles[:admin].id,
      full_name: "Admin User",
      email: "admin@example.com",
      mru_directory_path: "/home/admin"
    )
  end

  let(:student_user) do
    User.create!(
      name: "student_user",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student User",
      email: "student@example.com",
      mru_directory_path: "/home/student"
    )
  end

  let(:admin_token)   { JsonWebToken.encode({ id: admin_user.id }) }
  let(:student_token) { JsonWebToken.encode({ id: student_user.id }) }


  let(:participant) do
    Participant.create!(
      user_id: student_user.id,
      assignment_id: assignment.id
    )
  end

  let(:team) do
    Team.create!(
      # name: "Sample Team", # Uncomment if the "teams" table has a :name column
      assignment_id: assignment.id
    )
  end

  let(:join_team_request) do
    JoinTeamRequest.create!(
      comments: "Please let me join!",
      status: "PENDING",
      participant_id: participant.id,
      team_id: team.id # If your join_team_requests table really has a :team_id column
    )
  end

  #--------------------------------------------------------------------------
  # GET /join_team_requests
  #--------------------------------------------------------------------------
  path '/api/v1/join_team_requests' do
    get('list join_team_requests') do
      tags 'JoinTeamRequests'
      produces 'application/json'
      let(:Authorization) { "Bearer #{admin_token}" }

      response(200, 'successful') do
        before { join_team_request } # Ensures at least one record
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(403, 'forbidden') do
        let(:Authorization) { "Bearer #{student_token}" }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { errors: "Unauthorized" }
            }
          }
        end
        run_test!
      end
    end

    #--------------------------------------------------------------------------
    # POST /join_team_requests
    #--------------------------------------------------------------------------
    post('create join_team_request') do
      before do
        participant  # This ensures the participant is created in the DB
        team
        end
        tags 'JoinTeamRequests'
      consumes 'application/json'
      produces 'application/json'
      let(:Authorization) { "Bearer #{student_token}" }

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comments:      { type: :string },
          team_id:       { type: :integer },
          assignment_id: { type: :integer }
        },
        required: %w[team_id assignment_id]
      }

      response(201, 'created') do
        let(:payload) do
          {
            comments: "I would love to join your team!",
            team_id: team.id,
            assignment_id: assignment.id
          }
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable_entity') do
        let(:payload) do
          {
            comments: "Invalid request with no assignment",
            team_id: team.id
            # missing assignment_id => triggers "Participant not found"
          }
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { errors: "Participant not found" }
            }
          }
        end
        run_test!
      end
    end
  end

  #--------------------------------------------------------------------------
  # GET/PUT/PATCH/DELETE /join_team_requests/{id}
  #--------------------------------------------------------------------------
  path '/api/v1/join_team_requests/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'join_team_request id'

    let(:id) { join_team_request.id }

    #----------------------------------
    # GET
    #----------------------------------
    get('show join_team_request') do
      tags 'JoinTeamRequests'
      produces 'application/json'
      let(:Authorization) { "Bearer #{student_token}" }

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    #----------------------------------
    # PATCH
    #----------------------------------
    patch('update join_team_request') do
      tags 'JoinTeamRequests'
      consumes 'application/json'
      produces 'application/json'
      let(:Authorization) { "Bearer #{student_token}" }

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comments: { type: :string },
          status:   { type: :string }
        }
      }

      response(200, 'successful') do
        let(:payload) { { comments: "Updated Comments" } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "JoinTeamRequest was successfully updated" }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable_entity') do
        let(:payload) { { status: "INVALID_STATUS" } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { errors: ["Status is not included in the list"] }
            }
          }
        end
        run_test!
      end
    end

    #----------------------------------
    # PUT
    #----------------------------------
    put('update join_team_request') do
      tags 'JoinTeamRequests'
      consumes 'application/json'
      produces 'application/json'
      let(:Authorization) { "Bearer #{student_token}" }

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comments: { type: :string },
          status:   { type: :string }
        }
      }

      response(200, 'successful') do
        let(:payload) { { comments: "Updated Comments via PUT" } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "JoinTeamRequest was successfully updated" }
            }
          }
        end
        run_test!
      end
    end

    #----------------------------------
    # DELETE
    #----------------------------------
    delete('delete join_team_request') do
      tags 'JoinTeamRequests'
      produces 'application/json'
      let(:Authorization) { "Bearer #{student_token}" }

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "JoinTeamRequest was successfully deleted" }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable_entity') do
        before do
          allow_any_instance_of(JoinTeamRequest).to receive(:destroy).and_return(false)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { errors: "Failed to delete JoinTeamRequest" }
            }
          }
        end
        run_test!
      end
    end
  end

  #--------------------------------------------------------------------------
  # POST /api/v1/join_team_requests/decline/{id}
  #--------------------------------------------------------------------------
  # This matches the route in routes.rb:
  #   collection do
  #     post 'decline/:id', to: 'join_team_requests#decline'
  #   end
  #
  path '/api/v1/join_team_requests/decline/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'join_team_request id'

    post('decline join_team_request') do
      let(:id) { join_team_request.id }
      let(:Authorization) { "Bearer #{student_token}" }

      response(200, 'successful') do
        run_test!
      end

      response(422, 'unprocessable_entity') do
        before do
          allow_any_instance_of(JoinTeamRequest).to receive(:save).and_return(false)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { errors: ["Some validation error message"] }
            }
          }
        end
        run_test!
      end
    end
  end
end
