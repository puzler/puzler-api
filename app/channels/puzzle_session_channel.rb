class PuzzleSessionChannel < ApplicationCable::Channel
  def subscribed
    puzzle_id = params[:puzzle_id]
    stream_from "puzzle_session:#{puzzle_id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
