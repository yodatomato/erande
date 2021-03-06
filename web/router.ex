defmodule Erande.Router do
  use Erande.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Erande do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/ranking/", RankingController, :ranking
    get "/questions/answerclean", QuestionController, :answerclean
    resources "/questions", QuestionController do
      resources "/solutions", SolutionController
      get "/solutions/:id/mark", SolutionController, :mark
      get "/solutions/:id/unmark", SolutionController, :unmark
    end
    get "/questions/:id/propose", QuestionController, :propose_question
    get "/questions/:id/unpropose", QuestionController, :unpropose
    get "/questions/:id/answercheck", QuestionController, :answercheck
    get "/questions/:id/answeropen", QuestionController, :answeropen
  end

  scope "/auth", Erande do
    pipe_through [:browser]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", Erande do
  #   pipe_through :api
  # end
end
