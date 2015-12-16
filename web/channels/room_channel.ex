defmodule Zohyothanksgiving.RoomChannel do
  use Zohyothanksgiving.Web, :channel

  def join("rooms:lobby", payload, socket) do
    if authorized?(payload) do
      proposed_questions = Repo.all Zohyothanksgiving.ProposedQuestion
      if is_nil proposed_questions do
        {:ok, %{question_id: 0, question_body: "出題待ち", solutions: []}, socket}
      else
        [proposed_question] = Repo.preload proposed_questions, :question
        question = Repo.preload proposed_question.question, :solutions
        solutions = Repo.preload question.solutions, :collectanswer
        rs_solutions = Enum.map(solutions, fn(solution) -> %{id: solution.id, body: solution.body, correct: !is_nil(solution.collectanswer)} end)
        IO.inspect rs_solutions, pretty: true

        {:ok, %{question_id: question.id, question_body: question.body, solutions: rs_solutions}, socket}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (rooms:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
