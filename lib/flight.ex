defmodule Flight do
   defstruct [
    :id, :origin, :destination,
    seats: %{},
    passengers: %{},
    reservations: %{},
    next_passenger_id: 1,
    next_reservation_id: 1
  ]

  def new(id, origin, destination, num_seats) do
    seats = Map.new(1..num_seats, fn i -> {i, Seat.new(i)} end)
    %Flight{id: id, origin: origin, destination: destination, seats: seats}
  end

  def add_passenger(%Flight{} = flight, name) do
    passenger = Passenger.new(flight.next_passenger_id, name)

    %Flight{flight | next_passenger_id: flight.next_passenger_id + 1,
    passengers: Map.put(flight.passengers, passenger.id, passenger)}
  end

  def get_passenger(%Flight{} = flight, passenger_id) do
    Map.get(flight.passengers, passenger_id)
  end

  # Devuelve una lista de asientos disponibles
  def available_seats(%Flight{} = flight) do
    flight.seats
    |> Map.values()
    |> Enum.filter(fn seat -> Seat.available?(seat) end)
  end

  # Dado un id de asiento, devuelve el asiento o nil si no existe
  def get_seat(%Flight{} = flight, seat_id) do
    Map.get(flight.seats, seat_id)
  end

  def make_reservation(%Flight{} = flight, passenger_id, seat_id) do
    cond do
      # Valida que pasajero existe
      !Map.has_key?(flight.passengers, passenger_id) ->
        {:error, :passenger_not_found}

       # Valida que asiento existe
      !Map.has_key?(flight.seats, seat_id) ->
        {:error, :seat_not_found}

      # Valida que asiento esté disponible
      !Seat.available?(flight.seats[seat_id]) ->
        {:error, :seat_not_available}

      true ->
        reservation = Reservation.new(flight.next_reservation_id, passenger_id, seat_id)
        updated_seat = Seat.change_status(flight.seats[seat_id], :reserved)

        updated_flight = %Flight{
          flight |
          next_reservation_id: flight.next_reservation_id + 1,
          reservations: Map.put(flight.reservations, reservation.id, reservation),
          seats: Map.put(flight.seats, seat_id, updated_seat)
        }

        {:ok, updated_flight, reservation}
    end
  end

  def confirm_reservation(%Flight{} = flight, reservation_id) do
    #Busca la reserva por su ID en el vuelo
    case Map.fetch(flight.reservations, reservation_id) do
      {:ok, reservation} ->
        seat = flight.seats[reservation.seat_id]

        # Validar que la reserva esté en :pending
        cond do
          reservation.status != :pending ->
            {:error, :reservation_not_pending}

          seat.status != :reserved ->
            {:error, :seat_not_reserved}

          true ->
            confirmed_reservation = Reservation.change_status(reservation, :confirmed)
            confirmed_seat = Seat.change_status(seat, :confirmed)

            updated_flight = %Flight{
              flight |
              reservations: Map.put(flight.reservations, reservation_id, confirmed_reservation),
              seats: Map.put(flight.seats, reservation.seat_id, confirmed_seat)
            }

            {:ok, updated_flight, confirmed_reservation}
        end

      :error ->
        {:error, :reservation_not_found}
    end
  end

  def cancel_reservation(%Flight{} = flight, reservation_id) do#ok
    case Map.fetch(flight.reservations, reservation_id) do
      {:ok, reservation} ->
        # Validar que la reserva esté en :pending
        if reservation.status != :pending do
          {:error, :reservation_not_pending}
        else
          seat = flight.seats[reservation.seat_id]
          cancelled_reservation = Reservation.change_status(reservation, :cancelled)
          updated_seat = Seat.change_status(seat, :available)

          updated_flight = %Flight{
            flight |
            reservations: Map.put(flight.reservations, reservation_id, cancelled_reservation),
            seats: Map.put(flight.seats, reservation.seat_id, updated_seat)
          }
          {:ok, updated_flight}
        end

      :error ->
        {:error, :reservation_not_found}
    end
  end

  def get_reservation(%Flight{} = flight, reservation_id) do #ok
    Map.get(flight.reservations, reservation_id)
  end

  def expire_reservation(%Flight{} = flight, reservation_id) do
    case Map.fetch(flight.reservations, reservation_id) do
      :error ->
        {:error, :reservation_not_found}

      {:ok, reservation} ->
        case reservation.status do
          :pending ->
            seat = flight.seats[reservation.seat_id]
            expired_reservation = Reservation.change_status(reservation, :expired)
            updated_seat = Seat.change_status(seat, :available)
            {:ok, %Flight{
              flight |
              reservations: Map.put(flight.reservations, reservation_id, expired_reservation),
              seats: Map.put(flight.seats, seat.id, updated_seat)
            }}

          _ ->
            {:error, :reservation_not_pending}
        end
    end
  end

  def clean_expired_reservations(%Flight{} = flight) do #NO CHEKEADA
    expired_ids = flight.reservations
      |> Map.filter(fn {_, reservation} -> reservation.status == :pending && Reservation.expired?(reservation) end)
      |> Map.keys()

    Enum.reduce(expired_ids, flight, fn reservation_id, acc_flight ->
      case expire_reservation(acc_flight, reservation_id) do
        {:ok, updated_flight} -> updated_flight
        {:error, _} -> acc_flight
      end
    end)
  end

  def show_report(%Flight{} = flight) do

    IO.puts("\n" <> String.duplicate("=", 40))
    IO.puts("  REPORTE: #{flight.origin} → #{flight.destination}")
    IO.puts(String.duplicate("=", 40))

    total_personas = map_size(flight.passengers)
    IO.puts("PASAJEROS REGISTRADOS: #{total_personas}")

    total_seats = map_size(flight.seats)
    IO.puts("CANTIDAD DE ASIENTOS:  #{total_seats}")
    IO.puts(String.duplicate("-", 20))

    stats = flight.seats |> Map.values() |> Enum.frequencies_by(& &1.status)
    IO.puts("Asientos disponibles:  #{stats[:available] || 0}")
    IO.puts("Asientos reservados:   #{stats[:reserved] || 0}")
    IO.puts("Asientos confirmados:  #{stats[:confirmed] || 0}")

    IO.puts("\n" <> String.duplicate("-", 20))

    res_stats = flight.reservations |> Map.values() |> Enum.frequencies_by(& &1.status)
    IO.puts("Reservas confirmadas: #{res_stats[:confirmed] || 0}")
    IO.puts("Reservas canceladas:  #{res_stats[:cancelled] || 0}")
    IO.puts("Reservas expiradas:   #{res_stats[:expired] || 0}")
    IO.puts("Reservas pendientes:  #{res_stats[:pending] || 0}")

    IO.puts("\nReservas:")
    flight.reservations |> Map.values() |> Enum.each(fn r ->
    IO.puts("  [#{r.status}] reserva #{r.id} | pasajero #{r.passenger_id} | asiento #{r.seat_id}")
    end)

    IO.puts(String.duplicate("=", 40))
  end

end
