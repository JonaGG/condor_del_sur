defmodule Reservation do
  @reservation_timeout_seconds 30

  defstruct [:id, :passenger_id, :seat_id, :status, :created_at]

  def new(id, passenger_id, seat_id) do
    %Reservation{
      id: id,
      passenger_id: passenger_id,
      seat_id: seat_id,
      status: :pending,
      created_at: System.monotonic_time(:second)
    }
  end

  def change_status(reservation, new_status) do
    %{reservation | status: new_status}
  end

  def expired?(reservation) do
    elapsed = System.monotonic_time(:second) - reservation.created_at
    elapsed > @reservation_timeout_seconds
  end

end
