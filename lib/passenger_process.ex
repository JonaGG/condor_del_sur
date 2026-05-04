defmodule PassengerProcess do
  def start(passenger_id, seat_id, action \\ :confirm) do
    spawn(fn -> run(passenger_id, seat_id, action) end)
  end

  defp run(passenger_id, seat_id, action) do
    case FlightClient.make_reservation(passenger_id, seat_id) do
      {:ok, reservation} ->
        IO.puts("[Pasajero #{passenger_id}] reservó asiento #{seat_id}")
        IO.puts("[Tarea auxiliar] ExpirationProcess lanzado para reserva #{reservation.id}")
        ExpirationProcess.start(reservation.id) #caso expiración, se encargará de expirar la reserva después de un tiempo

        case action do
          :confirm ->
            Process.sleep(:rand.uniform(3000))
            FlightClient.confirm_reservation(reservation.id)
            IO.puts("[Pasajero #{passenger_id}] confirmó reserva #{reservation.id}")

          :cancel ->
            Process.sleep(:rand.uniform(1000))
            FlightClient.cancel_reservation(reservation.id)
            IO.puts("[Pasajero #{passenger_id}] canceló reserva #{reservation.id}")

          :expire ->
            IO.puts("[Pasajero #{passenger_id}] dejó expirar reserva #{reservation.id}")
        end

      {:error, reason} ->
        IO.puts("[Pasajero #{passenger_id}] no pudo reservar asiento #{seat_id}: #{reason}")
    end
  end
end
