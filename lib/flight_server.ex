defmodule FlightServer do
  def start(initial_flight) do
    pid = spawn(fn -> loop(initial_flight) end)
    Process.register(pid, :flight_server)  # Registra el proceso con un nombre

    if Process.whereis(:audit_server) do
     send(:audit_server, {:flight_server_ready, pid})
    end

    pid
  end

  # Envía un mensaje de log al AuditServer si está disponible
  defp log(message) do
    if Process.whereis(:audit_server) do
      send(:audit_server, {:log, message})
    end
  end

  defp loop(%Flight{} = flight) do
    receive do
      {:available_seats, caller} ->
        send(caller, {:available_seats_response, Flight.available_seats(flight)})
        loop(flight)

      {:add_passenger, caller, name} ->
        updated_flight = Flight.add_passenger(flight, name)
        passenger_id = updated_flight.next_passenger_id - 1
        log("Pasajero #{passenger_id} (#{name}) agregado")
        send(caller, {:add_passenger_response, {:ok, passenger_id}})
        loop(updated_flight)

      {:make_reservation, caller, passenger_id, seat_id} ->
        case Flight.make_reservation(flight, passenger_id, seat_id) do
          {:ok, updated_flight, reservation} ->
            log("Reserva #{reservation.id} creada - pasajero #{passenger_id} asiento #{seat_id}")
            send(caller, {:make_reservation_response, {:ok, reservation}})
            loop(updated_flight)
          {:error, reason} ->
            log("Reserva fallida - pasajero #{passenger_id} asiento #{seat_id}: #{reason}")
            send(caller, {:make_reservation_response, {:error, reason}})
            loop(flight)
        end

      {:confirm_reservation, caller, reservation_id} ->
        case Flight.confirm_reservation(flight, reservation_id) do
          {:ok, updated_flight, reservation} ->
            log("Reserva #{reservation_id} confirmada - asiento #{reservation.seat_id}")
            send(caller, {:confirm_reservation_response, {:ok, reservation}})
            loop(updated_flight)
          {:error, reason} ->
            log("Confirmación fallida - reserva #{reservation_id}: #{reason}")
            send(caller, {:confirm_reservation_response, {:error, reason}})
            loop(flight)
        end

      {:cancel_reservation, caller, reservation_id} ->
        case Flight.cancel_reservation(flight, reservation_id) do
          {:ok, updated_flight} ->
            log("Reserva #{reservation_id} cancelada")
            send(caller, {:cancel_reservation_response, :ok})
            loop(updated_flight)
          {:error, reason} ->
            log("Cancelación fallida - reserva #{reservation_id}: #{reason}")
            send(caller, {:cancel_reservation_response, {:error, reason}})
            loop(flight)
        end

      {:get_passenger, caller, passenger_id} ->
        passenger = Flight.get_passenger(flight, passenger_id)
        send(caller, {:get_passenger_response, passenger})
        loop(flight)

      {:get_reservation, caller, reservation_id} ->
        reservation = Flight.get_reservation(flight, reservation_id)
        send(caller, {:get_reservation_response, reservation})
        loop(flight)

      {:get_seat, caller, seat_id} ->
        seat = Flight.get_seat(flight, seat_id)
        send(caller, {:get_seat_response, seat})
        loop(flight)

      {:get_flight_state, caller} ->
        send(caller, {:flight_state_response, flight})
        loop(flight)

      {:expire_reservation, caller, reservation_id} ->
        case Flight.expire_reservation(flight, reservation_id) do
          {:ok, updated_flight} ->
            log("Reserva #{reservation_id} expirada")
            send(caller, {:expire_reservation_response, :ok})
            loop(updated_flight)
          {:error, reason} ->
            send(caller, {:expire_reservation_response, {:error, reason}})
            loop(flight)
        end

      {:clean_expired_reservations, caller} -> #para tareas auxiliares
        updated_flight = Flight.clean_expired_reservations(flight)
        send(caller, {:clean_expired_reservations_response, :ok})
        loop(updated_flight)

      {:show_report, caller} ->
        Flight.show_report(flight)
        send(caller, :ok)
        loop(flight)
    end
  end
end
