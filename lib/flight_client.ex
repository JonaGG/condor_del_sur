#Funciones helper para interactuar con el servidor
defmodule FlightClient do
  @server :flight_server
  @timeout 5_000

  def available_seats(server \\ @server) do
    send(server, {:available_seats, self()})

    receive do
      {:available_seats_response, seats} -> seats
    after
      @timeout -> {:error, :timeout}
    end
  end

  def add_passenger(name, server \\ @server) do
    send(server, {:add_passenger, self(), name})

    receive do
      {:add_passenger_response, result} -> result
    after
      @timeout -> {:error, :timeout}
    end
  end

  def make_reservation(passenger_id, seat_id, server \\ @server) do
    send(server, {:make_reservation, self(), passenger_id, seat_id})

    receive do
      {:make_reservation_response, result} -> result
    after
      @timeout -> {:error, :timeout}
    end
  end

  def confirm_reservation(reservation_id, server \\ @server) do
    send(server, {:confirm_reservation, self(), reservation_id})

    receive do
      {:confirm_reservation_response, result} -> result
    after
      @timeout -> {:error, :timeout}
    end
  end

  def cancel_reservation(reservation_id, server \\ @server) do
    send(server, {:cancel_reservation, self(), reservation_id})

    receive do
      {:cancel_reservation_response, result} -> result
    after
      @timeout -> {:error, :timeout}
    end
  end

  def get_passenger(passenger_id, server \\ @server) do
    send(server, {:get_passenger, self(), passenger_id})

    receive do
      {:get_passenger_response, passenger} -> passenger
    after
      @timeout -> {:error, :timeout}
    end
  end

  def get_seat(seat_id, server \\ @server) do
    send(server, {:get_seat, self(), seat_id})

    receive do
      {:get_seat_response, seat} -> seat
    after
      @timeout -> {:error, :timeout}
    end
  end

  def get_reservation(reservation_id, server \\ @server) do
    send(server, {:get_reservation, self(), reservation_id})

    receive do
      {:get_reservation_response, reservation} -> reservation
    after
      @timeout -> {:error, :timeout}
    end
  end

  def get_flight_state(server \\ @server) do
    send(server, {:get_flight_state, self()})

    receive do
      {:flight_state_response, flight} -> flight
    after
      @timeout -> {:error, :timeout}
    end
  end

  def show_report(server \\ @server) do
    send(server, {:show_report, self()})
    receive do
      :ok -> :ok
    after
      @timeout -> {:error, :timeout}
    end
  end

  def clean_expired_reservations(server \\ @server) do
    send(server, {:clean_expired_reservations, self()})

    receive do
      {:clean_expired_reservations_response, :ok} -> :ok
    after
      @timeout -> {:error, :timeout}
    end
  end

  def expire_reservation(reservation_id) do
    send(:flight_server, {:expire_reservation, self(), reservation_id})

    receive do
      {:expire_reservation_response, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

end
