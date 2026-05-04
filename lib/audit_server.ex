# Servidor de auditoría: registra eventos importantes del sistema en consola
defmodule AuditServer do

  def start do
    pid = spawn(fn -> setup_monitor() end)
    Process.register(pid, :audit_server) #Registra el proceso con un nombre
    pid
  end

  #Configura el monitor: si FlightServer ya existe lo monitorea, si no espera su aviso
  defp setup_monitor do
    case Process.whereis(:flight_server) do
      nil ->
        wait_flight_ready()

      flight_pid ->
        ref = Process.monitor(flight_pid)
        loop(ref)
    end
  end

  #Espera bloqueado hasta recibir el aviso de que FlightServer está listo
  defp wait_flight_ready do
    receive do
      {:flight_server_ready, flight_pid} ->
        ref = Process.monitor(flight_pid)
        loop(ref)
    end
  end

  # Registra logs y detecta caída del FlightServer
  defp loop(ref) do
    receive do
      {:log, message} ->
        IO.puts("[AUDIT] #{message}")
        loop(ref)

      {:DOWN, ^ref, :process, _pid, reason} ->
        IO.puts("[AUDIT] CRÍTICO: FlightServer caído. Razón: #{inspect(reason)}")
    end
  end

end
