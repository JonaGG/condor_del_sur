#Las reservas expiran automáticamente a los 30 segundos (al final no deberían quedar reservas en :pending)
defmodule ExpirationProcess do
  @expiration_timeout 30_000
  def start(reservation_id) do
    spawn(fn ->
     Process.sleep(@expiration_timeout)
      case FlightClient.expire_reservation(reservation_id) do
        :ok -> IO.puts("[Expiración] reserva #{reservation_id} expirada")
       {:error, _} -> :ok
      end
    end)
  end
end
