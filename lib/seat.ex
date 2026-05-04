defmodule Seat do
  defstruct [:id, status: :available]

  def new(id), do: %Seat{id: id}

  def change_status(seat, new_status) do
    %{seat | status: new_status}
  end

  def available?(seat) do
    seat.status == :available
  end

end
