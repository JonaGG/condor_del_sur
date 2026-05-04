defmodule Demo do
  def run do
    IO.puts("\n=== CÓNDOR DEL SUR - Sistema de reservas concurrentes ===")
    IO.puts("Vuelo: Buenos Aires → Bariloche | 13 asientos | 104 pasajeros\n")

    Process.sleep(800)

    # Crear vuelo:
    # asientos 1-10: competencia concurrente
    # asiento 11: cancelación
    # asiento 12: expiración
    # asiento 13: confirmación explícita (tarea auxiliar)
    flight = Flight.new(1, "Buenos Aires", "Bariloche", 13)
    flight = Enum.reduce(1..104, flight, fn i, acc ->
      Flight.add_passenger(acc, "Pasajero #{i}")
    end)

    AuditServer.start()
    FlightServer.start(flight)
        Process.sleep(500)######

    # --- PARTE 1: confirmación explícita ---
    IO.puts("--- [1] Caso de confirmación: pasajero 103 reserva el asiento 13 y confirma ---\n")
    PassengerProcess.start(103, 13, :confirm)
    esperar_ciclo_puntos("Procesando confirmación", 4)####Process.sleep(4000)
        pausa("Confirmación completada")#####


    # --- PARTE 2: cancelación ---
    IO.puts("\n--- [2] Caso de cancelación: pasajero 101 reserva el asiento 11 y cancela ---\n")
    PassengerProcess.start(101, 11, :cancel)
    esperar_ciclo_puntos("Procesando cancelación", 2)
        pausa("Cancelación completada")###


    # --- PARTE 3: expiración + tarea auxiliar ---
    IO.puts("\n--- [3] Caso de expiración con tarea auxiliar ---")##
    IO.puts("      Pasajero 102 reserva el asiento 12 y no confirma.")##
    #IO.puts("\n--- [3] Caso de expiración: pasajero 102 reserva el asiento 12 y no confirma ---\n")
    IO.puts("      (ExpirationProcess lanzado: expirará automáticamente en 30 segundos)\n")
    expiration_start = System.monotonic_time(:second)######////
    PassengerProcess.start(102, 12, :expire)
    esperar_ciclo_puntos("Esperando log de tarea auxiliar", 2)##
    pausa("Tarea auxiliar lanzada — expirará al final de la demo")##


    # --- PARTE 4: competencia concurrente ---
    IO.puts("\n--- [4] 100 pasajeros compiten por 10 asientos al mismo tiempo ---\n")
    IO.puts("      (los logs van a ir rápido)\n")##
    Process.sleep(2000)######
    for n <- 1..100 do
      seat_id = :rand.uniform(10)
      spawn(fn ->
        delay = :rand.uniform(500)#aleatorio para simular llegada concurrente
        Process.sleep(delay)
        PassengerProcess.start(n, seat_id, :confirm)
      end)
    end

    esperar_ciclo_puntos("Procesando reservas concurrentes", 5)
    pausa("Competencia resuelta")##

    # --- PARTE 5: esperar expiración del asiento 12 ---
    elapsed = System.monotonic_time(:second) - expiration_start #####/
    remaining = max(30 - elapsed, 0)#####/
    IO.puts("\n--- [5] Esperando que expire la reserva del asiento 12 ---\n")
    IO.puts("      (el proceso auxiliar lanzado en la parte 3 sigue corriendo)\n")##
    esperar_ciclo_puntos("Esperando expiración automática", remaining)#esperar_ciclo_puntos("Esperando expiración automática (30 seg)", 30)
    Process.sleep(1500)##
    pausa("Expiración completada")##

    # --- REPORTE FINAL ---
    IO.puts("\n--- [6] Estado final del vuelo ---")
    IO.puts("      Resultado esperado:")
    IO.puts("        Asientos  → 11 confirmados | 2 disponibles (cancelado + expirado) | 0 reservados")
    IO.puts("        Reservas  → 11 confirmadas | 1 cancelada | 1 expirada | 0 pendientes\n")

    FlightClient.show_report()
  end


  defp pausa(mensaje) do
    IO.puts("\n  ✓ #{mensaje}")
    Process.sleep(1500)
  end


  defp esperar_ciclo_puntos(mensaje, segundos) do
    IO.write("\n#{mensaje} ")
    patron = [".", "..", "...", ".."]

    Enum.each(0..segundos-1, fn i ->
      Process.sleep(1000)
      IO.write("\r#{mensaje} #{Enum.at(patron, rem(i, 4))}")
    end)

    IO.puts("")
  end
end
