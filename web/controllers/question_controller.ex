## ----------------------
## 問題管理コントローラー
## ----------------------
defmodule Zohyothanksgiving.QuestionController do
  use Zohyothanksgiving.Web, :controller

  alias Zohyothanksgiving.Question
  alias Zohyothanksgiving.ProposedQuestion

  plug :scrub_params, "question" when action in [:create, :update]

  # get /questions/
  def index(conn, _params) do
    questions = Repo.all(from(q in Question, preload: :proposed_question))
    render(conn, "index.html", questions: questions)
  end

  # get /questions/new
  def new(conn, _params) do
    changeset = Question.changeset(%Question{})
    render(conn, "new.html", changeset: changeset)
  end

  # post /questions/
  def create(conn, %{"question" => question_params}) do
    changeset = Question.changeset(%Question{}, question_params)

    case Repo.insert(changeset) do
      {:ok, _question} ->
        conn
        |> put_flash(:info, "Question created successfully.")
        |> redirect(to: question_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # get /questions/:id
  def show(conn, %{"id" => id}) do
    question = Repo.get!(Question, id)
    render(conn, "show.html", question: question)
  end

  # get /questions/:id/edit
  def edit(conn, %{"id" => id}) do
    question = Repo.get!(Question, id)
    changeset = Question.changeset(question)
    render(conn, "edit.html", question: question, changeset: changeset)
  end

  # put /questions/:id
  def update(conn, %{"id" => id, "question" => question_params}) do
    question = Repo.get!(Question, id)
    changeset = Question.changeset(question, question_params)

    case Repo.update(changeset) do
      {:ok, question} ->
        conn
        |> put_flash(:info, "Question updated successfully.")
        |> redirect(to: question_path(conn, :show, question))
      {:error, changeset} ->
        render(conn, "edit.html", question: question, changeset: changeset)
    end
  end

  # delete /questions/:id
  def delete(conn, %{"id" => id}) do
    question = Repo.get!(Question, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(question)

    conn
    |> put_flash(:info, "Question deleted successfully.")
    |> redirect(to: question_path(conn, :index))
  end

  # 問題公開
  def propose_question(conn, %{"id" => id}) do
    question = Repo.get!(Question, id)
               |> Repo.preload :solutions
    Repo.delete_all(ProposedQuestion)
    proposed_question = Ecto.Model.build(question, :proposed_question)
    Repo.insert!(proposed_question)
    solutions = Repo.preload question.solutions, :collectanswer
    rs_solutions = Enum.map(solutions, fn(solution) -> %{id: solution.id, body: solution.body, correct: !is_nil(solution.collectanswer)} end)
    IO.inspect rs_solutions, pretty: true

    Zohyothanksgiving.Endpoint.broadcast! "rooms:lobby", "proposed", %{question_id: question.id, question_body: question.body, solutions: rs_solutions}
    conn
    |> put_flash(:info, "問題を公開しました")
    |> redirect(to: question_path(conn, :show, id))
  end

  # 問題取り消し
  def unpropose(conn, %{"id" => id}) do
    Repo.delete_all(ProposedQuestion)
    Zohyothanksgiving.Endpoint.broadcast! "rooms:lobby", "proposed", %{question_id: 0, question_body: "出題待ち", solutions: []}
    conn
    |> put_flash(:info, "問題を取り消ししました")
    |> redirect(to: question_path(conn, :index))
  end
end
